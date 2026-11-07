extends RefCounted

## Hand-authored layout data for the Meadowlands region (D-068, enlarged in D-070).
## World units; +X is screen lower-right, -Z is screen upper-right for the
## field camera. The playable square is +/-PLAY_HALF; cliffs ring it.
## The original 168 x 168 meadow ("core", |x|,|z| < 84) is kept unchanged in the
## middle; the outer ring adds new places around it.
## Edit here and re-run tools/build_meadow.gd, or edit the generated scene.

const PLAY_HALF := 168.0
const WORLD_HALF := 250.0
const BORDER_HEIGHT := 12.0
# Borders between the camera and the player (south, east) stay low so they never hide the hero.
const NEAR_BORDER_HEIGHT := 3.0
const TERRACE_HEIGHT := 8.0
const SPAWN := Vector3(4, 0, 8)
# Where water leaves the map: the north stream (x) and the lake outflow on the east (z).
const NORTH_NOTCH := Vector2(38, 58)
const EAST_NOTCH := Vector2(128, 148)

# Dirt paths: [half width, points]. The first six are the original core paths.
const PATHS := [
	[3.2, [Vector2(4, 2), Vector2(18, -8), Vector2(30, -16), Vector2(40, -22), Vector2(52, -30), Vector2(62, -44), Vector2(68, -60)]],
	[3.0, [Vector2(0, 0), Vector2(-10, -12), Vector2(-20, -24), Vector2(-26, -36), Vector2(-35, -48)]],
	[2.6, [Vector2(-35, -48), Vector2(-44, -55), Vector2(-54, -62)]],
	[3.0, [Vector2(-2, 4), Vector2(-16, 14), Vector2(-32, 24), Vector2(-48, 36), Vector2(-60, 52)]],
	[2.6, [Vector2(4, 6), Vector2(14, 18), Vector2(24, 30), Vector2(33, 38)]],
	[3.0, [Vector2(0, 6), Vector2(3, 24), Vector2(-2, 44), Vector2(1, 64), Vector2(0, 92), Vector2(2, 110), Vector2(0, 130)]],
	# Short spurs from the village square to the start-area arenas (D-080).
	[2.2, [Vector2(-3, 2), Vector2(-15, 2)]],
	[2.2, [Vector2(3, -3), Vector2(4, -14)]],
	[2.2, [Vector2(-1, 7), Vector2(-8, 19)]],
	# Outer ring.
	[2.8, [Vector2(30, -16), Vector2(28, -40), Vector2(30, -64), Vector2(32, -88), Vector2(30, -110), Vector2(20, -128), Vector2(12, -140)]],
	[3.0, [Vector2(84, -2), Vector2(86, -22), Vector2(96, -42), Vector2(100, -70), Vector2(110, -95), Vector2(120, -116)]],
	# Branch to the region boss arena (D-085).
	[2.8, [Vector2(108, -92), Vector2(100, -112), Vector2(94, -128), Vector2(90, -138)]],
	[2.6, [Vector2(52, -30), Vector2(60, -22), Vector2(68, -10), Vector2(84, -2), Vector2(98, -8), Vector2(119, -4), Vector2(130, -2), Vector2(140, -1)]],
	[3.0, [Vector2(0, 130), Vector2(28, 138), Vector2(52, 138), Vector2(78, 140)]],
	[3.0, [Vector2(0, 130), Vector2(-28, 124), Vector2(-58, 118), Vector2(-90, 116), Vector2(-112, 118)]],
	[2.8, [Vector2(-60, 52), Vector2(-72, 53), Vector2(-90, 46), Vector2(-108, 34), Vector2(-124, 22)]],
	[2.6, [Vector2(-54, -62), Vector2(-46, -70), Vector2(-54, -84), Vector2(-66, -98), Vector2(-86, -102), Vector2(-107, -128.5), Vector2(-122, -140), Vector2(-138, -150)]],
]
# Dirt clearings painted like paths: [x, z, radius].
const PLAZAS := [Vector3(2, 2, 10), Vector3(-56, -64, 9), Vector3(68, -62, 9), Vector3(-62, 54, 7),
	Vector3(12, -142, 11), Vector3(120, -116, 12), Vector3(150, 0, 13), Vector3(0, 132, 12),
	Vector3(80, 142, 8), Vector3(-118, 120, 9), Vector3(-128, 20, 8), Vector3(-140, -150, 10),
	# Start-area arenas (D-080): Reaper (west), Blood Knight (north), Plague Knight (south-west).
	Vector3(-21, 2, 6.5), Vector3(4, -20, 6.5), Vector3(-12, 25, 6.5),
	# Region boss arena (D-085), in front of the sealed gate to the next region.
	Vector3(88, -148, 13)]
## Centres of the three start-area arenas, in the order above.
const REAPER_ARENA := Vector2(-21, 2)
const BLOOD_ARENA := Vector2(4, -20)
const PLAGUE_ARENA := Vector2(-12, 25)

# Stream, pond and lake (mask G).
const STREAM_HALF_WIDTH := 4.5
const STREAM := [Vector2(46, -205), Vector2(48, -172), Vector2(50, -150), Vector2(42, -125), Vector2(44, -100), Vector2(42, -72), Vector2(36, -50), Vector2(40, -22), Vector2(48, -4), Vector2(46, 16), Vector2(50, 34)]
const OUTFLOW := [Vector2(58, 56), Vector2(64, 72), Vector2(66, 95), Vector2(80, 110), Vector2(102, 120)]
const POND := [Vector3(54, 46, 12), Vector3(60, 40, 8), Vector3(48, 52, 7)]
const LAKE := [Vector3(125, 125, 26), Vector3(146, 104, 13), Vector3(108, 146, 12)]
const LAKE_OUTFLOW := [Vector2(146, 128), Vector2(160, 134), Vector2(175, 138), Vector2(205, 142)]

# Raised ground. Each plateau: outline, top height, the height it stands on,
# and ramps (bottom at `base`, top at `height`).
const PLATEAUS := [
	{"name": "Terrace", "height": 8.0, "base": 0.0, "seed": 11,
		"outline": [Vector2(-200, -200), Vector2(-30, -200), Vector2(-28, -172), Vector2(-22, -150), Vector2(-14, -128), Vector2(-12, -104), Vector2(-14, -74), Vector2(-24, -60), Vector2(-30, -50), Vector2(-44, -42), Vector2(-60, -38), Vector2(-72, -26), Vector2(-104, -24), Vector2(-125, -14), Vector2(-145, -8), Vector2(-172, -6), Vector2(-200, -6)],
		"ramps": [{"bottom": Vector2(-12, -15.5), "top": Vector2(-35.5, -48.5), "width": 12.0}]},
	{"name": "UpperTerrace", "height": 15.0, "base": 8.0, "seed": 12,
		"outline": [Vector2(-200, -200), Vector2(-80, -200), Vector2(-82, -172), Vector2(-92, -150), Vector2(-100, -132), Vector2(-118, -118), Vector2(-140, -110), Vector2(-160, -104), Vector2(-200, -102)],
		"ramps": [{"bottom": Vector2(-82, -97), "top": Vector2(-107, -128.5), "width": 12.0}]},
	{"name": "EastPlateau", "height": 4.5, "base": 0.0, "seed": 13,
		"outline": [Vector2(118, -50), Vector2(150, -58), Vector2(200, -60), Vector2(200, 62), Vector2(150, 58), Vector2(128, 44), Vector2(114, 12)],
		"ramps": [{"bottom": Vector2(90, -9.5), "top": Vector2(119, -4), "width": 12.0}]},
]

# Small decorative rock outcrops (not walkable on top): [x, z, radius, height].
const OUTCROPS := [Vector4(76, -30, 7, 3.0), Vector4(-76, 14, 6, 2.5), Vector4(24, 74, 7, 3.5), Vector4(74, 14, 5, 2.2),
	Vector4(100, 62, 7, 3.0), Vector4(60, 108, 6, 2.5), Vector4(-40, 104, 7, 3.2), Vector4(-62, 152, 6, 2.5),
	Vector4(30, -162, 7, 3.0), Vector4(-152, 52, 6, 2.8), Vector4(82, -110, 5, 2.4), Vector4(36, 158, 6, 2.6)]
# Rocky island in the lake, with props on top (see ISLAND_PROPS).
const ISLAND := Vector4(128, 128, 7, 1.5)

# Props: [asset, x, z, height, yaw, collision?, tint?]. Collision: "solid" (default for
# recovered props), "trunk" (default for trees), "box" or "none".
const VILLAGE := [
	["butcher/snow-lodge", 12, -46, 13.0, 0.75],
	["butcher/snow-lodge-b", -42, -10, 12.0, 1.6],
	["butcher/desert-building", 21, 5, 9.0, -1.2],
	["butcher/camp-structure", -6, -38, 8.0, 0.4],
	["butcher/desert-cart", 13, 27, 5.0, 2.2],
	["butcher/camp-bonfire", 12, 1, 1.4, 0.0, "none"],
	["stylized/log", 12, 4.5, 0.9, 0.0, "none"],
	["stylized/log", 15.5, 0, 0.9, 1.6, "none"],
	["butcher/camp-barrel", 12, -12, 2.4, 0.0],
	["butcher/camp-barrel", 17, -14, 2.0, 1.0],
	["butcher/snow-crate", 16, 30, 2.0, 0.3, "solid", Color("b9875a")],
	["butcher/snow-crate", 9, 30, 1.6, 1.1, "solid", Color("b9875a")],
	["butcher/camp-barrel", 17, 32, 2.2, 0.0],
	["butcher/stone-statue", -14, -5, 5.0, 0.7],
	["stylized/haystack", -26, -8, 2.6, 0.0, "solid"],
	["stylized/boulder", -14, -33, 2.6, 0.0, "solid"],
	["stylized/boulder", -28, -25, 2.2, 1.0, "solid"],
	["stylized/boulder", -18, -40, 3.2, 2.0, "solid"],
	["stylized/boulder", -31, -31, 2.8, 0.5, "solid"],
	["stylized/bush", -10, -29, 1.8, 0.0, "none"],
	["stylized/bush", -30, -22, 1.6, 0.0, "none"],
	["stylized/tree-round", 28, -6, 9.0, 0.0],
	["stylized/tree-round", -28, -16, 10.0, 1.0],
	["stylized/tree-tall", -12, 42, 11.0, 2.0],
	["stylized/tree-round", 30, 22, 9.0, 3.0],
	["stylized/tree-pine", 16, -30, 10.0, 0.0],
	["stylized/bush", -6, -24, 1.8, 0.0, "none"],
	["stylized/bush", 24, -16, 2.0, 1.0, "none"],
	["stylized/bush", -24, 16, 1.6, 2.0, "none"],
	["stylized/bush", 8, 38, 1.8, 0.5, "none"],
]

const TERRACE_PROPS := [
	["butcher/stone-statue", -60, -68, 9.0, 0.75],
	["butcher/stone-statue", -46, -50, 5.0, 0.75],
	["butcher/stone-statue", -40, -58, 5.0, 0.75],
	["butcher/green-crystal", -64, -58, 4.0, 0.4],
	["butcher/green-crystal", -52, -72, 3.2, 1.4],
	["butcher/green-crystal", -66, -62, 2.4, 2.4],
	["butcher/camp-bonfire", -54, -60, 1.4, 0.0, "none"],
	["butcher/grass-tree-b", -72, -48, 9.0, 1.2],
	["butcher/grass-tree-a", -30, -70, 8.0, 2.8],
	["stylized/tree-round", -80, -60, 11.0, 0.0],
	["stylized/tree-pine", -76, -78, 12.0, 0.0],
	["stylized/tree-round", -44, -80, 10.0, 0.5],
	["stylized/tree-pine", -24, -84, 11.0, 0.0],
	["stylized/tree-tall", -84, -40, 12.0, 0.0],
	["stylized/tree-round", -62, -86, 10.0, 0.0],
	["stylized/boulder", -36, -64, 2.4, 0.0, "solid"],
	["stylized/boulder", -70, -36, 2.0, 1.0, "solid"],
]

const FOREST := [
	["butcher/desert-building", 74, -70, 8.0, 0.6],
	["stylized/stump", 58, -58, 1.0, 0.0, "solid"],
	["stylized/stump", 74, -54, 1.0, 1.0, "solid"],
	["stylized/log", 64, -68, 1.0, 0.4, "box"],
	["stylized/log", 61, -70, 1.0, 0.2, "box"],
	["butcher/camp-barrel", 78, -60, 2.2, 0.0],
	["butcher/camp-bonfire", 67, -61, 1.2, 0.0, "none"],
	["stylized/tree-pine", 56, -78, 12.0, 0.0],
	["stylized/tree-round", 52, -54, 10.0, 0.0],
	["stylized/tree-pine", 80, -42, 11.0, 0.0],
	["stylized/tree-round", 50, -40, 9.0, 0.0],
	["stylized/tree-tall", 72, -36, 12.0, 0.0],
	["stylized/tree-pine", 50, -66, 11.0, 0.0],
	["stylized/tree-round", 82, -78, 10.0, 0.0],
	["stylized/tree-pine", 64, -84, 12.0, 0.0],
	["stylized/tree-round", 54, -22, 9.0, 0.0],
	["stylized/tree-pine", 66, -24, 11.0, 0.0],
	["stylized/tree-round", 80, -10, 10.0, 0.0],
	["stylized/tree-pine", 60, -6, 10.0, 0.0],
	["stylized/boulder", 70, -46, 2.2, 0.0, "solid"],
	["stylized/rock", 56, -60, 1.2, 0.0, "none"],
	["butcher/grass-tree-a", 82, -52, 7.0, 4.0],
]

const FARM := [
	["butcher/desert-building", -68, 60, 9.0, 0.8],
	["stylized/haystack", -63, 71, 2.8, 0.0, "solid"],
	["stylized/haystack", -58, 68, 2.4, 0.0, "solid"],
	["stylized/haystack", -72, 46, 2.6, 0.0, "solid"],
	["butcher/desert-cart", -46, 50, 4.5, 2.6],
	["butcher/camp-barrel", -64, 70, 2.2, 0.0],
	["stylized/tree-round", -78, 30, 10.0, 0.0],
	["stylized/tree-tall", -80, 74, 12.0, 0.0],
	["stylized/tree-round", -16, 66, 9.0, 0.0],
	["stylized/tree-pine", -36, 4, 10.0, 0.0],
	["stylized/tree-round", -8, 78, 10.0, 0.0],
	["stylized/bush", -44, 48, 1.8, 0.0, "none"],
	["stylized/bush", -30, 60, 1.6, 0.0, "none"],
]
# Crop plots: [x, z, yaw, size].
const FIELDS := [[-30, 40, 0.6, Vector2(18, 12)], [-60, 20, 0.6, Vector2(16, 12)], [-42, 64, 0.6, Vector2(14, 10)],
	[-96, 142, 0.1, Vector2(18, 12)], [-150, 140, 0.4, Vector2(16, 12)], [-132, 90, 0.5, Vector2(16, 10)], [-100, 94, 0.1, Vector2(14, 10)]]

const POND_PROPS := [
	["stylized/boulder", 42, 40, 2.0, 0.0, "solid"],
	["stylized/rock", 44, 56, 1.3, 0.0, "none"],
	["stylized/boulder", 66, 50, 2.4, 0.0, "solid"],
	["stylized/rock", 38, -30, 1.2, 0.0, "none"],
	["stylized/boulder", 47, -14, 1.8, 0.0, "solid"],
	["stylized/rock", 33, -40, 1.4, 0.0, "none"],
	["stylized/log", 38, 50, 1.0, 1.2, "box"],
	["stylized/tree-round", 36, 60, 10.0, 0.0],
	["stylized/tree-pine", 72, 34, 11.0, 0.0],
	["stylized/tree-round", 70, 64, 10.0, 0.0],
	["stylized/tree-tall", 32, 4, 11.0, 0.0],
	["stylized/tree-round", 56, 22, 9.0, 0.0],
	["stylized/tree-pine", 78, 78, 11.0, 0.0],
	["stylized/tree-round", 44, 76, 10.0, 0.0],
	["butcher/grass-tree-b", 24, 48, 8.0, 0.4],
]

const STONE := Color("a7a59d")
const OUTER_GROUPS := {
	"NorthRuins": [
		["butcher/volcanic-arch", 12, -152, 11.0, 0.8, "solid", STONE],
		["butcher/stone-statue", 0, -132, 6.0, 0.6],
		["butcher/stone-statue", 34, -134, 6.0, 2.2],
		["butcher/stone-statue", -2, -150, 4.0, 1.0],
		["butcher/sand-wall", 28, -150, 4.0, 2.4, "solid", STONE],
		["butcher/sand-wall", -6, -160, 3.5, 0.3, "solid", STONE],
		["butcher/green-crystal", 6, -128, 3.0, 0.2],
		["butcher/green-crystal", 4, -164, 3.6, 1.2],
		["butcher/grass-tree-b", 40, -156, 8.0, 0.5],
		["butcher/grass-tree-a", -8, -120, 7.0, 2.0],
		["stylized/boulder", 20, -166, 2.4, 0.0, "solid"],
	],
	"RangerOutpost": [
		["butcher/desert-tower", 134, -130, 18.0, 0.8],
		["butcher/camp-structure", 106, -128, 6.5, 0.7],
		["butcher/camp-structure", 132, -102, 8.0, 2.3],
		["butcher/desert-cart", 104, -108, 5.0, 1.4],
		["butcher/camp-bonfire", 120, -114, 1.4, 0.0, "none"],
		["stylized/log", 116, -110, 0.9, 0.6, "none"],
		["butcher/camp-barrel", 140, -112, 2.4, 0.0],
		["butcher/camp-barrel", 142, -116, 2.0, 1.0],
		["butcher/snow-crate", 112, -136, 2.0, 0.4, "solid", Color("b9875a")],
		["butcher/snow-crate", 116, -138, 1.6, 1.2, "solid", Color("b9875a")],
	],
	"LakeHut": [
		["butcher/snow-lodge-b", 78, 154, 11.0, 0.2],
		["butcher/camp-barrel", 90, 150, 2.2, 0.0],
		["stylized/log", 88, 136, 1.0, 0.9, "box"],
		["stylized/boulder", 98, 104, 2.2, 0.0, "solid"],
		["stylized/boulder", 152, 92, 2.6, 0.0, "solid"],
		["stylized/rock", 100, 132, 1.3, 0.0, "none"],
	],
	"SouthMarket": [
		["butcher/camp-structure", -14, 146, 8.0, 0.4],
		["butcher/camp-structure", 16, 148, 6.5, 2.6],
		["butcher/desert-cart", -20, 114, 5.0, 2.0],
		["butcher/desert-cart", 22, 118, 5.0, 0.8],
		["butcher/camp-barrel", 12, 116, 2.2, 0.0],
		["butcher/camp-barrel", 15, 114, 2.0, 0.6],
		["butcher/snow-crate", -24, 140, 2.0, 0.4, "solid", Color("b9875a")],
		["butcher/snow-crate", 26, 144, 1.8, 1.3, "solid", Color("b9875a")],
		["butcher/stone-statue", -6, 142, 5.0, 0.7],
		["butcher/camp-bonfire", 8, 138, 1.4, 0.0, "none"],
		["stylized/haystack", -26, 152, 2.6, 0.0, "solid"],
	],
	"PastureFarm": [
		["butcher/snow-lodge", -122, 136, 13.0, 0.9],
		["butcher/desert-building", -144, 112, 10.0, 1.4],
		["stylized/haystack", -134, 122, 2.8, 0.0, "solid"],
		["stylized/haystack", -138, 128, 2.4, 0.0, "solid"],
		["stylized/haystack", -104, 128, 2.6, 0.0, "solid"],
		["butcher/desert-cart", -126, 104, 4.5, 0.6],
		["butcher/camp-barrel", -112, 132, 2.2, 0.0],
		["butcher/camp-barrel", -150, 122, 2.0, 0.0],
	],
	"HunterCamp": [
		["butcher/camp-structure", -138, 12, 6.5, 0.6],
		["butcher/camp-bonfire", -126, 22, 1.4, 0.0, "none"],
		["stylized/log", -122, 26, 1.0, 0.4, "none"],
		["stylized/stump", -134, 30, 1.0, 0.0, "solid"],
		["butcher/creature-skull", -136, 26, 2.0, 1.0],
		["butcher/camp-barrel", -118, 14, 2.2, 0.0],
	],
}
# Props standing on a plateau or island: group name -> [base height, entries].
const RAISED_GROUPS := {
	"StoneCircle": [4.5, [
		["butcher/stone-statue", 162, 0, 6.0, 1.6],
		["butcher/stone-statue", 158.5, 8.5, 6.0, 2.4],
		["butcher/stone-statue", 150, 12, 6.0, 3.1],
		["butcher/stone-statue", 141.5, 8.5, 6.0, 3.9],
		["butcher/stone-statue", 141.5, -8.5, 6.0, 5.5],
		["butcher/stone-statue", 158.5, -8.5, 6.0, 0.8],
		["butcher/green-crystal", 150, 0, 5.0, 0.0],
		["butcher/green-crystal", 153, 3, 3.0, 1.0],
		["butcher/green-crystal", 147, -3, 2.6, 2.0],
	]],
	"HighShrine": [15.0, [
		["butcher/stone-statue", -146, -158, 14.0, 0.75],
		["butcher/green-crystal", -130, -152, 5.0, 0.3],
		["butcher/green-crystal", -150, -140, 4.0, 1.3],
		["butcher/green-crystal", -134, -162, 3.0, 2.0],
		["butcher/camp-bonfire", -138, -148, 1.4, 0.0, "none"],
		["butcher/grass-tree-b", -120, -160, 9.0, 0.4],
		["butcher/grass-tree-a", -158, -128, 9.0, 2.2],
	]],
	"Island": [1.5, [
		["butcher/grass-tree-b", 128, 128, 8.0, 0.0, "none"],
		["stylized/bush", 131, 125, 1.8, 0.0, "none"],
	]],
}

# Orchard: rows of fruit trees inside [origin, rows, columns, spacing, yaw].
const ORCHARD := [Vector2(84, -164), 3, 8, 8.5, 0.0]

# Generated woods: [name, polygon, tree count, base height, seed]. Trees avoid
# paths, water, props and clearings.
const GROVES := [
	["PineForest", [Vector2(-168, 2), Vector2(-140, -1), Vector2(-120, -6), Vector2(-100, -16), Vector2(-88, -18), Vector2(-88, 80), Vector2(-168, 84)], 70, 0.0, 501],
	["OutpostWoods", [Vector2(70, -88), Vector2(168, -88), Vector2(168, -168), Vector2(70, -168)], 34, 0.0, 502],
	["TerraceWoods", [Vector2(-168, -8), Vector2(-168, -100), Vector2(-90, -100), Vector2(-90, -168), Vector2(-32, -168), Vector2(-16, -104), Vector2(-74, -40), Vector2(-104, -28)], 55, 8.0, 503],
	["HighWoods", [Vector2(-168, -106), Vector2(-120, -122), Vector2(-96, -140), Vector2(-86, -168), Vector2(-168, -168)], 22, 15.0, 504],
	["EastPlateauWoods", [Vector2(152, -54), Vector2(168, -54), Vector2(168, 56), Vector2(152, 54)], 14, 4.5, 505],
	["LakeShore", [Vector2(88, 86), Vector2(168, 84), Vector2(168, 168), Vector2(84, 168)], 22, 0.0, 506],
	["SouthWoods", [Vector2(-84, 150), Vector2(84, 150), Vector2(84, 168), Vector2(-84, 168)], 24, 0.0, 507],
	["NorthMeadowEdge", [Vector2(-12, -100), Vector2(36, -100), Vector2(36, -168), Vector2(-24, -168)], 14, 0.0, 508],
	["EastMeadow", [Vector2(84, -86), Vector2(110, -86), Vector2(112, 84), Vector2(84, 84)], 16, 0.0, 509],
	["SouthWestMeadow", [Vector2(-168, 84), Vector2(-84, 84), Vector2(-84, 168), Vector2(-168, 168)], 14, 0.0, 510],
	["SouthMeadow", [Vector2(-84, 84), Vector2(84, 84), Vector2(84, 150), Vector2(-84, 150)], 18, 0.0, 511],
]
# Extra-dense flower meadows: polygons.
const FLOWER_MEADOWS := [
	[Vector2(-12, -104), Vector2(36, -104), Vector2(36, -166), Vector2(-24, -166)],
	[Vector2(-60, 96), Vector2(60, 96), Vector2(60, 150), Vector2(-60, 150)],
	[Vector2(86, 64), Vector2(160, 66), Vector2(150, 92), Vector2(88, 92)],
]

# Reeds hugging the water: [x, z].
const REED_SPOTS := [Vector2(42, 46), Vector2(46, 36), Vector2(62, 36), Vector2(66, 44), Vector2(58, 58), Vector2(46, 58), Vector2(36, -44), Vector2(44, -6), Vector2(50, 6), Vector2(34, -58), Vector2(42, 24), Vector2(52, 26),
	Vector2(100, 112), Vector2(98, 136), Vector2(112, 100), Vector2(150, 118), Vector2(120, 154), Vector2(140, 146), Vector2(36, -120), Vector2(56, -150), Vector2(70, 92)]

# Fence runs built from short upright plank segments: [from, to].
const FENCES := [
	[Vector2(-6, -30), Vector2(14, -30)],
	[Vector2(-31, -10), Vector2(-31, 9)],
	[Vector2(31, -4), Vector2(31, 14)],
	[Vector2(-23, 30), Vector2(-9, 35)],
	[Vector2(100, -142), Vector2(146, -142)],
	[Vector2(146, -138), Vector2(146, -104)],
	[Vector2(-160, 96), Vector2(-160, 160)],
	[Vector2(-156, 162), Vector2(-108, 162)],
	[Vector2(-30, 108), Vector2(-14, 104)],
]

# Training dummies near the village for auto-attack practice (D-072): [x, z, yaw].
const TRAINING_DUMMIES := [Vector3(20, 0, 14), Vector3(26, 0, 12), Vector3(24, 0, 20)]
