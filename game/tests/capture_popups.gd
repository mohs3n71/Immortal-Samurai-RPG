extends SceneTree

## Fall reward card and knight "LEVEL UP!" placement (D-098). Usage: -- <out.png>

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var out: String = OS.get_cmdline_user_args()[0]
	var progression = load("res://scripts/progression.gd")
	progression.persist = false
	progression.reset()
	progression.tutorial_done = true
	progression.damage = 830
	progression.blood_level = 13
	progression.plague_level = 16
	progression.hero_level = 31
	progression.max_health = 29
	var field := (load("res://scenes/meadow.tscn") as PackedScene).instantiate()
	root.add_child(field)
	await create_timer(1.0).timeout
	var player: CharacterBody3D = field.player
	player.get_node("AutoAttack").set_physics_process(false)
	var knight: Node3D = null
	for node in root.get_tree().get_nodes_in_group("enemies"):
		if node.get("data") is Dictionary and node.data.get("id", "") == "plague-knight":
			knight = node
	knight.set_physics_process(false)
	player.revive(knight.home + Vector3(4, 1, 9))
	await create_timer(0.8).timeout
	field.hud.show_reward(14)
	knight._show_level_up()
	await create_timer(0.5).timeout
	RenderingServer.force_draw()
	root.get_texture().get_image().save_png(out)
	print("CAPTURED")
	quit()
