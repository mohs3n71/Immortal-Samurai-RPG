extends SceneTree

## Screenshots for D-104: the minimap with the Reaper and knight portraits, and
## the fast travel combat lock with its notice. Args: out.png [fight]

const Progression = preload("res://scripts/progression.gd")

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	Progression.ensure_loaded()
	Progression.reset()
	Progression.persist = false
	Progression.tutorial_done = true
	var field: Node = (load("res://scenes/meadow.tscn") as PackedScene).instantiate()
	root.add_child(field)
	current_scene = field
	await process_frame
	if args.has("fight"):
		# Beside the soldiers of the clearing south-west of the village.
		field.player.revive(Vector3(-46, 2, 40))
		for i in 90:
			await process_frame
		field.fast_travel()
		for i in 20:
			await process_frame
	else:
		field.player.revive(Vector3(-40, 2, -40))
		for i in 30:
			await process_frame
	root.get_texture().get_image().save_png(args[0])
	print("combat ", field.in_combat())
	quit()
