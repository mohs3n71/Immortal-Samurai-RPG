extends SceneTree

## Region boss check (D-085): boss stats follow the formula, the gate is sealed
## until the boss is defeated, the boss heals fully when Kaze falls, hits for
## its hit x (1 + Plague Knight level), and its defeat opens the gate for good.
## Usage: godot --headless --fixed-fps 60 --path game --script res://tests/check_boss.gd -- uncapped

const Progression = preload("res://scripts/progression.gd")
const EnemyRoster = preload("res://scripts/enemies/enemy_roster.gd")
const Travel = preload("res://scripts/world/travel.gd")

var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _expect(ok: bool, label: String) -> void:
	print("%s %s" % ["PASS" if ok else "FAIL", label])
	if not ok:
		failures += 1

func _run() -> void:
	Progression.persist = false
	Progression.reset()
	Progression.tutorial_done = true   # The boss guide waits for the tutorial (D-094).
	var stats := EnemyRoster.boss_stats(1)
	_expect(int(stats.health) == 1110000 and int(EnemyRoster.boss_stats(2).health) == 3260000 and int(EnemyRoster.boss_stats(3).health) == 6510000, "region 1 boss: %s health, region 2: %s" % [Progression.format_number(stats.health), Progression.format_number(EnemyRoster.boss_stats(2).health)])
	_expect(EnemyRoster.region_minutes(1) == 30 and EnemyRoster.region_minutes(2) == 75 and EnemyRoster.region_minutes(3) == 135, "region targets 30, 75, 135 minutes in total (D-096)")
	var field := (load("res://scenes/meadow.tscn") as PackedScene).instantiate()
	root.add_child(field)
	var player: CharacterBody3D = field.player
	player.get_node("AutoAttack").set_physics_process(false)
	await create_timer(1.0).timeout
	var boss: Node = field.get_node_or_null("RegionBoss")
	var gate: Node3D = field.get_node("RegionGate")
	_expect(boss != null and not gate.is_open(), "boss guards a sealed gate")
	# Guide (D-090): the boss is the goal; off screen the edge pointer shows.
	var guide: Control = field.find_child("GuidePointer", true, false)
	var minimap: Control = field.find_child("Minimap", true, false)
	_expect(Travel.guide_target(root.get_tree()) == boss, "the boss is the region's guide target")
	player.revive(Vector3(2, 1, 2))
	await create_timer(0.6).timeout
	_expect(guide.shown_at != Vector2.INF, "from the village the screen-edge pointer leads to the boss (%s)" % guide.shown_at)
	_expect(minimap.to_minimap(boss.global_position).length() > 110.0, "the boss is beyond the minimap view, so its marker is pinned to the rim")
	player.revive(boss.home + Vector3(0, 1, 24))
	await create_timer(0.6).timeout
	_expect(guide.shown_at == Vector2.INF, "with the boss on screen the pointer hides")
	# The sealed gate blocks the way.
	player.revive(gate.global_position + Vector3(0, 1, 10))
	boss.set_physics_process(false)
	for frame in 150:
		player.joystick.direction = Vector2.ZERO
		await physics_frame
		player.velocity = Vector3.ZERO
		var push := (gate.global_position - player.global_position)
		push.y = 0.0
		player.lunge(push.normalized() * 20.0)
	_expect(player.global_position.distance_to(gate.global_position) > 1.5 and player.global_position.z > gate.global_position.z - 1.0, "the sealed barrier blocks Kaze (z %.1f, gate %.1f)" % [player.global_position.z, gate.global_position.z])
	boss.set_physics_process(true)
	# 30 s after the fight starts the boss refills; falls do not heal it.
	Progression.max_health = 1000000000
	player.refill()
	player.revive(boss.home + Vector3(0, 1, 8))
	for frame in 120:
		await physics_frame
		if boss.in_fight:
			break
	_expect(boss.in_fight and boss._label.text.ends_with("s"), "the fight starts with a 30 s timer (%s)" % boss._label.text.replace("\n", " "))
	boss.take_hit(1000000.0, player.global_position)
	var hurt: float = boss.health
	player.take_damage(2000000000, boss.global_position)
	await physics_frame
	_expect(boss.health == hurt, "a fall does not heal the boss")
	# Hold Kaze in the arena (the boss's blows knock him back).
	var hold: Vector3 = boss.home + Vector3(0, 1, 8)
	var wait_frames := int((boss.fight_left + 0.5) * 60.0)
	for frame in wait_frames:
		await physics_frame
		player.global_position = Vector3(hold.x, player.global_position.y, hold.z)
	_expect(boss.health == boss.max_health() and boss.in_fight and boss.fight_left > 28.0, "after 30 s the boss is back to full and a new 30 s starts (%s)" % Progression.format_number(boss.health))
	Progression.plague_level = 2
	_expect(boss.hit_damage() == 3, "the boss hits like everyone: 1 + Plague Knight level = %d" % boss.hit_damage())
	Progression.plague_level = 0
	# Defeat opens the gate permanently.
	boss.take_hit(1.0e12, player.global_position)
	for frame in 120:
		await physics_frame
		if boss.state == boss.State.DEAD:
			break
	_expect(boss.state == boss.State.DEAD and Progression.bosses_defeated == 1, "boss defeated, region 1 cleared")
	await create_timer(0.5).timeout
	_expect(gate.is_open() and gate._body.collision_layer == 0, "gate opened")
	_expect(Travel.guide_target(root.get_tree()) == gate, "after the boss falls the guide leads to the open gate")
	field.queue_free()
	await process_frame
	var again := (load("res://scenes/meadow.tscn") as PackedScene).instantiate()
	root.add_child(again)
	await create_timer(0.5).timeout
	_expect(again.get_node_or_null("RegionBoss") == null and again.get_node("RegionGate").is_open(), "after a restart the boss stays defeated and the gate open")
	print("RESULT: %s" % ("PASS" if failures == 0 else "FAIL (%d)" % failures))
	quit(1 if failures else 0)
