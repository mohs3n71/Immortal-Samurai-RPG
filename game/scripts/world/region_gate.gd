extends Node3D

## Gate to the next region (D-085): a stone arch sealed by a glowing barrier
## until the region's final boss is defeated. Then the barrier fades and the
## way is open: the passage behind it leads on into the next region (D-102),
## or, for the last region so far, to a "coming soon" note.

const GateArtwork = preload("res://scripts/world/gate_artwork.gd")
## The artwork's opening is about 12 wide at scale 1; the gateway is 14.
const ARTWORK_SCALE := 1.1
const Progression = preload("res://scripts/progression.gd")
const Travel = preload("res://scripts/world/travel.gd")

@export var region := 1
@export var boss_name := "Bone Warlord"
## Emitted once when Kaze walks through the open gate.
signal entered

var hero: Node3D
var _artwork: Node3D
var _barrier: MeshInstance3D
var _material: StandardMaterial3D
var _body: StaticBody3D
var _label: Label3D
var _noted := false

func _ready() -> void:
	# Butcher Hero gate artwork (D-104): metal posts in region 1, icy in region 2.
	_artwork = Node3D.new()
	_artwork.set_script(GateArtwork)
	_artwork.style = "frozen" if region == 2 else "metal"
	_artwork.scale = Vector3.ONE * ARTWORK_SCALE
	add_child(_artwork)
	_barrier = MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(12.5, 6.8, 0.6)
	_barrier.mesh = box
	_material = StandardMaterial3D.new()
	_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_material.albedo_color = Color(0.85, 0.25, 0.2, 0.55)
	_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_barrier.material_override = _material
	_barrier.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_barrier.position.y = 3.4
	add_child(_barrier)
	_body = StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var solid := BoxShape3D.new()
	solid.size = Vector3(12.0, 12.0, 2.0)
	shape.shape = solid
	shape.position.y = 6.0
	_body.add_child(shape)
	add_child(_body)
	_label = Label3D.new()
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.font_size = 72
	_label.outline_size = 18
	_label.pixel_size = 0.02
	_label.outline_modulate = Color("1a0c08")
	# On the barrier itself (depth-tested) so it never draws over the boss's
	# name and health above him (D-088).
	# The side facing the camera (the gate is turned round, so local -z).
	_label.position = Vector3(0, 8.2, -1.2)
	add_child(_label)
	Progression.ensure_loaded()
	if is_open():
		_set_open(false)
	else:
		_label.text = "Sealed\nDefeat the %s" % boss_name
		_label.modulate = Color("ff8a70")

func is_open() -> bool:
	return Progression.bosses_defeated >= region

func open() -> void:
	_set_open(true)

func _set_open(animate: bool) -> void:
	# Once the boss is beaten the guide leads to the open gate (D-090).
	add_to_group("guide_target")
	set_meta("guide", "gate")
	set_meta("guide_order", region * 2 + 1)
	_artwork.open_doors(animate)
	_body.process_mode = Node.PROCESS_MODE_DISABLED
	_body.collision_layer = 0
	_label.text = ("%s\nGate open" % Travel.NAMES[region + 1]) if Travel.has_region(region + 1) else ("Region %d\nGate open" % (region + 1))
	_label.modulate = Color("9df29a")
	if animate:
		var tween := create_tween()
		tween.tween_property(_material, "albedo_color:a", 0.0, 1.5)
		tween.tween_callback(func() -> void: _barrier.visible = false)
	else:
		_barrier.visible = false

func _physics_process(_delta: float) -> void:
	if hero == null or not is_open() or _noted:
		return
	var offset := hero.global_position - global_position
	offset.y = 0.0
	# Reached, or already beyond it in the next region: the guide moves on.
	if offset.length() < 6.0 or Travel.region_at(hero.global_position) > region:
		_noted = true
		remove_from_group("guide_target")
		if Travel.has_region(region + 1):
			entered.emit()
		else:
			_label.text = "Region %d\nComing soon" % (region + 1)
