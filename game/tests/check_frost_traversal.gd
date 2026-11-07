extends "res://tests/check_meadow_traversal.gd"

## Frostlands walking test (D-100): the mirrored ground plan must be as
## walkable as the Meadowlands. Same checks with mirrored coordinates: ramp
## and bridge routes, water, cliffs and the map edge block, every path walks
## both ways, and no trap anywhere (the farm and woods scanned finely).
## D-102: the Frostlands is part of the one world now (loaded with the
## Meadowlands, north of the gateway); the coordinates below are its own,
## shifted by Travel.OFFSETS[2] here.

const FrostLayout = preload("res://tools/frost_layout.gd")
const Travel = preload("res://scripts/world/travel.gd")
var OFFSET: Vector2 = Travel.OFFSETS[2]
var OFFSET3 := Vector3(OFFSET.x, 0, OFFSET.y)

func _run() -> void:
	var progression = load("res://scripts/progression.gd")
	progression.persist = false
	progression.reset()
	progression.tutorial_done = true
	field = (load("res://scenes/meadow.tscn") as PackedScene).instantiate()
	root.add_child(field)
	await create_timer(0.5).timeout
	_set_auto_attack(false)
	await _expect_route("spawn to frost terrace via ramp", Vector3(-4, 0, 8), [Vector2(18, -24), Vector2(35.5, -48.5), Vector2(50, -58)], 7.5)
	await _expect_route("camp across bridge to the lodge camp", Vector3(-20, 0, -9), [Vector2(-33, -18), Vector2(-44.3, -24.5), Vector2(-53.4, -37.9), Vector2(-55.8, -49.1)], -1.0)
	await _expect_blocked("frozen stream blocks wading", Vector3(-32, 0, -4), Vector2(-1, 0), func(p: Vector3): return p.x > -44.0)
	await _expect_blocked("pond blocks wading", Vector3(-30.5, 0, 41.3), Vector2(-1, 0), func(p: Vector3): return p.x > -40.5)
	await _expect_blocked("terrace cliff blocks climbing", Vector3(40, 0, -30), Vector2(0, -1), func(p: Vector3): return p.y < 1.0)
	await _expect_blocked("north border cliff", Vector3(0, 0, -107), Vector2(0, -1), func(p: Vector3): return p.z > -(FrostLayout.PLAY_HALF + 4.0))
	await _expect_blocked("west edge", Vector3(-107, 0, -71.4), Vector2(-1, 0), func(p: Vector3): return p.x >= -FrostLayout.PLAY_HALF - 0.01)
	await _expect_blocked("lake blocks wading", Vector3(-64.6, 0, 91.8), Vector2(-1, 0), func(p: Vector3): return p.x > -73.5)
	await _expect_blocked("upper terrace cliff blocks climbing", Vector3(73.5, 8, -73.5), Vector2(1, -1).normalized(), func(p: Vector3): return p.y < 9.0)
	await _expect_blocked("east plateau cliff blocks climbing", Vector3(-79, 0, 22.8), Vector2(-1, 0), func(p: Vector3): return p.y < 1.0)
	for index in FrostLayout.PATHS.size():
		await _expect_frost_path_walkable(index)
	await _expect_no_traps()
	await _expect_no_traps(Vector2(21.1, 24.4), Vector2(61.9, 63.2), 1.5)
	await _expect_no_traps(Vector2(70.5, 0), Vector2(116.8, 64.2), 3.0)
	print("RESULT: ", "PASS" if failures == 0 else "FAIL (%d)" % failures)
	quit(1 if failures > 0 else 0)

func _expect_frost_path_walkable(index: int) -> void:
	var points: Array = []
	for point: Vector2 in FrostLayout.PATHS[index][1]:
		points.append(point.clamp(Vector2.ONE * -(FrostLayout.PLAY_HALF - 2.0), Vector2.ONE * (FrostLayout.PLAY_HALF - 2.0)))
	for direction in ["forward", "back"]:
		var route := points.duplicate()
		if direction == "back":
			route.reverse()
		await _expect_route("path %d %s" % [index, direction], Vector3(route[0].x, 0, route[0].y), route.slice(1), -1.0)

# --- Region-local coordinates (D-102) ----------------------------------------

func _place(at: Vector3) -> void:
	await super._place(at + OFFSET3)

func _walk_to(target: Vector2, timeout: float) -> bool:
	return await super._walk_to(target + OFFSET, timeout)

func _expect_blocked(label: String, start: Vector3, direction: Vector2, still_ok: Callable) -> void:
	await super._expect_blocked(label, start, direction, func(p: Vector3): return still_ok.call(p - OFFSET3))

func _free_spot(point: Vector2) -> Variant:
	return await super._free_spot(point + OFFSET)
