@tool
extends Node3D

## Lowland ground plane using the shared ground material, with an infinite
## floor collider so the player can stand on it.

@export var half_size := 160.0
@export var material: Material
## x/z area the plane covers; empty means the square of half_size. A linked
## region's ground stops where its neighbour's begins (D-102).
@export var extents := Rect2()

func _ready() -> void:
	if get_node_or_null("Mesh") != null:
		return
	var plane := PlaneMesh.new()
	var area := extents if extents.has_area() else Rect2(-half_size, -half_size, half_size * 2.0, half_size * 2.0)
	plane.size = area.size
	plane.material = material
	var visual := MeshInstance3D.new()
	visual.name = "Mesh"
	visual.position = Vector3(area.get_center().x, 0.0, area.get_center().y)
	visual.mesh = plane
	visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(visual)
	var body := StaticBody3D.new()
	body.name = "Body"
	var shape := CollisionShape3D.new()
	shape.shape = WorldBoundaryShape3D.new()
	body.add_child(shape)
	add_child(body)
