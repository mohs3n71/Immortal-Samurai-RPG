extends SceneTree

## Enemy check (D-078): one soldier per clearing stands on the ground near
## home, notices and hurts Kaze, dies to his combos, goes home when he leaves,
## and Kaze respawns at full health after falling.
## Usage: godot --headless --fixed-fps 60 --path game --script res://tests/check_enemies.gd -- uncapped

const FIELD := "res://scenes/meadow.tscn"
const EnemyRoster = preload("res://scripts/enemies/enemy_roster.gd")

var failures := 0
var field: Node

func _initialize() -> void:
	call_deferred("_run")

func _expect(ok: bool, label: String) -> void:
	print("%s %s" % ["PASS" if ok else "FAIL", label])
	if not ok:
		failures += 1

## Region 1's soldiers (the Frostlands' share the map since D-102; check_regions covers them).
func _soldiers() -> Array:
	return root.get_tree().get_nodes_in_group("enemies").filter(func(node: Node) -> bool: return node.get("data") is Dictionary and not node.data.is_empty() and node.get("kind") == null and node.data.get("tier", "") != "boss" and node.data.plaza.y > -134.0)

func _run() -> void:
	var progression = load("res://scripts/progression.gd")
	progression.persist = false
	progression.reset()
	field = (load(FIELD) as PackedScene).instantiate()
	root.add_child(field)
	var player: CharacterBody3D = field.player
	var attacker: Node = player.get_node("AutoAttack")
	attacker.set_physics_process(false)
	await create_timer(1.5).timeout
	var soldiers := _soldiers()
	_expect(soldiers.size() == EnemyRoster.spawn_list().size() and soldiers.size() == 25, "%d soldiers spawned (groups of 3 for recruits and soldiers, captains and commanders alone)" % soldiers.size())
	var ids := {}
	for soldier in soldiers:
		ids[soldier.data.id] = true
	_expect(ids.size() == EnemyRoster.ROSTER.size(), "all %d soldier types appear" % ids.size())
	var groups := {}
	for soldier in soldiers:
		var key: Vector2 = soldier.data.plaza
		if not groups.has(key):
			groups[key] = {}
		groups[key][soldier.data.id] = true
	var mixed := true
	for key in groups:
		var group_size := soldiers.filter(func(s: Node) -> bool: return s.data.plaza == key).size()
		mixed = mixed and groups[key].size() == group_size
	_expect(groups.size() == 11 and mixed, "11 clearings, and each group is made of different types")
	# Wake each soldier briefly by putting Kaze near (but outside aggro) so it settles on the floor.
	var grounded := 0
	for soldier in soldiers:
		# 40 units toward the map centre: out of its reach, still on the (D-093 smaller) map.
		var inward := -Vector3(soldier.home.x, 0, soldier.home.z).normalized() * 40.0
		player.revive(soldier.home + inward + Vector3(0, 2, 0))
		await create_timer(0.6).timeout
		var drift := Vector2(soldier.global_position.x - soldier.home.x, soldier.global_position.z - soldier.home.z).length()
		if soldier.is_on_floor() and drift < 3.0 and absf(soldier.global_position.y - soldier.home.y) < 2.0:
			grounded += 1
		else:
			print("  ", soldier.data.id, " floor=", soldier.is_on_floor(), " drift=", drift, " y=", soldier.global_position.y, " home=", soldier.home)
	_expect(grounded == soldiers.size(), "all soldiers stand on the ground at home (%d/%d)" % [grounded, soldiers.size()])
	# Aggro and damage.
	var recruit: Node3D = soldiers.filter(func(s: Node) -> bool: return s.data.id == "axe-recruit")[0]
	player.revive(recruit.home + Vector3(10, 1, 0))
	await create_timer(5.0).timeout
	_expect(load("res://scripts/progression.gd").deaths > 0 or player.health < player.max_health, "recruit chased and hurt Kaze (falls %d)" % load("res://scripts/progression.gd").deaths)
	# Kaze fights back.
	attacker.set_physics_process(true)
	var killed := false
	for step in 40:
		await create_timer(0.25).timeout
		if not recruit.is_alive():
			killed = true
			break
	_expect(killed, "Kaze's combo defeated the recruit")
	# Leash: a soldier follows, then gives up and walks home.
	attacker.set_physics_process(false)
	var guard: Node3D = soldiers.filter(func(s: Node) -> bool: return s.data.id == "hammer-guard")[0]
	player.revive(guard.home + Vector3(12, 1, 0))
	await create_timer(1.5).timeout
	var chased := Vector2(guard.global_position.x - guard.home.x, guard.global_position.z - guard.home.z).length() > 2.0
	player.revive(guard.home + Vector3(70, 1, 0))
	await create_timer(8.0).timeout
	var home_again := Vector2(guard.global_position.x - guard.home.x, guard.global_position.z - guard.home.z).length() < 2.5
	_expect(chased and home_again, "guard chased, then returned home when Kaze left (chased=%s home=%s)" % [chased, home_again])
	# Falling: no death, Kaze keeps fighting where he stands with more health.
	player.revive(guard.home + Vector3(3, 1, 0))
	await create_timer(0.2).timeout
	var before: int = progression.max_health
	var spot := player.global_position
	player.take_damage(1000, guard.global_position)
	_expect(not player.dead and progression.max_health == before + 1 and player.health == player.max_health, "falling refills Kaze on the spot with +1 max health")
	_expect(player.global_position.distance_to(spot) < 6.0, "Kaze stays where he fell")
	# Bodies never sink into each other (D-087): Kaze pushes straight at a
	# soldier with the joystick while both fight; the gap stays at least the
	# two body radii.
	progression.max_health = 100000
	attacker.set_physics_process(true)
	for id in ["iron-commander", "battle-mage", "sword-soldier"]:
		var foe: Node3D = soldiers.filter(func(s: Node) -> bool: return s.data.id == id)[0]
		foe._respawn()
		player.revive(foe.home + Vector3(14, 1, 0))
		var minimum: float = player.BODY_RADIUS + foe.body_radius()
		var closest := 99.0
		var hits_before: int = attacker.swing_log.size()
		for frame in 240:
			var offset := foe.global_position - player.global_position
			offset.y = 0.0
			var right: Vector3 = player.camera.global_basis.x
			var forward: Vector3 = -player.camera.global_basis.z
			right.y = 0.0
			forward.y = 0.0
			player.joystick.direction = Vector2(offset.normalized().dot(right.normalized()), -offset.normalized().dot(forward.normalized()))
			await physics_frame
			if foe.is_alive():
				closest = minf(closest, Vector2(offset.x, offset.z).length())
		player.joystick.direction = Vector2.ZERO
		_expect(closest >= minimum - 0.2, "%s: Kaze stays outside its body (closest %.2f, bodies need %.2f)" % [id, closest, minimum])
		_expect(attacker.swing_log.size() > hits_before, "%s: and still fights it" % id)
	# Respawn (D-088): 30 s after defeat even with Kaze standing right there,
	# with a countdown where it will come back.
	attacker.set_physics_process(false)
	var returner: Node3D = soldiers.filter(func(s: Node) -> bool: return s.data.id == "pike-recruit")[0]
	returner._respawn()
	player.revive(returner.home + Vector3(9, 1, 0))
	returner.take_hit(1.0e9, player.global_position)
	await create_timer(0.5).timeout
	var countdown: Label3D = returner.get("_countdown")
	_expect(countdown != null and countdown.visible and countdown.text.contains("back in 30s"), "a countdown shows at its home (%s)" % (countdown.text.replace("\n", " ") if countdown else "none"))
	await create_timer(20.0).timeout
	_expect(not returner.is_alive() and countdown.text.contains("back in 10s"), "still down after 20 s (%s)" % countdown.text.replace("\n", " "))
	await create_timer(10.5).timeout
	_expect(returner.is_alive() and not countdown.visible, "back after 30 s with Kaze nearby, countdown gone")
	# Toughness (D-091): health follows Kaze's base damage at spawn; hits by rank.
	progression.damage = 1000
	progression.plague_level = 0
	var commander: Node3D = soldiers.filter(func(s: Node) -> bool: return s.data.id == "iron-commander")[0]
	var rookie: Node3D = soldiers.filter(func(s: Node) -> bool: return s.data.id == "axe-recruit")[0]
	commander._respawn()
	rookie._respawn()
	_expect(is_equal_approx(commander.max_health(), 60000.0) and is_equal_approx(rookie.max_health(), 15000.0), "with 1000 damage a commander has 60K health, a recruit 15K (%s, %s)" % [progression.format_number(commander.max_health()), progression.format_number(rookie.max_health())])
	progression.plague_level = 4
	_expect(commander.hit_damage() == 5 and rookie.hit_damage() == 5, "every rank hits the same: 1 + Plague level (%d, %d)" % [commander.hit_damage(), rookie.hit_damage()])
	progression.plague_level = 0
	progression.damage = 2000
	_expect(is_equal_approx(commander.max_health(), 60000.0), "health stays fixed until it respawns")
	print("RESULT: %s" % ("PASS" if failures == 0 else "FAIL (%d)" % failures))
	quit(1 if failures else 0)
