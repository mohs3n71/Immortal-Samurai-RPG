extends "res://tests/check_meadow_traversal.gd"

## Rough relative render cost (D-076): average wall time of forced draws at
## busy spots, portrait. Only meaningful compared with another run on the same
## machine. Env: BENCH_SCALE (3D render scale, default 1.0).
## Usage: godot --path game --resolution 720x1280 --script res://tests/bench_render_time.gd

const SPOTS := [Vector3(4, 0, 8), Vector3(-50, 8, -60), Vector3(60, 0, -60), Vector3(-45, 0, 45), Vector3(-124, 0, 26), Vector3(80, 0, 136)]
const FRAMES := 12

func _run() -> void:
	field = (load(FIELD) as PackedScene).instantiate()
	root.add_child(field)
	await create_timer(0.8).timeout
	_set_auto_attack(false)
	var scale := float(OS.get_environment("BENCH_SCALE")) if OS.has_environment("BENCH_SCALE") else 1.0
	root.scaling_3d_scale = scale
	var total := 0.0
	for spot in SPOTS:
		field.player.global_position = spot + Vector3(0, 1, 0)
		await process_frame
		await process_frame
		RenderingServer.force_draw()
		var start := Time.get_ticks_usec()
		for frame in FRAMES:
			RenderingServer.force_draw()
		var average := (Time.get_ticks_usec() - start) / 1000.0 / FRAMES
		total += average
		print("spot %s  %.1f ms" % [spot, average])
	print("BENCH scale=%.2f vertex_shading=%s mean=%.1f ms" % [scale, ProjectSettings.get_setting("rendering/shading/overrides/force_vertex_shading", false), total / SPOTS.size()])
	quit()
