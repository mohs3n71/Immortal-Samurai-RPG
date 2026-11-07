extends SceneTree

## Renders a rigged hero scene: a turnaround, then poses sampled from clips.
## Usage: --script res://tests/render_hero_sheet.gd -- <hero.tscn> <out_prefix>

const POSES := [["slash_1", 0.1], ["slash_1", 0.16], ["slash_1", 0.24], ["slash_2", 0.08], ["slash_2", 0.15], ["slash_2", 0.23], ["slash_3", 0.12], ["slash_3", 0.2], ["slash_3", 0.28], ["slash_4", 0.16], ["slash_4", 0.32], ["slash_4", 0.42]]
const VIEWS_ALL := [["front", 0.0], ["three-quarter", -40.0], ["side", -90.0], ["back", 180.0]]
const POSES_ALL := [["idle", 0.0], ["idle", 1.0], ["run", 0.0], ["run", 0.15], ["run", 0.3], ["run", 0.45], ["slash_1", 0.16], ["slash_2", 0.15], ["slash_3", 0.28], ["slash_4", 0.42]]

func _initialize() -> void:
	call_deferred("_render")

func _render() -> void:
	var args := OS.get_cmdline_user_args()
	var world := Node3D.new()
	root.add_child(world)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color("6f9a55")
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color("e4ecd6")
	environment.environment.ambient_light_energy = 0.55
	world.add_child(environment)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-45, -30, 0)
	sun.light_energy = 1.25
	world.add_child(sun)
	var hero := (load(args[0]) as PackedScene).instantiate() as Node3D
	world.add_child(hero)
	var player := hero.get_node("AnimationPlayer") as AnimationPlayer
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 2.2
	world.add_child(camera)
	camera.position = Vector3(0, 1.3, 10)
	camera.look_at(Vector3(0, 0.95, 0))
	camera.current = true
	player.play("idle")
	player.seek(0.0, true)
	player.pause()
	var views: Array = [] if OS.get_cmdline_user_args().size() > 2 else VIEWS_ALL
	var poses: Array = POSES if OS.get_cmdline_user_args().size() > 2 else POSES_ALL
	if OS.get_cmdline_user_args().size() > 2:
		camera.size = 2.0
	for view in views:
		hero.rotation_degrees.y = view[1]
		await _save("%s_view_%s.png" % [args[1], view[0]])
	hero.rotation_degrees.y = float(OS.get_cmdline_user_args()[2]) if OS.get_cmdline_user_args().size() > 2 else -60.0
	for pose in poses:
		player.play(pose[0])
		player.seek(pose[1], true)
		player.pause()
		await _save("%s_pose_%s_%.2f.png" % [args[1], pose[0], pose[1]])
	quit()

func _save(path: String) -> void:
	await create_timer(0.15).timeout
	RenderingServer.force_draw()
	root.get_texture().get_image().save_png(path)
