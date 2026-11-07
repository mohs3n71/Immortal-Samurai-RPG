extends SceneTree

## Screenshots of the gateway between the Meadowlands and the Frostlands
## (D-102). Args: x z [out.png] [top] — "top" renders a high top-down view.

const Progression = preload("res://scripts/progression.gd")

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	Progression.ensure_loaded()
	Progression.reset()
	Progression.tutorial_done = true
	Progression.bosses_defeated = 0 if OS.get_cmdline_user_args().has("sealed") else 1
	var field: Node = (load("res://scenes/meadow.tscn") as PackedScene).instantiate()
	root.add_child(field)
	current_scene = field
	await process_frame
	field.player.revive(Vector3(float(args[0]), 2, float(args[1])))
	if args.has("nobosses"):
		for node in field.get_children():
			if String(node.name).begins_with("RegionBoss"):
				node.queue_free()
	if args.has("hide"):
		field.player.get_node("Visual").visible = false
	if args.has("close"):
		field.camera.size = 30.0
	if args.has("top"):
		field.set_process(false)
		field.camera.position = field.player.position + Vector3(0, 200, 0.01)
		field.camera.look_at(field.player.position)
		field.camera.size = float(args[4]) if args.size() > 4 else 160.0
		field.camera.far = 1000.0
	for i in 40:
		await process_frame
	var image := root.get_texture().get_image()
	image.save_png(args[2] if args.size() > 2 and not args[2] == "top" else "/tmp/gateway.png")
	print("region ", field.region, " player ", field.player.global_position)
	quit()
