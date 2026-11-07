@tool
extends Node3D

## Scatters many small stylized meshes (grass, flowers, bushes, trees) with
## MultiMesh for low draw-call cost. Points avoid painted paths and water,
## stay inside `area` and outside `clearings` (x, z, radius).

const StylizedMeshes = preload("res://scripts/world/stylized_meshes.gd")
const BlobShadow = preload("res://scripts/world/blob_shadow.gd")

@export var area := PackedVector2Array([Vector2(-10, -10), Vector2(10, -10), Vector2(10, 10), Vector2(-10, 10)])
@export var kinds: Array[String] = ["grass"]
@export var variants := 1
@export var count := 100
@export var scale_range := Vector2(0.8, 1.3)
@export var surface_height := 0.0
@export var seed := 1
@export var clearings := PackedVector3Array()
## Polygons inside `area` to leave empty (for example higher plateaus).
@export var holes: Array[PackedVector2Array] = []
@export var avoid_paths := true
@export var shadow_radius := 0.0
@export var mask: Texture2D
@export var mask_origin := Vector2(-150, -150)
@export var mask_size := 300.0

var _mask_image: Image

func _ready() -> void:
	if get_node_or_null("Instances") != null:
		return
	if mask != null:
		_mask_image = mask.get_image()
	var random := RandomNumberGenerator.new()
	random.seed = seed
	var groups := {}
	var shadows: Array[Transform3D] = []
	var bounds := _area_bounds()
	var attempts := count * 4
	var placed := 0
	while placed < count and attempts > 0:
		attempts -= 1
		var point := Vector2(random.randf_range(bounds.position.x, bounds.end.x), random.randf_range(bounds.position.y, bounds.end.y))
		if not _is_open(point):
			continue
		var key := "%s:%d" % [kinds[random.randi_range(0, kinds.size() - 1)], random.randi_range(0, variants - 1)]
		var size := random.randf_range(scale_range.x, scale_range.y)
		var basis := Basis(Vector3.UP, random.randf_range(0.0, TAU)).scaled(Vector3.ONE * size)
		if not groups.has(key):
			groups[key] = []
		groups[key].append(Transform3D(basis, Vector3(point.x, surface_height, point.y)))
		if shadow_radius > 0.0:
			shadows.append(_shadow_transform(point, shadow_radius * size))
		placed += 1
	var holder := Node3D.new()
	holder.name = "Instances"
	add_child(holder)
	for key in groups:
		var parts: PackedStringArray = key.split(":")
		_add_multimesh(holder, StylizedMeshes.get_mesh(parts[0], int(parts[1])), groups[key])
	if not shadows.is_empty():
		_add_multimesh(holder, BlobShadow.shared_mesh(), shadows)

func _area_bounds() -> Rect2:
	var rect := Rect2(area[0], Vector2.ZERO)
	for point in area:
		rect = rect.expand(point)
	return rect

func _is_open(point: Vector2) -> bool:
	if not Geometry2D.is_point_in_polygon(point, area):
		return false
	for hole in holes:
		if Geometry2D.is_point_in_polygon(point, hole):
			return false
	for clearing in clearings:
		if point.distance_to(Vector2(clearing.x, clearing.y)) < clearing.z:
			return false
	if avoid_paths and _mask_image != null:
		var pixel := ((point - mask_origin) / mask_size * _mask_image.get_width()).floor()
		if pixel.x >= 0 and pixel.y >= 0 and pixel.x < _mask_image.get_width() and pixel.y < _mask_image.get_height():
			var value := _mask_image.get_pixelv(Vector2i(pixel))
			if value.r > 0.3 or value.g > 0.28:
				return false
	return true

func _shadow_transform(point: Vector2, radius: float) -> Transform3D:
	var flat := Basis(Vector3.RIGHT, -PI / 2.0) * Basis.from_scale(Vector3(radius * 2.3, radius * 1.9, 1.0))
	var offset := Vector3(BlobShadow.SUN_OFFSET.x * radius, surface_height + BlobShadow.HEIGHT, BlobShadow.SUN_OFFSET.y * radius)
	return Transform3D(flat, Vector3(point.x, 0, point.y) + offset)

func _add_multimesh(holder: Node3D, mesh: Mesh, transforms: Array) -> void:
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = mesh
	multimesh.instance_count = transforms.size()
	for index in transforms.size():
		multimesh.set_instance_transform(index, transforms[index])
	var visual := MultiMeshInstance3D.new()
	visual.multimesh = multimesh
	visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	holder.add_child(visual)
