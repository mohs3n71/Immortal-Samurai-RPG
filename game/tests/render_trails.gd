extends SceneTree

## Renders each combo trail style from the game camera angle, unfaded (D-075).
## Usage: --script res://tests/render_trails.gd -- <out.png>

const SlashFx = preload("res://scripts/slash_fx.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var world := Node3D.new()
	root.add_child(world)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color("6f9a55")
	world.add_child(environment)
	var styles := ["sweep_left", "sweep_right", "rise", "slam"]
	for index in styles.size():
		var holder := Node3D.new()
		holder.position = Vector3(index * 16.0 - 24.0, 0, 0)
		world.add_child(holder)
		var marker := MeshInstance3D.new()
		marker.mesh = BoxMesh.new()
		marker.mesh.size = Vector3(1, 6, 1)
		marker.position.y = 3
		holder.add_child(marker)
		var nose := MeshInstance3D.new()
		nose.mesh = BoxMesh.new()
		nose.mesh.size = Vector3(0.6, 0.6, 3)
		nose.position = Vector3(0, 5, 1.5)
		holder.add_child(nose)
		var trail := MeshInstance3D.new()
		trail.mesh = SlashFx._trail_mesh(styles[index])
		var material := SlashFx._fade_material()
		trail.material_override = material
		holder.add_child(trail)
	var camera := Camera3D.new()
	world.add_child(camera)
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 70
	camera.position = Vector3(24, 28.4, 24) * 3.0
	camera.look_at(Vector3.ZERO)
	camera.current = true
	await create_timer(0.3).timeout
	RenderingServer.force_draw()
	root.get_texture().get_image().save_png(OS.get_cmdline_user_args()[0])
	quit()
