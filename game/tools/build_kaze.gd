extends SceneTree

## Builds Kaze, an original low-poly ronin hero (D-071), as a rigged scene.
## Chunky, big-headed proportions so he reads well from the field camera:
## Skeleton3D + one skinned, flat-shaded vertex-colored mesh + AnimationPlayer
## with idle, run and combo clips (slash_1..slash_4). Every body part is rigidly bound to one bone.
## Usage: godot --headless --path game --script res://tools/build_kaze.gd
## Output: assets/heroes/kaze/kaze.tscn (overwritten on every run).

const OUTPUT := "res://assets/heroes/kaze/kaze.tscn"

# Palette.
const SKIN := Color("e7bf96")
const INDIGO := Color("2e3b78")
const INDIGO_LIGHT := Color("41539e")
const COAT := Color("e4dcc6")
const COAT_LIGHT := Color("f5f0e3")
const SASH := Color("c9a23a")
const TROUSERS := Color("272a35")
const TROUSERS_LIGHT := Color("3a3f50")
const WRAPS := Color("d8d0bc")
const SANDAL := Color("5a3e2b")
const SCARF := Color("2a8a85")
const SCARF_LIGHT := Color("3fb0a6")
const STRAW := Color("b8924c")
const STRAW_LIGHT := Color("e2c47f")
const HAIR := Color("1c1e26")
const EYE_WHITE := Color("f7f4ec")
const CORD := Color("c8453a")
const STRAW_DARK := Color("8c6a33")
const STEEL := Color("cfd8de")
const STEEL_EDGE := Color("f4f8fa")
const GOLD := Color("d6ad45")
const LACQUER := Color("1b1c24")

# name: [parent, rest position in model space]. The model faces +Z; his right is -X.
const BONES := {
	"root": ["", Vector3(0, 0, 0)],
	"hips": ["root", Vector3(0, 0.72, 0)],
	"spine": ["hips", Vector3(0, 0.82, 0)],
	"chest": ["spine", Vector3(0, 1.0, 0)],
	"neck": ["chest", Vector3(0, 1.22, 0)],
	"head": ["neck", Vector3(0, 1.28, 0)],
	"scarf_tail": ["chest", Vector3(0, 1.2, -0.15)],
	"upper_arm.L": ["chest", Vector3(0.25, 1.16, 0)],
	"forearm.L": ["upper_arm.L", Vector3(0.29, 0.95, 0)],
	"hand.L": ["forearm.L", Vector3(0.31, 0.76, 0.02)],
	"upper_arm.R": ["chest", Vector3(-0.25, 1.16, 0)],
	"forearm.R": ["upper_arm.R", Vector3(-0.29, 0.95, 0)],
	"hand.R": ["forearm.R", Vector3(-0.31, 0.76, 0.02)],
	"sword": ["hand.R", Vector3(-0.31, 0.73, 0.04)],
	"thigh.L": ["hips", Vector3(0.12, 0.7, 0)],
	"shin.L": ["thigh.L", Vector3(0.13, 0.38, 0)],
	"foot.L": ["shin.L", Vector3(0.13, 0.08, 0)],
	"thigh.R": ["hips", Vector3(-0.12, 0.7, 0)],
	"shin.R": ["thigh.R", Vector3(-0.13, 0.38, 0)],
	"foot.R": ["shin.R", Vector3(-0.13, 0.08, 0)],
}

var skeleton: Skeleton3D
var tool: SurfaceTool
var bone_index := {}

func _initialize() -> void:
	var root_node := Node3D.new()
	root_node.name = "Kaze"
	skeleton = Skeleton3D.new()
	skeleton.name = "Skeleton3D"
	root_node.add_child(skeleton)
	skeleton.owner = root_node
	_add_bones()
	var mesh_node := MeshInstance3D.new()
	mesh_node.name = "Body"
	mesh_node.mesh = _build_mesh()
	mesh_node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	skeleton.add_child(mesh_node)
	mesh_node.owner = root_node
	mesh_node.skeleton = NodePath("..")
	mesh_node.skin = skeleton.create_skin_from_rest_transforms()
	var player := AnimationPlayer.new()
	player.name = "AnimationPlayer"
	root_node.add_child(player)
	player.owner = root_node
	var library := AnimationLibrary.new()
	library.add_animation("idle", _idle())
	library.add_animation("run", _run())
	library.add_animation("slash_1", _slash_1())
	library.add_animation("slash_2", _slash_2())
	library.add_animation("slash_3", _slash_3())
	library.add_animation("slash_4", _slash_4())
	player.add_animation_library("", library)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT.get_base_dir()))
	var packed := PackedScene.new()
	packed.pack(root_node)
	var error := ResourceSaver.save(packed, OUTPUT)
	print("Saved " if error == OK else "FAILED ", OUTPUT, " bones=", skeleton.get_bone_count())
	quit()

func _add_bones() -> void:
	for bone_name in BONES:
		var spec: Array = BONES[bone_name]
		var index := skeleton.add_bone(bone_name)
		bone_index[bone_name] = index
		var parent_position := Vector3.ZERO
		if spec[0] != "":
			skeleton.set_bone_parent(index, bone_index[spec[0]])
			parent_position = BONES[spec[0]][1]
		skeleton.set_bone_rest(index, Transform3D(Basis.IDENTITY, spec[1] - parent_position))
	skeleton.reset_bone_poses()

# --- Mesh ----------------------------------------------------------------------

func _build_mesh() -> ArrayMesh:
	tool = SurfaceTool.new()
	tool.set_skin_weight_count(SurfaceTool.SKIN_4_WEIGHTS)
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	_head()
	_torso()
	_arms()
	_legs()
	_sword()
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.roughness = 0.85
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	tool.set_material(material)
	return tool.commit()

func _head() -> void:
	# Big round head for a friendly, readable silhouette.
	_blob("head", Vector3(0, 1.45, 0.01), Vector3(0.19, 0.2, 0.185), SKIN, SKIN.lightened(0.08))
	_blob("head", Vector3(0, 1.5, -0.07), Vector3(0.17, 0.15, 0.14), HAIR, HAIR)
	_blob("head", Vector3(0, 1.4, -0.2), Vector3(0.06, 0.07, 0.06), HAIR, HAIR.lightened(0.1))
	# Cloth mask over the lower face.
	_tube("head", Vector3(0, 1.28, 0.01), Vector2(0.17, 0.165), Vector3(0, 1.44, 0.015), Vector2(0.198, 0.195), 12, SCARF, SCARF_LIGHT)
	# Large expressive eyes with determined brows.
	for side: float in [-1.0, 1.0]:
		_box("head", Vector3(side * 0.075, 1.495, 0.178), Vector3(0.075, 0.06, 0.02), EYE_WHITE, EYE_WHITE)
		_box("head", Vector3(side * 0.07, 1.49, 0.19), Vector3(0.036, 0.046, 0.012), HAIR, HAIR)
		_box("head", Vector3(side * 0.08, 1.505, 0.197), Vector3(0.012, 0.012, 0.006), EYE_WHITE, EYE_WHITE)
		_slanted_box("head", Vector3(side * 0.078, 1.555, 0.18), Vector3(0.085, 0.02, 0.02), side * -0.28, HAIR)
	_hat()

## Detailed straw hat: woven bands, radial ribs, a rolled rim, a crown cap and
## a red chin cord, so it reads well from the high isometric camera.
func _hat() -> void:
	var base := Vector3(0, 1.6, 0)
	var radius := 0.52
	var height := 0.27
	var bands := 5
	for band in bands:
		var t0 := float(band) / bands
		var t1 := float(band + 1) / bands
		var r0 := radius * (1.0 - t0)
		var r1 := radius * (1.0 - t1)
		var y0 := base.y + height * t0
		var y1 := base.y + height * t1
		var color: Color = STRAW if band % 2 == 0 else STRAW_LIGHT
		_tube("head", Vector3(0, y0, 0), Vector2(r0, r0), Vector3(0, y1, 0), Vector2(maxf(r1, 0.005), maxf(r1, 0.005)), 16, color, color.lightened(0.06))
	# Raised radial ribs.
	for rib in 8:
		var angle := rib * TAU / 8.0 + 0.2
		var outward := Vector3(cos(angle), 0, sin(angle))
		var side := Vector3(-sin(angle), 0, cos(angle)) * 0.012
		var rim := base + outward * radius * 0.97 + Vector3(0, 0.012, 0)
		var top := base + outward * radius * 0.12 + Vector3(0, height * 0.88 + 0.012, 0)
		_face("head", rim - side, rim + side, top, STRAW_DARK, base)
		_face("head", rim - side, top, top + Vector3(0, 0.0, 0), STRAW_DARK, base)
	# Rolled rim and darker underside.
	_tube("head", Vector3(0, base.y - 0.03, 0), Vector2(radius + 0.015, radius + 0.015), Vector3(0, base.y + 0.01, 0), Vector2(radius + 0.02, radius + 0.02), 16, STRAW_DARK, STRAW)
	_cone("head", base + Vector3(0, -0.03, 0), radius + 0.01, 0.07, 16, STRAW.darkened(0.4), STRAW.darkened(0.3))
	# Crown cap with a red knot on top.
	_tube("head", Vector3(0, base.y + height - 0.015, 0), Vector2(0.07, 0.07), Vector3(0, base.y + height + 0.03, 0), Vector2(0.05, 0.05), 10, STRAW_DARK, STRAW)
	_blob("head", Vector3(0, base.y + height + 0.05, 0), Vector3(0.035, 0.03, 0.035), CORD, CORD.lightened(0.15))
	# Chin cord hanging from both sides of the brim.
	for side: float in [-1.0, 1.0]:
		_tube("head", Vector3(side * 0.2, 1.31, 0.05), Vector2(0.012, 0.012), Vector3(side * 0.3, 1.6, 0.03), Vector2(0.012, 0.012), 5, CORD, CORD)

func _slanted_box(bone: String, center: Vector3, size: Vector3, roll: float, color: Color) -> void:
	var basis := Basis(Vector3.FORWARD, roll)
	var half := size / 2.0
	var corners := []
	for index in 8:
		corners.append(center + basis * Vector3(half.x * (1 if index & 1 else -1), half.y * (1 if index & 2 else -1), half.z * (1 if index & 4 else -1)))
	for quad in [[0, 1, 3, 2], [4, 6, 7, 5], [0, 4, 5, 1], [2, 3, 7, 6], [0, 2, 6, 4], [1, 5, 7, 3]]:
		_face(bone, corners[quad[0]], corners[quad[1]], corners[quad[2]], color, center)
		_face(bone, corners[quad[0]], corners[quad[2]], corners[quad[3]], color, center)

func _torso() -> void:
	_tube("neck", Vector3(0, 1.18, 0), Vector2(0.17, 0.15), Vector3(0, 1.3, 0), Vector2(0.16, 0.15), 12, SCARF, SCARF_LIGHT)
	_tube("scarf_tail", Vector3(0, 1.22, -0.13), Vector2(0.085, 0.04), Vector3(0.03, 0.96, -0.32), Vector2(0.08, 0.035), 6, SCARF_LIGHT, SCARF)
	_tube("scarf_tail", Vector3(0.03, 0.96, -0.32), Vector2(0.08, 0.035), Vector3(0.07, 0.7, -0.5), Vector2(0.06, 0.025), 6, SCARF, SCARF.darkened(0.1))
	_tube("chest", Vector3(0, 0.86, 0), Vector2(0.2, 0.16), Vector3(0, 1.22, 0), Vector2(0.23, 0.165), 12, INDIGO, INDIGO_LIGHT)
	_tube("chest", Vector3(0, 0.84, -0.005), Vector2(0.222, 0.178), Vector3(0, 1.23, -0.005), Vector2(0.252, 0.185), 14, COAT, COAT_LIGHT, 0.5)
	_tube("spine", Vector3(0, 0.72, 0), Vector2(0.205, 0.165), Vector3(0, 0.9, 0), Vector2(0.205, 0.163), 12, INDIGO, INDIGO_LIGHT)
	_tube("spine", Vector3(0, 0.71, 0), Vector2(0.22, 0.18), Vector3(0, 0.83, 0), Vector2(0.222, 0.182), 14, SASH.darkened(0.1), SASH)
	_box("spine", Vector3(0, 0.77, -0.19), Vector3(0.16, 0.1, 0.05), SASH.darkened(0.15), SASH)
	_box("spine", Vector3(0.05, 0.69, -0.2), Vector3(0.05, 0.12, 0.03), SASH.darkened(0.2), SASH)
	# Coat skirt open at the front, trousers top and the scabbard on his left hip.
	_tube("hips", Vector3(0, 0.36, -0.02), Vector2(0.27, 0.23), Vector3(0, 0.74, -0.005), Vector2(0.23, 0.19), 14, COAT.darkened(0.08), COAT, 0.62)
	_tube("hips", Vector3(0, 0.56, 0), Vector2(0.21, 0.17), Vector3(0, 0.73, 0), Vector2(0.2, 0.16), 12, TROUSERS, TROUSERS_LIGHT)
	_tube("hips", Vector3(0.25, 0.3, -1.0), Vector2(0.045, 0.058), Vector3(0.21, 0.74, 0.18), Vector2(0.05, 0.064), 6, LACQUER, LACQUER.lightened(0.15))
	_blob("hips", Vector3(0.25, 0.3, -1.0), Vector3(0.058, 0.058, 0.058), GOLD, GOLD)
	_blob("hips", Vector3(0.21, 0.74, 0.18), Vector3(0.066, 0.066, 0.03), GOLD, GOLD)

func _arms() -> void:
	for side in ["L", "R"]:
		var x := 1.0 if side == "L" else -1.0
		_tube("upper_arm." + side, Vector3(x * 0.25, 1.2, 0), Vector2(0.095, 0.1), Vector3(x * 0.29, 0.98, 0), Vector2(0.115, 0.115), 9, COAT_LIGHT, COAT)
		_tube("forearm." + side, Vector3(x * 0.29, 0.99, 0), Vector2(0.115, 0.115), Vector3(x * 0.3, 0.84, -0.01), Vector2(0.14, 0.15), 9, COAT, COAT.darkened(0.08))
		_tube("forearm." + side, Vector3(x * 0.29, 0.95, 0), Vector2(0.07, 0.07), Vector3(x * 0.305, 0.78, 0.01), Vector2(0.062, 0.062), 8, INDIGO, INDIGO_LIGHT)
		_tube("forearm." + side, Vector3(x * 0.303, 0.78, 0.01), Vector2(0.066, 0.066), Vector3(x * 0.303, 0.83, 0.01), Vector2(0.068, 0.068), 8, WRAPS, WRAPS)
		_blob("hand." + side, Vector3(x * 0.312, 0.73, 0.025), Vector3(0.062, 0.066, 0.062), SKIN, SKIN.lightened(0.06))

func _legs() -> void:
	for side in ["L", "R"]:
		var x := 1.0 if side == "L" else -1.0
		# Wide pleated trousers flaring to below the knee.
		_tube("thigh." + side, Vector3(x * 0.13, 0.37, 0), Vector2(0.16, 0.15), Vector3(x * 0.115, 0.71, 0), Vector2(0.13, 0.13), 10, TROUSERS, TROUSERS_LIGHT)
		_tube("shin." + side, Vector3(x * 0.135, 0.14, 0), Vector2(0.18, 0.165), Vector3(x * 0.132, 0.39, 0), Vector2(0.158, 0.148), 10, TROUSERS.darkened(0.05), TROUSERS)
		_tube("shin." + side, Vector3(x * 0.13, 0.06, 0.005), Vector2(0.065, 0.065), Vector3(x * 0.13, 0.17, 0), Vector2(0.075, 0.075), 8, WRAPS.darkened(0.08), WRAPS)
		_box("foot." + side, Vector3(x * 0.13, 0.045, 0.045), Vector3(0.11, 0.07, 0.2), TROUSERS, TROUSERS_LIGHT)
		_box("foot." + side, Vector3(x * 0.13, 0.012, 0.05), Vector3(0.125, 0.025, 0.24), SANDAL, SANDAL.lightened(0.1))

## The katana: in the rest pose it points forward and down from the right hand.
func _sword() -> void:
	var grip := Vector3(-0.312, 0.73, 0.025)
	var direction := Vector3(0, -0.5, 0.866)
	# Oversized blade (user request): about 1.25 units, nearly his full height.
	var pommel := grip - direction * 0.16
	var guard := grip + direction * 0.13
	var tip := guard + direction * 1.25 + Vector3(0, 0.09, 0)
	_tube("sword", pommel, Vector2(0.03, 0.03), guard, Vector2(0.033, 0.033), 6, LACQUER, LACQUER.lightened(0.2))
	_blob("sword", pommel, Vector3(0.038, 0.038, 0.038), GOLD, GOLD)
	_disc_between("sword", guard, direction, 0.1, 0.024, GOLD)
	var middle := guard.lerp(tip, 0.5) + Vector3(0, 0.035, 0)
	_blade("sword", guard + direction * 0.014, middle, tip)

# --- Primitive builders (every vertex bound fully to one bone) ------------------

func _face(bone: String, a: Vector3, b: Vector3, c: Vector3, color: Color, center: Vector3) -> void:
	var normal := (b - a).cross(c - a).normalized()
	if normal.dot((a + b + c) / 3.0 - center) < 0.0:
		normal = -normal
	var shade := color.lightened(clampf(normal.y, 0.0, 1.0) * 0.1).darkened(clampf(-normal.y, 0.0, 1.0) * 0.2)
	for point in [a, b, c]:
		tool.set_color(shade)
		tool.set_normal(normal)
		tool.set_bones(PackedInt32Array([bone_index[bone], 0, 0, 0]))
		tool.set_weights(PackedFloat32Array([1.0, 0.0, 0.0, 0.0]))
		tool.add_vertex(point)

## Tapered tube between two elliptical rings. `opening` (0..1) leaves a gap
## of that fraction of a half-turn at the front (+Z), for open coats.
func _tube(bone: String, a: Vector3, a_radius: Vector2, b: Vector3, b_radius: Vector2, sides: int, color_a: Color, color_b: Color, opening := 0.0) -> void:
	var center := (a + b) / 2.0
	for side in sides:
		var t0 := float(side) / sides
		var t1 := float(side + 1) / sides
		var angle0 := t0 * TAU + PI / 2.0
		var angle1 := t1 * TAU + PI / 2.0
		if opening > 0.0 and _front_gap((angle0 + angle1) / 2.0, opening):
			continue
		var p0 := a + Vector3(cos(angle0) * a_radius.x, 0, sin(angle0) * a_radius.y)
		var p1 := a + Vector3(cos(angle1) * a_radius.x, 0, sin(angle1) * a_radius.y)
		var q0 := b + Vector3(cos(angle0) * b_radius.x, 0, sin(angle0) * b_radius.y)
		var q1 := b + Vector3(cos(angle1) * b_radius.x, 0, sin(angle1) * b_radius.y)
		var axis_center0 := center
		_face(bone, p0, p1, q1, color_a.lerp(color_b, 0.35), axis_center0)
		_face(bone, p0, q1, q0, color_a.lerp(color_b, 0.65), axis_center0)

func _front_gap(angle: float, opening: float) -> bool:
	var difference := absf(wrapf(angle - PI / 2.0, -PI, PI))
	return difference < opening * PI * 0.5

func _cone(bone: String, base: Vector3, radius: float, height: float, sides: int, color_rim: Color, color_tip: Color) -> void:
	var tip := base + Vector3(0, height, 0)
	var center := base + Vector3(0, height * 0.3, 0)
	for side in sides:
		var angle0 := float(side) / sides * TAU
		var angle1 := float(side + 1) / sides * TAU
		var p0 := base + Vector3(cos(angle0) * radius, 0, sin(angle0) * radius)
		var p1 := base + Vector3(cos(angle1) * radius, 0, sin(angle1) * radius)
		_face(bone, p0, p1, tip, color_rim.lerp(color_tip, 0.5 + 0.15 * (side % 2)), center)

func _blob(bone: String, center: Vector3, size: Vector3, color: Color, top: Color) -> void:
	var sphere := SphereMesh.new()
	sphere.radial_segments = 8
	sphere.rings = 5
	var arrays := sphere.get_mesh_arrays()
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	for index in range(0, indices.size(), 3):
		var a := center + vertices[indices[index]] * 2.0 * size
		var b := center + vertices[indices[index + 1]] * 2.0 * size
		var c := center + vertices[indices[index + 2]] * 2.0 * size
		var height := clampf(((a + b + c) / 3.0 - center).y / size.y * 0.5 + 0.5, 0.0, 1.0)
		_face(bone, a, b, c, color.lerp(top, height), center)

func _box(bone: String, center: Vector3, size: Vector3, color: Color, top: Color) -> void:
	var half := size / 2.0
	var corners := []
	for index in 8:
		corners.append(center + Vector3(half.x * (1 if index & 1 else -1), half.y * (1 if index & 2 else -1), half.z * (1 if index & 4 else -1)))
	var quads := [[0, 1, 3, 2], [4, 6, 7, 5], [0, 4, 5, 1], [2, 3, 7, 6], [0, 2, 6, 4], [1, 5, 7, 3]]
	for quad in quads:
		var shade: Color = top if quad == [2, 3, 7, 6] else color
		_face(bone, corners[quad[0]], corners[quad[1]], corners[quad[2]], shade, center)
		_face(bone, corners[quad[0]], corners[quad[2]], corners[quad[3]], shade, center)

func _disc_between(bone: String, center: Vector3, axis: Vector3, radius: float, thickness: float, color: Color) -> void:
	var side := axis.cross(Vector3.RIGHT).normalized()
	var up := axis.cross(side).normalized()
	var front := center + axis * thickness / 2.0
	var back := center - axis * thickness / 2.0
	for index in 8:
		var angle0 := index * TAU / 8.0
		var angle1 := (index + 1) * TAU / 8.0
		var offset0 := (side * cos(angle0) + up * sin(angle0)) * radius
		var offset1 := (side * cos(angle1) + up * sin(angle1)) * radius
		_face(bone, front, front + offset0, front + offset1, color, center - axis)
		_face(bone, back, back + offset1, back + offset0, color.darkened(0.2), center + axis)
		_face(bone, front + offset0, back + offset0, back + offset1, color.darkened(0.1), center)
		_face(bone, front + offset0, back + offset1, front + offset1, color.darkened(0.1), center)

## Slightly curved single-edged blade: a thin diamond cross-section along guard-middle-tip.
func _blade(bone: String, guard: Vector3, middle: Vector3, tip: Vector3) -> void:
	var direction := (tip - guard).normalized()
	var flat := direction.cross(Vector3.RIGHT).normalized()
	var spine := Vector3.RIGHT * 0.012
	var rings := [[guard, 0.052], [middle, 0.047], [tip - direction * 0.1, 0.036]]
	for index in rings.size() - 1:
		var p: Vector3 = rings[index][0]
		var q: Vector3 = rings[index + 1][0]
		var pw: float = rings[index][1]
		var qw: float = rings[index + 1][1]
		var p_edge := p - flat * pw
		var q_edge := q - flat * qw
		var p_back := p + flat * pw * 0.6
		var q_back := q + flat * qw * 0.6
		for sign: float in [-1.0, 1.0]:
			var p_mid := p + spine * sign
			var q_mid := q + spine * sign
			var center := (p + q) / 2.0 - spine * sign * 4.0
			_face(bone, p_edge, q_edge, q_mid, STEEL_EDGE, center)
			_face(bone, p_edge, q_mid, p_mid, STEEL_EDGE, center)
			_face(bone, p_mid, q_mid, q_back, STEEL, center)
			_face(bone, p_mid, q_back, p_back, STEEL, center)
	var last: Vector3 = rings[2][0]
	var last_width: float = rings[2][1]
	for sign: float in [-1.0, 1.0]:
		_face(bone, last - flat * last_width, tip, last + spine * sign, STEEL_EDGE, last - spine * sign * 4.0)
		_face(bone, last + spine * sign, tip, last + flat * last_width * 0.6, STEEL, last - spine * sign * 4.0)

# --- Animation -------------------------------------------------------------------

## Builds a clip from {bone: [[time, Vector3 euler degrees], ...]} rotation keys
## and optional {bone: [[time, Vector3 offset], ...]} position keys (offset from rest).
func _clip(length: float, loop: bool, rotations: Dictionary, positions := {}) -> Animation:
	var animation := Animation.new()
	animation.length = length
	animation.loop_mode = Animation.LOOP_LINEAR if loop else Animation.LOOP_NONE
	for bone_name in BONES:
		var track := animation.add_track(Animation.TYPE_ROTATION_3D)
		animation.track_set_path(track, NodePath("Skeleton3D:" + bone_name))
		var keys: Array = rotations.get(bone_name, [[0.0, Vector3.ZERO]])
		for key in keys:
			var euler: Vector3 = key[1] * (PI / 180.0)
			animation.rotation_track_insert_key(track, key[0], Basis.from_euler(euler).get_rotation_quaternion())
	for bone_name in positions:
		var track := animation.add_track(Animation.TYPE_POSITION_3D)
		animation.track_set_path(track, NodePath("Skeleton3D:" + bone_name))
		var rest: Vector3 = skeleton.get_bone_rest(bone_index[bone_name]).origin
		for key in positions[bone_name]:
			animation.position_track_insert_key(track, key[0], rest + key[1])
	return animation

func _idle() -> Animation:
	return _clip(2.0, true, {
		"spine": [[0.0, Vector3(4, 0, 0)]],
		"chest": [[0.0, Vector3(0, 0, 0)], [1.0, Vector3(2.5, 0, 0)], [2.0, Vector3(0, 0, 0)]],
		"head": [[0.0, Vector3(-3, 0, 0)], [1.0, Vector3(-1, 4, 0)], [2.0, Vector3(-3, 0, 0)]],
		"scarf_tail": [[0.0, Vector3(8, 0, 3)], [1.0, Vector3(14, 6, -3)], [2.0, Vector3(8, 0, 3)]],
		"upper_arm.L": [[0.0, Vector3(4, 0, 7)], [1.0, Vector3(6, 0, 8)], [2.0, Vector3(4, 0, 7)]],
		"forearm.L": [[0.0, Vector3(-12, 0, 0)]],
		"upper_arm.R": [[0.0, Vector3(-22, 0, -10)], [1.0, Vector3(-25, 0, -11)], [2.0, Vector3(-22, 0, -10)]],
		"forearm.R": [[0.0, Vector3(-28, 0, 0)]],
		"hand.R": [[0.0, Vector3(48, 0, 0)]],
		"thigh.L": [[0.0, Vector3(-6, 0, 4)]],
		"shin.L": [[0.0, Vector3(6, 0, 0)]],
		"thigh.R": [[0.0, Vector3(5, 0, -4)]],
		"shin.R": [[0.0, Vector3(4, 0, 0)]],
	})

func _run() -> Animation:
	var step := 0.15
	return _clip(step * 4.0, true, {
		"spine": [[0.0, Vector3(16, 0, 0)]],
		"chest": [[0.0, Vector3(0, 8, 0)], [step * 2.0, Vector3(0, -8, 0)], [step * 4.0, Vector3(0, 8, 0)]],
		"head": [[0.0, Vector3(-14, -6, 0)], [step * 2.0, Vector3(-14, 6, 0)], [step * 4.0, Vector3(-14, -6, 0)]],
		"scarf_tail": [[0.0, Vector3(55, 4, 0)], [step, Vector3(65, -4, 0)], [step * 2.0, Vector3(55, 4, 0)], [step * 3.0, Vector3(65, -4, 0)], [step * 4.0, Vector3(55, 4, 0)]],
		"upper_arm.L": [[0.0, Vector3(38, 0, 8)], [step * 2.0, Vector3(-38, 0, 8)], [step * 4.0, Vector3(38, 0, 8)]],
		"forearm.L": [[0.0, Vector3(-55, 0, 0)]],
		"upper_arm.R": [[0.0, Vector3(32, 0, -18)], [step * 2.0, Vector3(26, 0, -16)], [step * 4.0, Vector3(32, 0, -18)]],
		"forearm.R": [[0.0, Vector3(-20, 0, 0)]],
		"hand.R": [[0.0, Vector3(95, 0, 0)]],
		"thigh.L": [[0.0, Vector3(-42, 0, 0)], [step, Vector3(-5, 0, 0)], [step * 2.0, Vector3(34, 0, 0)], [step * 3.0, Vector3(0, 0, 0)], [step * 4.0, Vector3(-42, 0, 0)]],
		"shin.L": [[0.0, Vector3(12, 0, 0)], [step, Vector3(25, 0, 0)], [step * 2.0, Vector3(35, 0, 0)], [step * 3.0, Vector3(88, 0, 0)], [step * 4.0, Vector3(12, 0, 0)]],
		"foot.L": [[0.0, Vector3(-10, 0, 0)], [step * 2.0, Vector3(20, 0, 0)], [step * 4.0, Vector3(-10, 0, 0)]],
		"thigh.R": [[0.0, Vector3(34, 0, 0)], [step, Vector3(0, 0, 0)], [step * 2.0, Vector3(-42, 0, 0)], [step * 3.0, Vector3(-5, 0, 0)], [step * 4.0, Vector3(34, 0, 0)]],
		"shin.R": [[0.0, Vector3(35, 0, 0)], [step, Vector3(88, 0, 0)], [step * 2.0, Vector3(12, 0, 0)], [step * 3.0, Vector3(25, 0, 0)], [step * 4.0, Vector3(35, 0, 0)]],
		"foot.R": [[0.0, Vector3(20, 0, 0)], [step * 2.0, Vector3(-10, 0, 0)], [step * 4.0, Vector3(20, 0, 0)]],
	}, {
		"hips": [[0.0, Vector3(0, -0.03, 0)], [step, Vector3(0, 0.04, 0)], [step * 2.0, Vector3(0, -0.03, 0)], [step * 3.0, Vector3(0, 0.04, 0)], [step * 4.0, Vector3(0, -0.03, 0)]],
	})

## Combo (D-075). Four original swings that chain into each other: a
## right-to-left cut, a backhand cut, a rising cut and a leaping two-handed
## slam. Arm X -90 points forward; arm Y turns that forward reach sideways
## (negative = his right); hand X +40 keeps the blade level with the arm.

## 1: quick horizontal cut from his right across to his left, stepping in.
func _slash_1() -> Animation:
	return _clip(0.42, false, {
		"spine": [[0.0, Vector3(4, 0, 0)], [0.1, Vector3(8, -18, 0)], [0.16, Vector3(12, 6, 0)], [0.24, Vector3(12, 22, 0)], [0.42, Vector3(4, 0, 0)]],
		"chest": [[0.0, Vector3(0, 0, 0)], [0.1, Vector3(0, -30, 0)], [0.16, Vector3(4, 10, 0)], [0.24, Vector3(4, 30, 0)], [0.42, Vector3(0, 0, 0)]],
		"head": [[0.0, Vector3(-3, 0, 0)], [0.1, Vector3(-3, 28, 0)], [0.24, Vector3(-6, -24, 0)], [0.42, Vector3(-3, 0, 0)]],
		"scarf_tail": [[0.0, Vector3(8, 0, 3)], [0.16, Vector3(40, 20, 0)], [0.28, Vector3(45, -25, 0)], [0.42, Vector3(10, 0, 3)]],
		"upper_arm.R": [[0.0, Vector3(-22, 0, -10)], [0.1, Vector3(-82, -70, 0)], [0.16, Vector3(-84, 0, 0)], [0.24, Vector3(-78, 62, 0)], [0.3, Vector3(-70, 66, 0)], [0.42, Vector3(-22, 0, -10)]],
		"forearm.R": [[0.0, Vector3(-28, 0, 0)], [0.1, Vector3(-30, 0, 0)], [0.16, Vector3(-4, 0, 0)], [0.42, Vector3(-28, 0, 0)]],
		"hand.R": [[0.0, Vector3(48, 0, 0)], [0.1, Vector3(40, 0, 0)], [0.24, Vector3(40, 0, 0)], [0.42, Vector3(48, 0, 0)]],
		"upper_arm.L": [[0.0, Vector3(4, 0, 7)], [0.1, Vector3(-30, 0, 40)], [0.24, Vector3(10, 0, 50)], [0.42, Vector3(4, 0, 7)]],
		"forearm.L": [[0.0, Vector3(-12, 0, 0)], [0.1, Vector3(-40, 0, 0)], [0.42, Vector3(-12, 0, 0)]],
		"thigh.L": [[0.0, Vector3(-6, 0, 4)], [0.12, Vector3(-36, 0, 6)], [0.3, Vector3(-36, 0, 6)], [0.42, Vector3(-6, 0, 4)]],
		"shin.L": [[0.0, Vector3(6, 0, 0)], [0.12, Vector3(30, 0, 0)], [0.42, Vector3(6, 0, 0)]],
		"thigh.R": [[0.0, Vector3(5, 0, -4)], [0.16, Vector3(22, 0, -6)], [0.42, Vector3(5, 0, -4)]],
		"shin.R": [[0.0, Vector3(4, 0, 0)], [0.16, Vector3(28, 0, 0)], [0.42, Vector3(4, 0, 0)]],
	}, {
		"hips": [[0.0, Vector3.ZERO], [0.16, Vector3(0, -0.06, 0.07)], [0.3, Vector3(0, -0.06, 0.07)], [0.42, Vector3.ZERO]],
	})

## 2: backhand cut returning from his left to his right.
func _slash_2() -> Animation:
	return _clip(0.42, false, {
		"spine": [[0.0, Vector3(4, 0, 0)], [0.08, Vector3(10, 24, 0)], [0.15, Vector3(12, 0, 0)], [0.23, Vector3(12, -26, 0)], [0.42, Vector3(4, 0, 0)]],
		"chest": [[0.0, Vector3(0, 0, 0)], [0.08, Vector3(2, 34, 0)], [0.15, Vector3(4, -6, 0)], [0.23, Vector3(4, -36, 0)], [0.42, Vector3(0, 0, 0)]],
		"head": [[0.0, Vector3(-3, 0, 0)], [0.08, Vector3(-3, -30, 0)], [0.23, Vector3(-6, 30, 0)], [0.42, Vector3(-3, 0, 0)]],
		"scarf_tail": [[0.0, Vector3(10, 0, 3)], [0.15, Vector3(45, -25, 0)], [0.28, Vector3(42, 25, 0)], [0.42, Vector3(10, 0, 3)]],
		"upper_arm.R": [[0.0, Vector3(-40, 40, 0)], [0.08, Vector3(-80, 74, 0)], [0.15, Vector3(-86, 0, 0)], [0.23, Vector3(-80, -72, 0)], [0.3, Vector3(-72, -78, 0)], [0.42, Vector3(-22, 0, -10)]],
		"forearm.R": [[0.0, Vector3(-40, 0, 0)], [0.08, Vector3(-50, 0, 0)], [0.15, Vector3(-4, 0, 0)], [0.42, Vector3(-28, 0, 0)]],
		"hand.R": [[0.0, Vector3(40, 0, 0)], [0.23, Vector3(40, 0, 0)], [0.42, Vector3(48, 0, 0)]],
		"upper_arm.L": [[0.0, Vector3(10, 0, 50)], [0.08, Vector3(-20, 0, 30)], [0.23, Vector3(-30, 0, 45)], [0.42, Vector3(4, 0, 7)]],
		"forearm.L": [[0.0, Vector3(-30, 0, 0)], [0.23, Vector3(-50, 0, 0)], [0.42, Vector3(-12, 0, 0)]],
		"thigh.L": [[0.0, Vector3(-30, 0, 6)], [0.15, Vector3(10, 0, 6)], [0.42, Vector3(-6, 0, 4)]],
		"shin.L": [[0.0, Vector3(26, 0, 0)], [0.15, Vector3(24, 0, 0)], [0.42, Vector3(6, 0, 0)]],
		"thigh.R": [[0.0, Vector3(14, 0, -6)], [0.12, Vector3(-38, 0, -6)], [0.3, Vector3(-38, 0, -6)], [0.42, Vector3(5, 0, -4)]],
		"shin.R": [[0.0, Vector3(20, 0, 0)], [0.12, Vector3(32, 0, 0)], [0.42, Vector3(4, 0, 0)]],
	}, {
		"hips": [[0.0, Vector3(0, -0.04, 0.05)], [0.15, Vector3(0, -0.07, 0.09)], [0.3, Vector3(0, -0.07, 0.09)], [0.42, Vector3.ZERO]],
	})

## 3: crouch and rising cut from low on his left up past his right shoulder.
func _slash_3() -> Animation:
	return _clip(0.5, false, {
		"spine": [[0.0, Vector3(4, 0, 0)], [0.12, Vector3(26, 22, 0)], [0.2, Vector3(0, -6, 0)], [0.28, Vector3(-12, -20, 0)], [0.5, Vector3(4, 0, 0)]],
		"chest": [[0.0, Vector3(0, 0, 0)], [0.12, Vector3(10, 30, 0)], [0.2, Vector3(-6, -4, 0)], [0.28, Vector3(-10, -24, 0)], [0.5, Vector3(0, 0, 0)]],
		"head": [[0.0, Vector3(-3, 0, 0)], [0.12, Vector3(-20, -26, 0)], [0.28, Vector3(0, 20, 0)], [0.5, Vector3(-3, 0, 0)]],
		"scarf_tail": [[0.0, Vector3(10, 0, 3)], [0.12, Vector3(20, 0, 0)], [0.28, Vector3(70, 0, 0)], [0.5, Vector3(10, 0, 3)]],
		"upper_arm.R": [[0.0, Vector3(-22, 0, -10)], [0.12, Vector3(-20, 50, 0)], [0.2, Vector3(-95, -10, 0)], [0.28, Vector3(-160, -36, 0)], [0.36, Vector3(-158, -40, 0)], [0.5, Vector3(-22, 0, -10)]],
		"forearm.R": [[0.0, Vector3(-28, 0, 0)], [0.12, Vector3(-10, 0, 0)], [0.28, Vector3(-6, 0, 0)], [0.5, Vector3(-28, 0, 0)]],
		"hand.R": [[0.0, Vector3(48, 0, 0)], [0.12, Vector3(30, 0, 0)], [0.28, Vector3(40, 0, 0)], [0.5, Vector3(48, 0, 0)]],
		"upper_arm.L": [[0.0, Vector3(4, 0, 7)], [0.12, Vector3(-40, 0, 20)], [0.28, Vector3(20, 0, 55)], [0.5, Vector3(4, 0, 7)]],
		"forearm.L": [[0.0, Vector3(-12, 0, 0)], [0.12, Vector3(-60, 0, 0)], [0.28, Vector3(-20, 0, 0)], [0.5, Vector3(-12, 0, 0)]],
		"thigh.L": [[0.0, Vector3(-6, 0, 4)], [0.12, Vector3(-55, 0, 6)], [0.24, Vector3(-20, 0, 6)], [0.5, Vector3(-6, 0, 4)]],
		"shin.L": [[0.0, Vector3(6, 0, 0)], [0.12, Vector3(70, 0, 0)], [0.24, Vector3(20, 0, 0)], [0.5, Vector3(6, 0, 0)]],
		"foot.L": [[0.0, Vector3.ZERO], [0.12, Vector3(-15, 0, 0)], [0.24, Vector3.ZERO]],
		"thigh.R": [[0.0, Vector3(5, 0, -4)], [0.12, Vector3(-10, 0, -6)], [0.24, Vector3(14, 0, -6)], [0.5, Vector3(5, 0, -4)]],
		"shin.R": [[0.0, Vector3(4, 0, 0)], [0.12, Vector3(70, 0, 0)], [0.24, Vector3(30, 0, 0)], [0.5, Vector3(4, 0, 0)]],
	}, {
		"hips": [[0.0, Vector3.ZERO], [0.12, Vector3(0, -0.16, 0.0)], [0.22, Vector3(0, 0.05, 0.08)], [0.3, Vector3(0, 0.08, 0.1)], [0.5, Vector3.ZERO]],
	})

## 4 (finisher): crouch, leap with the sword raised in both hands, slam down.
func _slash_4() -> Animation:
	return _clip(0.8, false, {
		"spine": [[0.0, Vector3(4, 0, 0)], [0.16, Vector3(24, 0, 0)], [0.32, Vector3(-16, 0, 0)], [0.42, Vector3(30, 0, 0)], [0.6, Vector3(28, 0, 0)], [0.8, Vector3(4, 0, 0)]],
		"chest": [[0.0, Vector3(0, 0, 0)], [0.16, Vector3(8, 0, 0)], [0.32, Vector3(-14, 0, 0)], [0.42, Vector3(16, 0, 0)], [0.8, Vector3(0, 0, 0)]],
		"head": [[0.0, Vector3(-3, 0, 0)], [0.16, Vector3(-18, 0, 0)], [0.32, Vector3(8, 0, 0)], [0.42, Vector3(-26, 0, 0)], [0.8, Vector3(-3, 0, 0)]],
		"scarf_tail": [[0.0, Vector3(10, 0, 3)], [0.32, Vector3(-30, 0, 0)], [0.42, Vector3(80, 0, 0)], [0.6, Vector3(60, 0, 0)], [0.8, Vector3(10, 0, 3)]],
		"upper_arm.R": [[0.0, Vector3(-22, 0, -10)], [0.16, Vector3(-60, 0, 10)], [0.32, Vector3(-168, 0, 14)], [0.42, Vector3(-62, 0, 18)], [0.6, Vector3(-55, 0, 18)], [0.8, Vector3(-22, 0, -10)]],
		"forearm.R": [[0.0, Vector3(-28, 0, 0)], [0.16, Vector3(-40, 0, 0)], [0.32, Vector3(-30, 0, 0)], [0.42, Vector3(-4, 0, 0)], [0.8, Vector3(-28, 0, 0)]],
		"hand.R": [[0.0, Vector3(48, 0, 0)], [0.16, Vector3(10, 0, 0)], [0.32, Vector3(-30, 0, 0)], [0.42, Vector3(40, 0, 0)], [0.8, Vector3(48, 0, 0)]],
		"upper_arm.L": [[0.0, Vector3(4, 0, 7)], [0.16, Vector3(-58, 0, -12)], [0.32, Vector3(-164, 0, -18)], [0.42, Vector3(-58, 0, -26)], [0.6, Vector3(-52, 0, -26)], [0.8, Vector3(4, 0, 7)]],
		"forearm.L": [[0.0, Vector3(-12, 0, 0)], [0.16, Vector3(-40, 0, 0)], [0.32, Vector3(-30, 0, 0)], [0.42, Vector3(-10, 0, 0)], [0.8, Vector3(-12, 0, 0)]],
		"thigh.L": [[0.0, Vector3(-6, 0, 4)], [0.16, Vector3(-50, 0, 6)], [0.32, Vector3(-30, 0, 6)], [0.42, Vector3(-62, 0, 6)], [0.6, Vector3(-60, 0, 6)], [0.8, Vector3(-6, 0, 4)]],
		"shin.L": [[0.0, Vector3(6, 0, 0)], [0.16, Vector3(70, 0, 0)], [0.32, Vector3(60, 0, 0)], [0.42, Vector3(60, 0, 0)], [0.8, Vector3(6, 0, 0)]],
		"foot.L": [[0.0, Vector3.ZERO], [0.16, Vector3(-18, 0, 0)], [0.32, Vector3(30, 0, 0)], [0.42, Vector3.ZERO]],
		"thigh.R": [[0.0, Vector3(5, 0, -4)], [0.16, Vector3(-36, 0, -6)], [0.32, Vector3(10, 0, -6)], [0.42, Vector3(30, 0, -6)], [0.6, Vector3(30, 0, -6)], [0.8, Vector3(5, 0, -4)]],
		"shin.R": [[0.0, Vector3(4, 0, 0)], [0.16, Vector3(70, 0, 0)], [0.32, Vector3(80, 0, 0)], [0.42, Vector3(60, 0, 0)], [0.8, Vector3(4, 0, 0)]],
		"foot.R": [[0.0, Vector3.ZERO], [0.32, Vector3(30, 0, 0)], [0.42, Vector3.ZERO]],
	}, {
		"hips": [[0.0, Vector3.ZERO], [0.16, Vector3(0, -0.16, 0.0)], [0.3, Vector3(0, 0.32, 0.1)], [0.42, Vector3(0, -0.14, 0.16)], [0.6, Vector3(0, -0.13, 0.16)], [0.8, Vector3.ZERO]],
	})
