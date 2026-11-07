extends RefCounted

## Combo feedback (D-075): sword-trail arcs, a ground shockwave for the
## finisher, a floating hit counter, hit-stop and camera shake. Trail meshes
## are built once per style and shared; each spawn only adds one short-lived
## MeshInstance3D with its own fading material.

const TRAIL_COLOR := Color(1.0, 1.0, 1.0)
const TRAIL_EDGE := Color(0.05, 0.55, 0.72)
const COUNTER_COLOR := Color("ffd45a")
const SEGMENTS := 18

static var _meshes := {}
static var _ring: Mesh
static var _hit_stop_depth := 0

## Arc around the hero in his own space (+Z forward, +X his left).
static func spawn_trail(player: Node3D, yaw: float, style: String) -> void:
	var instance := MeshInstance3D.new()
	instance.mesh = _trail_mesh(style)
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var material := _fade_material()
	instance.material_override = material
	instance.rotation.y = yaw
	player.add_child(instance)
	var tween := instance.create_tween()
	tween.set_parallel(true)
	tween.tween_property(material, "albedo_color:a", 0.0, 0.3).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(instance, "scale", Vector3.ONE * 1.12, 0.24)
	tween.chain().tween_callback(instance.queue_free)

## Expanding ring on the ground where the finisher lands.
static func spawn_shockwave(world: Node3D, where: Vector3) -> void:
	var instance := MeshInstance3D.new()
	instance.mesh = _ring_mesh()
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var material := _fade_material()
	instance.material_override = material
	world.add_child(instance)
	instance.global_position = where + Vector3(0, 0.25, 0)
	instance.scale = Vector3.ONE * 0.4
	var tween := instance.create_tween()
	tween.set_parallel(true)
	tween.tween_property(instance, "scale", Vector3.ONE * 1.6, 0.35).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(material, "albedo_color:a", 0.0, 0.35).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(instance.queue_free)

## "3 HITS" over the target once a chain lands more than one blow.
static func show_counter(world: Node3D, where: Vector3, hits: int, finisher: bool) -> void:
	if hits < 2:
		return
	var label := Label3D.new()
	label.text = "%d HITS%s" % [hits, "!" if finisher else ""]
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.font_size = 112 if finisher else 84
	label.outline_size = 22
	label.modulate = COUNTER_COLOR
	label.outline_modulate = Color("3a2412")
	label.pixel_size = 0.02
	world.add_child(label)
	label.global_position = where + Vector3(0, 8.0, 0)
	var tween := label.create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "global_position", label.global_position + Vector3(0, 2.0, 0), 0.6).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, 0.25).set_delay(0.35)
	tween.tween_property(label, "outline_modulate:a", 0.0, 0.25).set_delay(0.35)
	tween.chain().tween_callback(label.queue_free)

## Freezes the action for a moment so each blow feels solid.
static func hit_stop(tree: SceneTree, seconds: float) -> void:
	_hit_stop_depth += 1
	Engine.time_scale = 0.05
	await tree.create_timer(seconds, true, false, true).timeout
	_hit_stop_depth -= 1
	if _hit_stop_depth <= 0:
		_hit_stop_depth = 0
		Engine.time_scale = 1.0

static func shake(camera: Camera3D, strength: float, seconds: float) -> void:
	if camera == null:
		return
	var tween := camera.create_tween()
	tween.set_ignore_time_scale(true)
	tween.tween_method(func(left: float) -> void: _jitter(camera, strength * left), 1.0, 0.0, seconds)
	tween.tween_callback(func() -> void: _jitter(camera, 0.0))

static func _jitter(camera: Camera3D, amount: float) -> void:
	if not is_instance_valid(camera):
		return
	camera.h_offset = randf_range(-amount, amount)
	camera.v_offset = randf_range(-amount, amount)

static func _fade_material() -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.vertex_color_use_as_albedo = true
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	# Drawn over the hat and the hero so the arc always reads from above.
	material.no_depth_test = true
	material.render_priority = 2
	material.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	return material

static func _trail_mesh(style: String) -> Mesh:
	if _meshes.has(style):
		return _meshes[style]
	var points: Array[Vector3] = []
	var inner := 5.8
	var outer := 8.2
	var basis := Basis.IDENTITY
	var from := -100.0
	var to := 100.0
	var height := 5.2
	match style:
		"sweep_left":
			basis = Basis(Vector3.BACK, deg_to_rad(8.0))
		"sweep_right":
			from = 100.0
			to = -100.0
			height = 4.6
			basis = Basis(Vector3.BACK, deg_to_rad(-10.0))
		"rise":
			from = 110.0
			to = -90.0
			basis = Basis(Vector3.BACK, deg_to_rad(-58.0))
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	# Crescent: thickest just behind the leading edge, tapering to nothing at
	# the trailing end; bright outer rim, teal inner rim.
	var rows: Array = []
	for index in SEGMENTS + 1:
		var t := float(index) / SEGMENTS
		var thickness := (outer - inner) * pow(sin(PI * clampf(t * 0.92 + 0.04, 0.0, 1.0)), 0.7) * (0.35 + 0.65 * t)
		if style == "slam":
			# Vertical arc from overhead down to the ground in front.
			var angle := deg_to_rad(lerpf(-20.0, 125.0, t))
			var center := Vector3(0, 4.2, 0.6)
			var radial := Vector3(0, cos(angle), sin(angle))
			rows.append([center + radial * (7.6 - thickness), center + radial * 7.6, t])
		else:
			var angle := deg_to_rad(lerpf(from, to, t))
			var direction := Vector3(sin(angle), 0, cos(angle))
			var lift := Vector3(0, height, 0)
			rows.append([basis * (direction * (outer - thickness)) + lift, basis * (direction * outer) + lift, t])
	for index in SEGMENTS:
		var a: Array = rows[index]
		var b: Array = rows[index + 1]
		var quad := [[a[0], a[2], false], [a[1], a[2], true], [b[1], b[2], true], [a[0], a[2], false], [b[1], b[2], true], [b[0], b[2], false]]
		for corner in quad:
			var alpha := smoothstep(0.0, 0.45, float(corner[1]))
			var color: Color = TRAIL_COLOR if corner[2] else TRAIL_EDGE
			tool.set_color(Color(color.r, color.g, color.b, alpha * (1.0 if corner[2] else 0.85)))
			tool.set_normal(Vector3.UP)
			tool.add_vertex(corner[0])
	var mesh := tool.commit()
	_meshes[style] = mesh
	return mesh

static func _ring_mesh() -> Mesh:
	if _ring != null:
		return _ring
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var sides := 28
	for index in sides:
		var a0 := TAU * index / sides
		var a1 := TAU * (index + 1) / sides
		var corners := [Vector3(cos(a0), 0, sin(a0)) * 3.8, Vector3(cos(a0), 0, sin(a0)) * 5.4, Vector3(cos(a1), 0, sin(a1)) * 5.4, Vector3(cos(a1), 0, sin(a1)) * 3.8]
		var alphas := [0.2, 0.85, 0.85, 0.2]
		for corner in [0, 1, 2, 0, 2, 3]:
			tool.set_color(Color(TRAIL_COLOR.r, TRAIL_COLOR.g, TRAIL_COLOR.b, alphas[corner]))
			tool.set_normal(Vector3.UP)
			tool.add_vertex(corners[corner])
	_ring = tool.commit()
	return _ring
