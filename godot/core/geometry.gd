class_name ZenoGeometry
extends RefCounted

## Anti-tunnelling segment-to-sphere hit detection (02-targets-and-hit-detection.md §6.C, AT-13).

const DEFAULT_HAND_TIP_RADIUS_M: float = 0.04

static func closest_point_on_segment(point: Vector3, seg_a: Vector3, seg_b: Vector3) -> Vector3:
	return Geometry3D.get_closest_point_to_segment(point, seg_a, seg_b)

static func segment_hit(
	p0: Vector3,
	p1: Vector3,
	centre: Vector3,
	target_radius_m: float,
	hand_tip_radius_m: float = DEFAULT_HAND_TIP_RADIUS_M
) -> bool:
	var closest := Geometry3D.get_closest_point_to_segment(centre, p0, p1)
	return closest.distance_to(centre) <= (target_radius_m + hand_tip_radius_m)

static func check_valid_hand_hit(
	candidate_hand: int,
	is_candidate_hand_enabled: bool,
	effective_hand_mode: int,
	required_target_hand: int,
	target_centre: Vector3,
	target_radius_m: float,
	prev_hand_tip_pos: Vector3,
	curr_hand_tip_pos: Vector3,
	hand_tip_radius_m: float = DEFAULT_HAND_TIP_RADIUS_M
) -> bool:
	if not is_candidate_hand_enabled:
		return false

	if effective_hand_mode == ZenoEnums.HandMode.LEFT_ONLY and candidate_hand != ZenoEnums.Hand.LEFT:
		return false
	if effective_hand_mode == ZenoEnums.HandMode.RIGHT_ONLY and candidate_hand != ZenoEnums.Hand.RIGHT:
		return false

	if required_target_hand == ZenoEnums.TargetHand.LEFT and candidate_hand != ZenoEnums.Hand.LEFT:
		return false
	if required_target_hand == ZenoEnums.TargetHand.RIGHT and candidate_hand != ZenoEnums.Hand.RIGHT:
		return false

	return segment_hit(prev_hand_tip_pos, curr_hand_tip_pos, target_centre, target_radius_m, hand_tip_radius_m)
