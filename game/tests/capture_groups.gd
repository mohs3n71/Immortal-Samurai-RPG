extends SceneTree

## Screenshots of soldier groups in their clearings (D-093). Usage: -- <out_dir> <x,z> ...

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var progression = load("res://scripts/progression.gd")
	progression.persist = false
	progression.reset()
	var field := (load("res://scenes/meadow.tscn") as PackedScene).instantiate()
	root.add_child(field)
	await create_timer(1.0).timeout
	var player: CharacterBody3D = field.player
	player.get_node("AutoAttack").set_physics_process(false)
	for spot in args.slice(1):
		var xz: PackedStringArray = spot.split(",")
		for soldier in root.get_tree().get_nodes_in_group("enemies"):
			if soldier.has_method("reset_to_home"):
				soldier.set_physics_process(false)
		player.revive(Vector3(float(xz[0]) + 6, 2, float(xz[1]) + 16))
		await create_timer(1.0).timeout
		RenderingServer.force_draw()
		root.get_texture().get_image().save_png("%s/group_%s.png" % [args[0], spot.replace(",", "_")])
		print("CAPTURED ", spot)
	quit()
