extends SceneTree

# Renders a top-down orthographic overview of a world scene.
# Usage: godot --path game --script res://tests/capture_overview.gd -- <world.tscn> <out.png> [size] [palette]

func _initialize() -> void:
	call_deferred("_capture")

func _capture() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 3:
		# Region colours for generated trees and cliffs (D-100: "frost").
		load("res://scripts/world/stylized_meshes.gd").palette = args[3]
		load("res://scripts/world/terrain_block.gd").palette = args[3]
	var world := (load(args[0]) as PackedScene).instantiate()
	root.add_child(world)
	var camera := Camera3D.new()
	root.add_child(camera)
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = float(args[2]) if args.size() > 2 else 190.0
	camera.position = Vector3(0, 200, 0.01)
	camera.look_at(Vector3.ZERO, Vector3.FORWARD)
	camera.far = 500.0
	camera.current = true
	await create_timer(1.0).timeout
	RenderingServer.force_draw()
	root.get_texture().get_image().save_png(args[1])
	quit()
