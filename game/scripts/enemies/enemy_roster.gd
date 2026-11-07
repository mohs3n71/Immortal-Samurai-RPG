extends RefCounted

## Which Toony Tiny RTS soldier guards which dirt clearing (D-078). One enemy
## per clearing in tools/meadow_layout.gd PLAZAS, except the village square
## where Kaze starts. Tougher soldiers stand further from the village.

const MODEL_DIR := "res://assets/enemies/toony-tiny/"
const Travel = preload("res://scripts/world/travel.gd")

## Tier stats (health raised about 5x in D-084). Kaze's full combo deals 5x his damage (1+1+1+2). Experience
## for a kill comes from health (Progression.experience_for, D-081).
## D-091: health scales with Kaze so soldiers stay hard. A soldier has
## "swings" x Kaze's base damage x 1.25 (the combo average), fixed when it
## spawns, and at least "health". Hero levels are left out, so they still
## help. Experience still comes from the fixed "health" (keeps the boss
## timing of D-085). Every hit costs the same enemy hit (1 + Plague level, D-092).
const TIERS := {
	"recruit": {"health": 15, "swings": 12, "damage": 8, "speed": 13.0, "height": 7.4, "cooldown": 1.6, "aggro": 16.0, "stagger": true},
	"soldier": {"health": 40, "swings": 20, "damage": 12, "speed": 14.0, "height": 8.1, "cooldown": 1.5, "aggro": 18.0, "stagger": true},
	"captain": {"health": 90, "swings": 32, "damage": 16, "speed": 14.0, "height": 9.3, "cooldown": 1.4, "aggro": 20.0, "stagger": false},
	"commander": {"health": 180, "swings": 48, "damage": 22, "speed": 13.0, "height": 10.8, "cooldown": 1.6, "aggro": 22.0, "stagger": false},
}

## attack: "attack_chop" (sword, axe, hammer, mace), "attack_thrust" (spear,
## pike, halberd) or "attack_cast" (mage burst around itself).
const ROSTER := [
	{"id": "axe-recruit", "name": "Axe Recruit", "tier": "recruit", "attack": "attack_chop", "plaza": Vector2(-53.4, 46.5)},
	{"id": "pike-recruit", "name": "Pike Recruit", "tier": "recruit", "attack": "attack_thrust", "plaza": Vector2(-47.8, -54.6)},
	{"id": "hammer-guard", "name": "Hammer Guard", "tier": "recruit", "attack": "attack_chop", "plaza": Vector2(57.1, -52)},
	{"id": "sword-soldier", "name": "Sword Soldier", "tier": "soldier", "attack": "attack_chop", "plaza": Vector2(-93.6, 14.6)},
	{"id": "spear-guard", "name": "Spear Guard", "tier": "soldier", "attack": "attack_thrust", "plaza": Vector2(0, 96.1)},
	{"id": "broadsword-soldier", "name": "Broadsword Soldier", "tier": "soldier", "attack": "attack_chop", "plaza": Vector2(107, 0)},
	{"id": "battle-mage", "name": "Battle Mage", "tier": "soldier", "attack": "attack_cast", "plaza": Vector2(57.6, 102.2)},
	{"id": "halberd-captain", "name": "Halberd Captain", "tier": "captain", "attack": "attack_thrust", "plaza": Vector2(8.6, -102.2)},
	{"id": "morningstar-captain", "name": "Morningstar Captain", "tier": "captain", "attack": "attack_chop", "plaza": Vector2(-87.3, 88.8)},
	{"id": "iron-commander", "name": "Iron Commander", "tier": "commander", "attack": "attack_chop", "plaza": Vector2(88.8, -85.8)},
	{"id": "warhammer-commander", "name": "Warhammer Commander", "tier": "commander", "attack": "attack_chop", "plaza": Vector2(-99.9, -107)},
]

## Frostlands (region 2, D-100): frozen undead from the Toony Tiny undead kit
## in icy colours (tools/make_frost_assets.py, tools/glb_retexture.py). Same
## ranks as region 1; clearings are region 1's mirrored left to right
## (tools/make_frost_layout.py).
const FROST_MODEL_DIR := "res://assets/enemies/frost/"
const FROST_ROSTER := [
	{"id": "frost-zombie", "name": "Frost Zombie", "tier": "recruit", "attack": "attack_chop", "plaza": Vector2(53.4, 46.5)},
	{"id": "ice-ghoul", "name": "Ice Ghoul", "tier": "recruit", "attack": "attack_chop", "plaza": Vector2(47.8, -54.6)},
	{"id": "snow-acolyte", "name": "Snow Acolyte", "tier": "recruit", "attack": "attack_cast", "plaza": Vector2(-57.1, -52)},
	{"id": "ice-vampire", "name": "Ice Vampire", "tier": "soldier", "attack": "attack_chop", "plaza": Vector2(93.6, 14.6)},
	{"id": "frozen-brute", "name": "Frozen Brute", "tier": "soldier", "attack": "attack_chop", "plaza": Vector2(0, 96.1)},
	{"id": "rime-cultist", "name": "Rime Cultist", "tier": "soldier", "attack": "attack_chop", "plaza": Vector2(-107, 0)},
	{"id": "frost-witch", "name": "Frost Witch", "tier": "soldier", "attack": "attack_cast", "plaza": Vector2(-57.6, 102.2)},
	{"id": "vampire-reaver", "name": "Vampire Reaver", "tier": "captain", "attack": "attack_chop", "plaza": Vector2(-8.6, -102.2)},
	{"id": "bone-sentinel", "name": "Bone Sentinel", "tier": "captain", "attack": "attack_chop", "plaza": Vector2(87.3, 88.8)},
	{"id": "glacier-lord", "name": "Glacier Lord", "tier": "commander", "attack": "attack_chop", "plaza": Vector2(-88.8, -85.8)},
	{"id": "frozen-warden", "name": "Frozen Warden", "tier": "commander", "attack": "attack_chop", "plaza": Vector2(99.9, -107)},
]
## Region 2 soldiers take this many times region 1's swings to beat.
const FROST_SWINGS := 1.5

static func roster(region: int) -> Array:
	return FROST_ROSTER if region == 2 else ROSTER

## Reach of each attack style (world units from the soldier's centre).
## Raised about a third in D-087 so fighters strike from outside each other's body.
const ATTACK_RANGE := {"attack_chop": 7.0, "attack_thrust": 8.6, "attack_cast": 10.0}

## D-093: recruit and soldier clearings hold a group of 3 (the clearing's own
## soldier plus two others of the same rank); captains and commanders stand
## alone. Group members stand GROUP_SPREAD from the clearing centre.
const GROUP_SIZE := {"recruit": 3, "soldier": 3, "captain": 1, "commander": 1}
const GROUP_SPREAD := 4.6

## Every soldier to spawn: entries with "home" (x, z) set, one per enemy.
static func spawn_list(region := 1) -> Array:
	var result := []
	var list := roster(region)
	for index in list.size():
		var lead := entry(index, region)
		var same_rank := []
		for other in list.size():
			if other != index and list[other].tier == lead.tier:
				same_rank.append(other)
		var count: int = GROUP_SIZE[lead.tier]
		for member in count:
			var data := lead if member == 0 else entry(same_rank[(index + member - 1) % same_rank.size()], region)
			var spot: Vector2 = lead.plaza
			if count > 1:
				spot += Vector2.from_angle(TAU * member / count + 0.4 * index) * GROUP_SPREAD
			# Placed in the shared world (D-102).
			data["home"] = Travel.to_world(region, spot)
			data["plaza"] = Travel.to_world(region, lead.plaza)
			result.append(data)
	return result

static func entry(index: int, region := 1) -> Dictionary:
	var data: Dictionary = roster(region)[index].duplicate()
	data.merge(TIERS[data.tier])
	data["model"] = (FROST_MODEL_DIR if region == 2 else MODEL_DIR) + data.id + ".glb"
	data["range"] = ATTACK_RANGE[data.attack]
	if region == 2:
		data["swings"] = roundi(float(data.swings) * FROST_SWINGS)
	return data

## Start-area arenas (same as tools/meadow_layout.gd PLAZAS; tools/ is not
## exported, so the game keeps its own copy).
const REAPER_ARENA := Vector2(-21, 2)
const BLOOD_ARENA := Vector2(4, -20)
const PLAGUE_ARENA := Vector2(-12, 25)

## The levelled knights by the village (D-080). Health and level come from
## scripts/enemies/level_knight.gd; these are the rest of their stats.
const KNIGHTS := [
	{"id": "blood-knight", "name": "Blood Knight", "kind": "blood", "model": "res://assets/enemies/undead/vampire-knight.glb", "tier": "knight", "attack": "attack_chop",
		"health": 3, "damage": 1, "speed": 12.0, "height": 8.4, "cooldown": 1.5, "aggro": 9.5, "stagger": true, "range": 7.0},
	{"id": "plague-knight", "name": "Plague Knight", "kind": "plague", "model": "res://assets/enemies/undead/zombie-knight.glb", "tier": "knight", "attack": "attack_chop",
		"health": 3, "damage": 1, "speed": 12.0, "height": 8.4, "cooldown": 1.5, "aggro": 9.5, "stagger": true, "range": 7.0},
]

## Region final bosses (D-085). The fight is a damage race: 30 s after it
## starts (and every 30 s after) the boss refills its health, so Kaze must deal
## all of it within 30 s. It hits like every enemy (1 + Plague level, D-092).
## Sized with tools/simulate_progression.py (D-101 rules: knights have the same
## 30 s window) so the best strategy it knows needs at least 30 minutes in
## region 1, 45 in region 2 and 60 in region 3 (D-096: 30, 75, 135 ... minutes
## in total): health is just above the best 30 s damage it reaches before
## each total. Simulated earliest kills: 30, 75, 137 min. Later regions:
## 3.26M x (minutes / 75)^1.16. Re-run the simulator when the rules change.
const BOSS_FIGHT_SECONDS := 30.0
const BOSS_HEALTH_AT_75 := 3260000.0
const BOSS_HEALTH_EXPONENT := 1.16
const BOSS_HEALTHS := [1110000.0, 3260000.0, 6510000.0]
const BASE_ATTACK_INTERVAL := 0.7
## Moved with the map in D-093 (tools/shrink_layout.py prints these).
const REGION_BOSS_ARENA := Vector2(62, -99.6)
const REGION_GATE := Vector2(62, -115.6)
## Region 2 is mirrored (D-100).
const FROST_BOSS_ARENA := Vector2(-62, -99.6)
const FROST_GATE := Vector2(-62, -115.6)

## World positions (D-102: the arena constants are region-local).
static func boss_arena(region: int) -> Vector2:
	return Travel.to_world(region, FROST_BOSS_ARENA if region == 2 else REGION_BOSS_ARENA)

static func gate_position(region: int) -> Vector2:
	return Travel.to_world(region, FROST_GATE if region == 2 else REGION_GATE)

## Total play time before region `region`'s boss can fall (D-096): region n
## takes 15 x (n + 1) minutes, so 30, 75, 135, 210 ... in total.
static func region_minutes(region: int) -> int:
	return 15 * (region * (region + 1) / 2 + region)

## {"health"} for the final boss of `region`.
static func boss_stats(region: int) -> Dictionary:
	if region <= BOSS_HEALTHS.size():
		return {"health": BOSS_HEALTHS[region - 1]}
	var minutes := float(region_minutes(region))
	return {"health": roundf(BOSS_HEALTH_AT_75 * pow(minutes / 75.0, BOSS_HEALTH_EXPONENT))}

static func boss_entry(region: int) -> Dictionary:
	var stats := boss_stats(region)
	if region == 2:
		return {"id": "frost-tyrant", "name": "Frost Tyrant", "tier": "boss", "attack": "attack_chop",
			"model": FROST_MODEL_DIR + "frost-tyrant.glb", "health": stats.health,
			"damage": 1, "speed": 13.0, "height": 15.0, "cooldown": 0.0, "aggro": 18.0, "stagger": false, "range": 11.5, "region": region}
	return {"id": "bone-warlord", "name": "Bone Warlord", "tier": "boss", "attack": "attack_thrust",
		"model": "res://assets/enemies/undead/bone-warlord.glb", "health": stats.health,
		"damage": 1, "speed": 13.0, "height": 15.0, "cooldown": 0.0, "aggro": 18.0, "stagger": false, "range": 11.5, "region": region}
