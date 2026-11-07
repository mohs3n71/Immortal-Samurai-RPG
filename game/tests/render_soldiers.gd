extends SceneTree

## Renders the converted Toony Tiny soldiers side by side (D-078).
## Usage: --script res://tests/render_soldiers.gd -- <out.png> [yaw_degrees] [clip] [time]

const CANDIDATES := ["reaper", "vampire-knight", "zombie-knight"]
## Frostlands frozen undead (D-100), shown with FROST=1 in the environment.
const FROST := ["frost-zombie", "ice-ghoul", "snow-acolyte", "ice-vampire", "frozen-brute", "frost-witch", "rime-cultist", "vampire-reaver", "bone-sentinel", "glacier-lord", "frozen-warden"]
const IDS := ["axe-recruit", "pike-recruit", "hammer-guard", "sword-soldier", "spear-guard", "broadsword-soldier", "battle-mage", "morningstar-captain", "halberd-captain", "warhammer-commander", "iron-commander"]

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var yaw := float(args[1]) if args.size() > 1 else 0.0
	var world := Node3D.new()
	root.add_child(world)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color("8fb46a")
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color(0.7, 0.7, 0.75)
	world.add_child(environment)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-50, 30, 0)
	world.add_child(light)
	var only := int(args[2]) if args.size() > 2 else -1
	for index in IDS.size():
		if only >= 0 and index != only:
			continue
		var scene: PackedScene
		if OS.has_environment("FROST"):
			scene = load("res://assets/enemies/frost/%s.glb" % FROST[index])
		elif OS.has_environment("CANDIDATES"):
			scene = load("res://assets/enemies/undead/%s.glb" % CANDIDATES[index])
		else:
			scene = load("res://assets/enemies/toony-tiny/%s.glb" % IDS[index])
		var soldier: Node3D = scene.instantiate()
		soldier.position = Vector3((index - 5) * 1.6, 0, 0) if only < 0 else Vector3.ZERO
		soldier.rotation_degrees.y = yaw
		world.add_child(soldier)
		if index == 0:
			var skeleton: Skeleton3D = soldier.find_children("*", "Skeleton3D", true, false)[0]
			var names := []
			for bone in skeleton.get_bone_count():
				names.append(skeleton.get_bone_name(bone))
			print("bones: ", names)
		var box := AABB()
		var first := true
		for mesh in soldier.find_children("*", "MeshInstance3D", true, false):
			var aabb: AABB = mesh.global_transform * mesh.get_aabb()
			box = aabb if first else box.merge(aabb)
			first = false
		print(IDS[index], " size ", box.size, " pos ", box.position)
	var camera := Camera3D.new()
	world.add_child(camera)
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 4.5 if only < 0 else 3.4
	camera.position = Vector3(0, 1.2, 10)
	camera.current = true
	await create_timer(0.4).timeout
	RenderingServer.force_draw()
	root.get_texture().get_image().save_png(args[0])
	quit()
