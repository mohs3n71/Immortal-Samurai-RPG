extends Node3D

## Region gate artwork from the Butcher Hero project (D-104): two posts and an
## arched double door, put together as in its Unity scene ("gates Italy1" /
## "gates Frozen1"): stone-and-metal posts for the Meadowlands, icy spiked posts
## for the Frostlands. The doors swing open when the region's boss falls.
## Width runs along local x (about 13 units between the posts at scale 1).

const DIR := "res://assets/environment/butcher-props/"
const ATLAS := preload("res://assets/environment/butcher-props/jungle-gate-color.png")
## Unity's -90 degree turn about x (Blender z-up meshes).
const UPRIGHT := Quaternion(-0.7071068, 0, 0, 0.7071068)
const DOOR_TILT := Quaternion(0, 0, -0.0043536583, 0.9999906)

@export_enum("metal", "frozen") var style := "metal"

var _hinges: Array[Node3D] = []
var _material: StandardMaterial3D

func _ready() -> void:
	_material = StandardMaterial3D.new()
	_material.albedo_texture = ATLAS
	# The Unity layout has the gate across its z axis: turn it to run along x.
	var frame := Node3D.new()
	frame.rotation.y = PI / 2.0
	add_child(frame)
	if style == "frozen":
		var posts := _unity(frame, Vector3(-0.34, 0.11, -0.13), Quaternion.IDENTITY, "", 1.053)
		_unity(posts, Vector3(1.0038071, 0, 0), UPRIGHT, "frozen-gate-posts")
	else:
		var posts := _unity(frame, Vector3(-13.678466, -0.74, -0.5292155), Quaternion(0, -0.0043536574, 0, 0.9999906))
		_unity(posts, Vector3(14.024724, 0, 0), UPRIGHT, "metal-gate-posts")
	var a := _unity(frame, Vector3(0.27, 1.69, 4.65), UPRIGHT)
	_unity(a, Vector3(0.12, -0.03, -0.29), DOOR_TILT, "gate-door-a")
	var b := _unity(frame, Vector3(0.265, 1.7067637, -6.427736), UPRIGHT)
	_unity(b, Vector3(0.15296799, -0.68924046, -0.31114066), DOOR_TILT, "gate-door-b")
	_hinges = [a, b]

## Swings both doors open (inward, away from the camera side).
func open_doors(animate: bool) -> void:
	for index in _hinges.size():
		var hinge := _hinges[index]
		var turn := Basis(Vector3.UP, deg_to_rad(95.0 if index == 0 else -95.0))
		var target := Quaternion(turn) * hinge.quaternion
		if animate:
			create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).tween_property(hinge, "quaternion", target, 1.6)
		else:
			hinge.quaternion = target

## Unity transform (left-handed) as a Godot node: x is mirrored.
func _unity(parent: Node3D, unity_position: Vector3, unity_rotation: Quaternion, mesh := "", scale_factor := 1.0) -> Node3D:
	var node: Node3D
	if mesh != "":
		var instance := MeshInstance3D.new()
		instance.mesh = load(DIR + mesh + ".obj")
		instance.material_override = _material
		node = instance
	else:
		node = Node3D.new()
	node.position = Vector3(-unity_position.x, unity_position.y, unity_position.z)
	node.quaternion = Quaternion(unity_rotation.x, -unity_rotation.y, -unity_rotation.z, unity_rotation.w)
	node.scale = Vector3.ONE * scale_factor
	parent.add_child(node)
	return node
