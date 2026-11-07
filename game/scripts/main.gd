extends Node3D

## Field root: loads the authored world, spawns the hero, follows it with the
## isometric camera and adds touch controls. Portrait layout (D-072).

const PlayerScript = preload("res://scripts/player.gd")
const VisualScript = preload("res://scripts/character_visual.gd")
const JoystickScript = preload("res://scripts/virtual_joystick.gd")
const AutoAttackScript = preload("res://scripts/auto_attack.gd")
const MinimapScript = preload("res://scripts/minimap.gd")
const GuidePointerScript = preload("res://scripts/guide_pointer.gd")
const QuestPanelScript = preload("res://scripts/ui/quest_panel.gd")
const TutorialScript = preload("res://scripts/ui/tutorial.gd")
const HeroHudScript = preload("res://scripts/hero_hud.gd")
const EnemyScript = preload("res://scripts/enemies/enemy.gd")
const EnemyRoster = preload("res://scripts/enemies/enemy_roster.gd")
const KnightScript = preload("res://scripts/enemies/level_knight.gd")
const ReaperScript = preload("res://scripts/enemies/reaper.gd")
const BossScript = preload("res://scripts/enemies/region_boss.gd")
const GateScript = preload("res://scripts/world/region_gate.gd")
const ReturnPortalScript = preload("res://scripts/world/return_portal.gd")
const Travel = preload("res://scripts/world/travel.gd")
const Progression = preload("res://scripts/progression.gd")
const BlobShadow = preload("res://scripts/world/blob_shadow.gd")
const StaticBatcher = preload("res://scripts/world/static_batcher.gd")
const StylizedMeshes = preload("res://scripts/world/stylized_meshes.gd")
const TerrainBlock = preload("res://scripts/world/terrain_block.gd")
## On phones the 3D scene renders at this fraction of the screen resolution (D-074).
const MOBILE_3D_SCALE := 0.65
const FIELD_HERO_SIZE_MULTIPLIER := 2.0
## Isometric view direction. The camera sits far back along it: with an
## orthographic camera distance does not change the picture, but the tall
## portrait view would otherwise reach the near clipping plane at the bottom
## of the screen and slice nearby objects (D-073).
const CAMERA_OFFSET := Vector3(24.0, 28.4, 24.0) * 3.0
## Visible world width in portrait; the height follows the screen's aspect.
const CAMERA_WIDTH := 40.0
const DEFAULT_HERO_ID := "kaze"

## Authored world to load; it brings its own lighting. The other regions'
## worlds (Travel.WORLDS) are placed beside it: one map (D-102).
@export var world_scene: PackedScene
## The region Kaze is in (1 Meadowlands, 2 Frostlands): picks the minimap and
## lighting; follows him through the gateways.
@export var region := 1
## Colours for generated trees, rocks and cliffs ("meadow" or "frost").
@export var palette := "meadow"
@export var spawn_position := Vector3.ZERO
@export var play_half_extent := 0.0

var player: CharacterBody3D
var camera: Camera3D
var hud: Control

func _ready() -> void:
	Progression.ensure_loaded()
	# A save made in another region starts at that region's entrance (D-102).
	if Progression.arrival is Vector3:
		spawn_position = Progression.arrival
	elif Progression.current_region != 1 and Travel.ENTRIES.has(Progression.current_region):
		spawn_position = Travel.ENTRIES[Progression.current_region]
	Progression.arrival = null
	# Generated trees, rocks and cliffs take each region's colours (D-100).
	StylizedMeshes.palette = palette
	TerrainBlock.palette = palette
	var world := world_scene.instantiate() as Node3D
	_world = world
	_lighting[1] = _read_lighting(world)
	add_child(world)
	StaticBatcher.batch(world)
	for other: int in Travel.WORLDS:
		StylizedMeshes.palette = Travel.PALETTES[other]
		TerrainBlock.palette = Travel.PALETTES[other]
		var extra := (load(Travel.WORLDS[other]) as PackedScene).instantiate() as Node3D
		# One sky and sun for the whole map: the region's light is tweened in
		# as Kaze crosses over.
		_lighting[other] = _read_lighting(extra)
		for light in ["Environment", "Sun", "SkyFill"]:
			if extra.has_node(light):
				extra.get_node(light).free()
		add_child(extra)
		StaticBatcher.batch(extra)
	StylizedMeshes.palette = palette
	TerrainBlock.palette = palette
	_apply_performance_settings(world)
	region = Travel.region_at(spawn_position)
	_build_player()
	_build_camera()
	_build_controls()
	for each: int in Travel.OFFSETS:
		_spawn_enemies(world, each)
		_spawn_region_boss(world, each)
	_spawn_start_npcs(world)
	if Progression.portal_region != 0:
		_spawn_portal()
	_enter_region(region, false)
	player.died.connect(_on_player_died)
	hud.fast_travel_requested.connect(fast_travel)

## Phones render 3D at reduced resolution and skip the colour-adjustment pass;
## the frame rate is capped at 60 everywhere.
func _apply_performance_settings(world: Node) -> void:
	# Tests pass "-- uncapped" (with --fixed-fps) to simulate faster than real time.
	Engine.max_fps = 0 if OS.get_cmdline_user_args().has("uncapped") else 60
	if not OS.has_feature("mobile"):
		return
	get_viewport().scaling_3d_scale = MOBILE_3D_SCALE
	var environment := world.find_child("Environment", false, false) as WorldEnvironment
	if environment != null and environment.environment != null:
		environment.environment.adjustment_enabled = false

func _process(_delta: float) -> void:
	if player == null:
		return
	camera.position = player.position + CAMERA_OFFSET
	if hud != null and hud.fast_travel_button != null:
		hud.fast_travel_button.visible = fast_travel_available()
		hud.set_fast_travel_blocked(in_combat())
	var here := Travel.region_at(player.global_position)
	if here != region:
		_enter_region(here, true)
	if _quest != null:
		_quest.set_region(mini(Progression.bosses_defeated + 1, Travel.OFFSETS.size()))

func _build_player() -> void:
	player = CharacterBody3D.new()
	player.set_script(PlayerScript)
	player.name = "Player"
	player.use_gravity = true
	player.half_extent = play_half_extent
	player.walkable_areas = Travel.AREAS
	player.floor_snap_length = 0.8
	player.floor_constant_speed = true
	# Ramps peak near 28 degrees; anything steeper (rocks, props) must not be walkable.
	player.floor_max_angle = deg_to_rad(35.0)
	add_child(player)
	player.position = spawn_position
	var collision := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 1.2
	capsule.height = 3.0
	collision.shape = capsule
	collision.position.y = 1.5
	player.add_child(collision)
	var visual := Node3D.new()
	visual.set_script(VisualScript)
	visual.size_multiplier = FIELD_HERO_SIZE_MULTIPLIER
	visual.hero = _hero_data()
	visual.name = "Visual"
	player.add_child(visual)
	player.visual = visual
	BlobShadow.attach(player, 1.6, 0.5)
	var attacker := Node.new()
	attacker.set_script(AutoAttackScript)
	attacker.name = "AutoAttack"
	player.add_child(attacker)

func _hero_data() -> Dictionary:
	var selection := get_node_or_null("/root/HeroSelection")
	if selection != null and not selection.selected_hero().is_empty():
		return selection.selected_hero()
	for hero in JSON.parse_string(FileAccess.get_file_as_string("res://assets/hero_catalog.json")):
		if hero.id == DEFAULT_HERO_ID:
			return hero
	return {}

func _build_camera() -> void:
	camera = Camera3D.new()
	add_child(camera)
	camera.position = CAMERA_OFFSET
	camera.look_at(Vector3(0, 1.6, 0))
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.keep_aspect = Camera3D.KEEP_WIDTH
	camera.size = CAMERA_WIDTH
	camera.near = 1.0
	camera.far = 600.0
	camera.current = true
	player.camera = camera

func _build_controls() -> void:
	var canvas := CanvasLayer.new()
	add_child(canvas)
	var joystick := Control.new()
	joystick.set_script(JoystickScript)
	joystick.name = "Joystick"
	canvas.add_child(joystick)
	player.joystick = joystick
	var guide := Control.new()
	guide.set_script(GuidePointerScript)
	guide.name = "GuidePointer"
	guide.player = player
	guide.camera = camera
	canvas.add_child(guide)
	var minimap := Control.new()
	minimap.set_script(MinimapScript)
	minimap.name = "Minimap"
	minimap.player = player
	minimap.camera = camera
	minimap.map_texture = load(MINIMAPS[1])
	minimap.second_texture = load(MINIMAPS[2])
	minimap.second_origin = Travel.offset(2)
	minimap.split_z = Travel.BORDER_Z
	canvas.add_child(minimap)
	_minimap = minimap
	hud = Control.new()
	hud.set_script(HeroHudScript)
	hud.name = "HeroHud"
	canvas.add_child(hud)
	hud.bind(player)
	# Region quest (D-094), shown once the tutorial is done or skipped.
	var quest := PanelContainer.new()
	quest.set_script(QuestPanelScript)
	quest.name = "QuestPanel"
	quest.region = mini(Progression.bosses_defeated + 1, Travel.OFFSETS.size())
	canvas.add_child(quest)
	Progression.ensure_loaded()
	quest.visible = Progression.tutorial_done
	_canvas = canvas
	_quest = quest
	# Shown on its own only once, on a fresh save (D-102); HOW TO PLAY replays it.
	if not Progression.tutorial_done:
		_start_tutorial()
	hud.tutorial_requested.connect(_start_tutorial)

var _canvas: CanvasLayer
var _minimap: Control
var _quest: Control

## Starts the tutorial: on a fresh save, or again from HOW TO PLAY (D-097,
## progress is kept). The quest card hides while it runs.
func _start_tutorial() -> void:
	if _canvas.get_node_or_null("Tutorial") != null:
		return
	# Shown once on its own (D-102); marked as seen as soon as it starts.
	Progression.tutorial_done = true
	Progression.tutorial_running = true
	Progression.save()
	_quest.visible = false
	hud.tutorial_button.visible = false
	var tutorial := Control.new()
	tutorial.set_script(TutorialScript)
	tutorial.name = "Tutorial"
	tutorial.player = player
	tutorial.camera = camera
	tutorial.hud = hud
	_canvas.add_child(tutorial)
	tutorial.finished.connect(func() -> void:
		Progression.tutorial_running = false
		hud.tutorial_button.visible = true
		_reveal_quest(_quest))
	tutorial.begin.call_deferred()

## The quest card slides in from the right edge when the tutorial ends.
func _reveal_quest(quest: Control) -> void:
	quest.visible = true
	quest.modulate.a = 0.0
	var home := quest.position.x
	quest.position.x = home + 340.0
	var tween := quest.create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(quest, "position:x", home, 0.5)
	tween.parallel().tween_property(quest, "modulate:a", 1.0, 0.3)

## One Toony Tiny soldier per dirt clearing (D-078), placed on the ground found
## below the clearing's centre (clearings on plateaus are higher up).
func _spawn_enemies(world: Node3D, in_region: int) -> void:
	var space := world.get_world_3d().direct_space_state
	for entry: Dictionary in EnemyRoster.spawn_list(in_region):
		var spot := _free_spot(space, entry.plaza, entry.home)
		var enemy := CharacterBody3D.new()
		enemy.set_script(EnemyScript)
		enemy.setup(entry, spot, player)
		add_child(enemy)
		enemy.global_position = spot

func _ground_height(space: PhysicsDirectSpaceState3D, at: Vector2) -> float:
	var query := PhysicsRayQueryParameters3D.create(Vector3(at.x, 80.0, at.y), Vector3(at.x, -20.0, at.y), 1)
	var hit := space.intersect_ray(query)
	return hit.position.y if not hit.is_empty() else 0.0

## A group member's home (D-093): its spot around the clearing, turned round
## the centre until it is on open ground (not on a building or rock beside a
## small clearing); the centre itself if no spot is free.
func _free_spot(space: PhysicsDirectSpaceState3D, centre: Vector2, wanted: Vector2) -> Vector3:
	var floor_height := _ground_height(space, centre)
	var offset := wanted - centre
	for turn in 12:
		var at := centre + offset.rotated(TAU * turn / 12.0)
		var height := _ground_height(space, at)
		if absf(height - floor_height) < 0.8:
			return Vector3(at.x, height + 0.2, at.y)
	return Vector3(centre.x, floor_height + 0.2, centre.y)

## Reaper, Blood Knight and Plague Knight in their arenas by the village (D-080).
func _spawn_start_npcs(world: Node3D) -> void:
	var arenas := [EnemyRoster.BLOOD_ARENA, EnemyRoster.PLAGUE_ARENA]
	for index in EnemyRoster.KNIGHTS.size():
		var entry: Dictionary = EnemyRoster.KNIGHTS[index].duplicate()
		var at := _ground(world, arenas[index])
		var knight := CharacterBody3D.new()
		knight.set_script(KnightScript)
		knight.kind = entry.kind
		knight.setup(entry, at, player)
		add_child(knight)
		knight.global_position = at
		var to_square := Vector3(2, 0, 2) - at
		knight.get_node("Visual").rotation.y = atan2(to_square.x, to_square.z)
		# Portrait marker on the minimap (D-104).
		knight.set_meta("minimap_icon", "blood-knight" if index == 0 else "plague-knight")
		knight.add_to_group("minimap_icons")
	var reaper := Node3D.new()
	reaper.set_script(ReaperScript)
	reaper.name = "Reaper"
	reaper.hero = player
	reaper.position = _ground(world, EnemyRoster.REAPER_ARENA)
	reaper.set_meta("minimap_icon", "reaper")
	reaper.add_to_group("minimap_icons")
	add_child(reaper)

## Final boss and the sealed gate behind it (D-085). A defeated boss stays
## defeated and its gate stays open.
func _spawn_region_boss(world: Node3D, region: int) -> void:
	var gate := Node3D.new()
	gate.set_script(GateScript)
	gate.name = "RegionGate" if region == 1 else "RegionGate%d" % region
	gate.region = region
	gate.boss_name = EnemyRoster.boss_entry(region).name
	gate.hero = player
	gate.position = _ground(world, EnemyRoster.gate_position(region))
	gate.rotation.y = PI
	add_child(gate)
	Progression.ensure_loaded()
	if Progression.bosses_defeated >= region:
		return
	var entry := EnemyRoster.boss_entry(region)
	var at := _ground(world, EnemyRoster.boss_arena(region))
	var boss := CharacterBody3D.new()
	boss.set_script(BossScript)
	boss.setup(entry, at, player)
	boss.name = "RegionBoss" if region == 1 else "RegionBoss%d" % region
	add_child(boss)
	boss.global_position = at
	boss.defeated.connect(func(_region: int) -> void: gate.open())

# --- Regions on one map (D-102) ---------------------------------------------

const MINIMAPS := {1: "res://assets/ui/minimap-v001.png", 2: "res://assets/ui/minimap-frost-v001.png"}
## Tests set this so teleports happen at once, without the fade.
static var travel_dry_run := false
var portal: Node3D
## Per region: sky, ambient and sun settings read from its world scene.
var _lighting := {}
var _world: Node3D
var _light_tween: Tween

## Kaze walked into another region (or starts in one): its light and the
## saved region.
func _enter_region(to_region: int, animate: bool) -> void:
	region = to_region
	if Progression.current_region != to_region:
		Progression.current_region = to_region
		Progression.save()
	_apply_lighting(to_region, 2.5 if animate else 0.0)

func _read_lighting(world: Node) -> Dictionary:
	var result := {}
	var environment := world.get_node_or_null("Environment") as WorldEnvironment
	if environment != null and environment.environment != null:
		var env := environment.environment
		result["env"] = {"background_color": env.background_color, "ambient_light_color": env.ambient_light_color,
			"ambient_light_energy": env.ambient_light_energy, "adjustment_saturation": env.adjustment_saturation}
	for light in ["Sun", "SkyFill"]:
		var node := world.get_node_or_null(light) as DirectionalLight3D
		if node != null:
			result[light] = {"light_color": node.light_color, "light_energy": node.light_energy}
	return result

func _apply_lighting(to_region: int, seconds: float) -> void:
	var world := _world
	var wanted: Dictionary = _lighting.get(to_region, {})
	if wanted.is_empty() or world == null:
		return
	if _light_tween != null:
		_light_tween.kill()
	_light_tween = create_tween().set_parallel(true)
	var targets := {}
	var environment := world.get_node_or_null("Environment") as WorldEnvironment
	if environment != null and environment.environment != null:
		targets["env"] = environment.environment
	for light in ["Sun", "SkyFill"]:
		if world.has_node(light):
			targets[light] = world.get_node(light)
	for key in wanted:
		if not targets.has(key):
			continue
		for property: String in wanted[key]:
			if seconds <= 0.0:
				targets[key].set(property, wanted[key][property])
			else:
				_light_tween.tween_property(targets[key], property, wanted[key][property], seconds)
	if seconds <= 0.0:
		_light_tween.kill()

func _teleport(to: Vector3, then: Callable = Callable()) -> void:
	var land := func() -> void:
		player.revive(to)
		if then.is_valid():
			then.call()
	if travel_dry_run:
		land.call()
	else:
		hud.fade_through_black(land)

## Shown when it saves a walk: when Kaze is away from the village (in any
## region) and no portal is waiting.
func fast_travel_available() -> bool:
	if get_node_or_null("Tutorial") != null or (hud != null and hud.get_parent().get_node_or_null("Tutorial") != null):
		return false
	return portal == null and Vector2(player.global_position.x - Travel.START_ARRIVAL.x, player.global_position.z - Travel.START_ARRIVAL.z).length() > 40.0

## Kaze is fighting (D-104): an enemy near him is chasing or attacking him.
## Fast travel waits until he wins or gets away (enemies give up and walk home).
const COMBAT_RANGE := 40.0

func in_combat() -> bool:
	if player == null:
		return false
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not (enemy is Node3D) or not enemy.has_method("is_alive") or not enemy.is_alive():
			continue
		var state = enemy.get("state")
		if state != EnemyScript.State.CHASE and state != EnemyScript.State.ATTACK:
			continue
		if (enemy as Node3D).global_position.distance_to(player.global_position) < COMBAT_RANGE:
			return true
	return false

## To the Reaper and knights; a portal there leads back to this spot.
func fast_travel() -> void:
	if not fast_travel_available():
		return
	if in_combat():
		hud.show_combat_notice()
		return
	Progression.portal_region = region
	Progression.portal_position = player.global_position
	Progression.save()
	_teleport(Travel.START_ARRIVAL + Vector3(0, 1, 0), _spawn_portal)

func _spawn_portal() -> void:
	if portal != null:
		return
	portal = Node3D.new()
	portal.set_script(ReturnPortalScript)
	portal.name = "ReturnPortal"
	portal.label_text = "Back to the %s" % Travel.NAMES.get(Progression.portal_region, "fight")
	portal.hero = player
	portal.position = Travel.PORTAL_SPOT
	portal.rotation.y = PI / 4.0
	add_child(portal)
	portal.entered.connect(_through_portal)

func _through_portal() -> void:
	var spot := Progression.portal_position
	Progression.portal_region = 0
	Progression.save()
	portal.queue_free()
	portal = null
	_teleport(spot + Vector3(0, 1, 0))

func _ground(world: Node3D, at: Vector2) -> Vector3:
	var query := PhysicsRayQueryParameters3D.create(Vector3(at.x, 80.0, at.y), Vector3(at.x, -20.0, at.y), 1)
	var hit := world.get_world_3d().direct_space_state.intersect_ray(query)
	return Vector3(at.x, (hit.position.y if not hit.is_empty() else 0.0) + 0.2, at.y)

## Kaze "falls" when his health reaches zero, but there is no death (D-080):
## +1 max health, +(1 + Blood Knight level) damage, full health, keep fighting.
func _on_player_died() -> void:
	var gained := Progression.damage_per_fall()
	Progression.hero_fell()
	player.refill()
	hud.show_reward(gained)

