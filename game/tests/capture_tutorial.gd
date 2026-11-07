extends SceneTree

## Screenshots of every tutorial step and the quest card (D-094), driving the
## steps by completing each condition. Usage (windowed): -- <out_dir>

func _initialize() -> void:
	call_deferred("_run")

func _shot(out: String, name: String) -> void:
	await create_timer(0.7).timeout
	RenderingServer.force_draw()
	root.get_texture().get_image().save_png("%s/%s.png" % [out, name])
	print("CAPTURED ", name)

func _run() -> void:
	var out: String = OS.get_cmdline_user_args()[0]
	var progression = load("res://scripts/progression.gd")
	progression.persist = false
	progression.reset()
	var field := (load("res://scenes/meadow.tscn") as PackedScene).instantiate()
	root.add_child(field)
	await create_timer(1.2).timeout
	var tutorial: Control = field.find_child("Tutorial", true, false)
	var player: CharacterBody3D = field.player
	player.get_node("AutoAttack").set_physics_process(false)
	for index in tutorial.steps.size():
		await _shot(out, "step%02d" % index)
		var data: Dictionary = tutorial.steps[index]
		if data.kind != "task":
			tutorial._next()
			continue
		# Satisfy the step's condition directly.
		match index:
			2: player.global_position += Vector3(10, 0, 0)
			3: player.revive(tutorial._enemy("blood-knight").global_position + Vector3(0, 1, 8))
			4: progression.hero_fell()
			5: progression.blood_knight_defeated()
			6:
				player.revive(tutorial._enemy("plague-knight").global_position + Vector3(0, 1, 14))
				await _shot(out, "step06-near")
				progression.plague_knight_defeated()
			7:
				player.revive(Vector3(30, 1, 30))
				await _shot(out, "step07-offscreen")
				progression.reaper_strike()
			8: progression.add_experience(10)
		await create_timer(1.8).timeout
	await create_timer(1.5).timeout
	await _shot(out, "quest")
	quit()
