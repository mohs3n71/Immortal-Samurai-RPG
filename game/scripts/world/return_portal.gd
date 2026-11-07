extends Node3D

## Return portal (D-100): appears by the village after a fast travel and takes
## Kaze back to where he was. A glowing ring with a swirling centre, a soft
## light and a label naming where it leads. No collision; stepping into it
## (within REACH) emits `entered` once.

signal entered

const REACH := 4.0
const SWIRL := """
shader_type spatial;
render_mode unshaded, cull_disabled;
uniform vec4 tint : source_color = vec4(0.25, 0.55, 1.0, 1.0);
void fragment() {
	vec2 p = UV - 0.5;
	float r = length(p) * 2.0;
	float a = atan(p.y, p.x);
	float swirl = sin(a * 3.0 + r * 9.0 - TIME * 4.0) * 0.5 + 0.5;
	float glow = (1.0 - smoothstep(0.55, 1.0, r)) * (0.35 + 0.65 * swirl);
	vec3 deep = tint.rgb * 0.55;
	ALBEDO = mix(deep, mix(tint.rgb, vec3(0.9, 0.97, 1.0), 0.5), swirl * (1.0 - r * 0.5));
	ALPHA = clamp(glow * 1.25, 0.0, 0.95);
}
"""

@export var label_text := "Return"
@export var tint := Color(0.3, 0.62, 1.0)

var hero: Node3D
var _armed := 0.8
var _done := false
var _disc: MeshInstance3D
var _ring: MeshInstance3D

func _ready() -> void:
	var stand := Node3D.new()
	stand.position.y = 4.6
	add_child(stand)
	_ring = MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 3.5
	torus.outer_radius = 4.3
	torus.rings = 32
	torus.ring_segments = 10
	_ring.mesh = torus
	_ring.rotation.x = PI / 2.0
	var stone := StandardMaterial3D.new()
	stone.albedo_color = Color(0.75, 0.88, 1.0)
	stone.emission_enabled = true
	stone.emission = tint
	stone.emission_energy_multiplier = 1.6
	_ring.material_override = stone
	_ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	stand.add_child(_ring)
	_disc = MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(7.8, 7.8)
	_disc.mesh = quad
	var shader := Shader.new()
	shader.code = SWIRL
	var swirl := ShaderMaterial.new()
	swirl.shader = shader
	swirl.set_shader_parameter("tint", tint)
	_disc.material_override = swirl
	_disc.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	stand.add_child(_disc)
	var glow := OmniLight3D.new()
	glow.light_color = tint
	glow.light_energy = 1.4
	glow.omni_range = 9.0
	glow.position.y = 3.6
	add_child(glow)
	var label := Label3D.new()
	label.text = label_text
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.font_size = 72
	label.outline_size = 18
	label.pixel_size = 0.02
	label.modulate = Color("bfeaff")
	label.outline_modulate = Color("10202e")
	label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	label.position.y = 10.2
	add_child(label)
	scale = Vector3.ONE * 0.2
	create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).tween_property(self, "scale", Vector3.ONE, 0.5)

func _process(delta: float) -> void:
	_ring.rotate_z(delta * 0.6)
	_disc.rotate_z(-delta * 1.2)
	if hero == null or _done:
		return
	_armed -= delta
	var offset := hero.global_position - global_position
	offset.y = 0.0
	if _armed <= 0.0 and offset.length() < REACH:
		_done = true
		entered.emit()
