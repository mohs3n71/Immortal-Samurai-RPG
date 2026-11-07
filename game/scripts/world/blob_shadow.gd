@tool
extends RefCounted

## Cheap soft "blob" contact shadows: a flat transparent quad with a radial
## gradient, slightly offset away from the sun. Used instead of real cast
## shadows, which remain disabled for mobile cost (D-030 / D-068).

const SUN_OFFSET := Vector2(0.22, 0.16)
const HEIGHT := 0.07

static var _mesh: QuadMesh

static func attach(parent: Node3D, radius: float, strength: float = 0.42) -> MeshInstance3D:
	var shadow := MeshInstance3D.new()
	shadow.name = "BlobShadow"
	shadow.mesh = shared_mesh()
	shadow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# The parent may be yawed; undo that so the ellipse and offset stay world-aligned.
	var to_local := Basis(Vector3.UP, parent.rotation.y).inverse()
	var flat := Basis(Vector3.RIGHT, -PI / 2.0) * Basis.from_scale(Vector3(radius * 2.3, radius * 1.9, 1.0))
	shadow.transform = Transform3D(to_local * flat, to_local * Vector3(SUN_OFFSET.x * radius, HEIGHT, SUN_OFFSET.y * radius))
	shadow.transparency = 1.0 - strength
	parent.add_child(shadow)
	return shadow

static func shared_mesh() -> QuadMesh:
	if _mesh == null:
		_mesh = QuadMesh.new()
		_mesh.size = Vector2.ONE
		_mesh.material = _material()
	return _mesh

static func _material() -> StandardMaterial3D:
	var gradient := Gradient.new()
	gradient.set_color(0, Color(0.06, 0.12, 0.05, 1.0))
	gradient.set_color(1, Color(0.06, 0.12, 0.05, 0.0))
	gradient.add_point(0.45, Color(0.06, 0.12, 0.05, 0.75))
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	texture.width = 64
	texture.height = 64
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_texture = texture
	material.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	material.render_priority = -1
	return material
