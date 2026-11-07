extends "res://tests/check_meadow_traversal.gd"

## Prints triangles, draw calls and objects per frame at busy spots (portrait).
## Usage: godot --path game --resolution 720x1280 --script res://tests/report_render_cost.gd

func _run() -> void:
	field = (load(FIELD) as PackedScene).instantiate()
	root.add_child(field)
	await create_timer(0.8).timeout
	_set_auto_attack(false)
	await _report_cost([Vector3(4, 0, 8), Vector3(-50, 8, -60), Vector3(60, 0, -60), Vector3(-45, 0, 45), Vector3(-124, 0, 26), Vector3(116, 0, -110), Vector3(80, 0, 136), Vector3(-134, 15, -146), Vector3(0, 0, 130), Vector3(40, 0, -22)])
	quit()
