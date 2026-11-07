extends "res://scripts/enemies/enemy.gd"

## The two levelled knights by the village (D-080). Each guards its own small
## arena, comes back straight after being defeated and gains a permanent
## level, shown above its head. Each level makes it much tougher (D-084).
##  - Blood Knight (vampire): each level adds +1 to the damage Kaze gains per fall.
##  - Plague Knight (zombie): each level makes every enemy hit cost 1 more health.

const RESPAWN_DELAY := 1.8
const FIGHT_SECONDS := 30.0

## "blood" or "plague".
var kind := "blood"
var _label: Label3D

func _ready() -> void:
	leash = 7.0
	respawn_seconds = RESPAWN_DELAY
	respawn_distance = -1.0
	# Like the bosses (D-101): 30 s to win once the fight starts, or he heals.
	fight_window = FIGHT_SECONDS
	super._ready()
	_label = make_overhead_label(80, 0.02, Color("ff6b6b") if kind == "blood" else Color("a5e86a"))
	_update_label()

func level() -> int:
	Progression.ensure_loaded()
	return 1 + (Progression.blood_level if kind == "blood" else Progression.plague_level)

## Exponential growth (D-084) so every level is clearly harder:
## health 6 x 1.6^(level-1). Their hit is the same as every enemy's (D-092).
const HEALTH_BASE := 6.0
const HEALTH_GROWTH := 1.6

## Kept as a float: from about Lv 92 the health no longer fits in an integer
## (the old int cast wrapped round to a negative number, so the knight fell to
## one blow, D-086).
func max_health() -> float:
	return roundf(HEALTH_BASE * pow(HEALTH_GROWTH, level() - 1))

## Knights level up instead of giving experience.
func _on_defeated() -> void:
	if kind == "blood":
		Progression.blood_knight_defeated()
	else:
		Progression.plague_knight_defeated()
	_update_label()
	_show_level_up()

func _respawn() -> void:
	super._respawn()
	# Face the village square.
	var to_square := Vector3(2, 0, 2) - global_position
	_visual.rotation.y = atan2(to_square.x, to_square.z)
	_update_label()

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	update_fight_window(delta)
	_update_label()

func _update_label() -> void:
	if _label != null:
		var timer := ("\n%ds" % ceili(fight_left)) if in_fight and is_alive() else ""
		_label.text = "%s\nLv %d%s" % [data.name, level(), timer]

func _show_level_up() -> void:
	var text := Label3D.new()
	text.text = "LEVEL UP!"
	text.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	text.no_depth_test = true
	text.font_size = 96
	text.outline_size = 22
	text.pixel_size = 0.02
	text.modulate = Color("ffd45a")
	text.outline_modulate = Color("3a2412")
	add_child(text)
	# Above the name and level lines, never on them (D-098).
	text.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	text.position.y = label_base_y() + 4.6
	var tween := text.create_tween().set_parallel(true)
	tween.tween_property(text, "position:y", text.position.y + 2.5, 1.2)
	tween.tween_property(text, "modulate:a", 0.0, 0.4).set_delay(0.8)
	tween.tween_property(text, "outline_modulate:a", 0.0, 0.4).set_delay(0.8)
	tween.chain().tween_callback(text.queue_free)
