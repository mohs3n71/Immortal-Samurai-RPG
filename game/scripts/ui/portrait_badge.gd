extends Control

## Round character portrait in a gold ring (D-094). Set `texture` and size.

const UiStyle = preload("res://scripts/ui/ui_style.gd")

const CIRCLE := """
shader_type canvas_item;
void fragment() {
	float d = distance(UV, vec2(0.5));
	COLOR = texture(TEXTURE, UV);
	COLOR.a *= 1.0 - smoothstep(0.47, 0.5, d);
}
"""

var texture: Texture2D:
	set(value):
		texture = value
		if _picture:
			_picture.texture = value
var ring := UiStyle.GOLD:
	set(value):
		ring = value
		queue_redraw()
var _picture: TextureRect
static var _shader: Shader

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if _shader == null:
		_shader = Shader.new()
		_shader.code = CIRCLE
	# A soft backdrop disc behind the character.
	_picture = TextureRect.new()
	_picture.texture = texture
	_picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_picture.set_anchors_preset(Control.PRESET_FULL_RECT)
	_picture.offset_left = 6
	_picture.offset_top = 6
	_picture.offset_right = -6
	_picture.offset_bottom = -6
	var material := ShaderMaterial.new()
	material.shader = _shader
	_picture.material = material
	_picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_picture)
	resized.connect(queue_redraw)

func _draw() -> void:
	var c := size * 0.5
	var r := minf(size.x, size.y) * 0.5
	draw_circle(c + Vector2(0, 4), r, Color(0, 0, 0, 0.35))
	draw_circle(c, r, UiStyle.INK)
	draw_circle(c, r - 3.0, Color("5b8f4a"))
	draw_circle(c + Vector2(0, -r * 0.25), r * 0.72, Color("79b35f"))
	draw_arc(c, r - 3.0, 0.0, TAU, 64, ring, 6.0, true)
	draw_arc(c, r - 7.0, PI * 1.1, PI * 1.6, 16, Color(1, 1, 1, 0.35), 2.5, true)
