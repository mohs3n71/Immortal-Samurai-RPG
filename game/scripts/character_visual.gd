extends Node3D

var hero: Dictionary
var size_multiplier := 1.0
var body_skeleton: Skeleton3D
var animation_player: AnimationPlayer
var attachments: Array[Dictionary] = []
var current_clip := ""
var idle_clip := "idle"
var run_clip := "run_walk"
var attack_clip := ""
var is_attacking := false
var is_walking := false

func _ready() -> void:
	process_priority = 100
	if hero.is_empty():
		hero = get_node("/root/HeroSelection").selected_hero()
	scale = Vector3.ONE * float(hero.model_scale) * size_multiplier
	idle_clip = hero.idle
	run_clip = hero.run
	attack_clip = hero.get("attack", "")
	var body := _add_model(hero.body)
	body_skeleton = _find_type(body, "Skeleton3D") as Skeleton3D
	animation_player = _find_type(body, "AnimationPlayer") as AnimationPlayer
	for part_path in hero.parts:
		var part := _add_model(part_path)
		var skeleton := _find_type(part, "Skeleton3D") as Skeleton3D
		if skeleton != null:
			attachments.append({"skeleton": skeleton, "bone_map": _make_bone_map(skeleton)})
	_make_run_in_place()
	for clip in [idle_clip, run_clip]:
		animation_player.get_animation(clip).loop_mode = Animation.LOOP_LINEAR
	if not attack_clip.is_empty():
		for clip in attack_clips():
			animation_player.get_animation(clip).loop_mode = Animation.LOOP_NONE
		animation_player.animation_finished.connect(_on_animation_finished)
	set_walking(false)

func _process(_delta: float) -> void:
	for attachment in attachments:
		var skeleton: Skeleton3D = attachment["skeleton"]
		var bone_map: Array = attachment["bone_map"]
		for index in bone_map.size():
			var source_index: int = bone_map[index]
			if source_index >= 0:
				skeleton.set_bone_global_pose(index, body_skeleton.get_bone_global_pose(source_index))

func set_walking(walking: bool) -> void:
	is_walking = walking
	if is_attacking:
		return
	var clip := run_clip if walking else idle_clip
	if clip != current_clip:
		current_clip = clip
		animation_player.play(clip, 0.15)

## Combo steps from the hero catalog (D-075); a single-attack hero gets one step.
func combo_steps() -> Array:
	var steps: Array = hero.get("combo", [])
	if steps.is_empty() and not attack_clip.is_empty():
		return [{"clip": attack_clip, "hit": 0.22, "chain": 99.0, "damage": 1, "trail": "sweep_left"}]
	return steps

func attack_clips() -> Array:
	var clips := []
	for step in combo_steps():
		clips.append(step.clip)
	return clips

## Plays an attack clip. `chain` lets a combo swing cut short the recovery of
## the swing before it.
func attack(clip := "", chain := false, duration := 0.0) -> void:
	if clip.is_empty():
		clip = attack_clip
	if clip.is_empty() or (is_attacking and not chain):
		return
	is_attacking = true
	current_clip = clip
	# `duration` > 0 plays the swing in exactly that many seconds (D-082).
	var speed := 1.0
	if duration > 0.0:
		speed = animation_player.get_animation(clip).length / duration
	animation_player.play(clip, 0.06 if chain else 0.1, speed)

## Seconds into the attack clip that is playing.
func attack_position() -> float:
	return animation_player.current_animation_position if is_attacking else 0.0

func _on_animation_finished(clip: StringName) -> void:
	if is_attacking and String(clip) == current_clip:
		is_attacking = false
		set_walking(is_walking)

func _make_run_in_place() -> void:
	# Movement is controlled by the player body; imported root travel would reset on each loop.
	var library := animation_player.get_animation_library("")
	var animation := library.get_animation(run_clip).duplicate(true) as Animation
	for track in animation.get_track_count():
		if animation.track_get_type(track) != Animation.TYPE_POSITION_3D:
			continue
		var bone_name := animation.track_get_path(track).get_concatenated_subnames()
		var bone := body_skeleton.find_bone(bone_name)
		if bone < 0 or body_skeleton.get_bone_parent(bone) >= 0:
			continue
		var origin: Vector3 = animation.track_get_key_value(track, 0)
		for key in animation.track_get_key_count(track):
			var position: Vector3 = animation.track_get_key_value(track, key)
			position.x = origin.x
			position.z = origin.z
			animation.track_set_key_value(track, key, position)
	library.remove_animation(run_clip)
	library.add_animation(run_clip, animation)

func _add_model(model_path: String) -> Node:
	var scene := load(model_path) as PackedScene
	var model := scene.instantiate()
	add_child(model)
	return model

func _make_bone_map(skeleton: Skeleton3D) -> Array:
	var body_names := {}
	for index in body_skeleton.get_bone_count():
		body_names[body_skeleton.get_bone_name(index).to_lower()] = index
	var result := []
	for index in skeleton.get_bone_count():
		result.append(body_names.get(skeleton.get_bone_name(index).to_lower(), -1))
	return result

func _find_type(node: Node, type_name: String) -> Node:
	if node.is_class(type_name):
		return node
	for child in node.get_children():
		var found := _find_type(child, type_name)
		if found != null:
			return found
	return null
