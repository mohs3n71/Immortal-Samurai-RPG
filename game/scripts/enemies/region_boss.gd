extends "res://scripts/enemies/enemy.gd"

## A region's final boss (D-085). Guards its arena in front of the sealed gate,
## swings at the shared attack speed, hits for its own hit x (1 + Plague Knight
## level) and never flinches. When the fight starts Kaze has 30 s: then the
## boss refills its health and a new 30 s begins. Leaving the arena ends the
## fight (full health). Defeating it is permanent and opens the gate; it gives
## no experience. Health and the fight timer are shown above its head.

const EnemyRoster = preload("res://scripts/enemies/enemy_roster.gd")

signal defeated(region: int)

var _label: Label3D

func _ready() -> void:
	leash = 16.0
	respawn_seconds = 1.0e9
	fight_window = EnemyRoster.BOSS_FIGHT_SECONDS
	super._ready()
	Progression.ensure_loaded()
	# Minimap and screen-edge guide point here (D-090).
	add_to_group("guide_target")
	set_meta("guide_order", int(data.get("region", 1)) * 2)
	_label = make_overhead_label(84, 0.022, Color("ffb347"))
	_label.outline_modulate = Color("1d1008")
	_update_label()

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	update_fight_window(delta)
	_update_label()

func _on_defeated() -> void:
	remove_from_group("guide_target")
	Progression.region_boss_defeated(int(data.region))
	_label.text = "%s\nDEFEATED" % data.name
	defeated.emit(int(data.region))

func _update_label() -> void:
	if _label == null or state == State.DEAD:
		return
	var timer := ("\n%ds" % ceili(fight_left)) if in_fight else ""
	_label.text = "%s\n%s / %s%s" % [data.name, Progression.format_number(health), Progression.format_number(max_health()), timer]
