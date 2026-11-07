@tool
extends Node3D

## A tilled farm plot: furrowed soil strips with rows of crops. Walkable.

const StylizedMeshes = preload("res://scripts/world/stylized_meshes.gd")
const SOIL := Color("7a5a3a")
const FURROW := Color("5e432b")

@export var size := Vector2(18, 12)
@export var rows := 6
@export var crop := "crop"
@export var crop_spacing := 1.6
@export var seed := 3

var _strips: SurfaceTool

func _ready() -> void:
	if get_node_or_null("Soil") != null:
		return
	var random := RandomNumberGenerator.new()
	random.seed = seed
	var soil := Node3D.new()
	soil.name = "Soil"
	add_child(soil)
	# Soil strips go into one vertex-colored mesh (one draw call).
	_strips = SurfaceTool.new()
	_strips.begin(Mesh.PRIMITIVE_TRIANGLES)
	_add_strip(soil, Vector3(0, 0.03, 0), Vector2(size.x + 1.0, size.y + 1.0), FURROW)
	var transforms: Array[Transform3D] = []
	var row_gap := size.y / rows
	for row in rows:
		var z := -size.y / 2.0 + (row + 0.5) * row_gap
		_add_strip(soil, Vector3(0, 0.06, z), Vector2(size.x, row_gap * 0.55), SOIL.darkened(random.randf_range(0.0, 0.08)))
		var x := -size.x / 2.0 + crop_spacing * 0.5
		while x < size.x / 2.0:
			var scale := random.randf_range(0.8, 1.25)
			var basis := Basis(Vector3.UP, random.randf_range(0.0, TAU)).scaled(Vector3.ONE * scale)
			transforms.append(Transform3D(basis, Vector3(x + random.randf_range(-0.2, 0.2), 0.06, z)))
			x += crop_spacing
	var soil_material := StandardMaterial3D.new()
	soil_material.vertex_color_use_as_albedo = true
	soil_material.roughness = 1.0
	_strips.set_material(soil_material)
	var soil_mesh := MeshInstance3D.new()
	soil_mesh.mesh = _strips.commit()
	soil_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	soil.add_child(soil_mesh)
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = StylizedMeshes.get_mesh(crop)
	multimesh.instance_count = transforms.size()
	for index in transforms.size():
		multimesh.set_instance_transform(index, transforms[index])
	var crops := MultiMeshInstance3D.new()
	crops.name = "Crops"
	crops.multimesh = multimesh
	crops.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(crops)

func _add_strip(_parent: Node3D, location: Vector3, extent: Vector2, color: Color) -> void:
	var half := extent / 2.0
	var corners := [location + Vector3(-half.x, 0, -half.y), location + Vector3(half.x, 0, -half.y), location + Vector3(half.x, 0, half.y), location + Vector3(-half.x, 0, half.y)]
	for index in [0, 1, 2, 0, 2, 3]:
		_strips.set_color(color)
		_strips.set_normal(Vector3.UP)
		_strips.add_vertex(corners[index])
