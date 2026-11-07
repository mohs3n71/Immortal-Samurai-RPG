extends RefCounted

## Original animation clips for the Toony Tiny RTS soldier rig (D-078). The
## extracted Unity clips are humanoid muscle curves that cannot be retargeted
## outside Unity, so these are authored here instead, the same way as Kaze's.
##
## Keys are Euler degrees in the soldier's model space (+Z forward, +X his
## left, like Kaze): X negative swings a hanging arm or leg forward, Z
## negative lifts the right arm out to his right. Each delta is converted to
## the bone's local space as rest * (G^-1 * D * G), where G is the bone's
## rest orientation in model space, so a key always turns the bone about the
## model axis no matter how the 3ds Max biped bones are oriented.

const BONES := {
	"pelvis": "Bip001 Pelvis",
	"spine": "Bip001 Spine",
	"upper_arm.L": "Bip001 L UpperArm", "forearm.L": "Bip001 L Forearm", "hand.L": "Bip001 L Hand",
	"upper_arm.R": "Bip001 R UpperArm", "forearm.R": "Bip001 R Forearm", "hand.R": "Bip001 R Hand",
	"thigh.L": "Bip001 L Thigh", "calf.L": "Bip001 L Calf", "foot.L": "Bip001 L Foot",
	"thigh.R": "Bip001 R Thigh", "calf.R": "Bip001 R Calf", "foot.R": "Bip001 R Foot",
}

## Seconds into each attack clip at which the blow lands.
const HIT_TIME := {"attack_chop": 0.42, "attack_thrust": 0.38, "attack_cast": 0.55}

static var _cache := {}

## Builds (or returns the cached) library for the skeleton of one soldier type.
static func library_for(key: String, skeleton: Skeleton3D, model_root: Node3D) -> AnimationLibrary:
	if _cache.has(key):
		return _cache[key]
	var context := {
		"skeleton": skeleton,
		"path": String(model_root.get_path_to(skeleton)),
		"to_skeleton": (model_root.global_transform.affine_inverse() * skeleton.global_transform).basis.orthonormalized(),
	}
	var library := AnimationLibrary.new()
	library.add_animation("idle", _idle(context))
	library.add_animation("walk", _walk(context))
	library.add_animation("attack_chop", _attack_chop(context))
	library.add_animation("attack_thrust", _attack_thrust(context))
	library.add_animation("attack_cast", _attack_cast(context))
	library.add_animation("hit", _hit(context))
	library.add_animation("death", _death(context))
	_cache[key] = library
	return library

## Relaxed arms: the rig's rest pose holds them out at about 45 degrees.
const ARMS_DOWN := {"upper_arm.L": Vector3(0, 0, -28), "upper_arm.R": Vector3(-18, 0, 28), "forearm.R": Vector3(-35, 0, 0), "forearm.L": Vector3(-10, 0, 0)}

static func _idle(context: Dictionary) -> Animation:
	return _clip(context, 1.6, true, {
		"pelvis": [[0.0, Vector3.ZERO], [0.8, Vector3(0, 3, 0)], [1.6, Vector3.ZERO]],
		"spine": [[0.0, Vector3(4, 0, 0)], [0.8, Vector3(7, -3, 0)], [1.6, Vector3(4, 0, 0)]],
		"upper_arm.L": [[0.0, Vector3(0, 0, -28)], [0.8, Vector3(-4, 0, -24)], [1.6, Vector3(0, 0, -28)]],
		"forearm.L": [[0.0, Vector3(-10, 0, 0)], [0.8, Vector3(-16, 0, 0)], [1.6, Vector3(-10, 0, 0)]],
		"upper_arm.R": [[0.0, Vector3(-18, 0, 28)], [0.8, Vector3(-24, 0, 24)], [1.6, Vector3(-18, 0, 28)]],
		"forearm.R": [[0.0, Vector3(-35, 0, 0)], [0.8, Vector3(-42, 0, 0)], [1.6, Vector3(-35, 0, 0)]],
	}, {"pelvis": [[0.0, Vector3.ZERO], [0.8, Vector3(0, -0.012, 0)], [1.6, Vector3.ZERO]]})

static func _walk(context: Dictionary) -> Animation:
	var step := 0.3
	return _clip(context, step * 2.0, true, {
		"pelvis": [[0.0, Vector3(0, 6, 0)], [step, Vector3(0, -6, 0)], [step * 2.0, Vector3(0, 6, 0)]],
		"spine": [[0.0, Vector3(10, -8, 0)], [step, Vector3(10, 8, 0)], [step * 2.0, Vector3(10, -8, 0)]],
		"thigh.L": [[0.0, Vector3(-32, 0, 0)], [step, Vector3(26, 0, 0)], [step * 2.0, Vector3(-32, 0, 0)]],
		"calf.L": [[0.0, Vector3(10, 0, 0)], [step * 0.5, Vector3(14, 0, 0)], [step, Vector3(8, 0, 0)], [step * 1.5, Vector3(55, 0, 0)], [step * 2.0, Vector3(10, 0, 0)]],
		"thigh.R": [[0.0, Vector3(26, 0, 0)], [step, Vector3(-32, 0, 0)], [step * 2.0, Vector3(26, 0, 0)]],
		"calf.R": [[0.0, Vector3(8, 0, 0)], [step * 0.5, Vector3(55, 0, 0)], [step, Vector3(10, 0, 0)], [step * 1.5, Vector3(14, 0, 0)], [step * 2.0, Vector3(8, 0, 0)]],
		"upper_arm.L": [[0.0, Vector3(24, 0, -26)], [step, Vector3(-28, 0, -26)], [step * 2.0, Vector3(24, 0, -26)]],
		"forearm.L": [[0.0, Vector3(-12, 0, 0)], [step, Vector3(-30, 0, 0)], [step * 2.0, Vector3(-12, 0, 0)]],
		"upper_arm.R": [[0.0, Vector3(-40, 0, 26)], [step, Vector3(-8, 0, 26)], [step * 2.0, Vector3(-40, 0, 26)]],
		"forearm.R": [[0.0, Vector3(-40, 0, 0)], [step, Vector3(-30, 0, 0)], [step * 2.0, Vector3(-40, 0, 0)]],
		"hand.R": [[0.0, Vector3(30, 0, 0)], [step, Vector3(12, 0, 0)], [step * 2.0, Vector3(30, 0, 0)]],
	}, {"pelvis": [[0.0, Vector3.ZERO], [step * 0.5, Vector3(0, 0.03, 0)], [step, Vector3.ZERO], [step * 1.5, Vector3(0, 0.03, 0)], [step * 2.0, Vector3.ZERO]]})

## Overhead chop: raise the weapon high, step in and bring it down.
static func _attack_chop(context: Dictionary) -> Animation:
	return _clip(context, 0.95, false, {
		"pelvis": [[0.0, Vector3.ZERO], [0.3, Vector3(0, -18, 0)], [0.42, Vector3(0, 14, 0)], [0.95, Vector3.ZERO]],
		"spine": [[0.0, Vector3(4, 0, 0)], [0.3, Vector3(-14, -10, 0)], [0.42, Vector3(26, 10, 0)], [0.6, Vector3(22, 6, 0)], [0.95, Vector3(4, 0, 0)]],
		"upper_arm.R": [[0.0, Vector3(-18, 0, 28)], [0.3, Vector3(-165, 0, 10)], [0.42, Vector3(-55, 0, 14)], [0.6, Vector3(-40, 0, 18)], [0.95, Vector3(-18, 0, 28)]],
		"forearm.R": [[0.0, Vector3(-35, 0, 0)], [0.3, Vector3(-60, 0, 0)], [0.42, Vector3(-8, 0, 0)], [0.95, Vector3(-35, 0, 0)]],
		"hand.R": [[0.0, Vector3.ZERO], [0.3, Vector3(20, 0, 0)], [0.42, Vector3(60, 0, 0)], [0.6, Vector3(50, 0, 0)], [0.95, Vector3.ZERO]],
		"upper_arm.L": [[0.0, Vector3(0, 0, -28)], [0.3, Vector3(-40, 0, -30)], [0.42, Vector3(-60, 0, -20)], [0.95, Vector3(0, 0, -28)]],
		"forearm.L": [[0.0, Vector3(-10, 0, 0)], [0.3, Vector3(-40, 0, 0)], [0.95, Vector3(-10, 0, 0)]],
		"thigh.L": [[0.0, Vector3.ZERO], [0.3, Vector3(-10, 0, 0)], [0.42, Vector3(-38, 0, 0)], [0.7, Vector3(-30, 0, 0)], [0.95, Vector3.ZERO]],
		"calf.L": [[0.0, Vector3.ZERO], [0.42, Vector3(30, 0, 0)], [0.95, Vector3.ZERO]],
		"thigh.R": [[0.0, Vector3.ZERO], [0.42, Vector3(18, 0, 0)], [0.95, Vector3.ZERO]],
		"calf.R": [[0.0, Vector3.ZERO], [0.42, Vector3(26, 0, 0)], [0.95, Vector3.ZERO]],
	}, {"pelvis": [[0.0, Vector3.ZERO], [0.42, Vector3(0, -0.05, 0.06)], [0.7, Vector3(0, -0.04, 0.05)], [0.95, Vector3.ZERO]]})

## Spear, pike and halberd thrust: pull back, then drive the point forward.
static func _attack_thrust(context: Dictionary) -> Animation:
	return _clip(context, 0.9, false, {
		"pelvis": [[0.0, Vector3.ZERO], [0.26, Vector3(0, -24, 0)], [0.38, Vector3(0, 16, 0)], [0.9, Vector3.ZERO]],
		"spine": [[0.0, Vector3(4, 0, 0)], [0.26, Vector3(-6, -16, 0)], [0.38, Vector3(18, 12, 0)], [0.9, Vector3(4, 0, 0)]],
		"upper_arm.R": [[0.0, Vector3(-18, 0, 28)], [0.26, Vector3(-40, 0, 40)], [0.38, Vector3(-88, 0, 8)], [0.6, Vector3(-80, 0, 10)], [0.9, Vector3(-18, 0, 28)]],
		"forearm.R": [[0.0, Vector3(-35, 0, 0)], [0.26, Vector3(-95, 0, 0)], [0.38, Vector3(-4, 0, 0)], [0.9, Vector3(-35, 0, 0)]],
		"hand.R": [[0.0, Vector3.ZERO], [0.26, Vector3(40, 0, 0)], [0.38, Vector3(82, 0, 0)], [0.6, Vector3(76, 0, 0)], [0.9, Vector3.ZERO]],
		"upper_arm.L": [[0.0, Vector3(0, 0, -28)], [0.26, Vector3(-30, 0, -20)], [0.38, Vector3(-70, 0, -10)], [0.9, Vector3(0, 0, -28)]],
		"forearm.L": [[0.0, Vector3(-10, 0, 0)], [0.38, Vector3(-30, 0, 0)], [0.9, Vector3(-10, 0, 0)]],
		"thigh.L": [[0.0, Vector3.ZERO], [0.38, Vector3(-40, 0, 0)], [0.7, Vector3(-34, 0, 0)], [0.9, Vector3.ZERO]],
		"calf.L": [[0.0, Vector3.ZERO], [0.38, Vector3(28, 0, 0)], [0.9, Vector3.ZERO]],
		"thigh.R": [[0.0, Vector3.ZERO], [0.38, Vector3(24, 0, 0)], [0.9, Vector3.ZERO]],
	}, {"pelvis": [[0.0, Vector3.ZERO], [0.26, Vector3(0, 0, -0.04)], [0.38, Vector3(0, -0.05, 0.1)], [0.7, Vector3(0, -0.04, 0.08)], [0.9, Vector3.ZERO]]})

## Mage: raise both hands, then push a burst forward.
static func _attack_cast(context: Dictionary) -> Animation:
	return _clip(context, 1.1, false, {
		"spine": [[0.0, Vector3(4, 0, 0)], [0.4, Vector3(-16, 0, 0)], [0.55, Vector3(20, 0, 0)], [1.1, Vector3(4, 0, 0)]],
		"upper_arm.L": [[0.0, Vector3(0, 0, -28)], [0.4, Vector3(-150, 0, -30)], [0.55, Vector3(-80, 0, 0)], [0.8, Vector3(-75, 0, 0)], [1.1, Vector3(0, 0, -28)]],
		"forearm.L": [[0.0, Vector3(-10, 0, 0)], [0.4, Vector3(-20, 0, 0)], [0.55, Vector3(0, 0, 0)], [1.1, Vector3(-10, 0, 0)]],
		"upper_arm.R": [[0.0, Vector3(-18, 0, 28)], [0.4, Vector3(-150, 0, 30)], [0.55, Vector3(-80, 0, 0)], [0.8, Vector3(-75, 0, 0)], [1.1, Vector3(-18, 0, 28)]],
		"forearm.R": [[0.0, Vector3(-35, 0, 0)], [0.4, Vector3(-20, 0, 0)], [0.55, Vector3(0, 0, 0)], [1.1, Vector3(-35, 0, 0)]],
		"thigh.L": [[0.0, Vector3.ZERO], [0.55, Vector3(-24, 0, 0)], [1.1, Vector3.ZERO]],
		"thigh.R": [[0.0, Vector3.ZERO], [0.55, Vector3(14, 0, 0)], [1.1, Vector3.ZERO]],
	}, {"pelvis": [[0.0, Vector3.ZERO], [0.4, Vector3(0, 0.03, 0)], [0.55, Vector3(0, -0.04, 0.05)], [1.1, Vector3.ZERO]]})

static func _hit(context: Dictionary) -> Animation:
	return _clip(context, 0.3, false, {
		"spine": [[0.0, Vector3(4, 0, 0)], [0.08, Vector3(-22, 8, 0)], [0.3, Vector3(4, 0, 0)]],
		"upper_arm.L": [[0.0, Vector3(0, 0, -28)], [0.08, Vector3(-30, 0, -50)], [0.3, Vector3(0, 0, -28)]],
		"upper_arm.R": [[0.0, Vector3(-18, 0, 28)], [0.08, Vector3(-40, 0, 50)], [0.3, Vector3(-18, 0, 28)]],
		"forearm.R": [[0.0, Vector3(-35, 0, 0)], [0.3, Vector3(-35, 0, 0)]],
	}, {"pelvis": [[0.0, Vector3.ZERO], [0.08, Vector3(0, 0, -0.05)], [0.3, Vector3.ZERO]]})

## Knees give and the arms fall; enemy.gd then tips the whole body over.
static func _death(context: Dictionary) -> Animation:
	return _clip(context, 0.6, false, {
		"spine": [[0.0, Vector3(4, 0, 0)], [0.2, Vector3(-30, 0, 0)], [0.6, Vector3(-40, 0, 0)]],
		"upper_arm.L": [[0.0, Vector3(0, 0, -28)], [0.3, Vector3(-60, 0, -70)], [0.6, Vector3(-80, 0, -80)]],
		"upper_arm.R": [[0.0, Vector3(-18, 0, 28)], [0.3, Vector3(-60, 0, 70)], [0.6, Vector3(-80, 0, 80)]],
		"forearm.R": [[0.0, Vector3(-35, 0, 0)], [0.6, Vector3(-10, 0, 0)]],
		"thigh.L": [[0.0, Vector3.ZERO], [0.3, Vector3(-30, 0, 0)], [0.6, Vector3(-20, 0, 0)]],
		"calf.L": [[0.0, Vector3.ZERO], [0.3, Vector3(50, 0, 0)], [0.6, Vector3(30, 0, 0)]],
		"thigh.R": [[0.0, Vector3.ZERO], [0.3, Vector3(-24, 0, 0)], [0.6, Vector3(-10, 0, 0)]],
		"calf.R": [[0.0, Vector3.ZERO], [0.3, Vector3(46, 0, 0)], [0.6, Vector3(20, 0, 0)]],
	}, {"pelvis": [[0.0, Vector3.ZERO], [0.3, Vector3(0, -0.12, 0)], [0.6, Vector3(0, -0.14, -0.05)]]})

## rotations: {key: [[time, Vector3 degrees in model space]]};
## positions: {key: [[time, Vector3 model-space offset in rig units]]}.
static func _clip(context: Dictionary, length: float, loop: bool, rotations: Dictionary, positions: Dictionary = {}) -> Animation:
	var skeleton: Skeleton3D = context.skeleton
	var to_skeleton: Basis = context.to_skeleton
	var animation := Animation.new()
	animation.length = length
	animation.loop_mode = Animation.LOOP_LINEAR if loop else Animation.LOOP_NONE
	for key in BONES:
		var bone := skeleton.find_bone(BONES[key])
		if bone < 0:
			continue
		var rest: Transform3D = skeleton.get_bone_rest(bone)
		var global_rest: Basis = skeleton.get_bone_global_rest(bone).basis.orthonormalized()
		var keys: Array = rotations.get(key, [[0.0, ARMS_DOWN.get(key, Vector3.ZERO)]])
		var track := animation.add_track(Animation.TYPE_ROTATION_3D)
		animation.track_set_path(track, "%s:%s" % [context.path, BONES[key]])
		for entry in keys:
			var degrees: Vector3 = entry[1]
			var model_delta := Basis.from_euler(degrees * PI / 180.0)
			var skeleton_delta := to_skeleton.inverse() * model_delta * to_skeleton
			var local := rest.basis.orthonormalized() * (global_rest.inverse() * skeleton_delta * global_rest)
			animation.rotation_track_insert_key(track, entry[0], local.get_rotation_quaternion())
		if positions.has(key):
			var position_track := animation.add_track(Animation.TYPE_POSITION_3D)
			animation.track_set_path(position_track, "%s:%s" % [context.path, BONES[key]])
			var parent := skeleton.get_bone_parent(bone)
			var parent_basis: Basis = skeleton.get_bone_global_rest(parent).basis if parent >= 0 else Basis.IDENTITY
			for entry in positions[key]:
				var offset: Vector3 = to_skeleton.inverse() * entry[1]
				animation.position_track_insert_key(position_track, entry[0], rest.origin + parent_basis.inverse() * offset)
	return animation
