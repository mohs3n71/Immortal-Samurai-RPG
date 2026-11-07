extends SceneTree

# Renders a labelled grid of environment props for visual selection.
# Usage: godot --path game --script res://tests/capture_prop_sheet.gd -- <out.png> name [name ...]

const PROP_ROOT := "res://assets/environment/butcher-props/"
const CELL := 12.0
const COLUMNS := 6

func _initialize() -> void:
	call_deferred("_capture")

func _capture() -> void:
	var args := OS.get_cmdline_user_args()
	var output: String = args[0]
	var names: Array = args.slice(1)
	var world := Node3D.new()
	root.add_child(world)
	_add_lighting(world)
	for index in names.size():
		var spot := Vector3((index % COLUMNS) * CELL, 0, (index / COLUMNS) * CELL)
		_add_prop(world, names[index], spot)
	var rows := ceili(names.size() / float(COLUMNS))
	var center := Vector3((COLUMNS - 1) * CELL / 2.0, 0, (rows - 1) * CELL / 2.0)
	var camera := Camera3D.new()
	world.add_child(camera)
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = rows * CELL * 1.25
	camera.position = center + Vector3(0, 40, 40)
	camera.look_at(center)
	camera.current = true
	await create_timer(0.3).timeout
	RenderingServer.force_draw()
	root.get_texture().get_image().save_png(output)
	quit()

func _add_lighting(world: Node3D) -> void:
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color("6d8f5a")
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color.WHITE
	environment.environment.ambient_light_energy = 0.6
	world.add_child(environment)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, -35, 0)
	world.add_child(sun)

func _add_prop(world: Node3D, asset_name: String, spot: Vector3) -> void:
	var mesh := load(PROP_ROOT + asset_name + ".obj") as Mesh
	var bounds := mesh.get_aabb()
	var factor := 8.0 / maxf(bounds.size.y, maxf(bounds.size.x, bounds.size.z))
	var model := MeshInstance3D.new()
	model.mesh = mesh
	model.scale = Vector3.ONE * factor
	model.position = spot - Vector3(bounds.get_center().x, bounds.position.y, bounds.get_center().z) * factor
	world.add_child(model)
	var label := Label3D.new()
	label.text = "%s\n%.1fx%.1fx%.1f" % [asset_name, bounds.size.x, bounds.size.y, bounds.size.z]
	label.font_size = 64
	label.pixel_size = 0.02
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position = spot + Vector3(0, 0.2, 5.0)
	label.modulate = Color.BLACK
	world.add_child(label)
