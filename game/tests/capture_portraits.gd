extends SceneTree

## Renders round-card portraits of the main characters from the live scene
## (D-094): each character alone on a transparent background (render layer
## 20, camera sees only that layer), in its idle pose. Output: assets/ui/portraits/.
## Usage (windowed, 512x512): --script res://tests/capture_portraits.gd -- <out_dir>

const LAYER := 1 << 19

func _initialize() -> void:
	call_deferred("_run")

func _find(predicate: Callable) -> Node3D:
	for node in root.get_tree().get_nodes_in_group("bodies"):
		if predicate.call(node):
			return node
	return null

func _run() -> void:
	var out: String = OS.get_cmdline_user_args()[0]
	var region_args := OS.get_cmdline_user_args()
	var progression = load("res://scripts/progression.gd")
	progression.persist = false
	progression.reset()
	progression.tutorial_done = true
	# Optional: a region's field scene and the ids to capture (D-100).
	var args := OS.get_cmdline_user_args()
	var field := (load(args[1] if args.size() > 1 else "res://scenes/meadow.tscn") as PackedScene).instantiate()
	root.add_child(field)
	await create_timer(1.5).timeout
	root.transparent_bg = true
	for canvas in field.find_children("*", "CanvasLayer", true, false):
		canvas.visible = false
	var environment := Environment.new()
	environment.background_mode = Environment.BG_CLEAR_COLOR
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.62, 0.6, 0.58)
	environment.ambient_light_energy = 0.9
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var camera := Camera3D.new()
	camera.cull_mask = LAYER
	camera.environment = environment
	camera.fov = 30.0
	root.add_child(camera)
	var key := DirectionalLight3D.new()
	key.light_cull_mask = LAYER
	key.light_energy = 1.4
	root.add_child(key)
	var player: Node3D = field.player
	player.get_node("AutoAttack").set_physics_process(false)
	var targets := {
		"kaze": player,
		"blood-knight": _find(func(n: Node) -> bool: return n.get("data") is Dictionary and n.data.get("id", "") == "blood-knight"),
		"plague-knight": _find(func(n: Node) -> bool: return n.get("data") is Dictionary and n.data.get("id", "") == "plague-knight"),
		"reaper": _find(func(n: Node) -> bool: return n.name == "Reaper"),
		"soldier": _find(func(n: Node) -> bool: return n.get("data") is Dictionary and n.data.get("id", "") == "sword-soldier"),
		"boss": _find(func(n: Node) -> bool: return n.get("data") is Dictionary and n.data.get("id", "") == "bone-warlord"),
		"frost-tyrant": _find(func(n: Node) -> bool: return n.get("data") is Dictionary and n.data.get("id", "") == "frost-tyrant"),
	}
	if args.size() > 2:
		var wanted := {}
		for id in args.slice(2):
			wanted[id] = targets.get(id)
		targets = wanted
	for enemy in root.get_tree().get_nodes_in_group("enemies"):
		enemy.set_physics_process(false)
	for name: String in targets:
		var target: Node3D = targets[name]
		if target == null:
			print("MISSING ", name)
			continue
		var meshes := target.find_children("*", "MeshInstance3D", true, false)
		var bounds := AABB()
		var first := true
		for mesh: MeshInstance3D in meshes:
			mesh.layers = LAYER
			if not mesh.is_visible_in_tree():
				continue
			var box: AABB = mesh.global_transform * mesh.get_aabb()
			bounds = box if first else bounds.merge(box)
			first = false
		var height := bounds.size.y
		var facing: Vector3 = target.get("visual").global_basis.z if target.get("visual") != null else (target.get("_visual").global_basis.z if target.get("_visual") != null else target.global_basis.z)
		facing.y = 0.0
		facing = facing.normalized()
		var side := facing.cross(Vector3.UP).normalized()
		# Head and shoulders, from slightly to one side and above.
		var focus := Vector3(target.global_position.x, bounds.position.y + height * (0.7 if name == "reaper" else 0.74), target.global_position.z)
		var distance := height * (1.05 if name == "reaper" else 1.35)
		camera.global_position = focus + (facing * 0.9 + side * 0.35).normalized() * distance + Vector3.UP * height * 0.08
		camera.look_at(focus, Vector3.UP)
		key.global_basis = Basis.looking_at((-facing + side * 0.8 + Vector3.DOWN * 0.9).normalized(), Vector3.UP)
		camera.make_current()
		await create_timer(0.4).timeout
		RenderingServer.force_draw()
		var image := root.get_texture().get_image()
		image.save_png("%s/%s.png" % [out, name])
		print("CAPTURED ", name, " height ", height)
		for mesh: MeshInstance3D in meshes:
			mesh.layers = 1
	quit()
