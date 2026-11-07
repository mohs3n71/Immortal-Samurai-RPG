@tool
extends RefCounted

## Builds and caches flat-shaded, vertex-colored low-poly meshes for the
## meadow (trees, bushes, rocks, grass, flowers, haystacks). They match the
## faceted look of the recovered Butcher Hero props.

const KINDS := ["tree-fruit", "tree-round", "tree-tall", "tree-pine", "bush", "rock", "boulder", "grass", "flower", "haystack", "crop", "log", "stump", "reeds"]

static var _cache := {}
static var _material: StandardMaterial3D
## "meadow" or "frost" (D-100): the region sets it before its world loads; the
## frost palette repaints the same shapes snowy (greens to snow and dark
## evergreen, rocks blue-grey, flowers to ice).
static var palette := "meadow"

static func get_mesh(kind: String, variant: int = 0) -> Mesh:
	var key := "%s:%s:%d" % [palette, kind, variant]
	if not _cache.has(key):
		var mesh := _build(kind, variant)
		_cache[key] = _frost_mesh(mesh) if palette == "frost" else mesh
	return _cache[key]

static func _frost_mesh(mesh: Mesh) -> Mesh:
	var result := ArrayMesh.new()
	for surface in mesh.get_surface_count():
		var arrays := mesh.surface_get_arrays(surface)
		var colors: PackedColorArray = arrays[Mesh.ARRAY_COLOR]
		var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
		for index in colors.size():
			var up := normals[index].y if index < normals.size() else 0.0
			colors[index] = frost_color(colors[index], up)
		arrays[Mesh.ARRAY_COLOR] = colors
		result.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		result.surface_set_material(surface, mesh.surface_get_material(surface))
	return result

## Snowy version of a meadow colour; `up` is the face normal's y (snow lies on top).
static func frost_color(color: Color, up: float) -> Color:
	var h := color.h
	if color.s > 0.2 and h > 0.15 and h < 0.5:
		# Foliage and grass: snow on upward faces, dark frosted evergreen below.
		var evergreen := Color(0.2, 0.33, 0.38).lerp(Color(0.32, 0.45, 0.5), color.v)
		return evergreen.lerp(Color(0.93, 0.96, 1.0), clampf(up * 1.4 - 0.15, 0.0, 1.0))
	if color.s < 0.2:
		# Stone: cold blue-grey, lighter.
		return Color(color.v * 0.95 + 0.1, color.v + 0.13, color.v * 1.05 + 0.2).clamp()
	if h > 0.04 and h < 0.15:
		# Wood and hay: dark, cold brown.
		return Color(color.r * 0.75, color.g * 0.72, color.b * 0.85 + 0.05)
	# Flowers and other bright accents: ice.
	return Color(0.72, 0.9, 1.0).lerp(Color(1, 1, 1), 0.3)

static func material() -> StandardMaterial3D:
	if _material == null:
		_material = StandardMaterial3D.new()
		_material.vertex_color_use_as_albedo = true
		_material.roughness = 1.0
		_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return _material

static func _build(kind: String, variant: int) -> Mesh:
	var random := RandomNumberGenerator.new()
	random.seed = hash(kind) + variant * 7919
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	match kind:
		"tree-round": _round_tree(tool, random, 1.0)
		"tree-tall": _round_tree(tool, random, 1.45)
		"tree-pine": _pine_tree(tool, random)
		"tree-fruit": _fruit_tree(tool, random)
		"bush": _bush(tool, random)
		"rock": _rock(tool, random, Vector3(1.0, 0.65, 0.9))
		"boulder": _rock(tool, random, Vector3(1.0, 0.8, 1.0))
		"grass": _grass(tool, random)
		"flower": _flower(tool, random, variant)
		"haystack": _haystack(tool, random)
		"crop": _crop(tool, random)
		"log": _log(tool, random)
		"stump": _stump(tool, random)
		"reeds": _reeds(tool, random)
		_: push_error("Unknown stylized mesh: " + kind)
	tool.set_material(material())
	return tool.commit()

# --- Shapes -----------------------------------------------------------------

static func _round_tree(tool: SurfaceTool, random: RandomNumberGenerator, stretch: float) -> void:
	var trunk_height := 2.6 * stretch
	_add_prism(tool, Vector3.ZERO, 0.55, 0.32, trunk_height + 0.6, 6, Color("6b4a33"), random)
	var greens := [Color("3f7f2a"), Color("519233"), Color("336a24")]
	var crown := Vector3(0, trunk_height + 1.6 * stretch, 0)
	_add_blob(tool, crown, Vector3(2.3, 2.0 * stretch, 2.3), greens[variant_pick(random, 3)], random, 0.22)
	for index in 3:
		var angle := random.randf() * TAU
		var offset := Vector3(cos(angle) * 1.4, random.randf_range(-0.6, 0.5) * stretch, sin(angle) * 1.4)
		var size := random.randf_range(1.2, 1.6)
		_add_blob(tool, crown + offset, Vector3(size, size * 0.9 * stretch, size), greens[index % 3], random, 0.2)

static func _fruit_tree(tool: SurfaceTool, random: RandomNumberGenerator) -> void:
	_round_tree(tool, random, 0.85)
	var fruit: Color = [Color("e0452f"), Color("f08a24"), Color("e6c13a")][random.randi_range(0, 2)]
	for index in 9:
		var angle := random.randf() * TAU
		var lift := random.randf_range(2.6, 4.6)
		var reach := random.randf_range(1.6, 2.5)
		_add_blob(tool, Vector3(cos(angle) * reach, lift, sin(angle) * reach), Vector3.ONE * 0.22, fruit, random, 0.05)

static func _pine_tree(tool: SurfaceTool, random: RandomNumberGenerator) -> void:
	_add_prism(tool, Vector3.ZERO, 0.4, 0.25, 1.8, 6, Color("5d4030"), random)
	var greens := [Color("24553a"), Color("2c6442"), Color("357149")]
	var base := 1.2
	for tier in 3:
		var radius := 2.4 - tier * 0.6
		var height := 2.6 - tier * 0.4
		_add_cone(tool, Vector3(0, base, 0), radius, height, 7, greens[tier], random)
		base += height * 0.55

static func _bush(tool: SurfaceTool, random: RandomNumberGenerator) -> void:
	var greens := [Color("3f7a28"), Color("4f8c30"), Color("356a24")]
	for index in 3:
		var angle := index * TAU / 3.0 + random.randf() * 0.6
		var offset := Vector3(cos(angle) * 0.6, 0.55, sin(angle) * 0.6)
		var size := random.randf_range(0.7, 0.95)
		_add_blob(tool, offset, Vector3(size, size * 0.8, size), greens[index], random, 0.18)

static func _rock(tool: SurfaceTool, random: RandomNumberGenerator, shape: Vector3) -> void:
	_add_blob(tool, Vector3(0, shape.y * 0.6, 0), shape, Color("70737a"), random, 0.28, Color("5d7a3c"))

static func _grass(tool: SurfaceTool, random: RandomNumberGenerator) -> void:
	for index in 5:
		var angle := random.randf() * TAU
		var root := Vector3(cos(angle), 0, sin(angle)) * random.randf_range(0.0, 0.25)
		var lean := Vector3(cos(angle), 0, sin(angle)) * 0.25
		var side := Vector3(-sin(angle), 0, cos(angle)) * 0.12
		var tip := root + lean + Vector3(0, random.randf_range(0.55, 0.9), 0)
		var color: Color = [Color("5c9c32"), Color("78b542"), Color("4b8a2b")][index % 3]
		_add_triangle(tool, root - side, root + side, tip, color)

static func _flower(tool: SurfaceTool, random: RandomNumberGenerator, variant: int) -> void:
	_grass(tool, random)
	var colors := [Color("f4f1e6"), Color("f2c94c"), Color("e98aa8"), Color("9db7f2")]
	var petal: Color = colors[variant % colors.size()]
	for index in 3:
		var angle := random.randf() * TAU
		var center := Vector3(cos(angle) * 0.25, random.randf_range(0.55, 0.75), sin(angle) * 0.25)
		_add_disc(tool, center, 0.16, 5, petal)

static func _haystack(tool: SurfaceTool, random: RandomNumberGenerator) -> void:
	_add_prism(tool, Vector3.ZERO, 1.4, 1.3, 1.4, 8, Color("d9b64e"), random)
	_add_cone(tool, Vector3(0, 1.4, 0), 1.45, 1.3, 8, Color("e6c65e"), random)

static func _crop(tool: SurfaceTool, random: RandomNumberGenerator) -> void:
	for index in 2:
		var offset := Vector3(random.randf_range(-0.2, 0.2), 0.35, random.randf_range(-0.2, 0.2))
		_add_blob(tool, offset, Vector3(0.45, 0.4, 0.45), [Color("6fae3a"), Color("8cc24a")][index], random, 0.15)

static func _log(tool: SurfaceTool, random: RandomNumberGenerator) -> void:
	var basis := Basis(Vector3.FORWARD, PI / 2.0)
	_add_prism(tool, Vector3(0, 0, 0), 0.45, 0.42, 3.2, 7, Color("7a5638"), random, basis, Vector3(1.6, 0.45, 0))

static func _stump(tool: SurfaceTool, random: RandomNumberGenerator) -> void:
	_add_prism(tool, Vector3.ZERO, 0.75, 0.6, 0.8, 7, Color("6b4a33"), random)
	_add_disc(tool, Vector3(0, 0.81, 0), 0.6, 7, Color("c49a64"))

static func _reeds(tool: SurfaceTool, random: RandomNumberGenerator) -> void:
	for index in 7:
		var root := Vector3(random.randf_range(-0.5, 0.5), 0, random.randf_range(-0.5, 0.5))
		var side := Vector3(0.07, 0, 0.07)
		var tip := root + Vector3(random.randf_range(-0.2, 0.2), random.randf_range(1.2, 1.9), random.randf_range(-0.2, 0.2))
		_add_triangle(tool, root - side, root + side, tip, Color("6e9a3c") if index % 2 == 0 else Color("8aa84a"))

# --- Primitive helpers ---------------------------------------------------

static func variant_pick(random: RandomNumberGenerator, count: int) -> int:
	return random.randi_range(0, count - 1)

static func _add_triangle(tool: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, color: Color) -> void:
	var normal := (b - a).cross(c - a).normalized()
	if normal.y < 0.0 or normal == Vector3.ZERO:
		normal = -normal if normal != Vector3.ZERO else Vector3.UP
	var shade := color.lightened(clampf(normal.y, 0.0, 1.0) * 0.12)
	for point in [a, b, c]:
		tool.set_color(shade)
		tool.set_normal(normal)
		tool.add_vertex(point)

static func _add_face(tool: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, color: Color, center: Vector3, top_color: Color = Color(0, 0, 0, 0)) -> void:
	var normal := (b - a).cross(c - a).normalized()
	if normal.dot((a + b + c) / 3.0 - center) < 0.0:
		normal = -normal
	var shade := color
	if top_color.a > 0.0 and normal.y > 0.6:
		shade = top_color
	shade = shade.lightened(clampf(normal.y, 0.0, 1.0) * 0.1).darkened(clampf(-normal.y, 0.0, 1.0) * 0.3)
	for point in [a, b, c]:
		tool.set_color(shade)
		tool.set_normal(normal)
		tool.add_vertex(point)

static func _add_blob(tool: SurfaceTool, center: Vector3, size: Vector3, color: Color, random: RandomNumberGenerator, jitter: float, top_color: Color = Color(0, 0, 0, 0)) -> void:
	var sphere := SphereMesh.new()
	sphere.radial_segments = 7
	sphere.rings = 4
	var arrays := sphere.get_mesh_arrays()
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	var moved := {}
	var points := PackedVector3Array()
	for vertex in vertices:
		var key := vertex.snappedf(0.001)
		if not moved.has(key):
			var push := 1.0 + random.randf_range(-jitter, jitter)
			moved[key] = center + vertex * 2.0 * size * push
		points.append(moved[key])
	for index in range(0, indices.size(), 3):
		_add_face(tool, points[indices[index]], points[indices[index + 1]], points[indices[index + 2]], color, center, top_color)

static func _add_prism(tool: SurfaceTool, base: Vector3, bottom_radius: float, top_radius: float, height: float, sides: int, color: Color, random: RandomNumberGenerator, basis: Basis = Basis.IDENTITY, origin: Vector3 = Vector3.ZERO) -> void:
	var center := origin + basis * (base + Vector3(0, height / 2.0, 0))
	for side in sides:
		var a0 := side * TAU / sides
		var a1 := (side + 1) * TAU / sides
		var p0 := origin + basis * (base + Vector3(cos(a0) * bottom_radius, 0, sin(a0) * bottom_radius))
		var p1 := origin + basis * (base + Vector3(cos(a1) * bottom_radius, 0, sin(a1) * bottom_radius))
		var q0 := origin + basis * (base + Vector3(cos(a0) * top_radius, height, sin(a0) * top_radius))
		var q1 := origin + basis * (base + Vector3(cos(a1) * top_radius, height, sin(a1) * top_radius))
		var tone := color.darkened(random.randf_range(0.0, 0.12))
		_add_face(tool, p0, p1, q1, tone, center)
		_add_face(tool, p0, q1, q0, tone, center)
		var cap := origin + basis * (base + Vector3(0, height, 0))
		_add_face(tool, q0, q1, cap, color.lightened(0.15), center)

static func _add_cone(tool: SurfaceTool, base: Vector3, radius: float, height: float, sides: int, color: Color, random: RandomNumberGenerator) -> void:
	var tip := base + Vector3(random.randf_range(-0.15, 0.15), height, random.randf_range(-0.15, 0.15))
	var center := base + Vector3(0, height * 0.3, 0)
	var start := random.randf() * TAU
	for side in sides:
		var a0 := start + side * TAU / sides
		var a1 := start + (side + 1) * TAU / sides
		var r0 := radius * random.randf_range(0.85, 1.1)
		var p0 := base + Vector3(cos(a0) * r0, random.randf_range(-0.15, 0.1), sin(a0) * r0)
		var p1 := base + Vector3(cos(a1) * radius, 0, sin(a1) * radius)
		_add_face(tool, p0, p1, tip, color.darkened(random.randf_range(0.0, 0.1)), center)
		_add_face(tool, p0, p1, base, color.darkened(0.35), center)

static func _add_disc(tool: SurfaceTool, center: Vector3, radius: float, sides: int, color: Color) -> void:
	for side in sides:
		var a0 := side * TAU / sides
		var a1 := (side + 1) * TAU / sides
		_add_triangle(tool, center, center + Vector3(cos(a0), 0, sin(a0)) * radius, center + Vector3(cos(a1), 0, sin(a1)) * radius, color)
