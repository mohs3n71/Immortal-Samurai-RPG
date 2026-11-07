extends Node

## Auto-attack combo (D-072, D-075): when an enemy (any node in the "enemies"
## group with a take_hit(damage, from_position, force) method) is within
## reach, the hero turns to it and swings. Swings chain through the hero's
## combo steps (hero_catalog.json "combo"): each next swing cuts into the
## recovery of the last, and the last step is a finisher that hits everything
## around the landing spot. Pausing longer than COMBO_WINDOW restarts the chain.

const SlashFx = preload("res://scripts/slash_fx.gd")
const Progression = preload("res://scripts/progression.gd")

const ENEMY_GROUP := "enemies"
## Raised in D-087 (was 5.6) together with the enemies' reach.
const REACH := 7.5
## A blow still lands if the target drifted a little out of reach mid-swing.
const HIT_SLACK := 1.5
const FINISHER_RADIUS := 9.0
const COMBO_WINDOW := 0.55
const HIT_COUNT_WINDOW := 1.6
## Each swing steps the hero in until he is about this far from the target.
## Never closer than the two bodies allow (player.gd keeps them apart, D-087).
const LUNGE_STOP := 5.6
const LUNGE_MAX := 28.0

var _player: CharacterBody3D
var _steps: Array = []
var _next := 0
var _playing := -1
var _since_swing := 99.0
var _hits := 0
var _since_hit := 99.0
## Steps started, for tests and debugging.
var swing_log: Array[String] = []

func _ready() -> void:
	_player = get_parent() as CharacterBody3D

func _physics_process(delta: float) -> void:
	_since_hit += delta
	if _since_hit > HIT_COUNT_WINDOW:
		_hits = 0
	var visual: Node3D = _player.visual
	if visual == null or _player.get("dead") == true:
		return
	if _steps.is_empty():
		_steps = visual.combo_steps()
		if _steps.is_empty():
			return
	# One swing per shared attack interval, exactly like the enemies (D-082).
	_since_swing += delta
	var interval := Progression.attack_interval()
	if _since_swing < interval:
		return
	if _since_swing > interval + COMBO_WINDOW:
		_next = 0
	var target := nearest_enemy()
	if target != null:
		_swing(visual, target, _since_swing < interval + delta * 1.5)

## Closest living enemy within reach, or null.
func nearest_enemy() -> Node3D:
	var best: Node3D = null
	var best_distance := REACH
	for enemy in _living_enemies():
		var distance := _flat_distance(enemy)
		if distance < best_distance:
			best = enemy
			best_distance = distance
	return best

## Index of the step the next swing will use (0 = chain start).
func next_step() -> int:
	return _next

func _swing(visual: Node3D, target: Node3D, chain: bool) -> void:
	var step: Dictionary = _steps[_next]
	var offset := target.global_position - _player.global_position
	visual.rotation.y = atan2(offset.x, offset.z)
	var interval := Progression.attack_interval()
	visual.attack(step.clip, true, interval)
	if not visual.is_attacking or visual.current_clip != step.clip:
		return
	# Keep the leftover time so swings stay on an exact beat.
	_since_swing = clampf(_since_swing - interval, 0.0, interval) if chain else 0.0
	swing_log.append(step.clip)
	_playing = _next
	_next = (_next + 1) % _steps.size()
	_lunge_toward(offset)
	# The blow lands at the same fraction of the swing as in the clip.
	var clip_length: float = visual.animation_player.get_animation(step.clip).length
	_land_hit.call_deferred(target, step, visual.rotation.y, float(step.hit) / clip_length * interval)

func _lunge_toward(offset: Vector3) -> void:
	offset.y = 0.0
	var gap := offset.length() - LUNGE_STOP
	if gap <= 0.0 or not _player.has_method("lunge"):
		return
	# Speed that, decaying at LUNGE_DECAY, travels about `gap`.
	var speed := minf(sqrt(2.0 * _player.LUNGE_DECAY * gap), LUNGE_MAX)
	_player.lunge(offset.normalized() * speed)

func _land_hit(target: Node3D, step: Dictionary, yaw: float, hit_time: float) -> void:
	var lead := minf(0.05, hit_time)
	await get_tree().create_timer(hit_time - lead).timeout
	if not is_inside_tree():
		return
	SlashFx.spawn_trail(_player, yaw, String(step.get("trail", "sweep_left")))
	await get_tree().create_timer(lead).timeout
	if not is_inside_tree():
		return
	var finisher: bool = step.get("finisher", false)
	# Combo step damage is a multiple of Kaze's damage (D-080).
	var damage := float(step.get("damage", 1)) * Progression.effective_damage()
	var victims: Array[Node3D] = []
	if finisher:
		var landing := _player.global_position + Vector3(sin(yaw), 0, cos(yaw)) * 5.5
		SlashFx.spawn_shockwave(_player.get_parent(), landing)
		for enemy in _living_enemies():
			if _flat_distance(enemy) < FINISHER_RADIUS:
				victims.append(enemy)
	elif is_instance_valid(target) and _flat_distance(target) < REACH + HIT_SLACK:
		victims.append(target)
	if victims.is_empty():
		return
	for victim in victims:
		if victim.has_method("take_hit"):
			victim.take_hit(damage, _player.global_position, 2.2 if finisher else 1.0)
	_hits += 1
	_since_hit = 0.0
	SlashFx.show_counter(_player.get_parent(), victims[0].global_position, _hits, finisher)
	SlashFx.shake(_player.camera, 0.7 if finisher else 0.22, 0.28 if finisher else 0.12)
	SlashFx.hit_stop(get_tree(), 0.09 if finisher else 0.045)

func _living_enemies() -> Array[Node3D]:
	var result: Array[Node3D] = []
	for enemy in get_tree().get_nodes_in_group(ENEMY_GROUP):
		if not (enemy is Node3D) or not enemy.is_inside_tree():
			continue
		if enemy.has_method("is_alive") and not enemy.is_alive():
			continue
		result.append(enemy)
	return result

func _flat_distance(enemy: Node3D) -> float:
	var offset := enemy.global_position - _player.global_position
	offset.y = 0.0
	return offset.length()
