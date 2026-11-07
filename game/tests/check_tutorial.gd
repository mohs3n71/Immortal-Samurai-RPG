extends SceneTree

## Tutorial and quest checks (D-094): the tutorial starts on a fresh save, each
## hands-on step waits for its action and then moves on, finishing saves the
## flag and reveals the quest card; the quest power bar compares 30 s damage
## with the boss's health; skip works; a finished tutorial never comes back.
## Usage: godot --headless --fixed-fps 60 --path game --script res://tests/check_tutorial.gd -- uncapped

const Progression = preload("res://scripts/progression.gd")
const EnemyRoster = preload("res://scripts/enemies/enemy_roster.gd")

var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _expect(ok: bool, label: String) -> void:
	print("%s %s" % ["PASS" if ok else "FAIL", label])
	if not ok:
		failures += 1

func _field() -> Node:
	var field := (load("res://scenes/meadow.tscn") as PackedScene).instantiate()
	root.add_child(field)
	await create_timer(0.6).timeout
	return field

func _run() -> void:
	Progression.persist = false
	Progression.reset()
	Progression.tutorial_done = false
	var field: Node = await _field()
	var tutorial: Control = field.find_child("Tutorial", true, false)
	var quest: Control = field.find_child("QuestPanel", true, false)
	var guide: Control = field.find_child("GuidePointer", true, false)
	var player: CharacterBody3D = field.player
	player.get_node("AutoAttack").set_physics_process(false)
	_expect(tutorial != null and tutorial.step == 0, "a fresh save starts the tutorial on its first card")
	_expect(quest != null and not quest.visible, "the quest card waits for the tutorial")
	_expect(guide.shown_at == Vector2.INF, "the boss pointer waits for the tutorial")
	tutorial._next()
	tutorial._next()
	await create_timer(0.3).timeout
	_expect(tutorial.step == 2 and tutorial.steps[2].kind == "task", "after the two story cards the first hands-on step (move) starts")
	await create_timer(2.0).timeout
	_expect(tutorial.step == 2, "a step waits for its action")
	player.global_position += Vector3(10, 0, 0)
	await create_timer(2.0).timeout
	_expect(tutorial.step == 3, "moving completes the move step")
	player.revive(tutorial._enemy("blood-knight").global_position + Vector3(0, 1, 8))
	await create_timer(2.0).timeout
	_expect(tutorial.step == 4, "reaching the Blood Knight completes that step")
	Progression.hero_fell()
	await create_timer(2.0).timeout
	Progression.blood_knight_defeated()
	await create_timer(2.0).timeout
	Progression.plague_knight_defeated()
	await create_timer(2.0).timeout
	Progression.reaper_strike()
	await create_timer(2.0).timeout
	_expect(tutorial.step == 8, "fall, Blood Knight, Plague Knight and Reaper steps each complete in turn (now step %d)" % tutorial.step)
	Progression.add_experience(10)
	await create_timer(2.0).timeout
	_expect(tutorial.steps[tutorial.step].title == "YOUR QUEST", "a soldier kill leads to the quest card")
	tutorial._next()
	await create_timer(1.2).timeout
	_expect(Progression.tutorial_done and not is_instance_valid(tutorial), "finishing saves the tutorial as done and removes it")
	_expect(quest.visible and quest.modulate.a > 0.9, "the quest card is shown")
	_expect(guide.shown_at != Vector2.INF, "and the boss pointer appears")
	# Quest power bar.
	Progression.damage = 1000
	var expected: float = Progression.effective_damage() * 1.25 * 30.0 / 0.7 / EnemyRoster.boss_stats(1).health
	_expect(is_equal_approx(quest.power_fraction(), expected), "quest power = 30 s damage / boss health (%.4f)" % quest.power_fraction())
	Progression.damage = 100000
	quest._refresh()
	_expect(quest.power_fraction() == 1.0 and quest._status.text.begins_with("You are ready"), "full power says ready")
	Progression.bosses_defeated = 1
	quest._refresh()
	_expect(quest._status.text.begins_with("Complete"), "a beaten boss completes the quest")
	field.queue_free()
	await process_frame
	# A finished tutorial never returns, not even after RESET (D-102).
	var again: Node = await _field()
	_expect(again.find_child("Tutorial", true, false) == null, "a finished tutorial does not come back")
	again.queue_free()
	Progression.reset()
	var after_reset: Node = await _field()
	_expect(after_reset.find_child("Tutorial", true, false) == null, "RESET does not bring it back")
	after_reset.queue_free()
	Progression.tutorial_done = false
	var fresh: Node = await _field()
	var skipped: Control = fresh.find_child("Tutorial", true, false)
	skipped._skip.pressed.emit()
	await create_timer(0.6).timeout
	_expect(Progression.tutorial_done and fresh.find_child("QuestPanel", true, false).visible, "SKIP TUTORIAL finishes it and shows the quest")
	# HOW TO PLAY replays it without touching progress (D-097).
	Progression.damage = 77
	var how: Button = fresh.find_child("TutorialButton", true, false)
	_expect(how != null and how.is_visible_in_tree(), "the HUD has a HOW TO PLAY button")
	how.pressed.emit()
	await create_timer(0.5).timeout
	var replay: Control = fresh.find_child("Tutorial", true, false)
	_expect(replay != null and replay.step == 0 and not fresh.find_child("QuestPanel", true, false).visible and Progression.damage == 77, "it replays the tutorial from the start and keeps progress")
	_expect(not how.is_visible_in_tree(), "the button hides while the tutorial runs")
	replay._skip.pressed.emit()
	await create_timer(0.6).timeout
	_expect(how.is_visible_in_tree() and fresh.find_child("QuestPanel", true, false).visible, "after it the button and quest come back")
	# Cards never overlap their portrait (D-097).
	Progression.reset()
	Progression.tutorial_done = false
	var cards: Node = await _field()
	var tutorial2: Control = cards.find_child("Tutorial", true, false)
	var overlaps := []
	for index in tutorial2.steps.size():
		await create_timer(0.5).timeout
		var badge: Control = tutorial2._card.find_children("*", "Control", true, false).filter(func(c: Node) -> bool: return c.get_script() == load("res://scripts/ui/portrait_badge.gd"))[0]
		for label: Label in tutorial2._card.find_children("*", "Label", true, false):
			if label.text != "" and badge.get_global_rect().grow(-4.0).intersects(label.get_global_rect()):
				overlaps.append("%d: %s" % [index, label.text.left(20)])
		var panel: Control = tutorial2._card.get_node("Panel")
		if not Rect2(Vector2.ZERO, tutorial2.size).encloses(panel.get_global_rect()):
			overlaps.append("%d: card off screen" % index)
		if tutorial2.steps[index].kind == "task":
			tutorial2._show(index + 1)
		else:
			tutorial2._next()
	_expect(overlaps.is_empty(), "no card text touches its portrait, every card fits on screen %s" % str(overlaps))
	print("RESULT: %s" % ("PASS" if failures == 0 else "FAIL (%d)" % failures))
	quit(1 if failures > 0 else 0)
