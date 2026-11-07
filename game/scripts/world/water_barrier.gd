@tool
extends Node3D

## Invisible colliders that keep the player out of painted water. Follows a
## polyline (optionally closed), leaving gaps where bridges cross.

const PIECE_LENGTH := 2.5

@export var polyline := PackedVector2Array()
@export var closed := false
@export var half_width := 2.0
@export var gaps := PackedVector2Array()
@export var gap_radius := 4.0

func _ready() -> void:
	if get_node_or_null("Body") != null or polyline.size() < 2:
		return
	var body := StaticBody3D.new()
	body.name = "Body"
	add_child(body)
	var count := polyline.size() if closed else polyline.size() - 1
	for index in count:
		_add_segment(body, polyline[index], polyline[(index + 1) % polyline.size()])

func _add_segment(body: StaticBody3D, a: Vector2, b: Vector2) -> void:
	var pieces := maxi(1, ceili(a.distance_to(b) / PIECE_LENGTH))
	for piece in pieces:
		var start := a.lerp(b, float(piece) / pieces)
		var end := a.lerp(b, float(piece + 1) / pieces)
		var middle := (start + end) * 0.5
		if _in_gap(middle):
			continue
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(half_width * 2.0, 3.0, start.distance_to(end) + 0.6)
		shape.shape = box
		shape.position = Vector3(middle.x, 1.5, middle.y)
		shape.rotation.y = atan2(end.x - start.x, end.y - start.y)
		body.add_child(shape)

func _in_gap(point: Vector2) -> bool:
	for gap in gaps:
		if point.distance_to(gap) < gap_radius:
			return true
	return false
