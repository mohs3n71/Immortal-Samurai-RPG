extends RefCounted

## One world, several regions (D-102). The Meadowlands sit round the origin;
## the Frostlands lie north of them and are reached on foot through the
## gateway behind the Bone Warlord, which opens when he falls. Fast travel to
## the start area (Reaper and knights) and the return portal back to where
## Kaze was are in-world teleports.

const Progression = preload("res://scripts/progression.gd")

## The whole world lives in this scene.
const WORLD_SCENE := "res://scenes/meadow.tscn"
const NAMES := {1: "Meadowlands", 2: "Frostlands"}
## Where each region's own layout is placed in the world (x, z). Region
## layouts (enemy roster, arenas, gates) are authored around their own origin.
const OFFSETS := {1: Vector2.ZERO, 2: Vector2(62, -268)}
## Extra world scenes loaded next to region 1's (which the field scene brings).
const WORLDS := {2: "res://scenes/world/frost_world.tscn"}
## Generated-mesh colours per region.
const PALETTES := {1: "meadow", 2: "frost"}
## North of this line is the Frostlands (the seam inside the gateway).
const BORDER_Z := -134.0
## Where Kaze stands when the game starts in a region (region 2: just inside
## the gateway).
const ENTRIES := {1: Vector3(0, 1, 4), 2: Vector3(62, 1, -172)}
## Fast travel lands here in region 1, by the village square between the
## Reaper, Blood Knight and Plague Knight; the return portal stands nearby.
const START_ARRIVAL := Vector3(6, 0, 4)
const PORTAL_SPOT := Vector3(-3, 0, -7)
## Walkable ground: each region's play square and the gateway corridor.
const AREAS := [
	Rect2(-118, -118, 236, 236),
	Rect2(55, -152, 14, 36),
	Rect2(-56, -386, 236, 236),
]

static func has_region(region: int) -> bool:
	return OFFSETS.has(region)

static func offset(region: int) -> Vector2:
	return OFFSETS.get(region, Vector2.ZERO)

## A region-local point (x, z) in world space.
static func to_world(region: int, local: Vector2) -> Vector2:
	return local + offset(region)

static func region_at(position: Vector3) -> int:
	return 2 if position.z < BORDER_Z else 1

## The goal the guide points at (D-090): the first unbeaten boss, or the open
## gate Kaze has not walked through yet, in region order.
static func guide_target(tree: SceneTree) -> Node3D:
	var best: Node3D = null
	var best_order := 1 << 30
	# Bosses already beaten (order 2 x region) are passed over.
	var first := 2 * Progression.bosses_defeated + 1
	for node: Node3D in tree.get_nodes_in_group("guide_target"):
		var order: int = node.get_meta("guide_order", 0)
		if order >= first and order < best_order:
			best_order = order
			best = node
	return best
