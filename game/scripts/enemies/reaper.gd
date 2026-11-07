extends Node3D

## The Reaper by the village (D-080). Kaze cannot hurt him. When Kaze steps
## into his arena and the Reaper is ready, he swings once and halves Kaze's
## max health; then he rests for COOLDOWN seconds, shown above his head.

const SoldierAnimations = preload("res://scripts/enemies/soldier_animations.gd")
const Progression = preload("res://scripts/progression.gd")
const BlobShadow = preload("res://scripts/world/blob_shadow.gd")

const MODEL := "res://assets/enemies/undead/reaper.glb"
const COOLDOWN := 20.0
const REACH := 8.5
## Footprint Kaze is kept outside of (D-087).
const BODY_RADIUS := 2.8

func body_radius() -> float:
	return BODY_RADIUS
const HEIGHT := 9.5
const TURN_SPEED := 8.0

var hero: CharacterBody3D
var cooldown := 0.0
var _visual: Node3D
var _animation: AnimationPlayer
var _label: Label3D
var _swinging := false
var _swing_time := 0.0
var _struck := false

func _ready() -> void:
	add_to_group("bodies")
	_visual = Node3D.new()
	add_child(_visual)
	var model: Node3D = (load(MODEL) as PackedScene).instantiate()
	_visual.add_child(model)
	var nub := model.find_child("Bip001 HeadNub", true, false) as Node3D
	var height := (model.global_transform.affine_inverse() * nub.global_position).y if nub != null else 2.0
	model.scale = Vector3.ONE * HEIGHT / maxf(height, 0.1)
	for mesh in model.find_children("*", "MeshInstance3D", true, false):
		mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var skeleton: Skeleton3D = model.find_children("*", "Skeleton3D", true, false)[0]
	_animation = AnimationPlayer.new()
	model.add_child(_animation)
	_animation.root_node = _animation.get_path_to(model)
	_animation.add_animation_library("", SoldierAnimations.library_for("reaper", skeleton, model))
	_animation.play("idle")
	BlobShadow.attach(self, 1.9, 0.45)
	var to_square := Vector3(2, 0, 2) - global_position
	_visual.rotation.y = atan2(to_square.x, to_square.z)
	_label = Label3D.new()
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.no_depth_test = true
	_label.font_size = 80
	_label.outline_size = 20
	_label.pixel_size = 0.02
	_label.outline_modulate = Color("120b14")
	# Bottom-aligned so the cooldown line never sinks into his head (D-088).
	_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	_label.position.y = HEIGHT + 1.4
	add_child(_label)
	_update_label()

func _physics_process(delta: float) -> void:
	if hero == null:
		return
	cooldown = maxf(cooldown - delta, 0.0)
	var offset := hero.global_position - global_position
	offset.y = 0.0
	if _swinging:
		_swing_time += delta
		if _swing_time < 0.3:
			_turn(offset, delta)
		# His swing takes the same shared attack interval as everyone's (D-082).
		var interval := Progression.attack_interval()
		var clip_length := _animation.get_animation("attack_chop").length
		if not _struck and _swing_time >= SoldierAnimations.HIT_TIME["attack_chop"] / clip_length * interval:
			_struck = true
			_strike(offset)
		if _swing_time >= interval:
			_swinging = false
			_animation.play("idle", 0.2)
	elif cooldown <= 0.0 and offset.length() < REACH and hero.get("dead") != true:
		_swinging = true
		_swing_time = 0.0
		_struck = false
		_turn(offset, 1.0)
		_animation.play("attack_chop", 0.08, _animation.get_animation("attack_chop").length / Progression.attack_interval())
	_update_label()

func _strike(offset: Vector3) -> void:
	cooldown = COOLDOWN
	if offset.length() > REACH + 2.0 or not hero.has_method("reaper_strike"):
		return
	hero.reaper_strike()
	var text := Label3D.new()
	text.text = "MAX HEALTH HALVED"
	text.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	text.no_depth_test = true
	text.font_size = 72
	text.outline_size = 18
	text.pixel_size = 0.02
	text.modulate = Color("d08cff")
	text.outline_modulate = Color("1a0d22")
	hero.add_child(text)
	text.position.y = 10.0
	var tween := text.create_tween().set_parallel(true)
	tween.tween_property(text, "position:y", 12.5, 1.4)
	tween.tween_property(text, "modulate:a", 0.0, 0.4).set_delay(1.0)
	tween.tween_property(text, "outline_modulate:a", 0.0, 0.4).set_delay(1.0)
	tween.chain().tween_callback(text.queue_free)

func _turn(offset: Vector3, weight: float) -> void:
	if offset.length_squared() < 0.0001:
		return
	_visual.rotation.y = lerp_angle(_visual.rotation.y, atan2(offset.x, offset.z), clampf(weight * TURN_SPEED, 0.0, 1.0))

func _update_label() -> void:
	if cooldown > 0.0:
		_label.text = "Reaper\n%ds" % ceili(cooldown)
		_label.modulate = Color("b9a3c9")
	else:
		_label.text = "Reaper\nReady"
		_label.modulate = Color("d08cff")
