extends SceneTree

# Captures field screenshots at several player positions.
# Usage: godot --path game --script res://tests/capture_field_views.gd -- <scene> <out_dir> x,z [x,z ...]

func _initialize() -> void:
	call_deferred("_capture")

func _capture() -> void:
	var args := OS.get_cmdline_user_args()
	var scene_path: String = args[0] if args.size() > 0 else "res://scenes/meadow.tscn"
	var output: String = args[1] if args.size() > 1 else "/tmp/field-views"
	var points: Array = args.slice(2) if args.size() > 2 else ["0,0"]
	DirAccess.make_dir_recursive_absolute(output)
	_ensure_selection()
	var field := (load(scene_path) as PackedScene).instantiate()
	root.add_child(field)
	await create_timer(0.5).timeout
	for point: String in points:
		var parts := point.split(",")
		var target := Vector3(float(parts[0]), 0.0, float(parts[1]))
		field.player.global_position = target + Vector3(0, 14.0, 0)
		field.player.velocity = Vector3.ZERO
		await create_timer(1.2).timeout
		RenderingServer.force_draw()
		var file := output.path_join("view_%s_%s.png" % [parts[0], parts[1]])
		root.get_texture().get_image().save_png(file)
		print("CAPTURED ", file, " player at ", field.player.global_position)
	quit()

func _ensure_selection() -> void:
	if root.get_node_or_null("HeroSelection") != null:
		return
	var selection := Node.new()
	selection.name = "HeroSelection"
	selection.set_script(load("res://scripts/hero_selection.gd"))
	root.add_child(selection)
