extends "res://tests/check_meadow_traversal.gd"

## Steps off both sides of every ramp at several heights and wanders around
## the ramp tops and the terrace shrine. The hero must never end up inside a
## plateau (below its top surface while within its outline) or get stuck.

func _run() -> void:
	field = (load(FIELD) as PackedScene).instantiate()
	root.add_child(field)
	await create_timer(0.5).timeout
	_set_auto_attack(false)
	var problems := []
	for plateau in Layout.PLATEAUS:
		for spec in plateau.ramps:
			var along: Vector2 = (spec.top - spec.bottom).normalized()
			var across := Vector2(-along.y, along.x)
			for t in [0.55, 0.7, 0.8, 0.9, 1.0]:
				for side in [-1.0, 1.0]:
					var start: Vector2 = spec.bottom.lerp(spec.top, t)
					await _place(Vector3(start.x, 0, start.y))
					_steer(across * side)
					for frame in 50:
						await physics_frame
					_steer(along)
					for frame in 30:
						await physics_frame
					_release()
					for frame in 20:
						await physics_frame
					var here: Vector3 = field.player.global_position
					if _inside_plateau(here):
						problems.append("%s ramp t=%.2f side %d: inside plateau at %s" % [plateau.name, t, side, here])
	for area in [Rect2(-65.4, -69.7, 35, 35), Rect2(-40, -60, 30, 40), Rect2(-82, -100.6, 26, 30), Rect2(71.6, -14.8, 22, 22)]:
		await _place(Vector3(area.get_center().x, 0, area.get_center().y))
		var random := RandomNumberGenerator.new()
		random.seed = 9
		var direction := Vector2.RIGHT
		var still := 0
		var last: Vector3 = field.player.global_position
		for frame in 60 * 120:
			var flat := Vector2(field.player.global_position.x, field.player.global_position.z)
			if not area.has_point(flat):
				direction = (area.get_center() - flat).normalized()
			elif random.randf() < 0.03:
				direction = Vector2.from_angle(random.randf() * TAU)
			_steer(direction)
			await physics_frame
			var here: Vector3 = field.player.global_position
			if _inside_plateau(here):
				problems.append("wander %s: inside plateau at %s" % [area, here])
				break
			still = still + 1 if here.distance_to(last) < 0.05 else 0
			last = here
			if still > 30:
				if await _open_directions(here) == 0:
					problems.append("wander %s: stuck at %s" % [area, here])
					break
				still = 0
				direction = Vector2.from_angle(random.randf() * TAU)
		_release()
	if problems.is_empty():
		print("PASS ramp edges and shrine: never inside a plateau, never stuck")
	else:
		for problem in problems.slice(0, 20):
			printerr("FAIL ", problem)
	print("RESULT: ", "PASS" if problems.is_empty() else "FAIL (%d)" % problems.size())
	quit(1 if not problems.is_empty() else 0)

## True when standing within a plateau's outline but well below its top.
func _inside_plateau(here: Vector3) -> bool:
	for plateau in Layout.PLATEAUS:
		var outline := PackedVector2Array(plateau.outline)
		var point := Vector2(here.x, here.z)
		if Geometry2D.is_point_in_polygon(point, outline) and here.y < plateau.height - 1.5 and here.y > plateau.base - 0.5:
			if not _on_any_ramp(point):
				return true
	return false

func _on_any_ramp(point: Vector2) -> bool:
	for plateau in Layout.PLATEAUS:
		for spec in plateau.ramps:
			if Geometry2D.get_closest_point_to_segment(point, spec.bottom, spec.top).distance_to(point) < spec.width * 0.5 + 0.5:
				return true
	return false
