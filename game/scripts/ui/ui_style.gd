extends RefCounted

## Shared look for cards, buttons and text (D-094): dark wood panels with a
## gold rim, Inter fonts, warm cream text. Matches the HUD frame colours.

const FONT_TITLE := preload("res://assets/ui/fonts/Inter-Black.otf")
const FONT_BOLD := preload("res://assets/ui/fonts/Inter-ExtraBold.otf")
const FONT_BODY := preload("res://assets/ui/fonts/Inter-SemiBold.otf")

const WOOD := Color("22150c")
const WOOD_LIGHT := Color("3a2615")
const GOLD := Color("f2c14e")
const GOLD_LIGHT := Color("ffe08a")
const CREAM := Color("f6ead2")
const MUTED := Color("c9b48f")
const GREEN := Color("8ee07a")
const RED := Color("ff7a6a")
const INK := Color("1b1009")

static func panel(border := GOLD, alpha := 0.95, radius := 24) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = Color(WOOD, alpha)
	box.border_color = border
	box.set_border_width_all(3)
	box.set_corner_radius_all(radius)
	box.shadow_color = Color(0, 0, 0, 0.45)
	box.shadow_size = 16
	box.shadow_offset = Vector2(0, 6)
	box.set_content_margin_all(24)
	box.anti_aliasing = true
	return box

static func chip(color := GOLD) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.set_corner_radius_all(12)
	box.content_margin_left = 12
	box.content_margin_right = 12
	box.content_margin_top = 3
	box.content_margin_bottom = 3
	return box

## A big gold call-to-action button.
static func button(text: String, primary := true) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(0, 76)
	b.add_theme_font_override("font", FONT_TITLE)
	b.add_theme_font_size_override("font_size", 28)
	var face := StyleBoxFlat.new()
	face.bg_color = GOLD if primary else Color(WOOD_LIGHT, 0.9)
	face.border_color = INK if primary else Color(GOLD, 0.6)
	face.set_border_width_all(3)
	face.border_width_bottom = 7
	face.set_corner_radius_all(18)
	face.content_margin_left = 30
	face.content_margin_right = 30
	face.anti_aliasing = true
	var pressed := face.duplicate() as StyleBoxFlat
	pressed.bg_color = face.bg_color.darkened(0.15)
	pressed.border_width_bottom = 3
	pressed.content_margin_top = 4
	for state in ["normal", "hover", "focus"]:
		b.add_theme_stylebox_override(state, face)
	b.add_theme_stylebox_override("pressed", pressed)
	var ink := INK if primary else CREAM
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(state, ink)
	b.add_to_group("touch_ui")
	return b

static func label(text: String, font: Font, size: int, color := CREAM, outline := 0) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", font)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	if outline > 0:
		l.add_theme_constant_override("outline_size", outline)
		l.add_theme_color_override("font_outline_color", INK)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l

static func body(text: String, size := 26, color := CREAM) -> Label:
	var l := label(text, FONT_BODY, size, color)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_constant_override("line_spacing", 4)
	return l
