@tool
extends Node3D

## Straw training dummy on a post (D-072): a simple enemy for testing
## auto-attack. Wobbles when hit, topples when its health runs out and stands
## back up after a few seconds. Joins the "enemies" group at runtime.

const StylizedMeshes = preload("res://scripts/world/stylized_meshes.gd")
const BlobShadow = preload("res://scripts/world/blob_shadow.gd")

const WOOD := Color("7a5536")
const STRAW := Color("d9b65a")
const STRAW_DARK := Color("b38f3e")
const SACK := Color("cdb994")
const ROPE := Color("8c6a3f")
const MARK := Color("b0352c")

@export var max_health := 5
@export var respawn_seconds := 3.5
@export var height := 5.2

var health := 5.0
var _body: Node3D
var _tween: Tween

func _ready() -> void:
	if get_node_or_null("Body") != null:
		return
	health = max_health
	_body = Node3D.new()
	_body.name = "Body"
	add_child(_body)
	var model := MeshInstance3D.new()
	model.mesh = _build_mesh()
	model.scale = Vector3.ONE * height / 2.1
	model.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_body.add_child(model)
	BlobShadow.attach(self, 1.1)
	_add_collision()
	if not Engine.is_editor_hint():
		add_to_group("enemies")

func is_alive() -> bool:
	return health > 0

## `force` scales the knock (combo finishers hit harder, D-075).
func take_hit(damage: float, from_position: Vector3, force := 1.0) -> void:
	if health <= 0:
		return
	health -= damage
	var away := global_position - from_position
	away.y = 0.0
	away = away.normalized() if away.length() > 0.01 else Vector3.FORWARD
	var axis := Vector3.UP.cross(away).normalized()
	if _tween != null:
		_tween.kill()
	_tween = create_tween()
	if health > 0:
		_tween.tween_property(_body, "basis", Basis(axis, minf(0.45 * force, 1.1)), 0.07)
		_tween.tween_property(_body, "basis", Basis(axis, -0.18 * force), 0.14)
		_tween.tween_property(_body, "basis", Basis.IDENTITY, 0.18)
	else:
		_tween.tween_property(_body, "basis", Basis(axis, 1.45), 0.35).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
		_tween.tween_interval(respawn_seconds)
		_tween.tween_property(_body, "basis", Basis.IDENTITY, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		_tween.tween_callback(func(): health = max_health)

func _add_collision() -> void:
	var static_body := StaticBody3D.new()
	static_body.name = "Collider"
	var shape := CollisionShape3D.new()
	var cylinder := CylinderShape3D.new()
	cylinder.radius = 0.75
	cylinder.height = height
	shape.shape = cylinder
	shape.position.y = height / 2.0
	static_body.add_child(shape)
	add_child(static_body)

## Built in a 2.1-unit-tall space, scaled to `height`.
func _build_mesh() -> Mesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	_prism(tool, Vector3(0, 0, 0), 0.08, 0.07, 1.25, 6, WOOD)
	_prism(tool, Vector3(0, 0, 0), 0.3, 0.26, 0.08, 7, WOOD.darkened(0.2))
	_prism(tool, Vector3(0, 0.62, 0), 0.3, 0.34, 0.75, 9, STRAW)
	for band_y in [0.75, 1.15]:
		_prism(tool, Vector3(0, band_y, 0), 0.335, 0.335, 0.05, 9, ROPE)
	_prism(tool, Vector3(0, 1.37, 0), 0.34, 0.2, 0.12, 9, STRAW_DARK)
	_beam(tool, Vector3(-0.72, 1.22, 0), Vector3(0.72, 1.22, 0), 0.06, WOOD)
	for side: float in [-1.0, 1.0]:
		_prism(tool, Vector3(side * 0.62, 1.05, 0), 0.1, 0.12, 0.3, 6, STRAW)
	_blob(tool, Vector3(0, 1.72, 0), Vector3(0.28, 0.3, 0.28), SACK)
	_blob(tool, Vector3(0, 2.01, 0), Vector3(0.08, 0.06, 0.08), ROPE)
	# Painted target cross on the chest and X eyes on the sack face.
	_quad(tool, Vector3(0, 0.98, 0.345), Vector2(0.28, 0.05), 0.785, MARK)
	_quad(tool, Vector3(0, 0.98, 0.345), Vector2(0.28, 0.05), -0.785, MARK)
	for side: float in [-1.0, 1.0]:
		_quad(tool, Vector3(side * 0.1, 1.77, 0.29), Vector2(0.1, 0.025), 0.785, Color("3a2a20"))
		_quad(tool, Vector3(side * 0.1, 1.77, 0.29), Vector2(0.1, 0.025), -0.785, Color("3a2a20"))
	tool.set_material(StylizedMeshes.material())
	return tool.commit()

func _face(tool: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, color: Color, center: Vector3) -> void:
	var normal := (b - a).cross(c - a).normalized()
	if normal.dot((a + b + c) / 3.0 - center) < 0.0:
		normal = -normal
	var shade := color.lightened(clampf(normal.y, 0.0, 1.0) * 0.12).darkened(clampf(-normal.y, 0.0, 1.0) * 0.25)
	for point in [a, b, c]:
		tool.set_color(shade)
		tool.set_normal(normal)
		tool.add_vertex(point)

func _prism(tool: SurfaceTool, base: Vector3, bottom: float, top: float, tall: float, sides: int, color: Color) -> void:
	var center := base + Vector3(0, tall / 2.0, 0)
	for side in sides:
		var a0 := side * TAU / sides
		var a1 := (side + 1) * TAU / sides
		var p0 := base + Vector3(cos(a0) * bottom, 0, sin(a0) * bottom)
		var p1 := base + Vector3(cos(a1) * bottom, 0, sin(a1) * bottom)
		var q0 := base + Vector3(cos(a0) * top, tall, sin(a0) * top)
		var q1 := base + Vector3(cos(a1) * top, tall, sin(a1) * top)
		var tone := color.darkened(0.05 * (side % 2))
		_face(tool, p0, p1, q1, tone, center)
		_face(tool, p0, q1, q0, tone, center)
		_face(tool, q0, q1, base + Vector3(0, tall, 0), color.lightened(0.1), center)

func _beam(tool: SurfaceTool, a: Vector3, b: Vector3, radius: float, color: Color) -> void:
	var center := (a + b) / 2.0
	var corners := [Vector3(0, radius, radius), Vector3(0, radius, -radius), Vector3(0, -radius, -radius), Vector3(0, -radius, radius)]
	for index in 4:
		var c0: Vector3 = corners[index]
		var c1: Vector3 = corners[(index + 1) % 4]
		_face(tool, a + c0, b + c0, b + c1, color, center)
		_face(tool, a + c0, b + c1, a + c1, color, center)

func _blob(tool: SurfaceTool, center: Vector3, size: Vector3, color: Color) -> void:
	var sphere := SphereMesh.new()
	sphere.radial_segments = 8
	sphere.rings = 5
	var arrays := sphere.get_mesh_arrays()
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	for index in range(0, indices.size(), 3):
		_face(tool, center + vertices[indices[index]] * 2.0 * size, center + vertices[indices[index + 1]] * 2.0 * size, center + vertices[indices[index + 2]] * 2.0 * size, color, center)

## Flat marking just in front of a surface facing +Z, rotated by `roll`.
func _quad(tool: SurfaceTool, center: Vector3, size: Vector2, roll: float, color: Color) -> void:
	var basis := Basis(Vector3.BACK, roll)
	var hx := basis * Vector3(size.x / 2.0, 0, 0)
	var hy := basis * Vector3(0, size.y / 2.0, 0)
	var behind := center - Vector3(0, 0, 1)
	_face(tool, center - hx - hy, center + hx - hy, center + hx + hy, color, behind)
	_face(tool, center - hx - hy, center + hx + hy, center - hx + hy, color, behind)
