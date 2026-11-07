extends Control

## Kaze's health bar (top left), a red screen-edge flash when he is hit, and
## the fade used when he falls and respawns (D-078). Touches pass through.

const BAR_SIZE := Vector2(250, 26)
const MARGIN := Vector2(24, 60)
const FRAME := Color("3a2615")
const BACK := Color(0.16, 0.08, 0.07, 0.85)
const FILL := Color("5fcf4e")
const FILL_LOW := Color("e2a63a")
const FILL_CRITICAL := Color("e0453a")
const HURT := Color(0.85, 0.08, 0.05)
const Progression = preload("res://scripts/progression.gd")
const UiStyle = preload("res://scripts/ui/ui_style.gd")
const ICON_DAMAGE := preload("res://assets/ui/icon_damage.png")
const ICON_MAX_HEALTH := preload("res://assets/ui/icon_max_health.png")
const ICON_FAST_TRAVEL := preload("res://assets/ui/icon_fast_travel.png")
const ICON_PER_FALL := preload("res://assets/ui/icon_damage_per_fall.png")
const ICON_ENEMY_HIT := preload("res://assets/ui/icon_enemy_hit.png")
const ICON_SIZE := 46.0
## Stats row, below the experience bar (relative to the health bar's top).
const STATS_TOP := 50.0

const VIGNETTE := """
shader_type canvas_item;
uniform float strength = 0.0;
uniform vec4 tint : source_color = vec4(0.85, 0.08, 0.05, 1.0);
void fragment() {
	vec2 d = abs(UV - 0.5) * 2.0;
	float edge = smoothstep(0.55, 1.0, max(d.x, d.y));
	COLOR = vec4(tint.rgb, edge * strength);
}
"""

var _health := 1.0
var _health_value := 1
var _max_value := 1
var _shown := 1.0
var _vignette: ColorRect
var _vignette_material: ShaderMaterial
var _fade: ColorRect
var _tween: Tween

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_vignette = ColorRect.new()
	_vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	_vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shader := Shader.new()
	shader.code = VIGNETTE
	_vignette_material = ShaderMaterial.new()
	_vignette_material.shader = shader
	_vignette.material = _vignette_material
	add_child(_vignette)
	_fade = ColorRect.new()
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.color = Color(0, 0, 0, 0)
	add_child(_fade)
	_build_reset_button()

## Progress reset (D-086): the first tap arms it for 3 s, the second wipes the
## save (back to 1 health, 1 damage, all knights Lv 1) and reloads the level.
var reset_button: Button
var tutorial_button: Button
var fast_travel_button: TextureButton
signal tutorial_requested
signal fast_travel_requested
var _reset_armed := 0.0

func _build_reset_button() -> void:
	reset_button = Button.new()
	reset_button.name = "ResetButton"
	reset_button.text = "RESET"
	reset_button.focus_mode = Control.FOCUS_NONE
	reset_button.position = MARGIN + Vector2(0, STATS_TOP + ICON_SIZE + 10.0)
	reset_button.custom_minimum_size = Vector2(110, 44)
	reset_button.add_theme_font_size_override("font_size", 20)
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0.16, 0.08, 0.07, 0.8)
	box.border_color = FRAME
	box.set_border_width_all(3)
	box.set_corner_radius_all(8)
	for style in ["normal", "hover", "pressed", "focus"]:
		reset_button.add_theme_stylebox_override(style, box)
	reset_button.pressed.connect(_on_reset_pressed)
	reset_button.add_to_group("touch_ui")
	add_child(reset_button)
	# Replay the tutorial any time (D-097); progress is kept.
	tutorial_button = Button.new()
	tutorial_button.name = "TutorialButton"
	tutorial_button.text = "HOW TO PLAY"
	tutorial_button.focus_mode = Control.FOCUS_NONE
	tutorial_button.position = reset_button.position + Vector2(122, 0)
	tutorial_button.custom_minimum_size = Vector2(150, 44)
	tutorial_button.add_theme_font_size_override("font_size", 20)
	for style in ["normal", "hover", "pressed", "focus"]:
		tutorial_button.add_theme_stylebox_override(style, box)
	tutorial_button.pressed.connect(func() -> void: tutorial_requested.emit())
	tutorial_button.add_to_group("touch_ui")
	add_child(tutorial_button)
	# Fast travel to the Reaper and knights (D-100); main.gd shows it when useful.
	fast_travel_button = TextureButton.new()
	fast_travel_button.name = "FastTravelButton"
	fast_travel_button.texture_normal = ICON_FAST_TRAVEL
	fast_travel_button.ignore_texture_size = true
	fast_travel_button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	fast_travel_button.custom_minimum_size = Vector2(60, 60)
	fast_travel_button.size = Vector2(60, 60)
	fast_travel_button.focus_mode = Control.FOCUS_NONE
	fast_travel_button.position = reset_button.position + Vector2(284, -8)
	fast_travel_button.pressed.connect(func() -> void: fast_travel_requested.emit())
	fast_travel_button.add_to_group("touch_ui")
	fast_travel_button.visible = false
	add_child(fast_travel_button)
	# Combat lock (D-104): crossed swords on a red disc over the icon.
	_combat_badge = Control.new()
	_combat_badge.name = "CombatBadge"
	_combat_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_combat_badge.position = Vector2(34, 34)
	_combat_badge.size = Vector2(30, 30)
	_combat_badge.draw.connect(func() -> void: _draw_swords(_combat_badge, Vector2(15, 15), 15.0))
	_combat_badge.visible = false
	fast_travel_button.add_child(_combat_badge)

var _combat_badge: Control
## True while fast travel is locked because Kaze is fighting (D-104).
var fast_travel_blocked := false

func set_fast_travel_blocked(blocked: bool) -> void:
	if blocked == fast_travel_blocked:
		return
	fast_travel_blocked = blocked
	_combat_badge.visible = blocked
	fast_travel_button.modulate = Color(0.55, 0.55, 0.6, 1.0) if blocked else Color.WHITE
	_combat_badge.modulate = Color(1.8, 1.8, 1.7, 1.0) if blocked else Color.WHITE

## Crossed swords on a red disc, drawn into `canvas` around `at`.
func _draw_swords(canvas: CanvasItem, at: Vector2, radius: float) -> void:
	canvas.draw_circle(at, radius, FRAME)
	canvas.draw_circle(at, radius - 2.5, Color("c8392b"))
	for side in [-1.0, 1.0]:
		var way := Vector2(side, -1.0).normalized()
		var across := Vector2(-way.y, way.x)
		var tip := at + way * radius * 0.62
		var hilt := at - way * radius * 0.38
		var blade := PackedVector2Array([tip, hilt + across * 1.8, hilt - across * 1.8])
		canvas.draw_colored_polygon(blade, Color("f4f1ea"))
		canvas.draw_line(hilt + across * radius * 0.28, hilt - across * radius * 0.28, Color("ffd45a"), 2.5)
		canvas.draw_line(hilt, at - way * radius * 0.62, Color("6b3d1f"), 3.0)

## Warning card (D-104): crossed swords, a title and a hint, under the HUD
## buttons; a new notice replaces the old one. The fast travel icon shakes.
var _notice: Control

func show_combat_notice() -> void:
	if _notice != null and is_instance_valid(_notice):
		_notice.queue_free()
	var card := PanelContainer.new()
	card.name = "CombatNotice"
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := UiStyle.panel(UiStyle.RED, 0.94, 16)
	style.content_margin_left = 14
	style.content_margin_right = 18
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	card.add_theme_stylebox_override("panel", style)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	card.add_child(row)
	var badge := Control.new()
	badge.custom_minimum_size = Vector2(52, 52)
	badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	badge.draw.connect(func() -> void: _draw_swords(badge, Vector2(26, 26), 26.0))
	row.add_child(badge)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 2)
	row.add_child(column)
	column.add_child(UiStyle.label("Can't fast travel in a fight", UiStyle.FONT_TITLE, 21, UiStyle.CREAM))
	var hint := UiStyle.label("Win the fight or get away from the enemy first.", UiStyle.FONT_BODY, 15, UiStyle.MUTED)
	# Narrow enough to stay clear of the quest card on the right.
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.custom_minimum_size.x = 270.0
	column.add_child(hint)
	add_child(card)
	_notice = card
	card.reset_size()
	var top := MARGIN.y + STATS_TOP + ICON_SIZE + 10.0 + 44.0 + 12.0
	card.position = Vector2(MARGIN.x - 6.0, top + 10.0)
	card.modulate.a = 0.0
	var tween := card.create_tween()
	tween.tween_property(card, "position:y", top, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(card, "modulate:a", 1.0, 0.15)
	tween.tween_interval(2.2)
	tween.tween_property(card, "modulate:a", 0.0, 0.4)
	tween.tween_callback(card.queue_free)
	var home := reset_button.position + Vector2(284, -8)
	var shake := fast_travel_button.create_tween()
	for offset in [10.0, -8.0, 6.0, -4.0, 0.0]:
		shake.tween_property(fast_travel_button, "position:x", home.x + offset, 0.05)

func _on_reset_pressed() -> void:
	if _reset_armed <= 0.0:
		_reset_armed = 3.0
		reset_button.text = "TAP AGAIN TO RESET"
		reset_button.add_theme_color_override("font_color", Color("ff7a6a"))
		reset_button.size = Vector2.ZERO
		return
	_reset_armed = 0.0
	Progression.reset()
	get_tree().reload_current_scene()

func bind(player: Node) -> void:
	player.health_changed.connect(_on_health_changed)
	Progression.notifier().changed.connect(queue_redraw)
	_health_value = player.health
	_max_value = player.max_health
	queue_redraw()

## "+1 max health, +N damage" after Kaze falls (D-080). A small card under
## the HUD buttons (D-098: it used to float over the map, off-centre); a new
## fall replaces the card instead of stacking.
var _reward: Control

func show_reward(damage_gained: int) -> void:
	if _reward != null and is_instance_valid(_reward):
		_reward.queue_free()
	var card := PanelContainer.new()
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := UiStyle.panel(UiStyle.GOLD, 0.9, 14)
	style.shadow_size = 8
	style.content_margin_left = 14
	style.content_margin_right = 16
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	card.add_theme_stylebox_override("panel", style)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	card.add_child(row)
	# Icons and numbers only (D-099): max health, then damage.
	for part in [[ICON_MAX_HEALTH, "+1", UiStyle.GREEN], [ICON_DAMAGE, "+" + Progression.format_number(damage_gained), UiStyle.GOLD_LIGHT]]:
		var icon := TextureRect.new()
		icon.texture = part[0]
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.custom_minimum_size = Vector2(36, 36)
		row.add_child(icon)
		var number := UiStyle.label(part[1], UiStyle.FONT_TITLE, 24, part[2])
		row.add_child(number)
		row.add_child(Control.new())
	add_child(card)
	_reward = card
	var top := MARGIN.y + STATS_TOP + ICON_SIZE + 10.0 + 44.0 + 12.0
	card.position = Vector2(MARGIN.x - 6.0, top + 10.0)
	card.modulate.a = 0.0
	var tween := card.create_tween()
	tween.tween_property(card, "position:y", top, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(card, "modulate:a", 1.0, 0.15)
	tween.tween_interval(1.4)
	tween.tween_property(card, "modulate:a", 0.0, 0.4)
	tween.tween_callback(card.queue_free)

func _on_health_changed(health: int, max_health: int) -> void:
	var previous := _health
	_health_value = health
	_max_value = max_health
	_health = float(health) / float(max_health)
	if _health < previous:
		if _tween:
			_tween.kill()
		_tween = create_tween()
		_tween.tween_method(_set_vignette, 0.75, 0.0, 0.45)
	queue_redraw()

## Fades to black and back; `midpoint` runs while the screen is dark.
func fade_through_black(midpoint: Callable) -> void:
	var tween := create_tween()
	tween.tween_property(_fade, "color:a", 1.0, 0.6).set_delay(0.9)
	tween.tween_callback(midpoint)
	tween.tween_property(_fade, "color:a", 0.0, 0.5).set_delay(0.2)

func _number(value: float) -> String:
	return Progression.format_number(value)

## One icon + number group; returns the x where the next group starts.
## Screen rects of the three stat groups (damage, per fall, enemy hit) and the
## level/experience bar, for the tutorial's highlights (D-094).
var stat_rects: Array[Rect2] = [Rect2(), Rect2(), Rect2()]
var level_rect := Rect2()

func _draw_stat(font: Font, icon: Texture2D, x: float, top: float, value: String, color: Color, note: String) -> float:
	var start := x
	draw_texture_rect(icon, Rect2(Vector2(x, top), Vector2(ICON_SIZE, ICON_SIZE)), false)
	x += ICON_SIZE + 4.0
	var baseline := top + ICON_SIZE * 0.5 + 9.0
	draw_string_outline(font, Vector2(x, baseline), value, HORIZONTAL_ALIGNMENT_LEFT, -1, 26, 7, FRAME)
	draw_string(font, Vector2(x, baseline), value, HORIZONTAL_ALIGNMENT_LEFT, -1, 26, color)
	x += font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, 26).x
	if note != "":
		x += 4.0
		draw_string_outline(font, Vector2(x, baseline - 1.0), note, HORIZONTAL_ALIGNMENT_LEFT, -1, 17, 5, FRAME)
		draw_string(font, Vector2(x, baseline - 1.0), note, HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("8fe3ff"))
		x += font.get_string_size(note, HORIZONTAL_ALIGNMENT_LEFT, -1, 17).x
	var slot := 0 if icon == ICON_DAMAGE else (1 if icon == ICON_PER_FALL else 2)
	stat_rects[slot] = Rect2(start, top, x - start + 4.0, ICON_SIZE)
	return x + 20.0

func _set_vignette(value: float) -> void:
	_vignette_material.set_shader_parameter("strength", value)

func _process(delta: float) -> void:
	if _reset_armed > 0.0:
		_reset_armed -= delta
		if _reset_armed <= 0.0:
			reset_button.text = "RESET"
			reset_button.remove_theme_color_override("font_color")
			reset_button.size = Vector2.ZERO
	if not is_equal_approx(_shown, _health):
		_shown = move_toward(_shown, _health, delta * 1.5)
		queue_redraw()

func _draw() -> void:
	var rect := Rect2(MARGIN, BAR_SIZE)
	draw_rect(rect.grow(4.0), FRAME)
	draw_rect(rect, BACK)
	# Recent damage shows as a pale strip that drains after the real value.
	if _shown > _health:
		draw_rect(Rect2(rect.position, Vector2(rect.size.x * _shown, rect.size.y)), Color(1, 0.9, 0.75, 0.8))
	var color := FILL if _health > 0.5 else (FILL_LOW if _health > 0.25 else FILL_CRITICAL)
	draw_rect(Rect2(rect.position, Vector2(rect.size.x * _health, rect.size.y)), color)
	draw_rect(Rect2(rect.position, Vector2(rect.size.x * _health, rect.size.y * 0.35)), Color(1, 1, 1, 0.18))
	var font := ThemeDB.fallback_font
	draw_string_outline(font, rect.position + Vector2(24, 20), "%s / %s" % [Progression.format_number(_health_value), Progression.format_number(_max_value)], HORIZONTAL_ALIGNMENT_LEFT, -1, 20, 6, FRAME)
	draw_string(font, rect.position + Vector2(24, 20), "%s / %s" % [Progression.format_number(_health_value), Progression.format_number(_max_value)], HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color.WHITE)
	# Hero level and experience (D-080), then the stats line.
	Progression.ensure_loaded()
	var xp_rect := Rect2(rect.position + Vector2(0, rect.size.y + 10), Vector2(rect.size.x, 9))
	level_rect = Rect2(xp_rect.position - Vector2(4, 4), Vector2(xp_rect.size.x + 70, xp_rect.size.y + 8))
	draw_rect(xp_rect.grow(2.0), FRAME)
	draw_rect(xp_rect, BACK)
	var xp_fraction := clampf(float(Progression.experience) / float(Progression.experience_to_next()), 0.0, 1.0)
	draw_rect(Rect2(xp_rect.position, Vector2(xp_rect.size.x * xp_fraction, xp_rect.size.y)), Color("5ec8f2"))
	var level_text := "Lv %d" % Progression.hero_level
	draw_string_outline(font, rect.position + Vector2(rect.size.x + 12, 20), level_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, 6, FRAME)
	draw_string(font, rect.position + Vector2(rect.size.x + 12, 20), level_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color("8fe3ff"))
	# Stats as icons and numbers, no words (D-089): damage, damage per fall, enemy hit.
	var bonus := Progression.hero_level - 1
	var x := rect.position.x - 6.0
	var top := rect.position.y + STATS_TOP
	x = _draw_stat(font, ICON_DAMAGE, x, top, _number(Progression.effective_damage()), Color("ffe08a"), ("+%d%%" % bonus) if bonus > 0 else "")
	x = _draw_stat(font, ICON_PER_FALL, x, top, "+" + _number(Progression.damage_per_fall()), Color("9df29a"), "")
	_draw_stat(font, ICON_ENEMY_HIT, x, top, _number(Progression.enemy_hit()), Color("ff9a8a"), "")
	# Heart badge at the left end.
	var heart := MARGIN + Vector2(-2, BAR_SIZE.y * 0.5)
	draw_circle(heart, 19.0, FRAME)
	draw_circle(heart + Vector2(-5, -3), 7.5, HURT)
	draw_circle(heart + Vector2(5, -3), 7.5, HURT)
	draw_colored_polygon(PackedVector2Array([heart + Vector2(-12, -1), heart + Vector2(12, -1), heart + Vector2(0, 12)]), HURT)
