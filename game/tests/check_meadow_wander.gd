extends "res://tests/check_meadow_traversal.gd"

## Random-walk stress test: wanders with held joystick input and reports any
## reachable spot where the hero cannot move in any of eight directions, or
## ends up standing on top of a prop.
## Usage: godot --headless --fixed-fps 60 --path game --script res://tests/check_meadow_wander.gd -- [seconds] [min_x min_z max_x max_z]

func _run() -> void:
	var selection := Node.new()
	selection.name = "HeroSelection"
	selection.set_script(load("res://scripts/hero_selection.gd"))
	root.add_child(selection)
	field = (load(FIELD) as PackedScene).instantiate()
	root.add_child(field)
	await create_timer(0.5).timeout
	_set_auto_attack(false)
	var args := Array(OS.get_cmdline_user_args()).filter(func(arg: String) -> bool: return arg.is_valid_float())
	var seconds := float(args[0]) if args.size() > 0 else 240.0
	var area := Rect2(-80, -80, 160, 160)
	if args.size() > 4:
		area = Rect2(float(args[1]), float(args[2]), float(args[3]) - float(args[1]), float(args[4]) - float(args[2]))
		await _place(Vector3(area.get_center().x, 0, area.get_center().y))
	var random := RandomNumberGenerator.new()
	random.seed = 4242
	var problems := []
	var elapsed := 0.0
	var direction := Vector2.RIGHT
	var still_frames := 0
	var last: Vector3 = field.player.global_position
	while elapsed < seconds:
		var flat := Vector2(field.player.global_position.x, field.player.global_position.z)
		if not area.has_point(flat):
			direction = (area.get_center() - flat).normalized()
		elif random.randf() < 0.025:
			direction = Vector2.from_angle(random.randf() * TAU)
		_steer(direction)
		await physics_frame
		elapsed += 1.0 / 60.0
		var here: Vector3 = field.player.global_position
		still_frames = still_frames + 1 if here.distance_to(last) < 0.05 else 0
		last = here
		if _on_prop(here):
			problems.append("on top of a prop at %s" % here)
			await _place(here + Vector3(4, 0, 4))
		if still_frames > 30:
			if await _open_directions(here) == 0:
				problems.append("stuck at %s" % here)
				await _place(Vector3(area.get_center().x, 0, area.get_center().y))
			elif not field.player.is_on_wall():
				# Nudge off ground seams, but never up the side of a prop (D-093).
				field.player.global_position = here + Vector3(0, 0.1, 0)
			direction = Vector2.from_angle(random.randf() * TAU)
			still_frames = 0
	_release()
	if problems.is_empty():
		print("PASS wandered %d seconds without getting stuck or climbing props" % seconds)
	else:
		_fail("wander", "\n".join(problems.slice(0, 20)))
	print("RESULT: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures > 0 else 0)

## True when the hero stands above the ground on something other than the terrace, ramp or bridge.
func _on_prop(here: Vector3) -> bool:
	if here.y < 0.6 or not field.player.is_on_floor():
		return false
	var space := field.get_world_3d().direct_space_state
	var ray := PhysicsRayQueryParameters3D.create(here + Vector3.UP, here + Vector3.DOWN * 2.0)
	ray.exclude = [field.player.get_rid()]
	var hit := space.intersect_ray(ray)
	if hit.is_empty():
		return false
	var owner_node: Node = hit.collider.get_parent()
	return owner_node != null and owner_node.get_script() == load("res://scripts/world/field_prop.gd")
