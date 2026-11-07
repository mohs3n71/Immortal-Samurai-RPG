extends Control

const RADIUS := 86.0
const DEAD_ZONE := 0.12

var direction := Vector2.ZERO
var active_touch := -1
var mouse_active := false
var knob_offset := Vector2.ZERO
## Floating stick: it appears wherever the thumb first touches the screen,
## which suits portrait play. Until then a faint hint shows its rest spot.
var touch_center := Vector2.ZERO
var held := false

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and active_touch == -1 and _in_activation_area(event.position):
			active_touch = event.index
			_update_direction(event.position)
		elif not event.pressed and event.index == active_touch:
			active_touch = -1
			_reset()
	elif event is InputEventScreenDrag and event.index == active_touch:
		_update_direction(event.position)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and _in_activation_area(event.position) and active_touch == -1:
			mouse_active = true
			_update_direction(event.position)
		elif not event.pressed and mouse_active:
			mouse_active = false
			_reset()
	elif event is InputEventMouseMotion and mouse_active:
		_update_direction(event.position)

func _rest_center() -> Vector2:
	return Vector2(size.x * 0.5, size.y - 190.0)

func _center() -> Vector2:
	return touch_center if held else _rest_center()

## Any touch on the screen starts the stick there (there are no other buttons).
func _in_activation_area(position: Vector2) -> bool:
	# Buttons and cards (group "touch_ui") take their own touches (D-094).
	for node in get_tree().get_nodes_in_group("touch_ui"):
		var control := node as Control
		if control != null and control.is_visible_in_tree() and control.get_global_rect().has_point(position):
			return false
	touch_center = position
	held = true
	return true

func _update_direction(position: Vector2) -> void:
	knob_offset = (position - _center()).limit_length(RADIUS)
	direction = knob_offset / RADIUS
	if direction.length() < DEAD_ZONE:
		direction = Vector2.ZERO
	queue_redraw()

func _reset() -> void:
	held = false
	knob_offset = Vector2.ZERO
	direction = Vector2.ZERO
	queue_redraw()

func _draw() -> void:
	var center := _center()
	if not held:
		draw_circle(center, RADIUS, Color(0.06, 0.10, 0.13, 0.18))
		draw_arc(center, RADIUS - 2.0, 0.0, TAU, 64, Color(0.79, 0.87, 0.81, 0.25), 2.0, true)
		draw_circle(center, 25.0, Color(0.79, 0.86, 0.82, 0.3))
		return
	draw_circle(center, RADIUS + 4.0, Color(0.72, 0.79, 0.77, 0.22))
	draw_circle(center, RADIUS, Color(0.06, 0.10, 0.13, 0.52))
	draw_arc(center, RADIUS - 2.0, 0.0, TAU, 64, Color(0.79, 0.87, 0.81, 0.48), 2.0, true)
	draw_circle(center + knob_offset, 31.0, Color(0.79, 0.86, 0.82, 0.85))
	draw_circle(center + knob_offset, 25.0, Color(0.28, 0.39, 0.36, 0.95))
