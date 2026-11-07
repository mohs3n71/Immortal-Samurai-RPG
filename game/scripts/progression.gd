extends RefCounted

## Permanent run progression (D-080), saved to user://progress.json.
##  - Kaze starts with 1 max health and 1 damage.
##  - Each time he falls: max health +1, damage +(1 + Blood Knight level).
##  - Every enemy hit costs (1 + Plague Knight level) health.
##  - The Reaper halves his max health (never below 1).
##  - Defeating soldiers (not the start-area NPCs) gives experience that grows
##    with the enemy's health (experience_for); each hero level adds +1% to
##    his base damage.
## All of it is static so the game, the NPCs and the tests share one state.

const SAVE_PATH := "user://progress.json"

static var max_health := 1
static var damage := 1
static var deaths := 0
static var blood_level := 0
static var plague_level := 0
## Shared by Kaze and every enemy (D-082): items that raise it later must
## speed both up. One swing (or combo step) every attack_interval() seconds.
const BASE_ATTACK_INTERVAL := 0.7
static var attack_speed := 1.0
static var hero_level := 1
static var experience := 0
## Highest region whose final boss is defeated (its gate is open, D-085).
static var bosses_defeated := 0
## The tutorial has been shown once (D-102): it never starts on its own again,
## not even after RESET; HOW TO PLAY replays it. Saved.
static var tutorial_done := false
## A tutorial is on screen right now (the boss pointer waits). Not saved.
static var tutorial_running := false
## Region Kaze is in (D-100); the game reopens there. Saved.
static var current_region := 1
## Where Kaze appears in the next region scene that loads (null: its spawn).
static var arrival: Variant = null
## Pending return portal after a fast travel (region 0 = none). Saved.
static var portal_region := 0
static var portal_position := Vector3.ZERO
## Counted this session only, for the tutorial's steps.
static var reaper_strikes := 0
static var soldiers_defeated := 0
## Tests turn this off so they never touch the player's save.
static var persist := true
static var _loaded := false
static var _notifier: Notifier

## Emits `changed` whenever the progression changes (the HUD listens).
class Notifier extends RefCounted:
	signal changed

static func notifier() -> Notifier:
	if _notifier == null:
		_notifier = Notifier.new()
	return _notifier

static func ensure_loaded() -> void:
	if _loaded:
		return
	_loaded = true
	if not persist or not FileAccess.file_exists(SAVE_PATH):
		return
	var data = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	if data is Dictionary:
		max_health = maxi(int(data.get("max_health", 1)), 1)
		damage = maxi(int(data.get("damage", 1)), 1)
		deaths = int(data.get("deaths", 0))
		blood_level = int(data.get("blood_level", 0))
		plague_level = int(data.get("plague_level", 0))
		hero_level = maxi(int(data.get("hero_level", 1)), 1)
		experience = int(data.get("experience", 0))
		attack_speed = maxf(float(data.get("attack_speed", 1.0)), 0.1)
		bosses_defeated = int(data.get("bosses_defeated", 0))
		tutorial_done = bool(data.get("tutorial_done", false))
		current_region = maxi(int(data.get("current_region", 1)), 1)
		portal_region = int(data.get("portal_region", 0))
		var spot: Array = data.get("portal_position", [0, 0, 0])
		portal_position = Vector3(float(spot[0]), float(spot[1]), float(spot[2]))

static func reset() -> void:
	max_health = 1
	damage = 1
	deaths = 0
	blood_level = 0
	plague_level = 0
	hero_level = 1
	experience = 0
	attack_speed = 1.0
	bosses_defeated = 0
	current_region = 1
	arrival = null
	portal_region = 0
	portal_position = Vector3.ZERO
	reaper_strikes = 0
	soldiers_defeated = 0
	_loaded = true
	_save()

## Damage Kaze gains each time he falls.
static func damage_per_fall() -> int:
	ensure_loaded()
	return 1 + blood_level

## Health every enemy hit takes from Kaze.
static func enemy_hit() -> int:
	ensure_loaded()
	return 1 + plague_level

## Seconds between swings, the same for Kaze and all enemies.
static func attack_interval() -> float:
	ensure_loaded()
	return BASE_ATTACK_INTERVAL / attack_speed

## Base damage with the hero-level bonus: +1% per level above 1.
static func effective_damage() -> float:
	ensure_loaded()
	return damage * (1.0 + 0.01 * (hero_level - 1))

## Experience for defeating an enemy with `health` max health (D-081):
## 1 per health point (kills take hits in proportion to health) plus a bonus
## for longer, riskier fights that grows with health and stops at +100% (40+).
static func experience_for(health: float) -> int:
	return int(roundf(health * (1.0 + minf(health, 40.0) / 40.0)))

## Experience needed to go from `level` to the next one.
static func experience_to_next(level: int = -1) -> int:
	ensure_loaded()
	return 5 * (hero_level if level < 0 else level)

## Returns how many levels were gained.
static func add_experience(amount: int) -> int:
	ensure_loaded()
	soldiers_defeated += 1
	experience += amount
	var gained := 0
	while experience >= experience_to_next():
		experience -= experience_to_next()
		hero_level += 1
		gained += 1
	_save()
	return gained

static func hero_fell() -> void:
	ensure_loaded()
	deaths += 1
	max_health += 1
	damage += damage_per_fall()
	_save()

static func reaper_strike() -> void:
	ensure_loaded()
	max_health = maxi(max_health / 2, 1)
	reaper_strikes += 1
	_save()

static func blood_knight_defeated() -> void:
	ensure_loaded()
	blood_level += 1
	_save()

static func plague_knight_defeated() -> void:
	ensure_loaded()
	plague_level += 1
	_save()

static func region_boss_defeated(region: int) -> void:
	ensure_loaded()
	bosses_defeated = maxi(bosses_defeated, region)
	_save()

## Short form for big numbers: 950, 12.3K, 4.56M, 7.89B.
static func format_number(value: float) -> String:
	var sign := "-" if value < 0 else ""
	value = absf(value)
	if value < 10000.0:
		return sign + (str(int(value)) if is_equal_approx(value, roundf(value)) else "%.1f" % value)
	if value >= 1e15:
		# Beyond trillions (very high knight levels): 2.49e31.
		var exponent := int(floor(log(value) / log(10.0)))
		return sign + "%.2fe%d" % [value / pow(10.0, exponent), exponent]
	for unit in [[1e12, "T"], [1e9, "B"], [1e6, "M"], [1e3, "K"]]:
		# 999,995 rounds to "1.00M", not "1000.00K".
		if value >= unit[0] * 0.999995:
			return sign + "%.2f%s" % [value / unit[0], unit[1]]
	return sign + str(int(value))

static func save() -> void:
	ensure_loaded()
	_save()

static func finish_tutorial() -> void:
	ensure_loaded()
	tutorial_done = true
	_save()

## Damage Kaze deals in one 30 s boss window at his current strength (combo
## average 1.25x); the quest bar compares it with the boss's health (D-094).
static func boss_window_damage() -> float:
	return effective_damage() * 1.25 * 30.0 / attack_interval()

static func _save() -> void:
	notifier().changed.emit()
	if not persist:
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify({"max_health": max_health, "damage": damage, "deaths": deaths, "blood_level": blood_level, "plague_level": plague_level, "hero_level": hero_level, "experience": experience, "attack_speed": attack_speed, "bosses_defeated": bosses_defeated, "tutorial_done": tutorial_done,
			"current_region": current_region, "portal_region": portal_region,
			"portal_position": [portal_position.x, portal_position.y, portal_position.z]}))
