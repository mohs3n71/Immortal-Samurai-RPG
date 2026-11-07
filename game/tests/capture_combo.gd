extends SceneTree

## Captures frames while the hero runs a full combo on a training dummy (D-075).
## Usage: --script res://tests/capture_combo.gd -- <out_prefix>

const FIELD := "res://scenes/meadow.tscn"

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var prefix: String = OS.get_cmdline_user_args()[0]
	var field := (load(FIELD) as PackedScene).instantiate()
	root.add_child(field)
	await create_timer(0.5).timeout
	var player: CharacterBody3D = field.player
	var target: Node3D = root.get_tree().get_nodes_in_group("enemies")[0]
	player.global_position = target.global_position + Vector3(-2.8, 0.5, 2.6)
	var attacker: Node = player.get_node("AutoAttack")
	var shots := 0
	var seen := {}
	for frame in 400:
		await process_frame
		var clip: String = player.visual.current_clip if player.visual.is_attacking else ""
		if clip.begins_with("slash") and not seen.has(clip):
			var hit: float = 0.0
			for step in player.visual.combo_steps():
				if step.clip == clip:
					hit = float(step.hit)
			if player.visual.attack_position() >= hit + 0.01:
				seen[clip] = true
				RenderingServer.force_draw()
				root.get_texture().get_image().save_png("%s_%s.png" % [prefix, clip])
				shots += 1
		if shots >= 4:
			break
	print("captured ", shots, " log ", attacker.swing_log)
	quit()
