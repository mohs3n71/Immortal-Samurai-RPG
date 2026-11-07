extends SceneTree

## Auto-attack check (D-072, D-075): walking up to a training dummy makes the
## hero swing without any button, the swings chain through the four-step combo
## in order, the finisher topples the dummy, the chain restarts after a pause,
## and the hero stops attacking once nothing is in reach.

const FIELD := "res://scenes/meadow.tscn"

var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var progression = load("res://scripts/progression.gd")
	progression.persist = false
	progression.reset()
	var field := (load(FIELD) as PackedScene).instantiate()
	root.add_child(field)
	await create_timer(0.5).timeout
	var player: CharacterBody3D = field.player
	var dummies := root.get_tree().get_nodes_in_group("enemies")
	_expect(dummies.size() >= 3, "training dummies registered as enemies (%d)" % dummies.size())
	_expect(field.find_child("AttackButton", true, false) == null, "no attack button")
	var target: Node3D = dummies[0]
	var swings := 0
	var was_attacking := false
	for frame in 600:
		var offset := target.global_position - player.global_position
		offset.y = 0.0
		if offset.length() > 3.5:
			_steer(field, Vector2(offset.x, offset.z).normalized())
		else:
			player.joystick.direction = Vector2.ZERO
		await physics_frame
		if player.visual.is_attacking and not was_attacking:
			swings += 1
		was_attacking = player.visual.is_attacking
		if not target.is_alive():
			break
	_expect(swings >= 1, "hero swung automatically (%d swing starts)" % swings)
	var log: Array = player.get_node("AutoAttack").swing_log
	_expect(log.slice(0, 4) == ["slash_1", "slash_2", "slash_3", "slash_4"], "combo plays in order: %s" % [log])
	_expect(not target.is_alive(), "finisher toppled the dummy (5 health = 1+1+1+2)")
	await create_timer(0.5, true, false, true).timeout
	_expect(is_equal_approx(Engine.time_scale, 1.0), "hit-stop released")
	player.joystick.direction = Vector2.ZERO
	player.global_position = Vector3(-30, 1, 40)
	await create_timer(1.2).timeout
	_expect(not player.visual.is_attacking, "no swinging with no enemy in reach")
	_expect(player.get_node("AutoAttack").next_step() == 0, "combo restarts after a pause")
	await create_timer(4.0).timeout
	_expect(target.is_alive(), "dummy stood back up")
	print("RESULT: ", "PASS" if failures == 0 else "FAIL (%d)" % failures)
	quit(1 if failures > 0 else 0)

func _steer(field: Node, world: Vector2) -> void:
	var right: Vector3 = field.camera.global_basis.x
	var forward: Vector3 = -field.camera.global_basis.z
	field.player.joystick.direction = Vector2(world.dot(Vector2(right.x, right.z).normalized()), -world.dot(Vector2(forward.x, forward.z).normalized()))

func _expect(condition: bool, label: String) -> void:
	print("PASS " if condition else "FAIL ", label)
	if not condition:
		failures += 1
