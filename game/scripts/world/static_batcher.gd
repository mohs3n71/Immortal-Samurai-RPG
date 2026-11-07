extends RefCounted

## Mobile performance (D-074): after the authored world has built itself,
## groups identical static models (same mesh and material) and all blob
## shadows into one MultiMesh per map tile, then frees the originals. Colliders
## are untouched. Tiles keep frustum culling effective. Nodes in the "enemies"
## group (and their children) stay separate because they animate.

const BlobShadow = preload("res://scripts/world/blob_shadow.gd")
const TILE := 48.0
const SKIP_GROUP := "enemies"

static var _shadow_material: StandardMaterial3D

## Returns {"before": instances considered, "after": draw nodes created}.
static func batch(world: Node3D) -> Dictionary:
	var groups := {}
	_collect(world, world, groups)
	var created := 0
	var replaced := 0
	for key in groups:
		var group: Dictionary = groups[key]
		if group.nodes.size() < 2:
			continue
		var holder := MultiMeshInstance3D.new()
		holder.name = "Batch_%d" % created
		holder.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var multimesh := MultiMesh.new()
		multimesh.transform_format = MultiMesh.TRANSFORM_3D
		multimesh.use_colors = group.shadow
		multimesh.mesh = group.mesh
		multimesh.instance_count = group.nodes.size()
		for index in group.nodes.size():
			var node: MeshInstance3D = group.nodes[index]
			multimesh.set_instance_transform(index, world.global_transform.affine_inverse() * node.global_transform)
			if group.shadow:
				multimesh.set_instance_color(index, Color(1, 1, 1, 1.0 - node.transparency))
			node.queue_free()
		holder.multimesh = multimesh
		if group.shadow:
			holder.material_override = _batched_shadow_material()
		elif group.material != null:
			holder.material_override = group.material
		world.add_child(holder)
		created += 1
		replaced += group.nodes.size()
	return {"replaced": replaced, "batches": created}

static func _collect(world: Node3D, node: Node, groups: Dictionary) -> void:
	if node.is_in_group(SKIP_GROUP):
		return
	if node is MeshInstance3D:
		_consider(node as MeshInstance3D, groups)
	for child in node.get_children():
		_collect(world, child, groups)

static func _consider(node: MeshInstance3D, groups: Dictionary) -> void:
	if node.mesh == null or not node.visible or node.skin != null:
		return
	var position := node.global_position
	var tile := Vector2i(floori(position.x / TILE), floori(position.z / TILE))
	var is_shadow := node.mesh == BlobShadow.shared_mesh()
	var material: Material = node.material_override
	if not is_shadow and material == null:
		var override := _single_surface_override(node)
		if override == null and _has_any_override(node):
			return
		material = override
	var key := "%s|%s|%s|%s" % [node.mesh.get_rid().get_id(), material.get_rid().get_id() if material != null else 0, tile, is_shadow]
	if not groups.has(key):
		groups[key] = {"mesh": node.mesh, "material": material, "shadow": is_shadow, "nodes": []}
	groups[key].nodes.append(node)

## A per-surface override can be batched only on single-surface meshes.
static func _single_surface_override(node: MeshInstance3D) -> Material:
	if node.mesh.get_surface_count() == 1:
		return node.get_surface_override_material(0)
	return null

static func _has_any_override(node: MeshInstance3D) -> bool:
	for surface in node.mesh.get_surface_count():
		if node.get_surface_override_material(surface) != null:
			return true
	return false

## Shadow material that takes per-instance alpha from the MultiMesh colour.
static func _batched_shadow_material() -> StandardMaterial3D:
	if _shadow_material == null:
		_shadow_material = (BlobShadow.shared_mesh().material as StandardMaterial3D).duplicate()
		_shadow_material.vertex_color_use_as_albedo = true
	return _shadow_material
