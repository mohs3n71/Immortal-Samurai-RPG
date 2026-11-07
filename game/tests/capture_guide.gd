extends SceneTree

## Screenshots of the guide to the boss (D-090): from the village, half way,
## and in front of the boss (pointer hidden). Usage: -- <out_dir>

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var out: String = OS.get_cmdline_user_args()[0]
	var progression = load("res://scripts/progression.gd")
	progression.persist = false
	progression.reset()
	var field := (load("res://scenes/meadow.tscn") as PackedScene).instantiate()
	root.add_child(field)
	await create_timer(1.0).timeout
	var player: CharacterBody3D = field.player
	player.get_node("AutoAttack").set_physics_process(false)
	var guide: Control = field.find_child("GuidePointer", true, false)
	var boss: Node3D = field.find_child("RegionBoss", true, false)
	for spot in [["village", Vector3(2, 1, 2)], ["west", Vector3(-60, 1, -20)], ["near", boss.home + Vector3(0, 1, 26)]]:
		player.revive(spot[1])
		await create_timer(0.8).timeout
		RenderingServer.force_draw()
		root.get_texture().get_image().save_png("%s/guide-%s.png" % [out, spot[0]])
		print("CAPTURED ", spot[0], " pointer at ", guide.shown_at)
	quit()
