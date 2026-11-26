class_name CalibrationController
extends RefCounted

## Streamlined 3-step seated comfort calibration (<= 15 s) plus 1-tap Welcome recenter.
## Steps: 1. Seat Anchor -> 2. Comfort Reach (L & R) -> 3. Lap Zone.

var working_profile: ComfortProfile
var current_body_frame: BodyFrame
var seat_anchor_local_spec: Vector3 = Vector3(0.0, 0.25, -0.08)
var seated_height_m: float = 1.18
var current_step: int = ZenoEnums.CalibrationStep.SEAT_ANCHOR
var _reach_left_captured: bool = false

func _init(p_profile: ComfortProfile = null) -> void:
	working_profile = p_profile if p_profile != null else ComfortProfile.create_default()
	current_body_frame = BodyFrame.new()

func start_calibration() -> void:
	current_step = ZenoEnums.CalibrationStep.SEAT_ANCHOR
	_reach_left_captured = false

func quick_recenter_seat(head_pos_spec: Vector3, head_fwd_spec: Vector3) -> BodyFrame:
	seated_height_m = clampf(head_pos_spec.y, 0.70, 1.80)
	current_body_frame = BodyFrame.rebuild_from_head_and_offset(
		head_pos_spec,
		head_fwd_spec,
		working_profile.chest_offset_from_head_m
	)
	seat_anchor_local_spec = current_body_frame.to_local_spec(head_pos_spec)
	return current_body_frame

func get_step_index() -> int:
	match current_step:
		ZenoEnums.CalibrationStep.SEAT_ANCHOR: return 1
		ZenoEnums.CalibrationStep.COMFORT_REACH: return 2
		ZenoEnums.CalibrationStep.LAP_ZONE: return 3
		_: return 3

func get_step_title() -> String:
	match current_step:
		ZenoEnums.CalibrationStep.SEAT_ANCHOR:
			return "Seated Posture"
		ZenoEnums.CalibrationStep.COMFORT_REACH:
			return "Comfortable Reach (Left)" if not _reach_left_captured else "Comfortable Reach (Right)"
		ZenoEnums.CalibrationStep.LAP_ZONE:
			return "Rest & Lap Zone"
		_:
			return "Calibration Ready"

func get_step_instruction() -> String:
	match current_step:
		ZenoEnums.CalibrationStep.SEAT_ANCHOR:
			return "Sit naturally upright and look straight ahead, then confirm your seated height."
		ZenoEnums.CalibrationStep.COMFORT_REACH:
			if not _reach_left_captured:
				return "Extend your LEFT arm comfortably forward without straining, then confirm (or Skip for Right-Only)."
			return "Extend your RIGHT arm comfortably forward without straining, then confirm (or Skip for Left-Only)."
		ZenoEnums.CalibrationStep.LAP_ZONE:
			return "Rest both hands naturally in your lap and confirm. This enables gentle hands-down Auto-Pause."
		_:
			return "Your comfort reach envelope is ready."

func confirm_current_step(
	head_pos_spec: Vector3,
	head_fwd_spec: Vector3,
	left_hand_spec: Vector3,
	right_hand_spec: Vector3
) -> bool:
	match current_step:
		ZenoEnums.CalibrationStep.SEAT_ANCHOR:
			quick_recenter_seat(head_pos_spec, head_fwd_spec)
			_reach_left_captured = false
			current_step = ZenoEnums.CalibrationStep.COMFORT_REACH
			return false

		ZenoEnums.CalibrationStep.COMFORT_REACH:
			if not _reach_left_captured:
				var local_l := current_body_frame.to_local_spec(left_hand_spec)
				working_profile.left_enabled = true
				working_profile.left_reach_forward_m = clampf(maxf(0.35, local_l.z), 0.30, 0.85)
				var arm_l := local_l.distance_to(working_profile.left_shoulder_local_m)
				working_profile.left_arm_length_m = clampf(maxf(0.45, arm_l), 0.35, 0.85)
				_reach_left_captured = true
				return false
			else:
				var local_r := current_body_frame.to_local_spec(right_hand_spec)
				working_profile.right_enabled = true
				working_profile.right_reach_forward_m = clampf(maxf(0.35, local_r.z), 0.30, 0.85)
				var arm_r := local_r.distance_to(working_profile.right_shoulder_local_m)
				working_profile.right_arm_length_m = clampf(maxf(0.45, arm_r), 0.35, 0.85)
				current_step = ZenoEnums.CalibrationStep.LAP_ZONE
				return false

		ZenoEnums.CalibrationStep.LAP_ZONE:
			var mid_world := (left_hand_spec + right_hand_spec) * 0.5
			var lap_local := current_body_frame.to_local_spec(mid_world)
			if lap_local.y > -0.10:
				lap_local = Vector3(0.0, -0.45, 0.20)
			working_profile.lap_point_from_chest_m = lap_local
			current_step = ZenoEnums.CalibrationStep.COMPLETE
			return true

	return true

func skip_current_step() -> bool:
	match current_step:
		ZenoEnums.CalibrationStep.SEAT_ANCHOR:
			current_step = ZenoEnums.CalibrationStep.COMFORT_REACH
			_reach_left_captured = false
			return false
		ZenoEnums.CalibrationStep.COMFORT_REACH:
			if not _reach_left_captured:
				working_profile.left_enabled = false
				_reach_left_captured = true
				return false
			if working_profile.left_enabled:
				working_profile.right_enabled = false
			current_step = ZenoEnums.CalibrationStep.LAP_ZONE
			return false
		ZenoEnums.CalibrationStep.LAP_ZONE:
			working_profile.lap_point_from_chest_m = Vector3(0.0, -0.45, 0.20)
			current_step = ZenoEnums.CalibrationStep.COMPLETE
			return true
		_:
			return true

func mark_obstacle_point(hand_world_spec: Vector3) -> void:
	var obs_local := current_body_frame.to_local_spec(hand_world_spec)
	working_profile.obstacles.append(obs_local)
