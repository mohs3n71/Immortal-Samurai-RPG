extends Control

## Round minimap in the top-right corner (D-077). Shows a pre-rendered
## top-down picture of the Meadowlands (assets/ui/minimap-v001.png, rendered by
## tests/capture_overview.gd and shaded by tools/minimap_image.py), turned to
## match the isometric camera so "up" on the minimap is "up" on screen. The
## hero is the arrow in the middle; enemies are dots. Touches pass through.

const Travel = preload("res://scripts/world/travel.gd")
const MAP_TEXTURE := preload("res://assets/ui/minimap-v001.png")
## The region's map image (D-100); main.gd sets it before adding the minimap.
var map_texture: Texture2D = MAP_TEXTURE
## World point (x, z) at the centre of map_texture.
var map_origin := Vector2.ZERO
## Map of the region to the north (D-102), centred on second_origin, shown
## north of world z split_z.
var second_texture: Texture2D
var second_origin := Vector2.ZERO
var split_z := 0.0
const BOSS_MARKER := preload("res://assets/ui/icon_boss_marker.png")
const GATE_MARKER := preload("res://assets/ui/icon_gate_marker.png")
## Round portrait markers for the Reaper and knights (D-104); off the map they
## sit on the rim in their direction, so the way back is always shown.
const PORTRAITS := {
	"blood-knight": preload("res://assets/ui/portraits/blood-knight.png"),
	"plague-knight": preload("res://assets/ui/portraits/plague-knight.png"),
	"reaper": preload("res://assets/ui/portraits/reaper.png"),
}
const PORTRAIT_RINGS := {"blood-knight": Color("d23b30"), "plague-knight": Color("7fc23a"), "reaper": Color("a77be0")}
const PORTRAIT_SIZE := 30.0
## Guide marker size; off the map it sits on the rim, pointing the way (D-090).
const GUIDE_SIZE := 30.0
## World units covered by the texture (centered on the origin).
const MAP_WORLD_SIZE := 260.0
## World units shown across the minimap.
const VIEW_WORLD_SIZE := 120.0
const DIAMETER := 220.0
const MARGIN := Vector2(22, 46)
const RIM := Color("5c4028")
const RIM_LIGHT := Color("e2c47f")
const HERO := Color("fdf6e3")
const HERO_OUTLINE := Color("1b1c24")
const ENEMY := Color("d9453a")
const ENEMY_DOWN := Color(0.35, 0.3, 0.28, 0.8)

const SHADER := """
shader_type canvas_item;
uniform sampler2D map_texture : filter_linear, repeat_disable;
uniform vec2 center_uv = vec2(0.5);
uniform vec2 right_uv = vec2(1.0, 0.0);
uniform vec2 down_uv = vec2(0.0, 1.0);
uniform vec3 outside_color : source_color = vec3(0.2, 0.25, 0.16);
// The next region's map, north of split_v (D-102: one world).
uniform sampler2D second_texture : filter_linear, repeat_disable;
uniform bool has_second = false;
uniform vec2 second_shift = vec2(0.0);
uniform float split_v = -1.0;
void fragment() {
	vec2 d = UV - 0.5;
	float r = length(d);
	vec2 uv = center_uv + right_uv * d.x + down_uv * d.y;
	vec3 color = texture(map_texture, uv).rgb;
	if (has_second && uv.y < split_v) {
		uv += second_shift;
		color = texture(second_texture, uv).rgb;
	}
	float inside = step(0.0, uv.x) * step(uv.x, 1.0) * step(0.0, uv.y) * step(uv.y, 1.0);
	color = mix(outside_color, color, inside);
	// Soft circular edge.
	float alpha = 1.0 - smoothstep(0.485, 0.5, r);
	COLOR = vec4(color, alpha * 0.94);
}
"""

var player: Node3D
var camera: Camera3D
var _map: TextureRect
var _overlay: Control
var _material: ShaderMaterial

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Anchored to the top-right corner; offsets are measured from that corner.
	anchor_left = 1.0
	anchor_right = 1.0
	anchor_top = 0.0
	anchor_bottom = 0.0
	offset_left = -DIAMETER - MARGIN.x
	offset_right = -MARGIN.x
	offset_top = MARGIN.y
	offset_bottom = MARGIN.y + DIAMETER
	var shader := Shader.new()
	shader.code = SHADER
	_material = ShaderMaterial.new()
	_material.shader = shader
	_material.set_shader_parameter("map_texture", map_texture)
	if second_texture != null:
		_material.set_shader_parameter("second_texture", second_texture)
		_material.set_shader_parameter("has_second", true)
		_material.set_shader_parameter("second_shift", (map_origin - second_origin) / MAP_WORLD_SIZE)
		_material.set_shader_parameter("split_v", (split_z - map_origin.y) / MAP_WORLD_SIZE + 0.5)
	_map = TextureRect.new()
	_map.name = "Map"
	_map.texture = map_texture
	_map.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_map.stretch_mode = TextureRect.STRETCH_SCALE
	_map.size = Vector2(DIAMETER, DIAMETER)
	_map.material = _material
	_map.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_map)
	_overlay = Control.new()
	_overlay.name = "Markers"
	_overlay.size = Vector2(DIAMETER, DIAMETER)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.draw.connect(_draw_markers)
	add_child(_overlay)

func _process(_delta: float) -> void:
	if player == null or camera == null:
		return
	var right := _flat(camera.global_basis.x)
	var down := _flat(camera.global_basis.z)
	var view := VIEW_WORLD_SIZE / MAP_WORLD_SIZE
	var at := player.global_position
	_material.set_shader_parameter("center_uv", (Vector2(at.x, at.z) - map_origin) / MAP_WORLD_SIZE + Vector2(0.5, 0.5))
	_material.set_shader_parameter("right_uv", right * view)
	_material.set_shader_parameter("down_uv", down * view)
	_overlay.queue_redraw()

## Screen offset (pixels from the minimap centre) of a world position.
func to_minimap(world: Vector3) -> Vector2:
	var offset := Vector2(world.x - player.global_position.x, world.z - player.global_position.z)
	var scale := DIAMETER / VIEW_WORLD_SIZE
	return Vector2(offset.dot(_flat(camera.global_basis.x)), offset.dot(_flat(camera.global_basis.z))) * scale

func _draw_markers() -> void:
	var center := Vector2(DIAMETER, DIAMETER) / 2.0
	var radius := DIAMETER / 2.0
	if player != null and camera != null:
		for enemy in get_tree().get_nodes_in_group("enemies"):
			if not (enemy is Node3D) or enemy.is_in_group("minimap_icons"):
				continue
			var spot := to_minimap(enemy.global_position)
			if spot.length() > radius - 8.0:
				continue
			var alive: bool = not enemy.has_method("is_alive") or enemy.is_alive()
			_overlay.draw_circle(center + spot, 6.5, HERO_OUTLINE)
			_overlay.draw_circle(center + spot, 5.0, ENEMY if alive else ENEMY_DOWN)
		for marked in get_tree().get_nodes_in_group("minimap_icons"):
			_draw_portrait(center, radius, marked)
		var visual: Node3D = player.get("visual")
		var yaw := visual.global_rotation.y if visual != null else 0.0
		var facing := to_minimap(player.global_position + Vector3(sin(yaw), 0, cos(yaw))).normalized()
		_draw_arrow(center, facing)
	_overlay.draw_arc(center, radius - 2.0, 0.0, TAU, 64, RIM, 6.0, true)
	_overlay.draw_arc(center, radius - 5.5, 0.0, TAU, 64, RIM_LIGHT, 1.5, true)
	# Guide last so the rim never covers its pointer.
	if player != null and camera != null:
		_draw_guide(center, radius)

func _draw_portrait(center: Vector2, radius: float, marked: Node3D) -> void:
	var key: String = marked.get_meta("minimap_icon", "")
	if not PORTRAITS.has(key):
		return
	var spot := to_minimap(marked.global_position)
	var edge := radius - PORTRAIT_SIZE * 0.5 - 6.0
	var pinned := spot.length() > edge
	var size := PORTRAIT_SIZE * (0.8 if pinned else 1.0)
	if pinned:
		spot = spot.normalized() * (radius - size * 0.5 - 6.0)
	var at := center + spot
	var half := size * 0.5
	_overlay.draw_circle(at, half + 3.0, HERO_OUTLINE)
	_overlay.draw_circle(at, half + 1.5, PORTRAIT_RINGS[key])
	# Portrait clipped to a circle.
	var points := PackedVector2Array()
	var uvs := PackedVector2Array()
	for step in 24:
		var direction := Vector2.from_angle(TAU * step / 24.0)
		points.append(at + direction * (half - 0.5))
		uvs.append(Vector2(0.5, 0.5) + direction * 0.5)
	var tint := Color(1, 1, 1, 0.8 if pinned else 1.0)
	_overlay.draw_polygon(points, PackedColorArray([tint]), uvs, PORTRAITS[key])

## The region's goal (boss, then the open gate) is always on the minimap:
## inside the view at its real spot, otherwise pinned to the rim with a small
## pointer, pulsing so it catches the eye.
func _draw_guide(center: Vector2, radius: float) -> void:
	var target := Travel.guide_target(get_tree())
	if target == null:
		return
	var spot := to_minimap(target.global_position)
	var edge := radius - GUIDE_SIZE * 0.5 - 14.0
	var pinned := spot.length() > edge
	if pinned:
		spot = spot.normalized() * edge
	var pulse := 1.0 + 0.12 * sin(Time.get_ticks_msec() / 160.0)
	var size := GUIDE_SIZE * pulse
	var icon: Texture2D = GATE_MARKER if target.get_meta("guide", "") == "gate" else BOSS_MARKER
	if pinned:
		var way := spot.normalized()
		var side := Vector2(-way.y, way.x)
		var tip := center + spot + way * (size * 0.5 + 9.0)
		var base := center + spot + way * (size * 0.5 - 2.0)
		_overlay.draw_colored_polygon(PackedVector2Array([tip + way * 2.0, base + side * 9.0, base - side * 9.0]), HERO_OUTLINE)
		_overlay.draw_colored_polygon(PackedVector2Array([tip, base + side * 6.5, base - side * 6.5]), Color("ffd45a"))
	_overlay.draw_texture_rect(icon, Rect2(center + spot - Vector2(size, size) * 0.5, Vector2(size, size)), false)

func _draw_arrow(center: Vector2, facing: Vector2) -> void:
	if facing.length() < 0.5:
		facing = Vector2.UP
	var side := Vector2(-facing.y, facing.x)
	var tip := center + facing * 13.0
	var back := center - facing * 8.0
	var points := PackedVector2Array([tip, back + side * 9.0, center - facing * 3.0, back - side * 9.0])
	var outline := PackedVector2Array([tip + facing * 3.0, back + side * 12.0 - facing * 2.0, center - facing * 1.0, back - side * 12.0 - facing * 2.0])
	_overlay.draw_colored_polygon(outline, HERO_OUTLINE)
	_overlay.draw_colored_polygon(points, HERO)

func _flat(vector: Vector3) -> Vector2:
	return Vector2(vector.x, vector.z).normalized()
