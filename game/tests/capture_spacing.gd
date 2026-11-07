extends SceneTree

## Screenshots of Kaze pressed against enemies at the closest allowed gap (D-087).
## Usage: --script res://tests/capture_spacing.gd -- <out_dir> <id> [id ...]

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
	for id: String in args.slice(1):
		var foe: Node3D = null
		for node in root.get_tree().get_nodes_in_group("bodies"):
			if (node.get("data") is Dictionary and node.data.get("id", "") == id) or (id == "reaper" and node.name == "Reaper"):
				foe = node
		if foe == null:
			continue
		foe.set_physics_process(false)
		var base: Vector3 = foe.home if foe.get("home") != null else foe.global_position
		player.revive(base + Vector3(9, 1, 0))
		for frame in 120:
			var offset := foe.global_position - player.global_position
			var right: Vector3 = player.camera.global_basis.x
			var forward: Vector3 = -player.camera.global_basis.z
			right.y = 0.0
			forward.y = 0.0
			offset.y = 0.0
			player.joystick.direction = Vector2(offset.normalized().dot(right.normalized()), -offset.normalized().dot(forward.normalized()))
			await physics_frame
		player.joystick.direction = Vector2.ZERO
		await create_timer(0.4).timeout
		RenderingServer.force_draw()
		root.get_texture().get_image().save_png("%s/%s.png" % [args[0], id])
		var gap := Vector2(foe.global_position.x - player.global_position.x, foe.global_position.z - player.global_position.z).length()
		print("CAPTURED ", id, " gap ", gap)
		foe.set_physics_process(true)
	quit()
