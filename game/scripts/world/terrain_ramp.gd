@tool
extends Node3D

## A walkable slope from `bottom` (at `base_height`) up to `top`, `rise` higher.
## Its far end should tuck into a plateau. The top uses the ground material;
## the sides reuse the plateau cliff colors.

const TerrainBlock = preload("res://scripts/world/terrain_block.gd")
const STEPS := 16
## Share of smoothstep blended into the linear climb (0 = linear, 1 = full S-curve).
const END_EASING := 0.35
## Horizontal spread of the side banks per unit of height.
const BANK_SPREAD := 0.55
## Fraction of the ramp length that stays level at the top.
const FLAT_TOP := 0.15

@export var bottom := Vector2(0, 10)
@export var top := Vector2(0, -10)
@export var width := 8.0
@export var rise := 4.0
## Height of the surface the ramp starts from (0 for the lowland).
@export var base_height := 0.0
@export var top_material: Material

func _ready() -> void:
	if get_node_or_null("Mesh") != null:
		return
	var mesh := ArrayMesh.new()
	var surface := _slope_surface()
	surface.set_material(top_material)
	surface.commit(mesh)
	var sides := _side_surface()
	sides.set_material(_side_material())
	sides.commit(mesh)
	var visual := MeshInstance3D.new()
	visual.name = "Mesh"
	visual.mesh = mesh
	visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(visual)
	var body := StaticBody3D.new()
	body.name = "Body"
	var shape := CollisionShape3D.new()
	var trimesh := mesh.create_trimesh_shape()
	trimesh.backface_collision = true
	shape.shape = trimesh
	body.add_child(shape)
	add_child(body)

func _edge(step: int, side: float) -> Vector3:
	var t := float(step) / STEPS
	var along := bottom.lerp(top, t)
	var direction := (top - bottom).normalized()
	var across := Vector2(-direction.y, direction.x) * width * 0.5 * side
	var flat := along + across
	# Ease the slope so both ends meet their surfaces smoothly, and reach full
	# height before the far end so a jagged cliff lip can never form a step.
	var climb := clampf(t / (1.0 - FLAT_TOP), 0.0, 1.0)
	# Mostly constant slope with softened ends, so climbing feels steady.
	var smooth := climb * climb * (3.0 - 2.0 * climb)
	var eased := lerpf(climb, smooth, END_EASING)
	return Vector3(flat.x, base_height + rise * eased + 0.03, flat.y)

func _across() -> Vector3:
	var direction := (top - bottom).normalized()
	return Vector3(-direction.y, 0, direction.x)

func _slope_surface() -> SurfaceTool:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for step in STEPS:
		var a := _edge(step, -1.0)
		var b := _edge(step, 1.0)
		var c := _edge(step + 1, 1.0)
		var d := _edge(step + 1, -1.0)
		for point in [a, c, b, a, d, c]:
			tool.set_normal(Vector3.UP)
			tool.set_uv(Vector2(point.x, point.z))
			tool.add_vertex(point)
	# Triangles wind counter-clockwise seen from above, so the upward normals
	# match the front face for both per-pixel and per-vertex lighting (D-076).
	return tool

func _side_surface() -> SurfaceTool:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for side in [-1.0, 1.0]:
		for step in STEPS:
			var upper_a := _edge(step, side)
			var upper_b := _edge(step + 1, side)
			# Sloped earth banks (too steep to walk on) instead of sheer walls.
			var outward: Vector3 = _across() * side
			var lower_a: Vector3 = Vector3(upper_a.x, base_height - 0.5, upper_a.z) + outward * (upper_a.y - base_height + 0.5) * BANK_SPREAD
			var lower_b: Vector3 = Vector3(upper_b.x, base_height - 0.5, upper_b.z) + outward * (upper_b.y - base_height + 0.5) * BANK_SPREAD
			var color: Color = TerrainBlock.cliff_colors()[step % TerrainBlock.cliff_colors().size()]
			for point in [lower_a, lower_b, upper_b, lower_a, upper_b, upper_a]:
				tool.set_color(color)
				tool.add_vertex(point)
	tool.generate_normals()
	return tool

func _side_material() -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.roughness = 1.0
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return material
