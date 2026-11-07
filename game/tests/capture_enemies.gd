extends SceneTree

## Screenshots of Kaze fighting soldiers at their clearings (D-078).
## Usage: --script res://tests/capture_enemies.gd -- <out_dir> <soldier id> [soldier id ...]

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var field := (load("res://scenes/meadow.tscn") as PackedScene).instantiate()
	root.add_child(field)
	await create_timer(1.0).timeout
	var player: CharacterBody3D = field.player
	for id: String in args.slice(1):
		var soldier: Node3D = null
		for node in root.get_tree().get_nodes_in_group("enemies"):
			if node.get("data") is Dictionary and node.data.get("id", "") == id:
				soldier = node
		if soldier == null:
			continue
		player.revive(soldier.home + Vector3(-11, 1.5, -11))
		soldier.set_physics_process(false)
		player.get_node("AutoAttack").set_physics_process(false)
		await create_timer(1.6).timeout
		RenderingServer.force_draw()
		root.get_texture().get_image().save_png("%s/%s.png" % [args[0], id])
		print("CAPTURED ", id, " soldier health ", soldier.health, " hero ", player.health)
	quit()
