extends CharacterBody3D

const WorldSettings = preload("res://scripts/world_settings.gd")
const GRAVITY := 40.0

## Gravity and floor snapping for ramps and plateaus (set by main.gd).
var use_gravity := false
var half_extent := 0.0
## Keeps Kaze inside the given world rectangles (D-102: the regions' play
## squares and the gateway corridor). Empty: the square of half_extent.
var walkable_areas: Array = []

var joystick: Control
var camera: Camera3D
var visual: Node3D

## While an auto-attack swing plays the hero keeps moving at reduced speed and
## keeps facing the target, so the player can always walk away (D-072).
const ATTACK_MOVE_FACTOR := 0.45
## Combo swings step the hero toward the target (D-075); the push fades fast.
const LUNGE_DECAY := 120.0
## Kaze's body footprint (D-087). He never gets closer to an enemy, the
## Reaper or a boss than this plus their own body_radius(), so bodies never
## sink into each other.
const BODY_RADIUS := 1.8
const BODY_GROUP := "bodies"

var _lunge := Vector3.ZERO

## Hero health (D-078). Max health and damage come from the saved
## progression (D-080); soldiers call take_damage(); main.gd handles falling.
signal health_changed(health: int, max_health: int)
signal died
const Progression = preload("res://scripts/progression.gd")
var max_health := 1
var health := 1
var dead := false

func _ready() -> void:
	Progression.ensure_loaded()
	max_health = Progression.max_health
	health = max_health

func take_damage(amount: int, _from_position: Vector3) -> void:
	if dead:
		return
	health = maxi(health - amount, 0)
	health_changed.emit(health, max_health)
	# No knockback (D-086): it pushed Kaze out of reach and out of the
	# knights' arenas, so strong enemies stopped fighting and never died.
	if health == 0:
		# No fall animation (D-080): main.gd grants the rewards and Kaze
		# keeps fighting on the spot at full health.
		died.emit()

func lunge(push: Vector3) -> void:
	_lunge = Vector3(push.x, 0.0, push.z)

## Hero level up from experience (D-080): +1% base damage per level.
func show_level_up() -> void:
	var text := Label3D.new()
	text.text = "LEVEL UP!  Lv %d\n+1%% damage" % Progression.hero_level
	text.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	text.no_depth_test = true
	text.font_size = 76
	text.outline_size = 18
	text.pixel_size = 0.02
	text.modulate = Color("8fe3ff")
	text.outline_modulate = Color("0d2230")
	add_child(text)
	text.position.y = 10.5
	var tween := text.create_tween().set_parallel(true)
	tween.tween_property(text, "position:y", 13.0, 1.6)
	tween.tween_property(text, "modulate:a", 0.0, 0.5).set_delay(1.2)
	tween.tween_property(text, "outline_modulate:a", 0.0, 0.5).set_delay(1.2)
	tween.chain().tween_callback(text.queue_free)

## The Reaper's blow: max health is halved and health capped to it.
func reaper_strike() -> void:
	Progression.reaper_strike()
	max_health = Progression.max_health
	health = mini(health, max_health)
	health_changed.emit(health, max_health)

## Back to full health where he stands, with the (new) max health.
func refill() -> void:
	max_health = Progression.max_health
	health = max_health
	dead = false
	health_changed.emit(health, max_health)

func revive(at: Vector3) -> void:
	global_position = at
	velocity = Vector3.ZERO
	_lunge = Vector3.ZERO
	max_health = Progression.max_health
	health = max_health
	dead = false
	health_changed.emit(health, max_health)

func _physics_process(delta: float) -> void:
	if dead:
		velocity = Vector3(0.0, _vertical_speed(delta), 0.0)
		move_and_slide()
		return
	var attacking: bool = visual.is_attacking
	var input_direction: Vector2 = joystick.direction
	if input_direction.length() < 0.01:
		var wasd := Input.get_vector("move_left", "move_right", "move_up", "move_down")
		var arrows := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
		input_direction = (wasd + arrows).limit_length(1.0)
	var right := camera.global_basis.x
	var forward := -camera.global_basis.z
	right.y = 0.0
	forward.y = 0.0
	var movement := (right.normalized() * input_direction.x - forward.normalized() * input_direction.y)
	var previous_position := global_position
	var vertical := _vertical_speed(delta)
	var speed := WorldSettings.WALK_SPEED * (ATTACK_MOVE_FACTOR if attacking else 1.0)
	velocity = _blocked_by_bodies(movement.limit_length(1.0) * speed + _lunge)
	_lunge = _lunge.move_toward(Vector3.ZERO, LUNGE_DECAY * delta)
	velocity.y = vertical
	move_and_slide()
	_push_out_of_bodies()
	if not walkable_areas.is_empty():
		position = _clamp_to_areas(position)
	else:
		var limit := half_extent if half_extent > 0.0 else WorldSettings.HALF_EXTENT
		position.x = clampf(position.x, -limit, limit)
		position.z = clampf(position.z, -limit, limit)
	if attacking:
		return
	var displacement := global_position - previous_position
	displacement.y = 0.0
	var walking := Vector2(displacement.x, displacement.z).length_squared() > pow(delta * 1.0, 2.0)
	visual.set_walking(walking)
	if walking:
		visual.rotation.y = atan2(movement.x, movement.z)

## Bodies Kaze must stay outside of: [node, minimum centre distance].
func _solid_bodies() -> Array:
	var result := []
	for body in get_tree().get_nodes_in_group(BODY_GROUP):
		if body == self or not body.has_method("body_radius"):
			continue
		if body.has_method("is_alive") and not body.is_alive():
			continue
		result.append([body, BODY_RADIUS + float(body.body_radius())])
	return result

## Removes the part of `move` that would walk Kaze into a body he touches.
func _blocked_by_bodies(move: Vector3) -> Vector3:
	for pair in _solid_bodies():
		var away := global_position - (pair[0] as Node3D).global_position
		away.y = 0.0
		var distance := away.length()
		if distance > float(pair[1]) + 0.3 or distance < 0.001:
			continue
		var normal := away / distance
		var into := move.dot(normal)
		if into < 0.0:
			move -= normal * into
	return move

## Pushes Kaze back out if something (a lunge, an enemy walking) left him inside a body.
func _push_out_of_bodies() -> void:
	for pair in _solid_bodies():
		var away := global_position - (pair[0] as Node3D).global_position
		away.y = 0.0
		var distance := away.length()
		var minimum := float(pair[1])
		if distance >= minimum:
			continue
		var normal := away / distance if distance > 0.001 else -global_basis.z
		move_and_collide(normal * (minimum - distance))

func _vertical_speed(delta: float) -> float:
	if not use_gravity:
		return 0.0
	if is_on_floor():
		return -1.0
	return velocity.y - GRAVITY * delta

func _clamp_to_areas(at: Vector3) -> Vector3:
	var flat := Vector2(at.x, at.z)
	var best := flat
	var best_distance := INF
	for area: Rect2 in walkable_areas:
		var inside := Vector2(clampf(flat.x, area.position.x, area.end.x), clampf(flat.y, area.position.y, area.end.y))
		var distance := inside.distance_squared_to(flat)
		if distance < best_distance:
			best_distance = distance
			best = inside
	return Vector3(best.x, at.y, best.y)
