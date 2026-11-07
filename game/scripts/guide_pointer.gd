extends Control

## Screen-edge guide to the region's goal (D-090): while the boss (or, once
## beaten, the open gate) is off screen, a pulsing arrow with its badge and
## the distance sits on the screen edge in its direction. Hidden when the goal
## is on screen. Touches pass through.

const Progression = preload("res://scripts/progression.gd")
const Travel = preload("res://scripts/world/travel.gd")
const BOSS_MARKER := preload("res://assets/ui/icon_boss_marker.png")
const GATE_MARKER := preload("res://assets/ui/icon_gate_marker.png")
const FRAME := Color("3a2615")
const GOLD := Color("ffd45a")
const ICON := 58.0
## Keep clear of the HUD at the top and the joystick at the bottom.
const INSET := Vector2(90, 90)
## Below the HUD and the quest card under the minimap (D-094).
const INSET_TOP := 450.0
const INSET_BOTTOM := 380.0
## World units per "m" shown.
const UNITS_PER_METRE := 2.0

var player: Node3D
var camera: Camera3D
## Screen point where the pointer sits, or Vector2.INF when hidden (tests).
var shown_at := Vector2.INF

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)

func _process(_delta: float) -> void:
	queue_redraw()

func _target() -> Node3D:
	return Travel.guide_target(get_tree())

func _draw() -> void:
	shown_at = Vector2.INF
	# The tutorial shows its own markers first (D-094).
	if Progression.tutorial_running:
		return
	var target := _target()
	if target == null or player == null or camera == null:
		return
	var view := get_viewport_rect().size
	var aim := target.global_position + Vector3(0, 4.0, 0)
	var behind := camera.is_position_behind(aim)
	var screen := camera.unproject_position(aim)
	var area := Rect2(Vector2(INSET.x, INSET_TOP), view - Vector2(INSET.x * 2.0, INSET_TOP + INSET_BOTTOM))
	if not behind and Rect2(Vector2.ZERO, view).grow(-20.0).has_point(screen):
		return
	# Direction from the screen centre toward the goal, clamped to the inset box.
	var middle := area.get_center()
	var way := (screen - middle) if not behind else (middle - screen)
	if way.length() < 0.01:
		return
	way = way.normalized()
	var half := area.size * 0.5
	var reach := minf(absf(half.x / way.x) if absf(way.x) > 0.001 else INF, absf(half.y / way.y) if absf(way.y) > 0.001 else INF)
	var spot := middle + way * reach
	shown_at = spot
	var pulse := 0.5 + 0.5 * sin(Time.get_ticks_msec() / 140.0)
	var size := ICON * (1.0 + 0.08 * pulse)
	# Arrow on the outer side of the badge.
	var side := Vector2(-way.y, way.x)
	var tip := spot + way * (size * 0.5 + 30.0)
	var base := spot + way * (size * 0.5 + 4.0)
	draw_colored_polygon(PackedVector2Array([tip + way * 4.0, base + side * 22.0 - way * 2.0, base - side * 22.0 - way * 2.0]), FRAME)
	draw_colored_polygon(PackedVector2Array([tip, base + side * 17.0, base - side * 17.0]), GOLD.lerp(Color.WHITE, pulse * 0.5))
	# Glow ring that flashes.
	draw_circle(spot, size * 0.5 + 10.0 * pulse + 4.0, Color(1.0, 0.85, 0.35, 0.35 * (1.0 - pulse)))
	var icon: Texture2D = GATE_MARKER if target.get_meta("guide", "") == "gate" else BOSS_MARKER
	draw_texture_rect(icon, Rect2(spot - Vector2(size, size) * 0.5, Vector2(size, size)), false)
	# Distance under the badge.
	var metres := Vector2(target.global_position.x - player.global_position.x, target.global_position.z - player.global_position.z).length() / UNITS_PER_METRE
	var text := "%dm" % roundi(metres)
	var font := ThemeDB.fallback_font
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 24).x
	var at := spot + Vector2(-width * 0.5, size * 0.5 + 26.0)
	draw_string_outline(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, 7, FRAME)
	draw_string(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color("f6ead2"))
