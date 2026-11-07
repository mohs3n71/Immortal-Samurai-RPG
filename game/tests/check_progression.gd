extends SceneTree

## Progression check (D-080): Kaze starts at 1 health / 1 damage; falling gives
## +1 max health and +(1 + Blood Knight level) damage on the spot; defeating
## the Blood Knight or Plague Knight levels it up permanently (it returns at
## once, stronger, with its level shown); every enemy hit costs
## 1 + Plague Knight level; the Reaper halves max health, then waits 20 s.
## Usage: godot --headless --fixed-fps 60 --path game --script res://tests/check_progression.gd -- uncapped

const Progression = preload("res://scripts/progression.gd")

var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _expect(ok: bool, label: String) -> void:
	print("%s %s" % ["PASS" if ok else "FAIL", label])
	if not ok:
		failures += 1

func _knight(kind: String) -> Node:
	for node in root.get_tree().get_nodes_in_group("enemies"):
		if node.get("kind") == kind:
			return node
	return null

func _run() -> void:
	Progression.persist = false
	Progression.reset()
	var field := (load("res://scenes/meadow.tscn") as PackedScene).instantiate()
	root.add_child(field)
	var player: CharacterBody3D = field.player
	var attacker: Node = player.get_node("AutoAttack")
	attacker.set_physics_process(false)
	await create_timer(1.0).timeout
	_expect(player.max_health == 1 and player.health == 1 and Progression.damage == 1, "Kaze starts with 1 health and 1 damage")
	_expect(Progression.enemy_hit() == 1 and Progression.damage_per_fall() == 1, "enemy hits cost 1, falls give +1 damage")
	var blood := _knight("blood")
	var plague := _knight("plague")
	var reaper: Node3D = field.get_node("Reaper")
	_expect(blood != null and plague != null and reaper != null, "Reaper, Blood Knight and Plague Knight are at the start area")
	_expect(blood.global_position.distance_to(player.global_position) > 14.0 and plague.global_position.distance_to(player.global_position) > 14.0 and reaper.global_position.distance_to(player.global_position) > 14.0, "the spawn point is outside every NPC arena")
	_expect(blood._label.text.ends_with("Lv 1") and plague._label.text.ends_with("Lv 1"), "knights show Lv 1")
	# A fall: Kaze stays put with more health and damage.
	var spot := player.global_position
	player.take_damage(1, spot + Vector3(1, 0, 0))
	await create_timer(0.3).timeout
	_expect(Progression.max_health == 2 and Progression.damage == 2 and player.health == 2 and not player.dead, "fall: max health 2, damage 2, full health")
	_expect(player.global_position.distance_to(spot) < 6.0, "Kaze keeps his place after falling")
	# Blood Knight: defeat it twice.
	Progression.damage = 50
	player.revive(blood.home + Vector3(0, 1, 5))
	attacker.set_physics_process(true)
	for step in 120:
		await create_timer(0.1).timeout
		if Progression.blood_level >= 2:
			break
	attacker.set_physics_process(false)
	player.revive(field.spawn_position)
	_expect(Progression.blood_level == 2, "Blood Knight defeated twice -> level %d" % (Progression.blood_level + 1))
	await create_timer(2.5).timeout
	_expect(blood.is_alive() and blood.max_health() == 15 and blood._label.text.ends_with("Lv 3"), "Blood Knight came back at once, stronger, Lv 3 (health %d)" % int(blood.max_health()))
	await create_timer(2.0).timeout
	_expect(blood._visual.visible and blood._visual.position.y > -0.1 and blood._visual.basis.get_euler().x < 0.2, "Blood Knight stays visible and upright after coming back")
	_expect(Progression.damage_per_fall() == 3, "falls now give +3 damage")
	attacker.set_physics_process(false)
	var damage_before := Progression.damage
	player.take_damage(1000, blood.global_position)
	await create_timer(0.2).timeout
	_expect(Progression.damage == damage_before + 3, "a fall added +3 damage")
	# Plague Knight.
	player.revive(plague.home + Vector3(0, 1, -5))
	attacker.set_physics_process(true)
	for step in 60:
		await create_timer(0.1).timeout
		if Progression.plague_level > 0:
			break
	attacker.set_physics_process(false)
	_expect(Progression.plague_level == 1 and Progression.enemy_hit() == 2, "Plague Knight defeated: enemy hits now cost 2")
	await create_timer(2.5).timeout
	_expect(plague.is_alive() and plague._label.text.contains("Lv 2"), "Plague Knight returned at Lv 2")
	_expect(plague.hit_damage() == 2 and blood.hit_damage() == 2, "knights hit like every enemy, 1 + Plague level (plague %d, blood %d)" % [plague.hit_damage(), blood.hit_damage()])
	# Reaper: halves max health once, then a 20 s cooldown.
	player.revive(field.spawn_position)
	await create_timer(0.3).timeout
	Progression.max_health = 9
	player.refill()
	player.revive(reaper.global_position + Vector3(0, 1, 4))
	await create_timer(2.0).timeout
	_expect(Progression.max_health == 4 and player.max_health == 4 and player.health <= 4, "Reaper halved max health 9 -> %d" % Progression.max_health)
	_expect(reaper.cooldown > 15.0 and reaper._label.text.contains("s"), "Reaper shows his cooldown (%s)" % reaper._label.text.replace("\n", " "))
	var swings_before: int = attacker.swing_log.size()
	attacker.set_physics_process(true)
	await create_timer(3.0).timeout
	attacker.set_physics_process(false)
	_expect(Progression.max_health == 4, "no second strike during the cooldown")
	_expect(attacker.swing_log.size() == swings_before and not reaper.has_method("take_hit") and not reaper.is_in_group("enemies"), "Kaze never attacks the Reaper")
	# Experience from soldiers (not NPCs) and +1% damage per hero level.
	Progression.damage = 100
	var level_before := Progression.hero_level
	var xp_before := Progression.experience
	var recruit: Node = null
	for node in root.get_tree().get_nodes_in_group("enemies"):
		if node.get("data") is Dictionary and node.data.get("id", "") == "axe-recruit":
			recruit = node
	player.revive(recruit.home + Vector3(0, 1, 5))
	attacker.set_physics_process(true)
	for step in 60:
		await create_timer(0.1).timeout
		if recruit.state == recruit.State.DEAD:
			break
	attacker.set_physics_process(false)
	_expect(Progression.experience_for(15) == 21 and Progression.experience >= 0 or Progression.hero_level > level_before, "a recruit (15 health) gives 21 experience (xp %d)" % Progression.experience)
	_expect(Progression.experience_for(6) == 7 and Progression.experience_for(10) == 13 and Progression.experience_for(16) == 22 and Progression.experience_for(80) == 160, "experience grows with health: 6->7, 10->13, 16->22, 80->160")
	Progression.add_experience(Progression.experience_to_next())
	_expect(Progression.hero_level >= level_before + 1, "enough experience levels Kaze up (Lv %d)" % Progression.hero_level)
	Progression.damage = 10
	Progression.hero_level = 4
	_expect(is_equal_approx(Progression.effective_damage(), 10.3), "each hero level adds +1%% base damage (%.2f)" % Progression.effective_damage())
	var xp_knights := Progression.experience
	Progression.blood_level = 0
	player.revive(blood.home + Vector3(0, 1, 5))
	attacker.set_physics_process(true)
	for step in 60:
		await create_timer(0.1).timeout
		if Progression.blood_level > 0:
			break
	attacker.set_physics_process(false)
	_expect(Progression.experience == xp_knights, "knights give no experience")
	# Same attack speed for Kaze and enemies, and items would speed up both (D-082).
	for speed in [1.0, 2.0]:
		Progression.attack_speed = speed
		Progression.max_health = 100000
		Progression.damage = 0
		Progression.hero_level = 1
		player.refill()
		var guard: Node = null
		for node in root.get_tree().get_nodes_in_group("enemies"):
			if node.get("data") is Dictionary and node.data.get("id", "") == "hammer-guard":
				guard = node
		player.revive(guard.home + Vector3(4, 1, 0))
		attacker.set_physics_process(true)
		await create_timer(1.5).timeout
		var hero_before: int = attacker.swing_log.size()
		var enemy_before: int = guard.swings_started
		await create_timer(4.2).timeout
		var hero_swings: int = attacker.swing_log.size() - hero_before
		var enemy_swings: int = guard.swings_started - enemy_before
		attacker.set_physics_process(false)
		# Hit-stop freezes everyone equally for a moment, so allow 20% fewer.
		var expected := int(4.2 / Progression.attack_interval())
		_expect(absi(hero_swings - enemy_swings) <= 1 and absi(hero_swings - expected) <= maxi(1, expected / 5), "attack speed %.0fx: Kaze %d swings, soldier %d swings (expected about %d)" % [speed, hero_swings, enemy_swings, expected])
		_expect(guard.is_alive() and guard.state == guard.State.ATTACK or guard.state == guard.State.CHASE, "Kaze's hits never interrupt the soldier (state %d)" % guard.state)
	Progression.attack_speed = 1.0
	# A soldier killed mid-swing still finishes the swing and hits Kaze (D-083).
	var swinger: Node = null
	for node in root.get_tree().get_nodes_in_group("enemies"):
		if node.get("data") is Dictionary and node.data.get("id", "") == "sword-soldier":
			swinger = node
	Progression.max_health = 1000
	Progression.damage = 0
	player.refill()
	player.revive(swinger.home + Vector3(4, 1, 0))
	for step in 300:
		await physics_frame
		if swinger.state == swinger.State.ATTACK and not swinger._hit_landed and swinger._timer < 0.05:
			break
	var health_before: int = player.health
	swinger.take_hit(1000.0, player.global_position)
	_expect(not swinger.is_alive() and swinger.state == swinger.State.ATTACK, "a soldier defeated mid-swing keeps swinging")
	await create_timer(Progression.attack_interval()).timeout
	_expect(player.health < health_before, "its blow still hits Kaze (%d -> %d)" % [health_before, player.health])
	_expect(swinger.state == swinger.State.DEAD, "then it falls")
	# High knight levels (D-086): health never overflows, and a strong knight
	# can still be beaten because enemy hits no longer knock Kaze out of reach.
	Progression.blood_level = 150
	_expect(blood.max_health() > 1.0e30 and blood.hit_damage() > 0, "Blood Knight Lv 151 keeps its huge health (%s) and a positive hit" % Progression.format_number(blood.max_health()))
	Progression.blood_level = 0
	Progression.plague_level = 19
	Progression.damage = 3000
	Progression.max_health = 40
	player.refill()
	plague._respawn()
	var plague_start: Vector3 = plague.home
	player.revive(plague_start + Vector3(0, 1, 5))
	attacker.set_physics_process(true)
	for second in 60:
		await create_timer(1.0).timeout
		if Progression.plague_level > 19:
			break
	var reach := Vector2(player.global_position.x - plague_start.x, player.global_position.z - plague_start.z).length()
	_expect(Progression.plague_level == 20, "a Lv 20 Plague Knight is beaten while Kaze falls and keeps fighting (Kaze %.1f from its home)" % reach)
	# Reset button (D-086): first tap only arms it.
	var reset_button := root.find_child("ResetButton", true, false) as Button
	_expect(reset_button != null and reset_button.is_visible_in_tree(), "the HUD has a reset button")
	if reset_button != null:
		reset_button.pressed.emit()
		_expect(reset_button.text.begins_with("TAP AGAIN") and Progression.plague_level == 20, "one tap only asks for a second tap (%s)" % reset_button.text)
		await create_timer(3.3).timeout
		_expect(reset_button.text == "RESET", "it disarms after 3 s")
	Progression.reset()
	_expect(Progression.max_health == 1 and Progression.damage == 1 and Progression.blood_level == 0 and Progression.plague_level == 0 and Progression.hero_level == 1 and Progression.bosses_defeated == 0, "reset returns to 1 health, 1 damage, knights Lv 1")
	# 30 s fight window for the knights too (D-101).
	Progression.blood_level = 20
	Progression.damage = 1
	blood._respawn()
	attacker.set_physics_process(false)
	player.revive(blood.home + Vector3(0, 1, 6))
	await create_timer(1.0).timeout
	_expect(blood.in_fight and blood._label.text.ends_with("s") and blood._label.text.contains("Lv 21"), "a knight fight shows its 30 s timer (%s)" % blood._label.text.replace("\n", " "))
	blood.take_hit(blood.max_health() * 0.5, player.global_position)
	var hurt: float = blood.health
	await create_timer(25.0).timeout
	_expect(is_equal_approx(blood.health, hurt) and blood.fight_left > 0.0, "the damage stays while the window lasts (%.0f s left)" % blood.fight_left)
	await create_timer(6.0).timeout
	_expect(is_equal_approx(blood.health, blood.max_health()) and blood.fight_left > 20.0, "after 30 s he is back to full health and a new window starts")
	blood.take_hit(blood.max_health() * 0.5, player.global_position)
	player.revive(field.spawn_position)
	await create_timer(3.0).timeout
	_expect(is_equal_approx(blood.health, blood.max_health()) and not blood.in_fight, "leaving the fight also heals him")
	print("RESULT: %s" % ("PASS" if failures == 0 else "FAIL (%d)" % failures))
	quit(1 if failures else 0)
