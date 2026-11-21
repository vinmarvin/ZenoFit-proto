class_name SpecSpace
extends RefCounted

## Coordinate & yaw conversion between Spec Space and Godot Space (03-godot-build.md §3.1, Rule 13).
## - Spec space: +X right, +Y up, +Z forward (left-handed, clockwise yaw positive from above).
## - Godot space: +X right, +Y up, -Z forward (right-handed, counter-clockwise rotation.y positive from above).

static func to_godot(p_spec: Vector3) -> Vector3:
	return Vector3(p_spec.x, p_spec.y, -p_spec.z)

static func to_spec(p_godot: Vector3) -> Vector3:
	return Vector3(p_godot.x, p_godot.y, -p_godot.z)

## In the spec, positive yaw (degrees) means turning RIGHT (clockwise from above).
## In Godot, positive rotation around +Y is counter-clockwise from above (turning LEFT),
## so turning right by +psi_deg in spec corresponds to -psi_deg in Godot rotation.y.
static func yaw_deg_to_godot_deg(spec_yaw_deg: float) -> float:
	return -spec_yaw_deg

static func godot_deg_to_spec_yaw_deg(godot_yaw_deg: float) -> float:
	return -godot_yaw_deg

static func yaw_deg_to_godot_rad(spec_yaw_deg: float) -> float:
	return deg_to_rad(-spec_yaw_deg)

static func godot_rad_to_spec_yaw_deg(godot_yaw_rad: float) -> float:
	return -rad_to_deg(godot_yaw_rad)
