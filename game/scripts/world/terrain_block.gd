@tool
extends Node3D

## A raised plateau: a polygon footprint extruded to `height` with layered,
## faceted cliff walls and a grass lip. The top uses the shared ground
## material, so paths painted in the ground mask continue across it.
## Collision is a trimesh, so the top is walkable and the walls block.

const CLIFF_COLORS := [Color("8a7360"), Color("9b836c"), Color("745f4e"), Color("907a64")]
const BASE_COLOR := Color("5c4a3d")
const LIP_COLOR := Color("4f8a2c")
## Frostlands rock (D-100): blue-grey bands, a snow lip on top.
const FROST_CLIFF_COLORS := [Color("8c9bb0"), Color("9eacbf"), Color("7d8ca3"), Color("94a3b8")]
const FROST_BASE_COLOR := Color("5f6b7d")
const FROST_LIP_COLOR := Color("e6eef7")
## Set by the region before its world loads, like StylizedMeshes.palette.
static var palette := "meadow"

static func cliff_colors() -> Array:
	return FROST_CLIFF_COLORS if palette == "frost" else CLIFF_COLORS
const SEGMENT_LENGTH := 3.2
const BAND_HEIGHT := 1.5
const BASE_DEPTH := -0.6

@export var outline := PackedVector2Array([Vector2(-10, -10), Vector2(10, -10), Vector2(10, 10), Vector2(-10, 10)])
@export var height := 4.0
@export var jaggedness := 0.7
@export var seed := 1
@export var top_material: Material
## Wall openings (x, z, radius in local space) where ramps enter the plateau.
@export var openings := PackedVector3Array()

var _random := RandomNumberGenerator.new()

func _ready() -> void:
	if get_node_or_null("Mesh") != null:
		return
	_random.seed = seed
	var points := _densify(_counter_clockwise(outline))
	var rings := _build_rings(points)
	var mesh := ArrayMesh.new()
	_commit(mesh, _cliff_surface(rings), _cliff_material())
	_commit(mesh, _top_surface(rings[-1]), top_material)
	var visual := MeshInstance3D.new()
	visual.name = "Mesh"
	visual.mesh = mesh
	visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(visual)
	_add_collision(mesh)

func top_height() -> float:
	return height

func _counter_clockwise(points: PackedVector2Array) -> PackedVector2Array:
	var area := 0.0
	for index in points.size():
		var a := points[index]
		var b := points[(index + 1) % points.size()]
		area += a.x * b.y - b.x * a.y
	if area < 0.0:
		var reversed := points.duplicate()
		reversed.reverse()
		return reversed
	return points

func _densify(points: PackedVector2Array) -> PackedVector2Array:
	var result := PackedVector2Array()
	for index in points.size():
		var a := points[index]
		var b := points[(index + 1) % points.size()]
		var steps := maxi(1, ceili(a.distance_to(b) / SEGMENT_LENGTH))
		for step in steps:
			result.append(a.lerp(b, float(step) / steps))
	return result

func _outward(points: PackedVector2Array, index: int) -> Vector2:
	var previous := points[(index - 1 + points.size()) % points.size()]
	var next := points[(index + 1) % points.size()]
	var direction := (next - previous).normalized()
	return Vector2(direction.y, -direction.x)

## Rings of 3D points from the buried base up to the grass lip.
func _build_rings(points: PackedVector2Array) -> Array:
	var levels: Array[float] = [BASE_DEPTH]
	var bands := maxi(1, roundi((height - 0.7) / BAND_HEIGHT))
	for band in range(1, bands + 1):
		levels.append((height - 0.7) * band / bands)
	levels.append(height)
	var rings := []
	for level_index in levels.size():
		var ring := PackedVector3Array()
		var is_lip := level_index == levels.size() - 1
		var band_offset := 0.25 if is_lip else _random.randf_range(-0.35, 0.35) * jaggedness
		for index in points.size():
			var outward := _outward(points, index)
			var push := band_offset + _random.randf_range(-jaggedness, jaggedness) * (0.4 if is_lip else 1.0)
			var flat := points[index] + outward * push
			ring.append(Vector3(flat.x, levels[level_index], flat.y))
		rings.append(ring)
	return rings

func _cliff_surface(rings: Array) -> SurfaceTool:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for level in rings.size() - 1:
		var lower: PackedVector3Array = rings[level]
		var upper: PackedVector3Array = rings[level + 1]
		var is_lip := level == rings.size() - 2
		var base_color: Color = cliff_colors()[(level + seed) % cliff_colors().size()]
		if is_lip:
			base_color = FROST_LIP_COLOR if palette == "frost" else LIP_COLOR
		elif level == 0:
			base_color = FROST_BASE_COLOR if palette == "frost" else BASE_COLOR
		for index in lower.size():
			var next := (index + 1) % lower.size()
			if _in_opening(lower[index], lower[next]):
				continue
			var tone := base_color.darkened(_random.randf_range(0.0, 0.14))
			_add_wall_face(tool, lower[index], lower[next], upper[next], tone)
			_add_wall_face(tool, lower[index], upper[next], upper[index], tone.lightened(0.04))
	return tool

func _in_opening(a: Vector3, b: Vector3) -> bool:
	var middle := Vector2(a.x + b.x, a.z + b.z) * 0.5
	for opening in openings:
		if middle.distance_to(Vector2(opening.x, opening.y)) < opening.z:
			return true
	return false

func _add_wall_face(tool: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, color: Color) -> void:
	var normal := (b - a).cross(c - a).normalized()
	var edge := b - a
	var outward := Vector3(edge.z, 0.0, -edge.x).normalized()
	if normal.dot(outward) < 0.0:
		normal = -normal
	for point in [a, b, c]:
		tool.set_color(color)
		tool.set_normal(normal)
		tool.add_vertex(point)

func _top_surface(ring: PackedVector3Array) -> SurfaceTool:
	var flat := PackedVector2Array()
	for point in ring:
		flat.append(Vector2(point.x, point.z))
	var indices := Geometry2D.triangulate_polygon(flat)
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for index in indices:
		tool.set_normal(Vector3.UP)
		tool.set_uv(flat[index])
		tool.add_vertex(Vector3(flat[index].x, height, flat[index].y))
	if indices.is_empty():
		push_warning("Plateau top could not be triangulated: " + name)
	return tool

func _commit(mesh: ArrayMesh, tool: SurfaceTool, material: Material) -> void:
	tool.set_material(material)
	tool.commit(mesh)

func _cliff_material() -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.roughness = 1.0
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return material

func _add_collision(mesh: ArrayMesh) -> void:
	var body := StaticBody3D.new()
	body.name = "Body"
	var shape := CollisionShape3D.new()
	var trimesh := mesh.create_trimesh_shape()
	trimesh.backface_collision = true
	shape.shape = trimesh
	body.add_child(shape)
	add_child(body)
