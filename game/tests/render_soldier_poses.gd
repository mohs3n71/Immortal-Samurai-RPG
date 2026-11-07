extends SceneTree

## Pose sheet for the soldier clips (D-078): one soldier in several clip poses.
## Usage: --script res://tests/render_soldier_poses.gd -- <out_prefix> <soldier id> <yaw> clip@time [clip@time ...]

const SoldierAnimations = preload("res://scripts/enemies/soldier_animations.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var prefix: String = args[0]
	var id: String = args[1]
	var yaw := float(args[2])
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
	var holder := Node3D.new()
	holder.rotation_degrees.y = yaw
	world.add_child(holder)
	var path := "res://assets/enemies/%s.glb" % id if id.contains("/") else "res://assets/enemies/toony-tiny/%s.glb" % id
	var soldier: Node3D = (load(path) as PackedScene).instantiate()
	holder.add_child(soldier)
	var skeleton: Skeleton3D = soldier.find_children("*", "Skeleton3D", true, false)[0]
	var player := AnimationPlayer.new()
	soldier.add_child(player)
	player.root_node = player.get_path_to(soldier)
	player.add_animation_library("", SoldierAnimations.library_for(id, skeleton, soldier))
	var camera := Camera3D.new()
	world.add_child(camera)
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 3.2
	camera.position = Vector3(0, 1.3, 10)
	camera.current = true
	for pose: String in args.slice(3):
		var parts := pose.split("@")
		player.play(parts[0])
		player.seek(float(parts[1]), true)
		player.pause()
		await process_frame
		RenderingServer.force_draw()
		root.get_texture().get_image().save_png("%s_%s_%s.png" % [prefix, parts[0], parts[1]])
	quit()
