extends SceneTree

## Builds the Meadowlands region from tools/meadow_layout.gd.
##   Phase 1 (paint the ground mask):   ... --script res://tools/build_meadow.gd -- mask
##   then re-import:                     ... --headless --import
##   Phase 2 (material + scenes):        ... --script res://tools/build_meadow.gd -- scene
## Outputs: assets/environment/meadow/*, scenes/world/meadow_world.tscn, scenes/meadow.tscn.
## Re-running phase 2 overwrites manual edits to the generated world scene.

const FieldProp = preload("res://scripts/world/field_prop.gd")
const TerrainBlock = preload("res://scripts/world/terrain_block.gd")
const TerrainRamp = preload("res://scripts/world/terrain_ramp.gd")
const MeadowGround = preload("res://scripts/world/meadow_ground.gd")
const WaterBarrier = preload("res://scripts/world/water_barrier.gd")
const WoodenBridge = preload("res://scripts/world/wooden_bridge.gd")
const GroundScatter = preload("res://scripts/world/ground_scatter.gd")
const CropField = preload("res://scripts/world/crop_field.gd")
const TrainingDummy = preload("res://scripts/world/training_dummy.gd")
const MainScript = preload("res://scripts/main.gd")

## Regions built by this script (D-100): pass the theme after the phase,
## e.g. "-- mask frost" then "-- scene frost". Default: meadow (region 1).
const THEMES := {
	"meadow": {"layout": "res://tools/meadow_layout.gd", "dir": "res://assets/environment/meadow/", "prefix": "meadow",
		"world": "res://scenes/world/meadow_world.tscn", "field": "res://scenes/meadow.tscn", "root": "MeadowWorld", "field_name": "MeadowField",
		"floor": "res://assets/environment/meadowlands-floor-v001.png", "path": "res://assets/environment/dirt-path-v001.png",
		"region": 1, "palette": "meadow", "shader": {},
		"background": Color("3b5a34"), "ambient": Color("e4ecd6"), "ambient_energy": 0.45, "saturation": 1.12,
		"sun": Color("fff1d8"), "sun_energy": 1.3, "fill": Color("b4ccff"), "fill_energy": 0.35},
	"frost": {"layout": "res://tools/frost_layout.gd", "dir": "res://assets/environment/frost/", "prefix": "frost",
		"world": "res://scenes/world/frost_world.tscn", "field": "", "root": "FrostWorld", "field_name": "FrostField",
		"floor": "res://assets/environment/frost/frost-floor-v001.png", "path": "res://assets/environment/frost/frost-path-v001.png",
		"region": 2, "palette": "frost", "offset": Vector3(62, 0, -268),
		"shader": {"grass_light": Color(0.97, 0.98, 1.0), "grass_dark": Color(0.8, 0.86, 0.95), "grass_desaturation": 0.0,
			"path_rim": Color(0.52, 0.6, 0.74), "shore_color": Color(0.86, 0.91, 0.97),
			"water_shallow": Color(0.66, 0.87, 0.96), "water_deep": Color(0.38, 0.62, 0.84)},
		"background": Color("8796ab"), "ambient": Color("dfe8ff"), "ambient_energy": 0.5, "saturation": 1.0,
		"sun": Color("f4f8ff"), "sun_energy": 1.05, "fill": Color("a9c1ff"), "fill_energy": 0.45},
}
var theme: Dictionary
var Layout: Script
var ASSET_DIR: String
var MASK_PATH: String
var MATERIAL_PATH: String
var WORLD_PATH: String
var FIELD_PATH: String
const MASK_ORIGIN := Vector2(-260, -260)
const MASK_SIZE := 520.0
const MASK_PIXELS := 1040
const SCATTER_TILE := 84.0

var root_node: Node3D
var ground_material: ShaderMaterial
var mask_image: Image
var clearings := PackedVector3Array()
## Solid things already placed (x, z, radius), so generated trees keep clear.
var occupied := PackedVector3Array()
var bridges := []

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var phase: String = args[0] if args.size() > 0 else "scene"
	theme = THEMES[args[1] if args.size() > 1 else "meadow"]
	Layout = load(theme.layout)
	ASSET_DIR = theme.dir
	MASK_PATH = ASSET_DIR + theme.prefix + "-ground-mask-v001.png"
	MATERIAL_PATH = ASSET_DIR + theme.prefix + "-ground-material-v001.tres"
	WORLD_PATH = theme.world
	FIELD_PATH = theme.field
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(ASSET_DIR))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://scenes/world"))
	if phase == "mask":
		_paint_mask()
	else:
		_build_scenes()
	quit()

# --- Water geometry ------------------------------------------------------------

## Water polylines: [points, half width]. The stream ends in the pond, the
## outflow runs from the pond to the lake, and the lake drains off the map.
func _water_lines() -> Array:
	var pond := Vector2(Layout.POND[0].x, Layout.POND[0].y)
	var lake := Vector2(Layout.LAKE[0].x, Layout.LAKE[0].y)
	var half_width: float = Layout.STREAM_HALF_WIDTH
	return [
		[Layout.STREAM + [pond], Layout.STREAM_HALF_WIDTH],
		[[pond] + Layout.OUTFLOW + [lake], Layout.STREAM_HALF_WIDTH * 0.8],
		[[lake] + Layout.LAKE_OUTFLOW, Layout.STREAM_HALF_WIDTH * 0.8],
	]

## A bridge wherever a path crosses a water line: [centre, length, width, yaw].
func _find_bridges() -> Array:
	var found := []
	for path in Layout.PATHS:
		var points: Array = path[1]
		for index in points.size() - 1:
			for line in _water_lines():
				var water: Array = line[0]
				for w in water.size() - 1:
					var hit = Geometry2D.segment_intersects_segment(points[index], points[index + 1], water[w], water[w + 1])
					if hit == null or _near_any(hit, found, 4.0):
						continue
					var direction: Vector2 = points[index + 1] - points[index]
					found.append([hit, line[1] * 2.0 + 5.0, 6.5, atan2(direction.x, direction.y)])
	return found

func _near_any(point: Vector2, entries: Array, distance: float) -> bool:
	for entry in entries:
		if point.distance_to(entry[0]) < distance:
			return true
	return false

# --- Ground mask -------------------------------------------------------------

func _paint_mask() -> void:
	var paths := PackedFloat32Array()
	var water := PackedFloat32Array()
	paths.resize(MASK_PIXELS * MASK_PIXELS)
	water.resize(MASK_PIXELS * MASK_PIXELS)
	for path in Layout.PATHS:
		_paint_polyline(paths, path[1], path[0])
	if not _link().is_empty():
		_paint_polyline(paths, _link().path, 3.4)
	for plaza in Layout.PLAZAS:
		_paint_segment(paths, Vector2(plaza.x, plaza.y), Vector2(plaza.x, plaza.y), plaza.z)
	for line in _water_lines():
		_paint_polyline(water, line[0], line[1])
	for pool in Layout.POND + Layout.LAKE:
		_paint_segment(water, Vector2(pool.x, pool.y), Vector2(pool.x, pool.y), pool.z)
	var image := Image.create(MASK_PIXELS, MASK_PIXELS, false, Image.FORMAT_RGB8)
	for y in MASK_PIXELS:
		for x in MASK_PIXELS:
			var index := y * MASK_PIXELS + x
			image.set_pixel(x, y, Color(paths[index], water[index], 0.0))
	image.save_png(ProjectSettings.globalize_path(MASK_PATH))
	print("Painted ", MASK_PATH)

func _paint_polyline(target: PackedFloat32Array, points: Array, half_width: float) -> void:
	for index in points.size() - 1:
		_paint_segment(target, points[index], points[index + 1], half_width)

## Stores 1 at the centre falling to 0.5 at the painted edge and 0 at twice
## that distance, so the shader can break the edge up with noise.
func _paint_segment(target: PackedFloat32Array, a: Vector2, b: Vector2, half_width: float) -> void:
	var reach := half_width * 2.0
	var low := _to_pixel(Vector2(minf(a.x, b.x), minf(a.y, b.y)) - Vector2.ONE * reach)
	var high := _to_pixel(Vector2(maxf(a.x, b.x), maxf(a.y, b.y)) + Vector2.ONE * reach)
	for y in range(maxi(low.y, 0), mini(high.y + 1, MASK_PIXELS)):
		for x in range(maxi(low.x, 0), mini(high.x + 1, MASK_PIXELS)):
			var world := MASK_ORIGIN + (Vector2(x, y) + Vector2(0.5, 0.5)) * MASK_SIZE / MASK_PIXELS
			var closest := Geometry2D.get_closest_point_to_segment(world, a, b)
			var value := clampf(1.0 - 0.5 * world.distance_to(closest) / half_width, 0.0, 1.0)
			var index := y * MASK_PIXELS + x
			target[index] = maxf(target[index], value)

func _to_pixel(world: Vector2) -> Vector2i:
	return Vector2i(((world - MASK_ORIGIN) / MASK_SIZE * MASK_PIXELS).floor())

# --- Scenes ------------------------------------------------------------------

func _build_scenes() -> void:
	ground_material = _build_ground_material()
	mask_image = Image.load_from_file(ProjectSettings.globalize_path(MASK_PATH))
	bridges = _find_bridges()
	root_node = Node3D.new()
	root_node.name = theme.root
	root_node.position = theme.get("offset", Vector3.ZERO)
	_collect_clearings()
	_add_lighting()
	_add_ground_and_terrain()
	_add_water()
	_add_props()
	_add_scatter()
	_save(root_node, WORLD_PATH)
	# Region 1's field scene holds the whole map (D-102); others only build worlds.
	if not String(theme.field).is_empty():
		_save_field_scene()

func _build_ground_material() -> ShaderMaterial:
	var noise := FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = 0.012
	noise.fractal_octaves = 3
	var noise_texture := NoiseTexture2D.new()
	noise_texture.noise = noise
	noise_texture.seamless = true
	noise_texture.width = 256
	noise_texture.height = 256
	var material := ShaderMaterial.new()
	material.shader = load("res://scripts/world/meadow_ground.gdshader")
	material.set_shader_parameter("grass_texture", load(theme.floor))
	material.set_shader_parameter("dirt_texture", load(theme.path))
	for parameter in theme.shader:
		material.set_shader_parameter(parameter, theme.shader[parameter])
	material.set_shader_parameter("mask_texture", load(MASK_PATH))
	material.set_shader_parameter("noise_texture", noise_texture)
	# The ground shader works in world space: bake in where this world sits (D-102).
	var offset: Vector3 = theme.get("offset", Vector3.ZERO)
	material.set_shader_parameter("mask_origin", MASK_ORIGIN + Vector2(offset.x, offset.z))
	material.set_shader_parameter("mask_size", MASK_SIZE)
	ResourceSaver.save(material, MATERIAL_PATH)
	_strip_null_parameters(MATERIAL_PATH)
	return load(MATERIAL_PATH)

## Removes "= null" parameter lines Godot writes for untouched uniforms, so the
## shader's own defaults apply when the material loads.
func _strip_null_parameters(path: String) -> void:
	var absolute := ProjectSettings.globalize_path(path)
	var lines := FileAccess.get_file_as_string(absolute).split("\n")
	var kept := PackedStringArray()
	for line in lines:
		if not line.ends_with(" = null"):
			kept.append(line)
	var file := FileAccess.open(absolute, FileAccess.WRITE)
	file.store_string("\n".join(kept))
	file.close()

func _all_lowland_groups() -> Array:
	var groups := [Layout.VILLAGE, Layout.FOREST, Layout.FARM, Layout.POND_PROPS]
	for key in Layout.OUTER_GROUPS:
		groups.append(Layout.OUTER_GROUPS[key])
	return groups

func _collect_clearings() -> void:
	for group in _all_lowland_groups() + [Layout.TERRACE_PROPS]:
		for entry in group:
			if String(entry[0]).begins_with("butcher/"):
				clearings.append(Vector3(entry[1], entry[2], clampf(entry[3] * 0.55, 2.0, 8.0)))
	for field in Layout.FIELDS:
		clearings.append(Vector3(field[0], field[1], field[3].x * 0.6))
	for bridge in bridges:
		clearings.append(Vector3(bridge[0].x, bridge[0].y, bridge[1] * 0.6))
	for spot in Layout.TRAINING_DUMMIES:
		clearings.append(Vector3(spot.x, spot.z, 2.5))

func _add_lighting() -> void:
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = theme.background
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = theme.ambient
	environment.ambient_light_energy = theme.ambient_energy
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.tonemap_exposure = 1.05
	environment.adjustment_enabled = true
	environment.adjustment_saturation = theme.saturation
	environment.adjustment_contrast = 1.05
	var world := WorldEnvironment.new()
	world.name = "Environment"
	world.environment = environment
	_add(root_node, world)
	var sun := DirectionalLight3D.new()
	sun.name = "Sun"
	sun.rotation_degrees = Vector3(-52, -35, 0)
	sun.light_color = theme.sun
	sun.light_energy = theme.sun_energy
	sun.shadow_enabled = false
	_add(root_node, sun)
	var fill := DirectionalLight3D.new()
	fill.name = "SkyFill"
	fill.rotation_degrees = Vector3(-35, 145, 0)
	fill.light_color = theme.fill
	fill.light_energy = theme.fill_energy
	fill.shadow_enabled = false
	_add(root_node, fill)

func _add_ground_and_terrain() -> void:
	var ground := _scripted(MeadowGround, "Ground", root_node)
	ground.half_size = Layout.WORLD_HALF
	ground.extents = Rect2(-Layout.WORLD_HALF, _outer_z(-1.0), Layout.WORLD_HALF * 2.0, _outer_z(1.0) - _outer_z(-1.0))
	ground.material = ground_material
	var terrain := _group("Terrain")
	for plateau in Layout.PLATEAUS:
		var block := _block(terrain, plateau.name, PackedVector2Array(plateau.outline), plateau.height, plateau.seed)
		var openings := PackedVector3Array()
		for index in plateau.ramps.size():
			var spec: Dictionary = plateau.ramps[index]
			openings.append(Vector3(spec.top.x, spec.top.y, spec.width * 0.6))
			var ramp := _scripted(TerrainRamp, "%sRamp%d" % [plateau.name, index], terrain)
			ramp.bottom = spec.bottom
			ramp.top = spec.top
			ramp.width = spec.width
			ramp.base_height = plateau.base
			ramp.rise = plateau.height - plateau.base
			ramp.top_material = ground_material
		block.openings = openings
	for border in _border_outlines():
		_block(terrain, border[0], border[1], _border_height(border[0]), border[2])
	for index in Layout.OUTCROPS.size():
		var rock: Vector4 = Layout.OUTCROPS[index]
		_block(terrain, "Outcrop%d" % index, _round_outline(Vector2(rock.x, rock.y), rock.z, 100 + index), rock.w, 30 + index)
		occupied.append(Vector3(rock.x, rock.y, rock.z * 1.15))
	var island: Vector4 = Layout.ISLAND
	_block(terrain, "Island", _round_outline(Vector2(island.x, island.y), island.z, 77), island.w, 77)

func _block(parent: Node3D, block_name: String, outline: PackedVector2Array, height: float, seed: int) -> Node3D:
	var block := _scripted(TerrainBlock, block_name, parent)
	block.outline = outline
	block.height = height
	block.seed = seed
	block.top_material = ground_material
	return block

func _border_height(border_name: String) -> float:
	return Layout.NEAR_BORDER_HEIGHT if _is_low_side(border_name) else Layout.BORDER_HEIGHT

## South and east borders stay low so they never hide Kaze; so does a linked
## north border, which the camera looks over from the next region (D-102).
func _is_low_side(part_name: String) -> bool:
	var side := part_name.trim_prefix("Border").trim_prefix("Forest")
	if side.begins_with("South") or side.begins_with("East"):
		return true
	return side.begins_with("North") and _link().get("side", "") == "north"

## Cliff borders with wavy inner edges, split where water leaves the map.
func _border_outlines() -> Array:
	var w: float = Layout.WORLD_HALF
	var inner: float = Layout.PLAY_HALF + 4.0
	var north: Vector2 = Layout.NORTH_NOTCH
	var east: Vector2 = Layout.EAST_NOTCH
	# A linked side (D-102) is a short band ending at the neighbour's band.
	var zn := _outer_z(-1.0)
	var zs := _outer_z(1.0)
	var sides := []
	# North: split by the stream notch, and by the gateway when linked north.
	var north_spans := [[-w, north.x], [north.y, w]]
	var south_spans := [[-w, w]]
	var link := _link()
	if not link.is_empty():
		var gap := Vector2(link.gate_x - link.gate_half, link.gate_x + link.gate_half)
		if link.side == "north":
			north_spans = _cut_spans(north_spans, gap)
		else:
			south_spans = _cut_spans(south_spans, gap)
	for index in north_spans.size():
		var span: Array = north_spans[index]
		sides.append(["BorderNorth%d" % index, _side(Vector2(span[0], zn), Vector2(span[1], zn), Vector2(span[1], -inner), Vector2(span[0], -inner), 1 + index * 7)])
	for index in south_spans.size():
		var span: Array = south_spans[index]
		sides.append(["BorderSouth%d" % index, _side(Vector2(span[1], zs), Vector2(span[0], zs), Vector2(span[0], inner), Vector2(span[1], inner), 5 + index * 7)])
	# The lake drains through the east border, or the west one in a
	# mirrored layout (D-100: Frostlands sets WATER_EXIT_WEST).
	if _water_exits_west():
		sides.append(["BorderEast", _side(Vector2(w, zn), Vector2(w, zs), Vector2(inner, zs), Vector2(inner, zn), 3)])
		sides.append(["BorderWestNorth", _side(Vector2(-w, east.x), Vector2(-w, zn), Vector2(-inner, zn), Vector2(-inner, east.x), 4)])
		sides.append(["BorderWestSouth", _side(Vector2(-w, zs), Vector2(-w, east.y), Vector2(-inner, east.y), Vector2(-inner, zs), 8)])
	else:
		sides.append(["BorderEastNorth", _side(Vector2(w, zn), Vector2(w, east.x), Vector2(inner, east.x), Vector2(inner, zn), 3)])
		sides.append(["BorderEastSouth", _side(Vector2(w, east.y), Vector2(w, zs), Vector2(inner, zs), Vector2(inner, east.y), 8)])
		sides.append(["BorderWest", _side(Vector2(-w, zs), Vector2(-w, zn), Vector2(-inner, zn), Vector2(-inner, zs), 4)])
	return sides.map(func(entry): return [entry[0], entry[1], 40 + entry[0].length()])

## Removes the gap (x from, x to) from a list of [from, to] spans.
func _cut_spans(spans: Array, gap: Vector2) -> Array:
	var result := []
	for span in spans:
		if gap.y <= span[0] or gap.x >= span[1]:
			result.append(span)
			continue
		if gap.x > span[0]:
			result.append([span[0], gap.x])
		if gap.y < span[1]:
			result.append([gap.y, span[1]])
	return result

## Keeps the gateway corridor clear of cliff-base shrubs (D-102).
func _gateway_holes() -> Array[PackedVector2Array]:
	var result: Array[PackedVector2Array] = []
	var link := _link()
	if link.is_empty():
		return result
	var x0: float = link.gate_x - link.gate_half - 2.0
	var x1: float = link.gate_x + link.gate_half + 2.0
	var z := float(link.outer) + 2.0
	var z_in: float = Layout.PLAY_HALF - 12.0
	if link.side == "north":
		result.append(PackedVector2Array([Vector2(x0, -z), Vector2(x1, -z), Vector2(x1, -z_in), Vector2(x0, -z_in)]))
	else:
		result.append(PackedVector2Array([Vector2(x0, z_in), Vector2(x1, z_in), Vector2(x1, z), Vector2(x0, z)]))
	return result

## Gateway to the neighbouring region, or {} (D-102).
func _link() -> Dictionary:
	return Layout.get_script_constant_map().get("LINK", {})

## How far the border reaches north (-1) or south (+1): WORLD_HALF, or the
## linked side's short band.
func _outer_z(direction: float) -> float:
	var link := _link()
	if not link.is_empty() and ((link.side == "north" and direction < 0.0) or (link.side == "south" and direction > 0.0)):
		return direction * float(link.outer)
	return direction * Layout.WORLD_HALF

func _water_exits_west() -> bool:
	return Layout.get_script_constant_map().get("WATER_EXIT_WEST", false)

## Outline from two outer corners, then a wavy inner edge between c and d.
func _side(a: Vector2, b: Vector2, c: Vector2, d: Vector2, seed: int) -> PackedVector2Array:
	var random := RandomNumberGenerator.new()
	random.seed = seed * 131
	var points := PackedVector2Array([a, b])
	var steps := maxi(2, int(c.distance_to(d) / 9.0))
	var across := (d - c).normalized().orthogonal()
	for step in steps + 1:
		var t := float(step) / steps
		var wobble := 0.0 if step == 0 or step == steps else random.randf_range(-3.5, 3.5)
		points.append(c.lerp(d, t) + across * wobble)
	return points

func _round_outline(center: Vector2, radius: float, seed: int) -> PackedVector2Array:
	var random := RandomNumberGenerator.new()
	random.seed = seed
	var points := PackedVector2Array()
	for index in 9:
		var angle := index * TAU / 9.0
		points.append(center + Vector2(cos(angle), sin(angle)) * radius * random.randf_range(0.75, 1.15))
	return points

func _add_water() -> void:
	var water := _group("Water")
	var gaps := PackedVector2Array()
	for bridge in bridges:
		gaps.append(bridge[0])
	var names := ["StreamBarrier", "OutflowBarrier", "LakeOutflowBarrier"]
	var lines := _water_lines()
	for index in lines.size():
		_barrier(water, names[index], lines[index][0], lines[index][1] - 1.3, gaps, false)
	_barrier(water, "PondBarrier", _pool_outline(Layout.POND), 1.5, PackedVector2Array(), true)
	_barrier(water, "LakeBarrier", _pool_outline(Layout.LAKE), 1.5, PackedVector2Array(), true)
	for index in bridges.size():
		var spec: Array = bridges[index]
		var bridge := _scripted(WoodenBridge, "Bridge%d" % index, water)
		bridge.length = spec[1]
		bridge.width = spec[2]
		bridge.position = Vector3(spec[0].x, 0, spec[0].y)
		bridge.rotation.y = spec[3]

func _barrier(parent: Node3D, barrier_name: String, points: Array, half_width: float, gaps: PackedVector2Array, closed: bool) -> void:
	var barrier := _scripted(WaterBarrier, barrier_name, parent)
	barrier.polyline = PackedVector2Array(points)
	barrier.half_width = half_width
	barrier.gaps = gaps
	barrier.gap_radius = 4.2
	barrier.closed = closed

## Ring just inside the union of a pool's circles.
func _pool_outline(pools: Array) -> PackedVector2Array:
	var center := Vector2(pools[0].x, pools[0].y)
	var points := PackedVector2Array()
	for index in 28:
		var direction := Vector2.from_angle(index * TAU / 28.0)
		var reach := 0.0
		for distance in range(1, 60):
			var point := center + direction * distance
			for pool in pools:
				if point.distance_to(Vector2(pool.x, pool.y)) < pool.z:
					reach = distance
		points.append(center + direction * maxf(reach - 2.5, 2.0))
	return points

func _add_props() -> void:
	_place_group("Village", Layout.VILLAGE, 0.0)
	_place_group("TerraceShrine", Layout.TERRACE_PROPS, Layout.TERRACE_HEIGHT)
	_place_group("WoodcutterForest", Layout.FOREST, 0.0)
	_place_group("Farm", Layout.FARM, 0.0)
	_place_group("PondAndStream", Layout.POND_PROPS, 0.0)
	for key in Layout.OUTER_GROUPS:
		_place_group(key, Layout.OUTER_GROUPS[key], 0.0)
	for key in Layout.RAISED_GROUPS:
		_place_group(key, Layout.RAISED_GROUPS[key][1], Layout.RAISED_GROUPS[key][0])
	var fields := _group("Fields")
	for index in Layout.FIELDS.size():
		var spec: Array = Layout.FIELDS[index]
		var field := _scripted(CropField, "CropField%d" % index, fields)
		field.size = spec[3]
		field.seed = 5 + index
		field.position = Vector3(spec[0], 0, spec[1])
		field.rotation.y = spec[2]
	_add_fences()
	_add_orchard()
	for plateau in Layout.PLATEAUS:
		_add_cliff_skirt(plateau)
	_add_reeds()
	_add_training_yard()
	_add_groves()

func _add_training_yard() -> void:
	var yard := _group("TrainingYard")
	for index in Layout.TRAINING_DUMMIES.size():
		var spot: Vector3 = Layout.TRAINING_DUMMIES[index]
		var dummy := _scripted(TrainingDummy, "TrainingDummy%d" % index, yard)
		dummy.position = Vector3(spot.x, 0, spot.z)
		dummy.rotation.y = 0.7 + index * 0.4
		occupied.append(Vector3(spot.x, spot.z, 2.5))

func _add_reeds() -> void:
	var reeds := _group("Reeds")
	var random := RandomNumberGenerator.new()
	random.seed = 77
	for spot in Layout.REED_SPOTS:
		for copy in 3:
			var offset := Vector2(random.randf_range(-2.5, 2.5), random.randf_range(-2.5, 2.5))
			_prop(reeds, ["stylized/reeds", spot.x + offset.x, spot.y + offset.y, random.randf_range(1.4, 2.2), random.randf() * TAU, "none"], 0.0)

func _add_fences() -> void:
	var fences := _group("Fences")
	for run in Layout.FENCES:
		_fence_run(fences, run[0], run[1])
	for index in Layout.FIELDS.size():
		var spec: Array = Layout.FIELDS[index]
		var basis := Basis(Vector3.UP, spec[2])
		var half: Vector2 = spec[3] / 2.0 + Vector2(1.5, 1.5)
		for side in [-1.0, 1.0]:
			var a := basis * Vector3(-half.x, 0, side * half.y)
			var b := basis * Vector3(half.x, 0, side * half.y)
			_fence_run(fences, Vector2(spec[0] + a.x, spec[1] + a.z), Vector2(spec[0] + b.x, spec[1] + b.z))

## Upright plank fence segments (about 3.7 units each) between two points.
func _fence_run(parent: Node3D, from: Vector2, to: Vector2) -> void:
	var segments := maxi(1, roundi(from.distance_to(to) / 3.7))
	var direction := to - from
	for index in segments:
		var middle := from.lerp(to, (index + 0.5) / segments)
		var yaw := atan2(-direction.y, direction.x)
		_prop(parent, ["butcher/camp-fence", middle.x, middle.y, 2.0, yaw, "box"], 0.0)

func _add_orchard() -> void:
	var orchard := _group("Orchard")
	var origin: Vector2 = Layout.ORCHARD[0]
	var spacing: float = Layout.ORCHARD[3]
	var random := RandomNumberGenerator.new()
	random.seed = 66
	for row in Layout.ORCHARD[1]:
		for column in Layout.ORCHARD[2]:
			var point := origin + Vector2(column, row) * spacing + Vector2(random.randf_range(-0.6, 0.6), random.randf_range(-0.6, 0.6))
			_prop(orchard, ["stylized/tree-fruit", point.x, point.y, random.randf_range(7.0, 8.5), random.randf() * TAU], 0.0)

## Boulders and shrubs along the foot of a plateau cliff so it reads as rock.
func _add_cliff_skirt(plateau: Dictionary) -> void:
	var skirt := _group(plateau.name + "Skirt")
	var random := RandomNumberGenerator.new()
	random.seed = 900 + plateau.seed
	var outline: Array = plateau.outline
	for index in outline.size():
		var a: Vector2 = outline[index]
		var b: Vector2 = outline[(index + 1) % outline.size()]
		var outward := (b - a).normalized().orthogonal() * _winding_sign(outline)
		var steps := int(a.distance_to(b) / 5.0)
		for step in steps:
			var point := a.lerp(b, (step + random.randf()) / maxf(steps, 1)) + outward * random.randf_range(2.0, 4.5)
			if absf(point.x) > Layout.PLAY_HALF or absf(point.y) > Layout.PLAY_HALF:
				continue
			if _near_ramp(point, 9.0) or _surface_at(point) != plateau.base or _on_mask(point):
				continue
			var kind: String = ["stylized/boulder", "stylized/bush", "stylized/rock"][random.randi_range(0, 2)]
			var size := random.randf_range(1.4, 2.6) if kind != "stylized/rock" else random.randf_range(0.8, 1.4)
			_prop(skirt, [kind, point.x, point.y, size, random.randf() * TAU, "solid" if kind == "stylized/boulder" else "none"], plateau.base)

## +1 when the outline is counter-clockwise (x, z as x, y), so orthogonal() points outward.
func _winding_sign(outline: Array) -> float:
	var area := 0.0
	for index in outline.size():
		var a: Vector2 = outline[index]
		var b: Vector2 = outline[(index + 1) % outline.size()]
		area += a.x * b.y - b.x * a.y
	return 1.0 if area > 0.0 else -1.0

func _near_ramp(point: Vector2, distance: float) -> bool:
	for plateau in Layout.PLATEAUS:
		for spec in plateau.ramps:
			if Geometry2D.get_closest_point_to_segment(point, spec.bottom, spec.top).distance_to(point) < distance:
				return true
	return false

## Height of the walkable surface at a point (highest plateau containing it).
func _surface_at(point: Vector2) -> float:
	var height := 0.0
	for plateau in Layout.PLATEAUS:
		if Geometry2D.is_point_in_polygon(point, PackedVector2Array(plateau.outline)):
			height = maxf(height, plateau.height)
	return height

## True on painted paths or water.
func _on_mask(point: Vector2, path_limit := 0.25, water_limit := 0.2) -> bool:
	var pixel := Vector2i(((point - MASK_ORIGIN) / MASK_SIZE * MASK_PIXELS).floor())
	if pixel.x < 0 or pixel.y < 0 or pixel.x >= MASK_PIXELS or pixel.y >= MASK_PIXELS:
		return false
	var value := mask_image.get_pixelv(pixel)
	return value.r > path_limit or value.g > water_limit

func _distance_to_plateau_edge(point: Vector2) -> float:
	var best := INF
	for plateau in Layout.PLATEAUS:
		var outline: Array = plateau.outline
		for index in outline.size():
			best = minf(best, Geometry2D.get_closest_point_to_segment(point, outline[index], outline[(index + 1) % outline.size()]).distance_to(point))
	return best

## Generated woods: spaced trees with trunk colliders that avoid paths, water,
## props, ramps and cliff edges, so they never form traps.
func _add_groves() -> void:
	var kinds := ["stylized/tree-round", "stylized/tree-pine", "stylized/tree-tall", "stylized/tree-round", "stylized/tree-pine", "stylized/bush"]
	for grove in Layout.GROVES:
		var group := _group(grove[0])
		var polygon := PackedVector2Array(grove[1])
		var base: float = grove[3]
		var random := RandomNumberGenerator.new()
		random.seed = grove[4]
		var bounds := Rect2(polygon[0], Vector2.ZERO)
		for point in polygon:
			bounds = bounds.expand(point)
		var placed := 0
		var attempts := 0
		while placed < grove[2] and attempts < grove[2] * 40:
			attempts += 1
			var point := Vector2(random.randf_range(bounds.position.x, bounds.end.x), random.randf_range(bounds.position.y, bounds.end.y))
			if not _tree_spot_ok(point, polygon, base):
				continue
			var kind: String = kinds[random.randi_range(0, kinds.size() - 1)]
			if grove[0] == "PineForest" and random.randf() < 0.6:
				kind = "stylized/tree-pine"
			var height := random.randf_range(1.6, 2.4) if kind == "stylized/bush" else random.randf_range(8.5, 12.5)
			_prop(group, [kind, point.x, point.y, height, random.randf() * TAU, "none" if kind == "stylized/bush" else "trunk"], base)
			placed += 1

func _tree_spot_ok(point: Vector2, polygon: PackedVector2Array, base: float) -> bool:
	if absf(point.x) > Layout.PLAY_HALF - 3.0 or absf(point.y) > Layout.PLAY_HALF - 3.0:
		return false
	if not Geometry2D.is_point_in_polygon(point, polygon) or _surface_at(point) != base:
		return false
	if _on_mask(point, 0.12, 0.12) or _near_ramp(point, 8.0) or _distance_to_plateau_edge(point) < 5.0:
		return false
	for spot in occupied:
		if point.distance_to(Vector2(spot.x, spot.y)) < spot.z + 3.5:
			return false
	for clearing in clearings:
		if point.distance_to(Vector2(clearing.x, clearing.y)) < clearing.z:
			return false
	return true

func _place_group(group_name: String, entries: Array, height: float) -> void:
	var group := _group(group_name)
	for entry in entries:
		_prop(group, entry, height)

## Fight clearings (D-079): every dirt clearing except the village square has a
## soldier (scripts/enemies/enemy_roster.gd); props and bushes stay out of its
## inner part so the arena is clean. Statues ringing the rim stay.
const ARENA_CLEAR := 0.75

func _in_arena(point: Vector2) -> bool:
	for index in range(1, Layout.PLAZAS.size()):
		var plaza: Vector3 = Layout.PLAZAS[index]
		if point.distance_to(Vector2(plaza.x, plaza.y)) < plaza.z * ARENA_CLEAR:
			return true
	return false

## Circles around the fight clearings, as scatter holes for bushes and rocks.
func _arena_holes() -> Array[PackedVector2Array]:
	var result: Array[PackedVector2Array] = []
	for index in range(1, Layout.PLAZAS.size()):
		var plaza: Vector3 = Layout.PLAZAS[index]
		var circle := PackedVector2Array()
		for step in 16:
			var angle := TAU * step / 16.0
			circle.append(Vector2(plaza.x, plaza.y) + Vector2(cos(angle), sin(angle)) * plaza.z * 0.95)
		result.append(circle)
	return result

func _prop(parent: Node3D, entry: Array, base_height: float) -> void:
	var asset: String = entry[0]
	if _in_arena(Vector2(entry[1], entry[2])):
		print("Arena kept clear: skipped %s at (%s, %s)" % [asset, entry[1], entry[2]])
		return
	var prop := _scripted(FieldProp, asset.get_file(), parent)
	prop.asset = asset
	prop.height = entry[3]
	prop.position = Vector3(entry[1], base_height, entry[2])
	prop.rotation.y = entry[4]
	prop.collision = _collision_for(asset, entry)
	if prop.collision != FieldProp.Collision.NONE:
		occupied.append(Vector3(entry[1], entry[2], clampf(entry[3] * 0.45, 1.5, 7.0)))
		_warn_if_on_path(asset, Vector2(entry[1], entry[2]), base_height)
	if entry.size() > 6:
		prop.tint = entry[6]
	if asset.contains("tree"):
		prop.variant = absi(int(entry[1] * 7 + entry[2] * 3)) % 3
		prop.shadow_scale = 0.75
	if asset.contains("reeds"):
		prop.shadow_scale = 0.0

## Solid props on a dirt path at the same height would block the route; report them while building.
func _warn_if_on_path(asset: String, point: Vector2, base_height: float) -> void:
	for path in Layout.PATHS:
		var points: Array = path[1]
		for index in points.size() - 1:
			var closest := Geometry2D.get_closest_point_to_segment(point, points[index], points[index + 1])
			if closest.distance_to(point) < path[0] + 1.5 and absf(_surface_at(closest) - base_height) < 0.5:
				push_warning("Solid prop %s at %s blocks a path" % [asset, point])
				return

func _collision_for(asset: String, entry: Array) -> int:
	if entry.size() > 5:
		return {"solid": FieldProp.Collision.SOLID, "trunk": FieldProp.Collision.TRUNK, "box": FieldProp.Collision.BOX, "none": FieldProp.Collision.NONE}[entry[5]]
	return FieldProp.Collision.TRUNK if asset.contains("tree") else FieldProp.Collision.SOLID

## Mesh variants are kept low (one per kind for most scatter) because each
## variant is a separate draw call per tile on phones (D-074).
func _add_scatter() -> void:
	var scatter := _group("Scatter")
	var half: float = Layout.PLAY_HALF + 2.0
	var play := PackedVector2Array([Vector2(-half, -half), Vector2(half, -half), Vector2(half, half), Vector2(-half, half)])
	var lowland_holes := _plateau_outlines(0.0)
	_tiled(scatter, "Grass", play, lowland_holes, ["grass"], 1, 108.0, Vector2(0.9, 1.6), 0.0, 1, 0.0)
	_tiled(scatter, "Flowers", play, lowland_holes, ["flower"], 2, 22.0, Vector2(0.8, 1.3), 0.0, 2, 0.0)
	var arenas := _arena_holes()
	var shrub_holes: Array[PackedVector2Array] = lowland_holes + arenas
	_tiled(scatter, "Shrubs", play, shrub_holes, ["bush", "rock", "bush"], 1, 3.7, Vector2(0.9, 1.6), 0.0, 3, 1.0)
	for index in Layout.FLOWER_MEADOWS.size():
		_tiled(scatter, "FlowerMeadow%d" % index, PackedVector2Array(Layout.FLOWER_MEADOWS[index]), lowland_holes, ["flower"], 2, 45.0, Vector2(0.9, 1.4), 0.0, 20 + index, 0.0)
	for plateau in Layout.PLATEAUS:
		var outline := PackedVector2Array(plateau.outline)
		var holes := _plateau_outlines(plateau.height)
		_tiled(scatter, plateau.name + "Grass", outline, holes, ["grass", "flower"], 1, 90.0, Vector2(0.9, 1.5), plateau.height, 4 + plateau.seed, 0.0)
		var plateau_shrub_holes: Array[PackedVector2Array] = holes + arenas
		_tiled(scatter, plateau.name + "Shrubs", outline, plateau_shrub_holes, ["bush", "rock"], 1, 4.0, Vector2(0.9, 1.5), plateau.height, 5 + plateau.seed, 1.0)
	for strip in _cliff_base_strips():
		_tiled(scatter, strip[0], strip[1], shrub_holes, ["bush", "rock", "boulder", "grass", "bush"], 1, 58.0, Vector2(0.9, 2.0), 0.0, strip[2], 1.2)
	for chunk in _border_forest_chunks():
		var near_side: bool = _is_low_side(chunk[0])
		var kinds: Array = ["bush", "boulder", "bush", "grass"] if near_side else ["tree-round", "tree-pine", "tree-tall", "tree-round", "bush"]
		var height: float = Layout.NEAR_BORDER_HEIGHT if near_side else Layout.BORDER_HEIGHT
		var forest := _scatter(scatter, chunk[0], chunk[1], kinds, 1, 140 if near_side else 90, Vector2(1.0, 2.2) if near_side else Vector2(1.0, 1.5), height, chunk[2], 1.6 if near_side else 2.3)
		forest.avoid_paths = false
		forest.clearings = _notch_clearings()

## Outlines of plateaus standing directly on the given height.
func _plateau_outlines(base: float) -> Array[PackedVector2Array]:
	var result: Array[PackedVector2Array] = []
	for plateau in Layout.PLATEAUS:
		if plateau.base == base:
			result.append(PackedVector2Array(plateau.outline))
	return result

## Splits a scatter into map tiles (so off-screen tiles are culled), sized by
## density per 1000 square units of each tile's share of the area.
func _tiled(parent: Node3D, scatter_name: String, area: PackedVector2Array, holes: Array[PackedVector2Array], kinds: Array, variants: int, density: float, scale_range: Vector2, height: float, seed: int, shadow: float) -> void:
	var half: float = Layout.PLAY_HALF + 2.0
	var tile_index := 0
	var y := -half
	while y < half:
		var x := -half
		while x < half:
			var tile := PackedVector2Array([Vector2(x, y), Vector2(x + SCATTER_TILE, y), Vector2(x + SCATTER_TILE, y + SCATTER_TILE), Vector2(x, y + SCATTER_TILE)])
			for piece in Geometry2D.intersect_polygons(tile, area):
				var count := int(_polygon_area(piece) * density / 1000.0)
				if count < 1:
					continue
				var node := _scatter(parent, "%s%d" % [scatter_name, tile_index], piece, kinds, variants, count, scale_range, height, seed * 97 + tile_index, shadow)
				node.holes = _holes_near(holes, piece)
				tile_index += 1
			x += SCATTER_TILE
		y += SCATTER_TILE

## Only the holes overlapping a tile's bounds, to keep the saved scene small.
func _holes_near(holes: Array[PackedVector2Array], piece: PackedVector2Array) -> Array[PackedVector2Array]:
	var bounds := Rect2(piece[0], Vector2.ZERO)
	for point in piece:
		bounds = bounds.expand(point)
	var result: Array[PackedVector2Array] = []
	for hole in holes:
		var hole_bounds := Rect2(hole[0], Vector2.ZERO)
		for point in hole:
			hole_bounds = hole_bounds.expand(point)
		if bounds.intersects(hole_bounds):
			result.append(hole)
	return result

func _polygon_area(polygon: PackedVector2Array) -> float:
	var area := 0.0
	for index in polygon.size():
		var a := polygon[index]
		var b := polygon[(index + 1) % polygon.size()]
		area += a.x * b.y - b.x * a.y
	return absf(area) * 0.5

func _scatter(parent: Node3D, scatter_name: String, area: PackedVector2Array, kinds: Array, variants: int, count: int, scale_range: Vector2, height: float, seed: int, shadow: float) -> Node3D:
	var scatter := _scripted(GroundScatter, scatter_name, parent)
	scatter.area = area
	var typed: Array[String] = []
	for kind in kinds:
		typed.append(kind)
	scatter.kinds = typed
	scatter.variants = variants
	scatter.count = count
	scatter.scale_range = scale_range
	scatter.surface_height = height
	scatter.seed = seed
	scatter.shadow_radius = shadow
	scatter.clearings = clearings if height == 0.0 else PackedVector3Array()
	scatter.mask = load(MASK_PATH)
	scatter.mask_origin = MASK_ORIGIN
	scatter.mask_size = MASK_SIZE
	return scatter

func _cliff_base_strips() -> Array:
	var p: float = Layout.PLAY_HALF + 4.0
	var depth := 9.0
	var strips := [
		["CliffBaseNorth", PackedVector2Array([Vector2(-30, -p), Vector2(p, -p), Vector2(p, -p + depth), Vector2(-30, -p + depth)]), 61],
		["CliffBaseEast", PackedVector2Array([Vector2(p - depth, -p), Vector2(p, -p), Vector2(p, p), Vector2(p - depth, p)]), 62],
		["CliffBaseSouth", PackedVector2Array([Vector2(-p, p - depth), Vector2(p, p - depth), Vector2(p, p), Vector2(-p, p)]), 63],
		["CliffBaseWest", PackedVector2Array([Vector2(-p, -6), Vector2(-p + depth, -6), Vector2(-p + depth, p), Vector2(-p, p)]), 64],
	]
	if not _water_exits_west():
		return strips
	# Mirrored layout (D-100): mirror the strips too.
	for strip in strips:
		var mirrored := PackedVector2Array()
		for point: Vector2 in strip[1]:
			mirrored.insert(0, Vector2(-point.x, point.y))
		strip[1] = mirrored
	return strips

## Keeps cliff-top trees out of the gaps cut where water leaves the map.
func _notch_clearings() -> PackedVector3Array:
	var result := PackedVector3Array()
	var north_x: float = (Layout.NORTH_NOTCH.x + Layout.NORTH_NOTCH.y) / 2.0
	var north_r: float = (Layout.NORTH_NOTCH.y - Layout.NORTH_NOTCH.x) / 2.0 + 3.0
	var east_z: float = (Layout.EAST_NOTCH.x + Layout.EAST_NOTCH.y) / 2.0
	var east_r: float = (Layout.EAST_NOTCH.y - Layout.EAST_NOTCH.x) / 2.0 + 3.0
	var east_sign := -1.0 if _water_exits_west() else 1.0
	for depth in range(int(Layout.PLAY_HALF), int(Layout.WORLD_HALF), 6):
		result.append(Vector3(north_x, -depth, north_r))
		result.append(Vector3(depth * east_sign, east_z, east_r))
	# Gateway corridor (D-102).
	var link := _link()
	if not link.is_empty():
		var side := -1.0 if link.side == "north" else 1.0
		for depth in range(int(Layout.PLAY_HALF) - 6, int(link.outer) + 4, 4):
			result.append(Vector3(link.gate_x, depth * side, link.gate_half + 2.0))
	return result

## Forest on top of the border cliffs, split into chunks so off-screen parts are culled.
func _border_forest_chunks() -> Array:
	var chunks := []
	var near: float = Layout.PLAY_HALF + 9.0
	var far: float = Layout.PLAY_HALF + 44.0
	var seed := 200
	for start in range(-int(far), int(far), 44):
		var end := start + 44.0
		chunks.append(["ForestNorth%d" % seed, PackedVector2Array([Vector2(start, -far), Vector2(end, -far), Vector2(end, -near), Vector2(start, -near)]), seed])
		chunks.append(["ForestSouth%d" % seed, PackedVector2Array([Vector2(start, near), Vector2(end, near), Vector2(end, far), Vector2(start, far)]), seed + 1])
		if start > -near and end < near + 44.0:
			chunks.append(["ForestEast%d" % seed, PackedVector2Array([Vector2(near, start), Vector2(far, start), Vector2(far, end), Vector2(near, end)]), seed + 2])
			chunks.append(["ForestWest%d" % seed, PackedVector2Array([Vector2(-far, start), Vector2(-near, start), Vector2(-near, end), Vector2(-far, end)]), seed + 3])
		seed += 4
	# Linked side (D-102): keep the trees on this region's short band.
	var top := _outer_z(-1.0)
	var bottom := _outer_z(1.0)
	var clipped := []
	for chunk in chunks:
		var outline := PackedVector2Array()
		for point: Vector2 in chunk[1]:
			outline.append(Vector2(point.x, clampf(point.y, top, bottom)))
		if absf(outline[2].y - outline[0].y) > 2.0 or absf(outline[1].y - outline[3].y) > 2.0:
			clipped.append([chunk[0], outline, chunk[2]])
	return clipped

# --- Scene helpers -----------------------------------------------------------

func _group(group_name: String) -> Node3D:
	var group := Node3D.new()
	group.name = group_name
	_add(root_node, group)
	return group

func _scripted(script: Script, node_name: String, parent: Node) -> Node3D:
	var node := Node3D.new()
	node.set_script(script)
	node.name = node_name
	_add(parent, node)
	return node

func _add(parent: Node, child: Node) -> void:
	parent.add_child(child, true)
	child.owner = root_node

func _save(node: Node, path: String) -> void:
	var packed := PackedScene.new()
	var error := packed.pack(node)
	if error == OK:
		error = ResourceSaver.save(packed, path)
	print("Saved " if error == OK else "FAILED to save ", path)

func _save_field_scene() -> void:
	var field := Node3D.new()
	field.name = theme.field_name
	field.set_script(MainScript)
	field.region = theme.region
	field.palette = theme.palette
	field.world_scene = load(WORLD_PATH)
	field.spawn_position = Layout.SPAWN
	field.play_half_extent = Layout.PLAY_HALF
	_save(field, FIELD_PATH)
