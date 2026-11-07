extends Control

## First-launch interactive tutorial (D-094). Two story cards, then hands-on
## steps that each wait for the player to do the thing: move, fall, level the
## Blood and Plague Knights, take the Reaper's strike, beat a soldier. A
## bouncing marker shows the target (an edge arrow when it is off screen) and
## the HUD stat it changes glows. It ends with the region quest. Skippable;
## it starts on its own only once ever (Progression.tutorial_done, D-102).

const Progression = preload("res://scripts/progression.gd")
const UiStyle = preload("res://scripts/ui/ui_style.gd")
const PortraitBadge = preload("res://scripts/ui/portrait_badge.gd")
const ICON_DAMAGE := preload("res://assets/ui/icon_damage.png")
const ICON_PER_FALL := preload("res://assets/ui/icon_damage_per_fall.png")
const ICON_ENEMY_HIT := preload("res://assets/ui/icon_enemy_hit.png")
const PORTRAITS := {
	"kaze": preload("res://assets/ui/portraits/kaze.png"),
	"blood": preload("res://assets/ui/portraits/blood-knight.png"),
	"plague": preload("res://assets/ui/portraits/plague-knight.png"),
	"reaper": preload("res://assets/ui/portraits/reaper.png"),
	"soldier": preload("res://assets/ui/portraits/soldier.png"),
	"boss": preload("res://assets/ui/portraits/boss.png"),
}
## Bottom of the screen kept free for the thumb and joystick.
const THUMB_ZONE := 330.0

signal finished

var player: Node3D
var camera: Camera3D
var hud: Control

var step := -1
var steps: Array[Dictionary] = []
var _start := {}
var _done := false
var _completing := false
var _dim: ColorRect
var _card: Control
var _skip: Button
var _time := 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_dim = ColorRect.new()
	_dim.color = Color(0.03, 0.02, 0.01, 0.0)
	_dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_dim)
	_skip = Button.new()
	_skip.text = "SKIP TUTORIAL"
	_skip.focus_mode = Control.FOCUS_NONE
	_skip.add_theme_font_override("font", UiStyle.FONT_BOLD)
	_skip.add_theme_font_size_override("font_size", 18)
	_skip.add_theme_color_override("font_color", UiStyle.MUTED)
	var flat := StyleBoxFlat.new()
	flat.bg_color = Color(UiStyle.WOOD, 0.75)
	flat.set_corner_radius_all(14)
	flat.content_margin_left = 16
	flat.content_margin_right = 16
	flat.content_margin_top = 8
	flat.content_margin_bottom = 8
	for state in ["normal", "hover", "pressed", "focus"]:
		_skip.add_theme_stylebox_override(state, flat)
	_skip.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_skip.offset_top = 8.0
	_skip.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_skip.pressed.connect(_finish)
	_skip.add_to_group("touch_ui")
	add_child(_skip)
	_build_steps()

func begin() -> void:
	_show(0)

func _build_steps() -> void:
	steps = [
		{"kind": "modal", "portrait": "kaze", "title": "THE UNDYING BLADE",
			"body": "Kaze is immortal.\nWhen his health runs out he does not die: he rises on the spot, stronger than before.\n\nThe more he falls, the more powerful he becomes.",
			"button": "CONTINUE"},
		{"kind": "rules", "portrait": "kaze", "title": "EVERY FALL MAKES YOU STRONGER",
			"button": "LET'S GO"},
		{"kind": "task", "portrait": "kaze", "title": "Move", "body": "Drag anywhere on the screen to walk.",
			"hint": "drag", "check": func() -> bool: return _flat(player.global_position).distance_to(_start.position) > 8.0},
		{"kind": "task", "portrait": "blood", "title": "Meet the Blood Knight", "body": "Walk to him. Kaze swings his katana on his own.",
			"target": func() -> Node3D: return _enemy("blood-knight"),
			"check": func() -> bool: return _near(_enemy("blood-knight"), 11.0)},
		{"kind": "task", "portrait": "blood", "title": "Fall and rise", "body": "Let him hit you until you fall. Watch your damage grow!",
			"target": func() -> Node3D: return _enemy("blood-knight"), "highlight": 0,
			"check": func() -> bool: return Progression.deaths > _start.deaths},
		{"kind": "task", "portrait": "blood", "title": "Level the Blood Knight", "body": "Defeat him within 30 s, or he heals. Each of his levels gives +1 damage on every fall.",
			"target": func() -> Node3D: return _enemy("blood-knight"), "highlight": 1,
			"check": func() -> bool: return Progression.blood_level > _start.blood},
		{"kind": "task", "portrait": "plague", "title": "Level the Plague Knight", "body": "Defeat him within 30 s too. Each of his levels makes every enemy hit 1 harder, so you fall faster.",
			"target": func() -> Node3D: return _enemy("plague-knight"), "highlight": 2,
			"check": func() -> bool: return Progression.plague_level > _start.plague},
		{"kind": "task", "portrait": "reaper", "title": "Face the Reaper", "body": "Let him strike you. He halves your max health: less health, faster falls. You can't fight him.",
			"target": func() -> Node3D: return _reaper(),
			"check": func() -> bool: return Progression.reaper_strikes > _start.reaper},
		{"kind": "task", "portrait": "soldier", "title": "Hunt soldiers", "body": "Defeat a soldier. Soldiers give experience, and every hero level adds +1% damage.",
			"target": func() -> Node3D: return _nearest_soldier(), "highlight": 3,
			"check": func() -> bool: return Progression.soldiers_defeated > _start.soldiers},
		{"kind": "modal", "portrait": "boss", "title": "YOUR QUEST",
			"body": "The Bone Warlord guards the gate to the next region.\n\nOnce the fight starts you have 30 seconds to take all of his health, or he heals back to full.\n\nGrow stronger until your quest bar is full, then face him. The skull on your map shows the way.",
			"button": "BEGIN QUEST"},
	]

func task_count() -> int:
	return steps.filter(func(s: Dictionary) -> bool: return s.kind == "task").size()

func task_number(index: int) -> int:
	var number := 0
	for i in index + 1:
		if steps[i].kind == "task":
			number += 1
	return number

# --- Flow -----------------------------------------------------------------

func _show(index: int) -> void:
	step = index
	_completing = false
	_start = {"position": _flat(player.global_position), "deaths": Progression.deaths, "blood": Progression.blood_level,
		"plague": Progression.plague_level, "reaper": Progression.reaper_strikes, "soldiers": Progression.soldiers_defeated}
	if _card:
		_card.queue_free()
	var data: Dictionary = steps[index]
	match data.kind:
		"modal":
			_card = _modal_card(data, _story_body(data))
		"rules":
			_card = _modal_card(data, _rules_body())
		_:
			_card = _task_card(data)
	add_child(_card)
	_place_card()
	move_child(_skip, -1)
	var dimmed: bool = data.kind != "task"
	create_tween().tween_property(_dim, "color:a", 0.62 if dimmed else 0.0, 0.25)
	_skip.visible = index < steps.size() - 1

func _next() -> void:
	if step + 1 >= steps.size():
		_finish()
	else:
		_show(step + 1)

func _finish() -> void:
	if _done:
		return
	_done = true
	Progression.finish_tutorial()
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_callback(func() -> void:
		finished.emit()
		queue_free())

func _process(delta: float) -> void:
	_time += delta
	_place_card()
	queue_redraw()
	if _done or step < 0 or _completing:
		return
	var data: Dictionary = steps[step]
	if data.kind == "task" and (data.check as Callable).call():
		_complete_task()

## A finished task: the card turns green with a tick, then the next step.
func _complete_task() -> void:
	_completing = true
	var panel := _card.get_node("Panel") as PanelContainer
	panel.add_theme_stylebox_override("panel", UiStyle.panel(UiStyle.GREEN))
	var tag := _card.find_child("Tag", true, false) as Label
	if tag:
		tag.text = "DONE!"
		tag.add_theme_color_override("font_color", UiStyle.INK)
		(tag.get_parent() as PanelContainer).add_theme_stylebox_override("panel", UiStyle.chip(UiStyle.GREEN))
	var tween := create_tween()
	tween.tween_property(panel, "scale", Vector2.ONE * 1.04, 0.12)
	tween.tween_property(panel, "scale", Vector2.ONE, 0.12)
	tween.tween_interval(1.0)
	tween.tween_property(_card, "modulate:a", 0.0, 0.25)
	tween.tween_callback(func() -> void: _next.call_deferred())

# --- Cards ----------------------------------------------------------------

func _modal_card(data: Dictionary, content: Control) -> Control:
	var holder := Control.new()
	holder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var panel := PanelContainer.new()
	panel.name = "Panel"
	var style := UiStyle.panel()
	style.content_margin_top = 28
	style.content_margin_left = 36
	style.content_margin_right = 36
	style.content_margin_bottom = 30
	panel.add_theme_stylebox_override("panel", style)
	var width := minf(size.x - 64.0, 600.0)
	panel.custom_minimum_size = Vector2(width, 0)
	panel.add_to_group("touch_ui")
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 18)
	panel.add_child(column)
	# Portrait inside the card's layout, above the title: it can never sit
	# on the text (D-097).
	var badge := PortraitBadge.new()
	badge.texture = PORTRAITS[data.portrait]
	badge.custom_minimum_size = Vector2(132, 132)
	badge.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	badge.ring = UiStyle.RED if data.portrait == "boss" else UiStyle.GOLD
	column.add_child(badge)
	var title := UiStyle.label(data.title, UiStyle.FONT_TITLE, 36, UiStyle.GOLD_LIGHT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(title)
	column.add_child(content)
	var button := UiStyle.button(data.button)
	button.pressed.connect(_next)
	column.add_child(button)
	column.add_child(_dots())
	_fit_wrapping(column, width - 72.0)
	holder.add_child(panel)
	holder.set_meta("place", "centre")
	holder.modulate.a = 0.0
	panel.scale = Vector2.ONE * 0.92
	var tween := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(panel, "scale", Vector2.ONE, 0.3)
	tween.parallel().tween_property(holder, "modulate:a", 1.0, 0.2)
	return holder

func _story_body(data: Dictionary) -> Control:
	var body := UiStyle.body(data.body, 27)
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return body

## The three stats, with the icons the HUD uses.
func _rules_body() -> Control:
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 16)
	var intro := UiStyle.body("Each fall gives +1 max health and more damage. Three icons under your health bar tell the story:", 24, UiStyle.MUTED)
	intro.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(intro)
	for row in [[ICON_DAMAGE, "Damage", "How hard Kaze hits."],
			[ICON_PER_FALL, "Damage per fall", "Added to your damage every time you fall."],
			[ICON_ENEMY_HIT, "Enemy hit", "How much every enemy hit takes. Harder hits mean faster falls."]]:
		var line := HBoxContainer.new()
		line.add_theme_constant_override("separation", 16)
		var icon := TextureRect.new()
		icon.texture = row[0]
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.custom_minimum_size = Vector2(64, 64)
		line.add_child(icon)
		var words := VBoxContainer.new()
		words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		words.add_theme_constant_override("separation", 0)
		words.add_child(UiStyle.label(row[1], UiStyle.FONT_BOLD, 24, UiStyle.GOLD_LIGHT))
		words.add_child(UiStyle.body(row[2], 21))
		line.add_child(words)
		column.add_child(line)
	return column

## Progress dots for the hands-on steps.
func _dots() -> Control:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 10)
	for i in steps.size():
		var dot := ColorRect.new()
		dot.custom_minimum_size = Vector2(22 if i == step else 10, 10)
		dot.color = UiStyle.GOLD if i <= step else Color(UiStyle.MUTED, 0.35)
		row.add_child(dot)
	return row

## Hands-on step: a compact card above the thumb zone, portrait beside the text.
func _task_card(data: Dictionary) -> Control:
	var holder := Control.new()
	holder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var panel := PanelContainer.new()
	panel.name = "Panel"
	var style := UiStyle.panel(UiStyle.GOLD, 0.93, 22)
	style.set_content_margin_all(18)
	style.content_margin_right = 24
	panel.add_theme_stylebox_override("panel", style)
	var width := minf(size.x - 40.0, 640.0)
	panel.custom_minimum_size = Vector2(width, 0)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	panel.add_child(row)
	var badge := PortraitBadge.new()
	badge.texture = PORTRAITS[data.portrait]
	badge.custom_minimum_size = Vector2(100, 100)
	badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(badge)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(column)
	var head := HBoxContainer.new()
	var chip := PanelContainer.new()
	chip.add_theme_stylebox_override("panel", UiStyle.chip(UiStyle.GOLD))
	var tag := UiStyle.label("STEP %d OF %d" % [task_number(step), task_count()], UiStyle.FONT_BOLD, 15, UiStyle.INK)
	tag.name = "Tag"
	chip.add_child(tag)
	head.add_child(chip)
	column.add_child(head)
	var title := UiStyle.label(data.title, UiStyle.FONT_TITLE, 30, UiStyle.GOLD_LIGHT)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(title)
	column.add_child(UiStyle.body(data.body, 22))
	_fit_wrapping(column, width - 18.0 - 24.0 - 100.0 - 18.0)
	holder.add_child(panel)
	holder.set_meta("place", "bottom")
	holder.modulate.a = 0.0
	holder.position.y = 80.0
	var tween := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(holder, "position:y", 0.0, 0.35)
	tween.parallel().tween_property(holder, "modulate:a", 1.0, 0.25)
	return holder

## Keeps the current card centred (story cards) or above the thumb zone
## (steps) every frame, whatever the screen size (D-097).
func _place_card() -> void:
	if _card == null or not is_instance_valid(_card):
		return
	var panel := _card.get_node_or_null("Panel") as Control
	if panel == null:
		return
	panel.size = panel.get_combined_minimum_size()
	if _card.get_meta("place", "") == "centre":
		panel.position = ((size - panel.size) * 0.5).max(Vector2(16, 16))
	else:
		panel.position = Vector2((size.x - panel.size.x) * 0.5, maxf(size.y - THUMB_ZONE - panel.size.y, 60.0))
	panel.pivot_offset = panel.size * 0.5

## Wrapped labels measure their height at zero width unless told their width,
## which makes cards absurdly tall: give each one the room it really has.
func _fit_wrapping(root_node: Node, width: float) -> void:
	for label: Label in root_node.find_children("*", "Label", true, false):
		if label.autowrap_mode == TextServer.AUTOWRAP_OFF:
			continue
		var room := width
		var parent := label.get_parent()
		while parent != root_node and parent != null:
			if parent is HBoxContainer:
				room -= 80.0
			parent = parent.get_parent()
		label.custom_minimum_size.x = room

# --- Targets ----------------------------------------------------------------

func _flat(v: Vector3) -> Vector2:
	return Vector2(v.x, v.z)

func _enemy(id: String) -> Node3D:
	for node in get_tree().get_nodes_in_group("enemies"):
		if node.get("data") is Dictionary and node.data.get("id", "") == id:
			return node
	return null

func _reaper() -> Node3D:
	for node in get_tree().get_nodes_in_group("bodies"):
		if node.name == "Reaper":
			return node
	return null

func _nearest_soldier() -> Node3D:
	var best: Node3D = null
	var best_distance := INF
	for node in get_tree().get_nodes_in_group("enemies"):
		if not (node.get("data") is Dictionary) or not node.data.has("swings") or not node.is_alive():
			continue
		var d := _flat(node.global_position).distance_to(_flat(player.global_position))
		if d < best_distance:
			best_distance = d
			best = node
	return best

func _near(node: Node3D, distance: float) -> bool:
	return node != null and _flat(node.global_position).distance_to(_flat(player.global_position)) < distance

# --- Overlay: target marker, stat highlight, drag hint ----------------------

func _draw() -> void:
	if _done or step < 0 or camera == null:
		return
	var data: Dictionary = steps[step]
	if data.kind != "task":
		return
	if data.has("highlight") and hud != null:
		_draw_highlight(int(data.highlight))
	if data.get("hint", "") == "drag":
		_draw_drag_hint()
	if data.has("target"):
		var target: Node3D = (data.target as Callable).call()
		if target != null:
			_draw_marker(target)

func _draw_highlight(slot: int) -> void:
	var rect: Rect2 = hud.level_rect if slot == 3 else hud.stat_rects[slot]
	if rect.size == Vector2.ZERO:
		return
	var pulse := 0.5 + 0.5 * sin(_time * 6.0)
	var box := rect.grow(6.0 + 3.0 * pulse)
	draw_rect(box, Color(UiStyle.GOLD, 0.16 + 0.12 * pulse))
	draw_rect(box, UiStyle.GOLD_LIGHT, false, 3.0)
	# A small pointer under it.
	var tip := Vector2(box.get_center().x, box.end.y + 4.0)
	draw_colored_polygon(PackedVector2Array([tip, tip + Vector2(-12, 16), tip + Vector2(12, 16)]), UiStyle.GOLD_LIGHT)

func _draw_drag_hint() -> void:
	var centre := Vector2(size.x * 0.5, size.y - 190.0)
	var t := fmod(_time, 1.8) / 1.8
	var reach := Vector2(0, -70).rotated(sin(_time * 1.1) * 0.9) * smoothstep(0.1, 0.7, t)
	draw_arc(centre, 86.0, 0.0, TAU, 64, Color(UiStyle.GOLD, 0.7), 3.0, true)
	draw_circle(centre + reach, 30.0, Color(UiStyle.GOLD_LIGHT, 0.85 * (1.0 - smoothstep(0.75, 1.0, t))))
	draw_circle(centre + reach, 30.0 - 6.0, Color(1, 1, 1, 0.5 * (1.0 - smoothstep(0.75, 1.0, t))))
	var font := UiStyle.FONT_TITLE
	var text := "DRAG"
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 26).x
	draw_string_outline(font, centre + Vector2(-width * 0.5, 130), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 26, 8, UiStyle.INK)
	draw_string(font, centre + Vector2(-width * 0.5, 130), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 26, UiStyle.GOLD_LIGHT)

## Bouncing arrow above the target; on the screen edge when it is off screen.
func _draw_marker(target: Node3D) -> void:
	var height := 10.0
	if target.get("data") is Dictionary:
		height = float(target.data.get("height", 10.0))
	# Above the name and level labels.
	var aim := target.global_position + Vector3(0, height + 9.0, 0)
	var behind := camera.is_position_behind(aim)
	var spot := camera.unproject_position(aim)
	var area := Rect2(Vector2(60, 300), (size - Vector2(120, 300 + THUMB_ZONE + 150)).max(Vector2(10, 10)))
	if not behind and area.has_point(spot):
		var bounce := absf(sin(_time * 4.0)) * 18.0
		var tip := spot + Vector2(0, -bounce)
		var ground := camera.unproject_position(target.global_position)
		var pulse := fmod(_time, 1.2) / 1.2
		draw_set_transform(ground, 0.0, Vector2(1.0, 0.45))
		draw_arc(Vector2.ZERO, 40.0 + 40.0 * pulse, 0.0, TAU, 48, Color(UiStyle.GOLD_LIGHT, 0.8 * (1.0 - pulse)), 5.0, true)
		draw_set_transform(Vector2.ZERO)
		_arrow(tip, Vector2.DOWN, 1.0)
		return
	var middle := area.get_center()
	var way := (spot - middle) if not behind else (middle - spot)
	if way.length() < 0.01:
		return
	way = way.normalized()
	var half := area.size * 0.5
	var reach := minf(absf(half.x / way.x) if absf(way.x) > 0.001 else INF, absf(half.y / way.y) if absf(way.y) > 0.001 else INF)
	_arrow(middle + way * reach, way, 1.0 + 0.1 * sin(_time * 6.0))

func _arrow(tip: Vector2, way: Vector2, grow: float) -> void:
	var side := Vector2(-way.y, way.x)
	var back := tip - way * 46.0 * grow
	var outline := PackedVector2Array([tip + way * 5.0, back + side * 34.0 * grow - way * 4.0, back - way * 4.0 + way * 12.0, back - side * 34.0 * grow - way * 4.0])
	draw_colored_polygon(outline, UiStyle.INK)
	draw_colored_polygon(PackedVector2Array([tip, back + side * 28.0 * grow, back + way * 12.0, back - side * 28.0 * grow]), UiStyle.GOLD)
	draw_colored_polygon(PackedVector2Array([tip, back + side * 28.0 * grow, back + way * 12.0]), UiStyle.GOLD_LIGHT)
