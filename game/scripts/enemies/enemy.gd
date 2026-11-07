extends CharacterBody3D

## A Toony Tiny soldier guarding one clearing (D-078). Stands at home until
## Kaze comes close, chases him, swings when in reach and goes back home (and
## heals) if he leaves. Works with Kaze's auto-attack through the "enemies"
## group: take_hit(damage, from, force) and is_alive(). Respawns at home a
## while after dying. Far from the hero it sleeps (no physics, paused
## animation) to save phone CPU.

const SoldierAnimations = preload("res://scripts/enemies/soldier_animations.gd")
const BlobShadow = preload("res://scripts/world/blob_shadow.gd")
const Progression = preload("res://scripts/progression.gd")

const GRAVITY := 40.0
## Kaze stays a target while within this distance of the soldier's home.
const LEASH := 34.0
const ACTIVE_DISTANCE := 95.0
const RESPAWN_SECONDS := 30.0
const TURN_SPEED := 10.0
const HIT_SLACK := 1.4
const HEAL_PER_SECOND := 2.0

enum State { IDLE, CHASE, ATTACK, STAGGER, RETURN, DEAD }

var data: Dictionary
## Subclasses (levelled knights, D-080) shorten these.
var leash := LEASH
var respawn_seconds := RESPAWN_SECONDS
## Respawn waits only for the timer (D-088); -1 means "wherever Kaze is".
var respawn_distance := -1.0
var home := Vector3.ZERO
var hero: CharacterBody3D
var health := 1.0
var state := State.IDLE

var _visual: Node3D
var _model: Node3D
var _animation: AnimationPlayer
var _meshes: Array[MeshInstance3D] = []
var _bar: MeshInstance3D
var _bar_material: ShaderMaterial
var _timer := 0.0
var _cooldown := 0.0
var _swing_length := 0.7
var _hit_at := 0.4
var _hit_landed := false
## Defeated mid-swing: the swing still finishes and hits, then it falls (D-083).
var _dying := false
var _death_away := Vector3.BACK
var _sleeping := false
var _heal := 0.0
var _tween: Tween

static var _flash_material: StandardMaterial3D
static var _bar_shader: Shader
static var _model_scale := {}

func setup(entry: Dictionary, at: Vector3, target: CharacterBody3D) -> void:
	data = entry
	home = at
	hero = target
	health = float(max_health())
	name = data.id

func _ready() -> void:
	add_to_group("enemies")
	add_to_group("bodies")
	collision_layer = 2
	collision_mask = 1
	floor_snap_length = 0.8
	floor_max_angle = deg_to_rad(35.0)
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 1.5
	capsule.height = 3.0
	shape.shape = capsule
	shape.position.y = 1.5
	add_child(shape)
	_visual = Node3D.new()
	_visual.name = "Visual"
	add_child(_visual)
	_model = (load(data.model) as PackedScene).instantiate()
	_visual.add_child(_model)
	_model.scale = Vector3.ONE * _scale_for(data.model, _model, float(data.height))
	for mesh in _model.find_children("*", "MeshInstance3D", true, false):
		mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_meshes.append(mesh)
	var skeleton: Skeleton3D = _model.find_children("*", "Skeleton3D", true, false)[0]
	_animation = AnimationPlayer.new()
	_model.add_child(_animation)
	_animation.root_node = _animation.get_path_to(_model)
	_animation.add_animation_library("", SoldierAnimations.library_for(data.id, skeleton, _model))
	_animation.animation_finished.connect(_on_animation_finished)
	_animation.play("idle")
	_animation.seek(randf() * 1.5)
	BlobShadow.attach(self, 1.5 * float(data.height) / 7.0, 0.45)
	_build_bar()
	_visual.rotation.y = randf() * TAU

## Every enemy, without exception, hits for exactly 1 + Plague Knight level
## (D-092): soldiers of every rank, both knights and the boss.
func hit_damage() -> int:
	return Progression.enemy_hit()

## Float so very high levels never overflow (D-086).
func max_health() -> float:
	if data.has("swings"):
		if _scaled_max <= 0.0:
			_rescale()
		return _scaled_max
	return float(data.health)

## Soldier health locked at spawn (D-091), see enemy_roster.gd TIERS.
var _scaled_max := 0.0

func _rescale() -> void:
	if data.has("swings"):
		_scaled_max = maxf(float(data.health), roundf(float(data.swings) * float(Progression.damage) * 1.25))

## Radius of the body's footprint; Kaze is kept outside it (D-087).
func body_radius() -> float:
	return float(data.get("body", float(data.height) * 0.3))

func is_alive() -> bool:
	return state != State.DEAD and not _dying

## Kaze's blows (auto_attack.gd). Captains and commanders only flinch from the finisher.
func take_hit(damage: float, from_position: Vector3, force := 1.0) -> void:
	if state == State.DEAD or _dying:
		return
	health -= damage
	_heal = 0.0
	_update_bar()
	_flash()
	var away := global_position - from_position
	away.y = 0.0
	away = away.normalized() if away.length() > 0.01 else Vector3.BACK
	velocity = away * (6.0 + 8.0 * force)
	if health <= 0:
		# An attack already under way is never interrupted, not even by death.
		if state == State.ATTACK and not _hit_landed:
			_dying = true
			_death_away = away
			_bar.visible = false
			return
		_die(away)
		return
	# Kaze's blows never interrupt an attack (D-082): no flinch, and a soldier
	# in the middle of a swing is not knocked back either.
	if state == State.ATTACK:
		velocity = Vector3.ZERO
	elif state == State.IDLE or state == State.RETURN:
		_face(-away, 1.0)
		state = State.CHASE

func _physics_process(delta: float) -> void:
	if hero == null:
		return
	var offset := hero.global_position - global_position
	offset.y = 0.0
	var distance := offset.length()
	var asleep := distance > ACTIVE_DISTANCE and state != State.DEAD
	if asleep != _sleeping:
		_sleeping = asleep
		if asleep:
			_animation.pause()
		else:
			_animation.play()
	if _sleeping:
		return
	_cooldown = maxf(_cooldown - delta, 0.0)
	var hero_dead: bool = hero.get("dead") == true
	var hero_from_home := Vector2(hero.global_position.x - home.x, hero.global_position.z - home.z).length()
	var move := Vector3.ZERO
	match state:
		State.DEAD:
			_timer -= delta
			_update_countdown()
			if _timer <= 0.0 and distance > respawn_distance:
				_respawn()
			return
		State.IDLE:
			_play_loop("idle")
			if not hero_dead and distance < float(data.aggro) and hero_from_home < leash:
				state = State.CHASE
		State.CHASE:
			if hero_dead or hero_from_home > leash + 6.0 or distance > float(data.aggro) * 2.2:
				state = State.RETURN
			elif distance <= float(data.range) and _cooldown <= 0.0:
				_start_attack(offset)
			elif distance > float(data.range) * 0.8:
				move = offset / distance * float(data.speed)
				_face(offset, delta)
			else:
				_face(offset, delta)
				_play_loop("idle")
		State.ATTACK:
			# The swing lasts one shared attack interval (D-082); the next one
			# can start straight after, exactly like Kaze's.
			_timer += delta
			if _timer < _hit_at * 0.8:
				_face(offset, delta * 0.6)
			if not _hit_landed and _timer >= _hit_at:
				_hit_landed = true
				_land_blow(offset, distance, hero_dead)
				if _dying:
					_dying = false
					_die(_death_away)
					return
			if _timer >= _swing_length:
				# Straight into the next swing on the same beat if Kaze is still in reach.
				var over := _timer - _swing_length
				state = State.CHASE
				if not hero_dead and distance <= float(data.range):
					_start_attack(offset)
					_timer = over
		State.RETURN:
			var back := home - global_position
			back.y = 0.0
			if back.length() < 1.5:
				state = State.IDLE
			else:
				move = back.normalized() * float(data.speed)
				_face(back, delta)
			_heal += HEAL_PER_SECOND * delta
			if _heal >= 1.0 and health < max_health():
				_heal -= 1.0
				health = minf(health + 1.0, float(max_health()))
				_update_bar()
			if not hero_dead and distance < float(data.aggro) * 0.7 and hero_from_home < leash:
				state = State.CHASE
	move += _separation()
	if move != Vector3.ZERO and not _ground_ahead(move):
		move = Vector3.ZERO
	if move != Vector3.ZERO:
		_play_loop("walk")
	elif state == State.CHASE or state == State.RETURN:
		_play_loop("idle")
	# Knockback from hits fades; walking replaces it.
	var push := Vector3(velocity.x, 0.0, velocity.z).move_toward(Vector3.ZERO, 60.0 * delta)
	velocity = move if move != Vector3.ZERO else push
	velocity.y = -1.0 if is_on_floor() else _fall_speed(delta)
	move_and_slide()

func _fall_speed(delta: float) -> float:
	return get_real_velocity().y - GRAVITY * delta

## Steps away from other living enemies it overlaps, so a group around Kaze
## spreads out instead of standing inside each other (D-093).
func _separation() -> Vector3:
	if state == State.DEAD:
		return Vector3.ZERO
	var push := Vector3.ZERO
	for other in get_tree().get_nodes_in_group("enemies"):
		if other == self or not other.has_method("body_radius") or not other.is_alive():
			continue
		var away: Vector3 = global_position - other.global_position
		away.y = 0.0
		var distance := away.length()
		var minimum: float = body_radius() + other.body_radius()
		if distance < minimum:
			push += (away / distance if distance > 0.01 else Vector3.RIGHT) * (minimum - distance) * 6.0
	return push

## Fight window (D-085 bosses, D-101 knights too): once the fight starts
## Kaze has `fight_window` seconds; then the enemy refills its health and a new
## window begins. Leaving the fight also refills it. 0 = no window.
var fight_window := 0.0
var fight_left := 0.0
var in_fight := false

## Call once per physics frame from enemies that use a fight window.
func update_fight_window(delta: float) -> void:
	if fight_window <= 0.0:
		return
	if not is_alive():
		in_fight = false
	elif state == State.CHASE or state == State.ATTACK:
		if not in_fight:
			in_fight = true
			fight_left = fight_window
		fight_left -= delta
		if fight_left <= 0.0:
			# Time is up: full health, and a new window begins.
			health = float(max_health())
			_update_bar()
			fight_left += fight_window
	elif in_fight:
		in_fight = false
		health = float(max_health())
		_update_bar()

## Swings started, for tests.
var swings_started := 0

func _start_attack(offset: Vector3) -> void:
	swings_started += 1
	state = State.ATTACK
	_timer = 0.0
	_hit_landed = false
	_face(offset, 1.0)
	_swing_length = Progression.attack_interval()
	var clip_length := _animation.get_animation(data.attack).length
	_hit_at = SoldierAnimations.HIT_TIME[data.attack] / clip_length * _swing_length
	_animation.play(data.attack, 0.08, clip_length / _swing_length)

func _land_blow(offset: Vector3, distance: float, hero_dead: bool) -> void:
	if hero_dead or not hero.has_method("take_damage"):
		return
	var facing := Vector3(sin(_visual.rotation.y), 0, cos(_visual.rotation.y))
	var in_front: bool = offset.normalized().dot(facing) > 0.2 or data.attack == "attack_cast"
	if distance <= float(data.range) + HIT_SLACK and in_front:
		hero.take_damage(hit_damage(), global_position)
	if data.attack == "attack_cast":
		_cast_ring()

func _on_animation_finished(clip: StringName) -> void:
	if state != State.ATTACK and String(clip) == data.attack:
		_animation.play("idle", 0.15)
func _die(away: Vector3) -> void:
	state = State.DEAD
	_timer = respawn_seconds
	_on_defeated()
	_bar.visible = false
	_animation.play("death", 0.05)
	if _tween:
		_tween.kill()
	_tween = create_tween()
	# Tip over away from Kaze, then sink into the ground and vanish.
	var axis := Vector3.UP.cross(away).normalized()
	var fallen := Basis(axis, deg_to_rad(80.0)) * _visual.basis
	_tween.tween_property(_visual, "basis", fallen, 0.45).set_delay(0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_tween.tween_property(_visual, "position:y", -3.0, 1.0).set_delay(1.4)
	_tween.tween_callback(func() -> void: _visual.visible = false)

## Hook for subclasses: called once when this enemy is defeated.
func _on_defeated() -> void:
	var gained := Progression.add_experience(Progression.experience_for(float(data.get("health", max_health())) if data.has("swings") else max_health()))
	if gained > 0 and hero != null and hero.has_method("show_level_up"):
		hero.show_level_up()

func _respawn() -> void:
	# Stop the death topple/sink: it would hide an enemy that came back before
	# it finished (the knights return after 1.8 s).
	if _tween:
		_tween.kill()
		_tween = null
	global_position = home
	velocity = Vector3.ZERO
	_rescale()
	health = float(max_health())
	_visual.basis = Basis(Vector3.UP, randf() * TAU)
	_visual.position = Vector3.ZERO
	_visual.visible = true
	_update_bar()
	state = State.IDLE
	_animation.play("idle")
	_update_countdown()

## Called when Kaze respawns: everyone goes home at full health.
func reset_to_home() -> void:
	if state == State.DEAD:
		return
	global_position = home
	velocity = Vector3.ZERO
	health = float(max_health())
	_update_bar()
	state = State.IDLE

func _play_loop(clip: String) -> void:
	if _animation.current_animation != clip:
		_animation.play(clip, 0.15)

func _face(direction: Vector3, weight: float) -> void:
	if direction.length_squared() < 0.0001:
		return
	var target := atan2(direction.x, direction.z)
	_visual.rotation.y = lerp_angle(_visual.rotation.y, target, clampf(weight * TURN_SPEED, 0.0, 1.0))

## Stops soldiers walking off plateau edges or into water channels.
func _ground_ahead(move: Vector3) -> bool:
	var ahead := global_position + move.normalized() * 2.2
	var query := PhysicsRayQueryParameters3D.create(ahead + Vector3(0, 3.0, 0), ahead + Vector3(0, -3.0, 0), 1)
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	return not hit.is_empty() and hit.position.y > global_position.y - 1.6

## Scales each model so the top of its head is at `target_height`.
func _scale_for(model_path: String, model: Node3D, target_height: float) -> float:
	if not _model_scale.has(model_path):
		var nub := model.find_child("Bip001 HeadNub", true, false) as Node3D
		var height := 2.0
		if nub != null:
			height = (model.global_transform.affine_inverse() * nub.global_position).y
		_model_scale[model_path] = 1.0 / maxf(height, 0.1)
	return float(_model_scale[model_path]) * target_height

func _flash() -> void:
	if _flash_material == null:
		_flash_material = StandardMaterial3D.new()
		_flash_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_flash_material.albedo_color = Color(1, 1, 1, 0.65)
		_flash_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	for mesh in _meshes:
		mesh.material_overlay = _flash_material
	get_tree().create_timer(0.08).timeout.connect(func() -> void:
		for mesh in _meshes:
			if is_instance_valid(mesh):
				mesh.material_overlay = null)

func _cast_ring() -> void:
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.85
	torus.outer_radius = 1.0
	torus.rings = 24
	torus.ring_segments = 4
	ring.mesh = torus
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color(0.75, 0.45, 1.0, 0.85)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ring.material_override = material
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(ring)
	ring.position.y = 0.4
	ring.scale = Vector3(1.0, 0.3, 1.0)
	var tween := ring.create_tween().set_parallel(true)
	tween.tween_property(ring, "scale", Vector3(float(data.range), 0.3, float(data.range)), 0.3)
	tween.tween_property(material, "albedo_color:a", 0.0, 0.35)
	tween.chain().tween_callback(ring.queue_free)

const BAR_SHADER := """
shader_type spatial;
render_mode unshaded, cull_disabled, depth_test_disabled, shadows_disabled;
uniform float fill = 1.0;
uniform vec4 fill_color : source_color = vec4(0.9, 0.25, 0.2, 1.0);
void vertex() {
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
}
void fragment() {
	vec2 border = step(vec2(0.03, 0.14), UV) * step(UV, vec2(0.97, 0.86));
	float inside = border.x * border.y;
	vec3 color = UV.x < fill ? fill_color.rgb : vec3(0.18, 0.08, 0.07);
	ALBEDO = mix(vec3(0.08, 0.05, 0.04), color, inside);
}
"""

func _build_bar() -> void:
	if _bar_shader == null:
		_bar_shader = Shader.new()
		_bar_shader.code = BAR_SHADER
	_bar = MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(3.2, 0.5) * float(data.height) / 7.0
	_bar.mesh = quad
	_bar_material = ShaderMaterial.new()
	_bar_material.shader = _bar_shader
	_bar_material.render_priority = 3
	_bar.material_override = _bar_material
	_bar.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_bar.position.y = float(data.height) + 1.2
	add_child(_bar)
	_update_bar()

## Height where overhead text starts: just above the health bar. Labels use
## bottom alignment from here, so extra lines grow upwards and never cover
## the bar (D-088).
func label_base_y() -> float:
	return float(data.height) + 1.2 + 0.25 * float(data.height) / 7.0 + 0.5

## Standard overhead label (name, level, health, timers).
func make_overhead_label(font_size: int, pixel_size: float, color: Color) -> Label3D:
	var label := Label3D.new()
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.font_size = font_size
	label.outline_size = maxi(font_size / 4, 12)
	label.pixel_size = pixel_size
	label.modulate = color
	label.outline_modulate = Color("1d1210")
	label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	label.position.y = label_base_y()
	add_child(label)
	return label

## Respawn countdown shown where the enemy will come back (D-088). Only for
## waits long enough to read (not the knights' 1.8 s, not the boss).
var _countdown: Label3D

func _update_countdown() -> void:
	var showing := state == State.DEAD and respawn_seconds >= 3.0 and respawn_seconds < 1000.0 and _timer > 0.0
	if not showing:
		if _countdown != null:
			_countdown.visible = false
		return
	if _countdown == null:
		_countdown = Label3D.new()
		_countdown.top_level = true
		_countdown.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		_countdown.no_depth_test = true
		_countdown.font_size = 72
		_countdown.outline_size = 18
		_countdown.pixel_size = 0.02
		_countdown.modulate = Color("f6ead2")
		_countdown.outline_modulate = Color("1d1210")
		add_child(_countdown)
	_countdown.global_position = home + Vector3(0, 3.0, 0)
	_countdown.text = "%s\nback in %ds" % [data.name, ceili(_timer)]
	_countdown.visible = true

func _update_bar() -> void:
	var fraction := clampf(float(health) / float(max_health()), 0.0, 1.0)
	_bar_material.set_shader_parameter("fill", fraction)
	_bar.visible = fraction < 1.0 and state != State.DEAD
