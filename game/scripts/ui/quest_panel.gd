extends PanelContainer

## Region quest card under the minimap (D-094): "Defeat the Bone Warlord" with
## a power bar comparing the damage Kaze can deal in one 30 s boss window with
## the boss's health, so the player always knows how far he is from ready.
## Turns gold and pulses when ready, green when the boss is beaten.

const Progression = preload("res://scripts/progression.gd")
const EnemyRoster = preload("res://scripts/enemies/enemy_roster.gd")
const UiStyle = preload("res://scripts/ui/ui_style.gd")
const PortraitBadge = preload("res://scripts/ui/portrait_badge.gd")
const BOSS_PORTRAIT := preload("res://assets/ui/portraits/boss.png")
const FROST_BOSS_PORTRAIT := preload("res://assets/ui/portraits/frost-tyrant.png")

const WIDTH := 300.0
## Right edge and top, matching the minimap above (minimap.gd MARGIN, DIAMETER).
const TOP := 46.0 + 220.0 + 14.0
const RIGHT := 22.0

@export var region := 1

var _badge: Control
var _tag: Label
var _title: Label
var _bar: Control
var _status: Label
var _fraction := 0.0
var _shown := 0.0
var _time := 0.0
var _style: StyleBoxFlat

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	anchor_left = 1.0
	anchor_right = 1.0
	offset_left = -RIGHT - WIDTH
	offset_right = -RIGHT
	offset_top = TOP
	custom_minimum_size = Vector2(WIDTH, 0)
	_style = UiStyle.panel(UiStyle.GOLD, 0.9, 18)
	_style.set_content_margin_all(14)
	add_theme_stylebox_override("panel", _style)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	add_child(row)
	var badge := PortraitBadge.new()
	_badge = badge
	badge.texture = FROST_BOSS_PORTRAIT if region == 2 else BOSS_PORTRAIT
	badge.ring = UiStyle.RED
	badge.custom_minimum_size = Vector2(60, 60)
	badge.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	row.add_child(badge)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 4)
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(column)
	var chip := PanelContainer.new()
	chip.add_theme_stylebox_override("panel", UiStyle.chip(UiStyle.GOLD))
	chip.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_tag = UiStyle.label("REGION %d QUEST" % region, UiStyle.FONT_BOLD, 13, UiStyle.INK)
	chip.add_child(_tag)
	column.add_child(chip)
	_title = UiStyle.label("Defeat the %s" % EnemyRoster.boss_entry(region).name, UiStyle.FONT_TITLE, 19, UiStyle.CREAM)
	_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(_title)
	_bar = Control.new()
	_bar.custom_minimum_size = Vector2(0, 26)
	_bar.draw.connect(_draw_bar)
	column.add_child(_bar)
	_status = UiStyle.label("", UiStyle.FONT_BODY, 15, UiStyle.MUTED)
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(_status)
	for wrapped in [_title, _status]:
		wrapped.custom_minimum_size.x = WIDTH - 28.0 - 72.0
	Progression.notifier().changed.connect(_refresh)
	_refresh()

## The quest moves on to the next region once its boss is beaten (D-102:
## main.gd follows Progression.bosses_defeated).
func set_region(value: int) -> void:
	if value == region:
		return
	region = value
	if _title == null:
		return
	_badge.texture = FROST_BOSS_PORTRAIT if region == 2 else BOSS_PORTRAIT
	_badge.queue_redraw()
	_tag.text = "REGION %d QUEST" % region
	_title.text = "Defeat the %s" % EnemyRoster.boss_entry(region).name
	_shown = 0.0
	_refresh()

func boss_health() -> float:
	return float(EnemyRoster.boss_stats(region).health)

func is_complete() -> bool:
	return Progression.bosses_defeated >= region

## 0..1: Kaze's 30 s damage against the boss's health.
func power_fraction() -> float:
	return clampf(Progression.boss_window_damage() / boss_health(), 0.0, 1.0)

func _refresh() -> void:
	_fraction = 1.0 if is_complete() else power_fraction()
	if is_complete():
		_status.text = "Complete! The gate to region %d is open." % (region + 1)
		_status.add_theme_color_override("font_color", UiStyle.GREEN)
		_style.border_color = UiStyle.GREEN
	elif _fraction >= 1.0:
		_status.text = "You are ready! Follow the skull and strike within 30 s."
		_status.add_theme_color_override("font_color", UiStyle.GOLD_LIGHT)
		_style.border_color = UiStyle.GOLD_LIGHT
	else:
		# Region 1 has the knights and Reaper; elsewhere fast travel reaches them.
		_status.text = "Fall, level the knights, visit the Reaper." if region == 1 else "Grow at the knights and Reaper, then head through the gateway north."
		_status.add_theme_color_override("font_color", UiStyle.MUTED)
		_style.border_color = UiStyle.GOLD
	_bar.queue_redraw()

func _process(delta: float) -> void:
	_time += delta
	if not is_equal_approx(_shown, _fraction):
		_shown = move_toward(_shown, _fraction, delta * 0.8)
		_bar.queue_redraw()
	elif _fraction >= 1.0 and not is_complete():
		_bar.queue_redraw()

func _draw_bar() -> void:
	var rect := Rect2(Vector2.ZERO, _bar.size)
	_bar.draw_rect(rect, UiStyle.INK)
	var inner := rect.grow(-3.0)
	_bar.draw_rect(inner, Color(UiStyle.WOOD_LIGHT, 1.0))
	var color := UiStyle.GREEN if is_complete() else (UiStyle.GOLD_LIGHT if _fraction >= 1.0 else UiStyle.RED.lerp(UiStyle.GOLD, _shown))
	if _fraction >= 1.0 and not is_complete():
		color = color.lerp(Color.WHITE, 0.25 + 0.25 * sin(_time * 5.0))
	var fill := Rect2(inner.position, Vector2(inner.size.x * _shown, inner.size.y))
	_bar.draw_rect(fill, color)
	_bar.draw_rect(Rect2(fill.position, Vector2(fill.size.x, fill.size.y * 0.4)), Color(1, 1, 1, 0.18))
	var text := "COMPLETE" if is_complete() else "POWER  %s / %s" % [Progression.format_number(Progression.boss_window_damage()), Progression.format_number(boss_health())]
	var font := UiStyle.FONT_BOLD
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x
	var at := Vector2((rect.size.x - width) * 0.5, rect.size.y * 0.5 + 5.5)
	_bar.draw_string_outline(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, 5, UiStyle.INK)
	_bar.draw_string(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, UiStyle.CREAM)
