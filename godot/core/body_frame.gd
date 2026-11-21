class_name BodyFrame
extends RefCounted

## Calibrated coordinate system (01-body-frame-and-calibration.md §3):
## Origin = user's chest point C (in tracking space)
## +Z (spec) = horizontal direction user faces at calibration
## +Y (spec) = world up
## +X (spec) = right

var origin_spec: Vector3 = Vector3(0.0, 0.95, 0.0)
var yaw_spec_rad: float = 0.0 # clockwise yaw about +Y in spec space (0 = facing +Z in spec / -Z in Godot)

func _init(p_origin_spec: Vector3 = Vector3(0.0, 0.95, 0.0), p_yaw_spec_rad: float = 0.0) -> void:
	origin_spec = p_origin_spec
	yaw_spec_rad = p_yaw_spec_rad

static func rebuild_from_head_and_offset(
	head_pos_spec: Vector3,
	head_forward_spec: Vector3,
	chest_offset_from_head_spec: Vector3
) -> BodyFrame:
	var flat_fwd := Vector3(head_forward_spec.x, 0.0, head_forward_spec.z)
	var yaw_rad := 0.0
	if flat_fwd.length_squared() > 1e-6:
		flat_fwd = flat_fwd.normalized()
		yaw_rad = atan2(flat_fwd.x, flat_fwd.z)
	var bf := BodyFrame.new(Vector3.ZERO, yaw_rad)
	var rotated_offset := bf.rotate_local_to_world_spec(chest_offset_from_head_spec)
	bf.origin_spec = head_pos_spec + rotated_offset
	return bf

static func rebuild_from_godot_head(
	head_pos_godot: Vector3,
	head_basis_godot: Basis,
	chest_offset_from_head_spec: Vector3
) -> BodyFrame:
	var head_pos_spec := SpecSpace.to_spec(head_pos_godot)
	var head_fwd_godot := -head_basis_godot.z
	var head_fwd_spec := SpecSpace.to_spec(head_fwd_godot)
	return rebuild_from_head_and_offset(head_pos_spec, head_fwd_spec, chest_offset_from_head_spec)

func rotate_local_to_world_spec(local_spec: Vector3) -> Vector3:
	var c := cos(yaw_spec_rad)
	var s := sin(yaw_spec_rad)
	return Vector3(
		local_spec.x * c + local_spec.z * s,
		local_spec.y,
		-local_spec.x * s + local_spec.z * c
	)

func rotate_world_to_local_spec(vec_spec: Vector3) -> Vector3:
	var c := cos(-yaw_spec_rad)
	var s := sin(-yaw_spec_rad)
	return Vector3(
		vec_spec.x * c + vec_spec.z * s,
		vec_spec.y,
		-vec_spec.x * s + vec_spec.z * c
	)

func to_world_spec(local_spec: Vector3) -> Vector3:
	return origin_spec + rotate_local_to_world_spec(local_spec)

func to_local_spec(world_spec: Vector3) -> Vector3:
	return rotate_world_to_local_spec(world_spec - origin_spec)

func to_godot_world(local_spec: Vector3) -> Vector3:
	return SpecSpace.to_godot(to_world_spec(local_spec))

func from_godot_world(world_godot: Vector3) -> Vector3:
	return to_local_spec(SpecSpace.to_spec(world_godot))

func get_godot_yaw_rad() -> float:
	return -yaw_spec_rad
