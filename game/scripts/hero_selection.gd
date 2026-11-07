extends Node

const CATALOG_PATH := "res://assets/hero_catalog.json"

var selected_id := "kaze"
var heroes: Array = []

func _ready() -> void:
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(CATALOG_PATH))
	if parsed is Array:
		heroes = parsed
	else:
		push_error("Could not load hero catalog")

func selected_hero() -> Dictionary:
	for hero in heroes:
		if hero.id == selected_id:
			return hero
	return {}
