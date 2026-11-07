@tool
extends Node3D

## A low wooden plank bridge along local Z, with railings that keep the
## player on the deck. Rotate the node to cross a stream.

const PLANK_COLORS := [Color("9a6a3f"), Color("a8774a"), Color("8c5f38")]
const BEAM_COLOR := Color("6e4a2c")
const DECK_HEIGHT := 0.3

@export var length := 14.0
@export var width := 6.0

var _tool: SurfaceTool

func _ready() -> void:
	if get_node_or_null("Planks") != null:
		return
	var random := RandomNumberGenerator.new()
	random.seed = 4401
	var planks := Node3D.new()
	planks.name = "Planks"
	add_child(planks)
	# All planks, posts and rails go into one vertex-colored mesh (one draw call).
	_tool = SurfaceTool.new()
	_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var count := int(length / 1.1)
	for index in count:
		var z := -length / 2.0 + (index + 0.5) * length / count
		var tilt := -atan(_arch_slope(z))
		var plank := Vector3(width + random.randf_range(-0.2, 0.3), 0.22, length / count + 0.05)
		_add_box(planks, plank, Vector3(random.randf_range(-0.12, 0.12), _arch(z) - 0.11, z), PLANK_COLORS[index % 3], random.randf_range(-0.04, 0.04), tilt)
	for side in [-1.0, 1.0]:
		for post in 4:
			var z := -length / 2.0 + 0.4 + post * (length - 0.8) / 3.0
			_add_box(planks, Vector3(0.45, 1.8, 0.45), Vector3(side * width / 2.0, _arch(z) + 0.7, z), BEAM_COLOR)
		for segment in 3:
			var z0 := -length / 2.0 + 0.4 + segment * (length - 0.8) / 3.0
			var z1 := z0 + (length - 0.8) / 3.0
			var middle := (z0 + z1) / 2.0
			var rise := _arch(z1) - _arch(z0)
			_add_box(planks, Vector3(0.28, 0.25, sqrt(pow(z1 - z0, 2.0) + rise * rise)), Vector3(side * width / 2.0, (_arch(z0) + _arch(z1)) / 2.0 + 1.45, middle), BEAM_COLOR, 0.0, -atan2(rise, z1 - z0))
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.roughness = 1.0
	_tool.generate_normals()
	_tool.set_material(material)
	var visual := MeshInstance3D.new()
	visual.mesh = _tool.commit()
	visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	planks.add_child(visual)
	_add_collision()

## Deck surface height along the bridge: zero at both ends, highest midway.
func _arch(z: float) -> float:
	var t := clampf(z / (length / 2.0), -1.0, 1.0)
	return DECK_HEIGHT + 0.9 * (1.0 - t * t)

func _arch_slope(z: float) -> float:
	var half := length / 2.0
	return -1.8 * z / (half * half)

func _add_box(_parent: Node3D, size: Vector3, location: Vector3, color: Color, yaw: float = 0.0, pitch: float = 0.0) -> void:
	var basis := Basis.from_euler(Vector3(pitch, yaw, 0.0))
	var half := size / 2.0
	var corners := []
	for index in 8:
		corners.append(location + basis * Vector3(half.x * (1 if index & 1 else -1), half.y * (1 if index & 2 else -1), half.z * (1 if index & 4 else -1)))
	for quad in [[0, 2, 3, 1], [4, 5, 7, 6], [0, 1, 5, 4], [2, 6, 7, 3], [0, 4, 6, 2], [1, 3, 7, 5]]:
		for index in [0, 1, 2, 0, 2, 3]:
			_tool.set_color(color)
			_tool.add_vertex(corners[quad[index]])

func _add_collision() -> void:
	var body := StaticBody3D.new()
	body.name = "Body"
	add_child(body)
	body.add_child(_deck_collider())
	for side in [-1.0, 1.0]:
		var rail := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(0.6, 3.0, length + 1.0)
		rail.shape = box
		rail.position = Vector3(side * (width / 2.0 + 0.2), 1.5, 0)
		body.add_child(rail)

## Walkable arched deck that also ramps down to the ground beyond each end.
func _deck_collider() -> CollisionShape3D:
	var faces := PackedVector3Array()
	var steps := 10
	var half := width / 2.0
	var profile: Array[Vector2] = [Vector2(-length / 2.0 - 1.5, 0.0)]
	for step in steps + 1:
		var z := -length / 2.0 + step * length / steps
		profile.append(Vector2(z, _arch(z)))
	profile.append(Vector2(length / 2.0 + 1.5, 0.0))
	for index in profile.size() - 1:
		var a := profile[index]
		var b := profile[index + 1]
		var corners := [Vector3(-half, a.y, a.x), Vector3(half, a.y, a.x), Vector3(half, b.y, b.x), Vector3(-half, b.y, b.x)]
		faces.append_array([corners[0], corners[1], corners[2], corners[0], corners[2], corners[3]])
	var shape := ConcavePolygonShape3D.new()
	shape.set_faces(faces)
	shape.backface_collision = true
	var collider := CollisionShape3D.new()
	collider.name = "Deck"
	collider.shape = shape
	return collider
