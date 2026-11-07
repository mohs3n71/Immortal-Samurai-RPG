extends SceneTree

## Screenshots of a region from the game camera (D-100).
## Usage (windowed): -- <field.tscn> <out_dir> <x,z> [x,z ...]

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var progression = load("res://scripts/progression.gd")
	progression.persist = false
	progression.reset()
	progression.tutorial_done = true
	var field := (load(args[0]) as PackedScene).instantiate()
	root.add_child(field)
	await create_timer(1.2).timeout
	var player: CharacterBody3D = field.player
	player.get_node("AutoAttack").set_physics_process(false)
	for enemy in root.get_tree().get_nodes_in_group("enemies"):
		enemy.set_physics_process(false)
	for spot in args.slice(2):
		var xz: PackedStringArray = spot.split(",")
		player.revive(Vector3(float(xz[0]), 2, float(xz[1])))
		await create_timer(1.0).timeout
		RenderingServer.force_draw()
		root.get_texture().get_image().save_png("%s/%s.png" % [args[1], spot.replace(",", "_")])
		print("CAPTURED ", spot)
	quit()
