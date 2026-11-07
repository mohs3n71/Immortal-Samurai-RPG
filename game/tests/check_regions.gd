extends SceneTree

## Regions on one map (D-100, D-102): the Frostlands lies north of the
## Meadowlands in the same world, with its own frozen-undead roster, the Frost
## Tyrant and no Reaper or knights. The gateway behind the Bone Warlord is
## sealed until he falls, then Kaze walks through into the Frostlands (its
## quest, minimap and light take over). Fast travel goes to the start area and
## a return portal brings Kaze back to where he was, without loading.
## Usage: godot --headless --fixed-fps 60 --path game --script res://tests/check_regions.gd -- uncapped

const Progression = preload("res://scripts/progression.gd")
const EnemyRoster = preload("res://scripts/enemies/enemy_roster.gd")
const Travel = preload("res://scripts/world/travel.gd")
const Main = preload("res://scripts/main.gd")

var failures := 0
var field: Node

func _initialize() -> void:
	call_deferred("_run")

func _expect(ok: bool, label: String) -> void:
	print("%s %s" % ["PASS" if ok else "FAIL", label])
	if not ok:
		failures += 1

func _open() -> Node:
	field = (load("res://scenes/meadow.tscn") as PackedScene).instantiate()
	root.add_child(field)
	await create_timer(0.6).timeout
	field.player.get_node("AutoAttack").set_physics_process(false)
	return field

func _close() -> void:
	field.queue_free()
	await process_frame
	await process_frame

## Walks Kaze toward (x, z) for up to `seconds`; true when he gets there.
func _walk(target: Vector2, seconds: float) -> bool:
	var elapsed := 0.0
	var right: Vector3 = field.camera.global_basis.x
	var forward: Vector3 = -field.camera.global_basis.z
	var right_flat := Vector2(right.x, right.z).normalized()
	var forward_flat := Vector2(forward.x, forward.z).normalized()
	while elapsed < seconds:
		var here := Vector2(field.player.global_position.x, field.player.global_position.z)
		if here.distance_to(target) < 2.0:
			field.player.joystick.direction = Vector2.ZERO
			return true
		var way := (target - here).normalized()
		field.player.joystick.direction = Vector2(way.dot(right_flat), -way.dot(forward_flat))
		await physics_frame
		elapsed += 1.0 / Engine.physics_ticks_per_second
	field.player.joystick.direction = Vector2.ZERO
	return false

func _soldiers() -> Array:
	return root.get_tree().get_nodes_in_group("enemies").filter(func(n: Node) -> bool: return n.get("data") is Dictionary and n.data.has("swings"))

func _run() -> void:
	Progression.persist = false
	Progression.reset()
	Progression.tutorial_done = true
	Main.travel_dry_run = true
	await _open()
	# --- One world ---------------------------------------------------------
	var frost_ids := EnemyRoster.FROST_ROSTER.map(func(e: Dictionary) -> String: return e.id)
	var frozen := _soldiers().filter(func(s: Node) -> bool: return frost_ids.has(s.data.id))
	var meadow_soldiers := _soldiers().filter(func(s: Node) -> bool: return not frost_ids.has(s.data.id))
	_expect(frozen.size() == 25 and frozen.all(func(s: Node) -> bool: return String(s.data.model).contains("/frost/") and Travel.region_at(s.global_position) == 2), "25 frozen undead stand in the Frostlands, north of the gateway (%d)" % frozen.size())
	_expect(meadow_soldiers.size() == 25 and meadow_soldiers.all(func(s: Node) -> bool: return Travel.region_at(s.global_position) == 1), "and the 25 Meadowlands soldiers in the south, on the same map")
	_expect(frozen.all(func(s: Node) -> bool: return s.is_on_floor() or absf(s.global_position.y - s.home.y) < 1.5), "they stand at their clearings")
	var bosses := root.get_tree().get_nodes_in_group("enemies").filter(func(n: Node) -> bool: return n.name.begins_with("RegionBoss"))
	var tyrant: Node = null
	for boss in bosses:
		if boss.data.id == "frost-tyrant":
			tyrant = boss
	_expect(bosses.size() == 2 and tyrant != null and is_equal_approx(tyrant.max_health(), 3260000.0) and Travel.region_at(tyrant.global_position) == 2, "both bosses are on the map; the Frost Tyrant (3.26M) in the Frostlands")
	var reapers := root.get_tree().root.find_children("Reaper", "", true, false)
	_expect(reapers.size() == 1 and Travel.region_at(reapers[0].global_position) == 1, "the Reaper and knights are only in the Meadowlands")
	var gates := field.find_children("RegionGate*", "", false, false)
	_expect(gates.size() == 2, "each region has its gate")
	var gate: Node3D = gates.filter(func(g: Node) -> bool: return g.region == 1)[0]
	_expect(field.region == 1 and field.find_child("Minimap", true, false).second_texture.resource_path.ends_with("minimap-frost-v001.png"), "the minimap holds both regions")
	var guide_target: Node3D = Travel.guide_target(root.get_tree())
	_expect(guide_target != null and guide_target.get("data") != null and guide_target.data.id != "frost-tyrant", "the guide leads to the region 1 boss first")
	# --- The sealed gateway -------------------------------------------------
	field.player.revive(Vector3(62, 1, -104))
	await create_timer(0.3).timeout
	var through := await _walk(Vector2(62, -160), 4.0)
	_expect(not through and field.player.global_position.z > -118.0 and field.region == 1, "the gateway is sealed while the Bone Warlord stands (held at z %.1f)" % field.player.global_position.z)
	# --- Open: walk into the Frostlands -------------------------------------
	field.player.revive(Vector3(62, 1, -80))
	field.find_child("RegionBoss", false, false).queue_free()
	Progression.bosses_defeated = 1
	gate.open()
	await process_frame
	await process_frame
	guide_target = Travel.guide_target(root.get_tree())
	_expect(guide_target == gate, "once he falls the guide leads to the open gate")
	var quest: Control = field.find_child("QuestPanel", true, false)
	_expect(quest.region == 2 and quest._title.text == "Defeat the Frost Tyrant" and quest._tag.text == "REGION 2 QUEST", "and the quest moves on to the Frost Tyrant")
	await create_timer(0.3).timeout
	through = await _walk(Vector2(62, -155), 12.0)
	await create_timer(0.2).timeout
	_expect(through and field.region == 2 and Progression.current_region == 2, "Kaze walks through the gateway into the Frostlands (at %s)" % field.player.global_position)
	guide_target = Travel.guide_target(root.get_tree())
	_expect(guide_target == tyrant, "the guide now leads to the Frost Tyrant")
	await create_timer(3.0).timeout
	var environment: Environment = field.find_child("Environment", true, false).environment
	_expect(environment.background_color.is_equal_approx(field._lighting[2].env.background_color), "the Frostlands light is faded in")
	_expect(field.hud.tutorial_button.visible, "HOW TO PLAY stays available")
	# Walking back south works too.
	through = await _walk(Vector2(62, -105), 8.0)
	_expect(through and field.region == 1, "and back south into the Meadowlands")
	field.player.revive(Vector3(40 + 62, 1, 60 - 268))
	await create_timer(0.3).timeout
	# --- Fast travel and the return portal -----------------------------------
	var here: Vector3 = field.player.global_position
	await process_frame
	_expect(field.region == 2 and field.hud.fast_travel_button.visible, "the fast travel icon is shown in the Frostlands")
	field.fast_travel()
	await create_timer(0.3).timeout
	_expect(Progression.portal_region == 2 and Progression.portal_position.distance_to(here) < 0.5, "fast travel remembers where Kaze was")
	_expect(field.player.global_position.distance_to(Travel.START_ARRIVAL) < 3.0 and field.region == 1 and field.portal != null, "and takes him to the Reaper and knights, with a portal back")
	_expect(String(field.portal.label_text).contains("Frostlands"), "the portal leads back to the Frostlands")
	await process_frame
	_expect(not field.hud.fast_travel_button.visible, "no fast travel icon while already at the start")
	field.player.revive(field.portal.global_position + Vector3(0, 1, 0))
	await create_timer(1.5).timeout
	_expect(field.player.global_position.distance_to(here) < 3.0 and field.region == 2 and Progression.portal_region == 0, "the portal takes him back to the same spot in the Frostlands")
	# No fast travel in a fight (D-104).
	var soldier: Node3D = meadow_soldiers[0]
	field.player.revive(soldier.home + Vector3(5, 1, 0))
	await create_timer(1.0).timeout
	_expect(field.in_combat(), "next to a soldier who attacks, Kaze is in a fight")
	await process_frame
	_expect(field.hud.fast_travel_blocked and field.hud.fast_travel_button.visible, "the fast travel icon shows the combat lock")
	var before: Vector3 = field.player.global_position
	field.fast_travel()
	await create_timer(0.3).timeout
	var notice: Control = field.hud.get_node_or_null("CombatNotice")
	_expect(field.portal == null and Progression.portal_region == 0 and field.player.global_position.distance_to(Travel.START_ARRIVAL) > 20.0, "tapping it does not travel")
	_expect(notice != null and notice.visible and notice.size.x < 700.0, "and a \"Can't fast travel in a fight\" card appears")
	var icons := root.get_tree().get_nodes_in_group("minimap_icons").map(func(n: Node) -> String: return n.get_meta("minimap_icon"))
	_expect(icons.size() == 3 and icons.has("reaper") and icons.has("blood-knight") and icons.has("plague-knight"), "the Reaper and both knights have minimap portraits")
	# Fast travel inside region 1.
	# A quiet spot far from the village, out of every soldier's reach.
	var quiet := Vector3(-90, 1, 20)
	for candidate in [Vector3(-80, 1, -30), Vector3(-90, 1, 20), Vector3(60, 1, 60), Vector3(0, 1, 90)]:
		if meadow_soldiers.all(func(s: Node) -> bool: return s.home.distance_to(candidate) > 30.0):
			quiet = candidate
			break
	field.player.revive(quiet)
	await create_timer(0.3).timeout
	var far: Vector3 = field.player.global_position
	await process_frame
	_expect(field.hud.fast_travel_button.visible, "far from the village the icon appears in region 1 too")
	field.fast_travel()
	await create_timer(0.3).timeout
	_expect(field.player.global_position.distance_to(Travel.START_ARRIVAL) < 3.0 and field.portal != null, "region 1 fast travel jumps to the village and opens a portal")
	field.player.revive(field.portal.global_position + Vector3(0, 1, 0))
	await create_timer(1.5).timeout
	_expect(field.player.global_position.distance_to(far) < 3.0 and field.portal == null, "its portal brings him back to where he was")
	await _close()
	# --- A save made in the Frostlands starts there ---------------------------
	Progression.current_region = 2
	await _open()
	_expect(field.region == 2 and field.player.global_position.distance_to(Travel.ENTRIES[2]) < 3.0, "a game saved in the Frostlands resumes just inside its gateway")
	await _close()
	print("RESULT: %s" % ("PASS" if failures == 0 else "FAIL (%d)" % failures))
	quit(1 if failures > 0 else 0)
