@tool
extends Node3D

## One placeable environment object. Set `asset` to "butcher/<name>" for a
## recovered prop or "stylized/<kind>" for a generated low-poly mesh. The node
## builds its model, blob shadow and collider when it enters the tree, so the
## saved scene only stores the parameters and can be edited in the Godot editor.

const StylizedMeshes = preload("res://scripts/world/stylized_meshes.gd")
const BlobShadow = preload("res://scripts/world/blob_shadow.gd")
const PROP_ROOT := "res://assets/environment/butcher-props/"

enum Collision { NONE, SOLID, TRUNK, BOX }

@export var asset := "stylized/tree-round"
@export var variant := 0
@export var height := 6.0
@export var collision := Collision.SOLID
@export var tint := Color.WHITE
@export var shadow_scale := 1.0

static var _meshes := {}
static var _shapes := {}
static var _tinted := {}

func _ready() -> void:
	if get_node_or_null("Model") != null:
		return
	var mesh := _load_mesh()
	if mesh == null:
		push_error("Could not load environment prop: " + asset)
		return
	var bounds := mesh.get_aabb()
	var factor := height / maxf(bounds.size.y, 0.001)
	var model := MeshInstance3D.new()
	model.name = "Model"
	model.mesh = mesh
	model.scale = Vector3.ONE * factor
	model.position = Vector3(-bounds.get_center().x, -bounds.position.y, -bounds.get_center().z) * factor
	model.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(model)
	_apply_tint(model)
	var footprint := maxf(bounds.size.x, bounds.size.z) * factor
	if shadow_scale > 0.0:
		BlobShadow.attach(self, footprint * 0.5 * shadow_scale)
	_add_collision(model, bounds, factor)

func footprint_radius() -> float:
	var mesh := _load_mesh()
	var bounds := mesh.get_aabb()
	return maxf(bounds.size.x, bounds.size.z) * height / maxf(bounds.size.y, 0.001) * 0.5

func _load_mesh() -> Mesh:
	# The region's palette is part of the key (D-100), so travelling between
	# regions never reuses the other region's colours.
	var key := "%s:%d:%s" % [asset, variant, StylizedMeshes.palette]
	if not _meshes.has(key):
		var parts := asset.split("/")
		if parts[0] == "stylized":
			_meshes[key] = StylizedMeshes.get_mesh(parts[1], variant)
		else:
			_meshes[key] = load(PROP_ROOT + parts[1] + ".obj") as Mesh
	return _meshes[key]

func _apply_tint(model: MeshInstance3D) -> void:
	if tint == Color.WHITE:
		return
	for surface in model.mesh.get_surface_count():
		var key := "%s:%d:%s" % [asset, surface, tint.to_html()]
		if not _tinted.has(key):
			var source := model.mesh.surface_get_material(surface)
			var copy: BaseMaterial3D = source.duplicate() if source is BaseMaterial3D else StandardMaterial3D.new()
			copy.albedo_color = copy.albedo_color * tint
			_tinted[key] = copy
		model.set_surface_override_material(surface, _tinted[key])

func _add_collision(model: MeshInstance3D, bounds: AABB, factor: float) -> void:
	if collision == Collision.NONE:
		return
	var body := StaticBody3D.new()
	body.name = "Body"
	var shape := CollisionShape3D.new()
	match collision:
		Collision.TRUNK:
			var trunk := CylinderShape3D.new()
			trunk.radius = clampf(maxf(bounds.size.x, bounds.size.z) * factor * 0.12, 0.5, 1.4)
			trunk.height = 4.0
			shape.shape = trunk
			shape.position.y = 2.0
		Collision.BOX:
			var box := BoxShape3D.new()
			box.size = bounds.size * factor
			shape.shape = box
			shape.position.y = box.size.y / 2.0
		_ when asset.begins_with("stylized/"):
			# Rounded generated shapes get upright sides so heroes cannot climb onto them.
			var column := CylinderShape3D.new()
			column.radius = maxf(bounds.size.x, bounds.size.z) * factor * 0.45
			column.height = maxf(bounds.size.y * factor, 3.0)
			shape.shape = column
			shape.position.y = column.height / 2.0
		_:
			var key := asset + ":%d" % variant
			if not _shapes.has(key):
				_shapes[key] = model.mesh.create_convex_shape()
			shape.shape = _shapes[key]
			shape.transform = model.transform
	body.add_child(shape)
	add_child(body)
