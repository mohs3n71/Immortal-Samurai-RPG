extends SceneTree

## Drives the hero through the Meadowlands with simulated joystick input:
## reachable routes (ramp to terrace, bridge) must succeed; water, cliffs and
## the map edge must block. Also prints rendering cost at a few spots.

const FIELD := "res://scenes/meadow.tscn"
const Layout = preload("res://tools/meadow_layout.gd")
const TRAP_GRID := 8.0

var field: Node3D
var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var progression = load("res://scripts/progression.gd")
	progression.persist = false
	progression.reset()
	var selection := Node.new()
	selection.name = "HeroSelection"
	selection.set_script(load("res://scripts/hero_selection.gd"))
	root.add_child(selection)
	field = (load(FIELD) as PackedScene).instantiate()
	root.add_child(field)
	await create_timer(0.5).timeout
	# Route and trap checks test the map, not combat: pause auto-attack and the
	# soldiers (D-078) so fighting is not mistaken for being stuck.
	_set_auto_attack(false)
	# Coordinates follow the D-093 smaller map (tools/shrink_layout.py warp).
	await _expect_route("spawn to terrace shrine via ramp", Vector3(4, 0, 8), [Vector2(-18, -24), Vector2(-35.5, -48.5), Vector2(-50, -58)], 7.5)
	await _expect_route("village across bridge to woodcutter camp", Vector3(20, 0, -9), [Vector2(33, -18), Vector2(44.3, -24.5), Vector2(53.4, -37.9), Vector2(55.8, -49.1)], -1.0)
	await _expect_blocked("stream blocks wading", Vector3(32, 0, -4), Vector2(1, 0), func(p: Vector3): return p.x < 44.0)
	await _expect_blocked("pond blocks wading", Vector3(30.5, 0, 41.3), Vector2(1, 0), func(p: Vector3): return p.x < 40.5)
	await _expect_blocked("terrace cliff blocks climbing", Vector3(-40, 0, -30), Vector2(0, -1), func(p: Vector3): return p.y < 1.0)
	await _expect_blocked("north border cliff", Vector3(0, 0, -107), Vector2(0, -1), func(p: Vector3): return p.z > -(Layout.PLAY_HALF + 4.0))
	await _expect_blocked("east edge", Vector3(107, 0, -71.4), Vector2(1, 0), func(p: Vector3): return p.x <= Layout.PLAY_HALF + 0.01)
	await _expect_blocked("lake blocks wading", Vector3(64.6, 0, 91.8), Vector2(1, 0), func(p: Vector3): return p.x < 73.5)
	await _expect_blocked("upper terrace cliff blocks climbing", Vector3(-73.5, 8, -73.5), Vector2(-1, -1).normalized(), func(p: Vector3): return p.y < 9.0)
	await _expect_blocked("east plateau cliff blocks climbing", Vector3(79, 0, 22.8), Vector2(1, 0), func(p: Vector3): return p.y < 1.0)
	# Route and trap checks test the map, not combat: pause auto-attack so
	# swinging at training dummies is not mistaken for being stuck.
	_set_auto_attack(false)
	for index in Layout.PATHS.size():
		await _expect_path_walkable(index)
	await _expect_no_traps()
	# The farm is the most crowded area (user report 2026-11-05): scan it finely.
	await _expect_no_traps(Vector2(-61.9, 24.4), Vector2(-21.1, 63.2), 1.5)
	# Densest generated woods.
	await _expect_no_traps(Vector2(-116.8, 0), Vector2(-70.5, 64.2), 3.0)
	if DisplayServer.get_name() != "headless":
		await _report_cost([Vector3(4, 0, 8), Vector3(-43.5, 8, -52.2), Vector3(52.2, 0, -52.2), Vector3(-43, 0, 43), Vector3(-91.2, 0, 19.1), Vector3(86.3, 0, -81.8), Vector3(57.9, 0, 98.5), Vector3(-96, 15, -104.6)])
	print("RESULT: ", "PASS" if failures == 0 else "FAIL (%d)" % failures)
	quit(1 if failures > 0 else 0)

func _set_auto_attack(enabled: bool) -> void:
	# Never touch the player's saved progression from a test (D-080).
	var progression = load("res://scripts/progression.gd")
	if progression.persist:
		progression.persist = false
		progression.reset()
	var attacker: Node = field.player.get_node_or_null("AutoAttack")
	if attacker != null:
		attacker.set_physics_process(enabled)
	for enemy in field.get_tree().get_nodes_in_group("enemies"):
		if enemy.has_method("reset_to_home"):
			enemy.set_physics_process(enabled)
	# Frozen enemies stand on the paths; this test checks the ground, so
	# Kaze may walk through their bodies here (D-087).
	for body in field.get_tree().get_nodes_in_group("bodies") + field.get_tree().get_nodes_in_group("walk_test_ghosts"):
		if enabled:
			body.remove_from_group("walk_test_ghosts")
			body.add_to_group("bodies")
		else:
			body.remove_from_group("bodies")
			body.add_to_group("walk_test_ghosts")

## Every dirt path must be walkable end to end in both directions.
func _expect_path_walkable(index: int) -> void:
	var points: Array = []
	for point: Vector2 in Layout.PATHS[index][1]:
		points.append(point.clamp(Vector2.ONE * -(Layout.PLAY_HALF - 2.0), Vector2.ONE * (Layout.PLAY_HALF - 2.0)))
	for direction in ["forward", "back"]:
		var route := points.duplicate()
		if direction == "back":
			route.reverse()
		await _expect_route("path %d %s" % [index, direction], Vector3(route[0].x, 0, route[0].y), route.slice(1), -1.0)

## From every free spot on a grid, the hero must be able to move away in at
## least three of eight directions; otherwise it is a trap between objects.
func _expect_no_traps(low := Vector2.ONE * -(Layout.PLAY_HALF - 3.0), high := Vector2.ONE * (Layout.PLAY_HALF - 3.0), grid := TRAP_GRID) -> void:
	var traps := []
	var x := low.x
	while x <= high.x:
		var z := low.y
		while z <= high.y:
			var spot: Variant = await _free_spot(Vector2(x, z))
			if spot != null and await _open_directions(spot) < 3:
				traps.append(Vector2(spot.x, spot.z))
			z += grid
		x += grid
	if traps.is_empty():
		print("PASS no trapping pockets on a %.1f-unit grid in %s..%s" % [grid, low, high])
	else:
		_fail("trapping pockets", str(traps))

## A spot on a walkable surface (ground, plateau, ramp, bridge) with room for the hero.
func _free_spot(point: Vector2) -> Variant:
	var space := field.get_world_3d().direct_space_state
	var ray := PhysicsRayQueryParameters3D.create(Vector3(point.x, 40, point.y), Vector3(point.x, -1, point.y))
	ray.exclude = [field.player.get_rid()]
	var hit := space.intersect_ray(ray)
	if hit.is_empty():
		return null
	var owner_node: Node = hit.collider.get_parent()
	if owner_node == null or not _is_walkable_surface(owner_node):
		return null
	var ground: float = hit.position.y
	var query := PhysicsShapeQueryParameters3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 1.3
	capsule.height = 3.0
	query.shape = capsule
	query.transform = Transform3D(Basis.IDENTITY, Vector3(point.x, ground + 1.6, point.y))
	query.exclude = [field.player.get_rid()]
	if not space.intersect_shape(query, 1).is_empty():
		return null
	return Vector3(point.x, ground, point.y)

func _is_walkable_surface(node: Node) -> bool:
	var walkable_names := ["Ground", "Terrace", "UpperTerrace", "EastPlateau"]
	return node.name in walkable_names or String(node.name).contains("Ramp") or String(node.name).begins_with("Bridge")

func _open_directions(spot: Vector3) -> int:
	var open := 0
	for step in 8:
		field.player.global_position = spot + Vector3(0, 0.1, 0)
		field.player.velocity = Vector3.ZERO
		await physics_frame
		_steer(Vector2.from_angle(step * TAU / 8.0))
		for frame in 8:
			await physics_frame
		_release()
		var moved := Vector2(field.player.global_position.x - spot.x, field.player.global_position.z - spot.z).length()
		if moved > 2.0:
			open += 1
	return open

## Drops the hero onto the highest walkable surface at this XZ position.
func _place(at: Vector3) -> void:
	var space := field.get_world_3d().direct_space_state
	var ray := PhysicsRayQueryParameters3D.create(Vector3(at.x, 30, at.z), Vector3(at.x, -1, at.z))
	ray.exclude = [field.player.get_rid()]
	var hit := space.intersect_ray(ray)
	var ground: float = hit.position.y if not hit.is_empty() else 0.0
	field.player.global_position = Vector3(at.x, ground + 0.5, at.z)
	field.player.velocity = Vector3.ZERO
	await create_timer(0.3).timeout

func _expect_route(label: String, start: Vector3, waypoints: Array, minimum_end_height: float) -> void:
	await _place(start)
	for waypoint: Vector2 in waypoints:
		var reached := await _walk_to(waypoint, 6.0)
		if not reached:
			_fail(label, "stuck before %s at %s" % [waypoint, field.player.global_position])
			_release()
			return
	_release()
	if minimum_end_height >= 0.0 and field.player.global_position.y < minimum_end_height:
		_fail(label, "ended too low: %s" % field.player.global_position)
		return
	print("PASS ", label, " -> ", field.player.global_position)

func _expect_blocked(label: String, start: Vector3, direction: Vector2, still_ok: Callable) -> void:
	await _place(start)
	_steer(direction)
	var ok := true
	for frame in 150:
		await physics_frame
		if not still_ok.call(field.player.global_position):
			ok = false
			break
	_release()
	if ok:
		print("PASS ", label, " -> held at ", field.player.global_position)
	else:
		_fail(label, "passed through to %s" % field.player.global_position)

func _walk_to(target: Vector2, timeout: float) -> bool:
	var elapsed := 0.0
	while elapsed < timeout:
		var here := Vector2(field.player.global_position.x, field.player.global_position.z)
		if here.distance_to(target) < 2.0:
			return true
		_steer((target - here).normalized())
		await physics_frame
		elapsed += 1.0 / Engine.physics_ticks_per_second
	return false

## Converts a world-space XZ direction into the camera-relative joystick input.
func _steer(world: Vector2) -> void:
	var right: Vector3 = field.camera.global_basis.x
	var forward: Vector3 = -field.camera.global_basis.z
	var right_flat := Vector2(right.x, right.z).normalized()
	var forward_flat := Vector2(forward.x, forward.z).normalized()
	field.player.joystick.direction = Vector2(world.dot(right_flat), -world.dot(forward_flat))

func _release() -> void:
	field.player.joystick.direction = Vector2.ZERO

func _report_cost(spots: Array) -> void:
	for spot: Vector3 in spots:
		await _place(spot)
		await process_frame
		await process_frame
		var primitives := Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)
		var draws := Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
		var objects := Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME)
		print("COST at %s: %d triangles, %d draw calls, %d objects" % [spot, primitives, draws, objects])

func _fail(label: String, detail: String) -> void:
	failures += 1
	printerr("FAIL ", label, ": ", detail)
