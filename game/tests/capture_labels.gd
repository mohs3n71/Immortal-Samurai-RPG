extends SceneTree

## Overhead labels (D-088): boss mid-fight, a hurt knight, the Reaper on
## cooldown and a soldier's respawn countdown. Usage: -- <out_dir>

func _initialize() -> void:
	call_deferred("_run")

func _shot(path: String) -> void:
	await create_timer(0.5).timeout
	RenderingServer.force_draw()
	root.get_texture().get_image().save_png(path)
	print("CAPTURED ", path)

func _find(id: String) -> Node3D:
	for node in root.get_tree().get_nodes_in_group("bodies"):
		if (node.get("data") is Dictionary and node.data.get("id", "") == id) or node.name == id:
			return node
	return null

func _run() -> void:
	var out: String = OS.get_cmdline_user_args()[0]
	var progression = load("res://scripts/progression.gd")
	progression.persist = false
	progression.reset()
	progression.max_health = 1000000
	var field := (load("res://scenes/meadow.tscn") as PackedScene).instantiate()
	root.add_child(field)
	await create_timer(1.0).timeout
	var player: CharacterBody3D = field.player
	player.refill()
	player.get_node("AutoAttack").set_physics_process(false)
	var boss := _find("bone-warlord")
	player.revive(boss.home + Vector3(0, 1, 9))
	await create_timer(3.0).timeout
	boss.health = boss.max_health() * 0.98
	boss._update_bar()
	await _shot(out + "/boss.png")
	var knight := _find("blood-knight")
	player.revive(knight.home + Vector3(0, 1, 9))
	await create_timer(1.0).timeout
	knight.take_hit(2.0, player.global_position)
	await _shot(out + "/knight.png")
	var reaper := _find("Reaper")
	player.revive(reaper.global_position + Vector3(0, 1, 7))
	await create_timer(2.0).timeout
	await _shot(out + "/reaper.png")
	var soldier := _find("axe-recruit")
	player.revive(soldier.home + Vector3(8, 1, 8))
	await create_timer(0.5).timeout
	soldier.take_hit(1.0e9, player.global_position)
	await create_timer(3.0).timeout
	await _shot(out + "/countdown.png")
	quit()
