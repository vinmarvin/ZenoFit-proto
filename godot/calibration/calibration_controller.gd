class_name CalibrationController
extends RefCounted

## Implements 8-step seated calibration (01-body-frame-and-calibration.md §4.2 + CHAIR_CHECK),
## returning-user quick seat check (GP-CAL-11, <= 10s),
## and on-demand Level B module calibrations (Twist, Neck, Lean, §4.7).

var working_profile: ComfortProfile
var current_body_frame: BodyFrame
var seat_anchor_local_spec: Vector3 = Vector3(0.0, 0.25, -0.08)
var current_step: int = ZenoEnums.CalibrationStep.SEAT_ANCHOR
var is_quick_check_only: bool = false
var is_swivel_chair: bool = false
var _left_shoulder_captured: bool = false
var _module_left_captured: bool = false

func _init(p_profile: ComfortProfile = null) -> void:
	working_profile = p_profile if p_profile != null else ComfortProfile.create_default()
	current_body_frame = BodyFrame.new()

func start_full_calibration() -> void:
	is_quick_check_only = false
	current_step = ZenoEnums.CalibrationStep.SEAT_ANCHOR
	_left_shoulder_captured = false
	_module_left_captured = false

func start_returning_user_quick_check() -> void:
	# GP-CAL-11: Returning user only confirms seated pose (steps 1-2) in <= 10s
	is_quick_check_only = true
	current_step = ZenoEnums.CalibrationStep.SEAT_ANCHOR

func confirm_chair_type(swivel_chair: bool) -> bool:
	is_swivel_chair = swivel_chair
	if current_step == ZenoEnums.CalibrationStep.CHAIR_CHECK:
		current_step = ZenoEnums.CalibrationStep.CHEST_POINT
	return false

func start_module_calibration(module_step: int) -> void:
	is_quick_check_only = false
	current_step = module_step
	_module_left_captured = false

func get_step_instruction() -> String:
	match current_step:
		ZenoEnums.CalibrationStep.SEAT_ANCHOR:
			if is_quick_check_only:
				return "Quick Seat Check (<= 10 s): Sit comfortably looking straight ahead and confirm."
			return "Step 1/8: Sit comfortably and look straight forward. Press Pinch / Trigger / Space to confirm."
		ZenoEnums.CalibrationStep.CHAIR_CHECK:
			return "Step 2/8: Chair Safety Check — Is this a STABLE non-rolling chair? Confirm Stable, or press Skip if Swivel/Rolling (locks Level B safely)."
		ZenoEnums.CalibrationStep.CHEST_POINT:
			return "Step 3/8: Touch your chest (sternum) with a hand and confirm (or Skip for default)."
		ZenoEnums.CalibrationStep.SHOULDERS:
			return "Step 4/8: Touch your LEFT shoulder and confirm, then RIGHT shoulder (or Skip for 0.40 m)."
		ZenoEnums.CalibrationStep.LEFT_REACH:
			return "Step 5/8: Reach forward with your LEFT hand as far as comfortable (no pain) and confirm (Skip disables Left hand)."
		ZenoEnums.CalibrationStep.RIGHT_REACH:
			return "Step 6/8: Reach forward with your RIGHT hand as far as comfortable (no pain) and confirm (Skip disables Right hand)."
		ZenoEnums.CalibrationStep.LAP_POINT:
			return "Step 7/8: Rest both hands in your lap and confirm (used for 2 s safety Auto-Pause)."
		ZenoEnums.CalibrationStep.OBSTACLES:
			return "Step 8/8: Touch desk edge / keyboard / armrests to mark obstacles, or click Finish Calibration."
		ZenoEnums.CalibrationStep.MODULE_TWIST:
			if not _module_left_captured:
				return "Twist Module (1/2): Hold controllers near chest, turn torso LEFT comfortably, and confirm."
			else:
				return "Twist Module (2/2): Now turn torso RIGHT comfortably and confirm."
		ZenoEnums.CalibrationStep.MODULE_NECK:
			if not _module_left_captured:
				return "Neck Module (1/2): Turn head LEFT as far as comfortable and confirm."
			else:
				return "Neck Module (2/2): Turn head RIGHT as far as comfortable and confirm."
		ZenoEnums.CalibrationStep.MODULE_LEAN:
			if not _module_left_captured:
				return "Lean Module (1/2): Hold overhead rail, lean torso LEFT comfortably, and confirm."
			else:
				return "Lean Module (2/2): Hold overhead rail, lean torso RIGHT comfortably, and confirm."
		_:
			return "Calibration complete! Stop at any time if anything hurts."

func confirm_current_step(
	head_pos_spec: Vector3,
	head_fwd_spec: Vector3,
	left_hand_spec: Vector3,
	right_hand_spec: Vector3
) -> bool:
	match current_step:
		ZenoEnums.CalibrationStep.SEAT_ANCHOR:
			current_body_frame = BodyFrame.rebuild_from_head_and_offset(
				head_pos_spec,
				head_fwd_spec,
				working_profile.chest_offset_from_head_m
			)
			seat_anchor_local_spec = current_body_frame.to_local_spec(head_pos_spec)
			if is_quick_check_only:
				current_step = ZenoEnums.CalibrationStep.COMPLETE
				return true
			current_step = ZenoEnums.CalibrationStep.CHAIR_CHECK
			return false

		ZenoEnums.CalibrationStep.CHAIR_CHECK:
			is_swivel_chair = false
			current_step = ZenoEnums.CalibrationStep.CHEST_POINT
			return false

		ZenoEnums.CalibrationStep.CHEST_POINT:
			var chest_world := right_hand_spec
			var offset := chest_world - head_pos_spec
			if offset.length() > 0.05 and offset.length() < 0.65:
				working_profile.chest_offset_from_head_m = current_body_frame.rotate_world_to_local_spec(offset)
			else:
				working_profile.chest_offset_from_head_m = Vector3(0.0, -ComfortProfile.DEFAULT_CHEST_OFFSET_BELOW_HEAD_M, 0.08)
			current_body_frame = BodyFrame.rebuild_from_head_and_offset(
				head_pos_spec,
				head_fwd_spec,
				working_profile.chest_offset_from_head_m
			)
			seat_anchor_local_spec = current_body_frame.to_local_spec(head_pos_spec)
			current_step = ZenoEnums.CalibrationStep.SHOULDERS
			_left_shoulder_captured = false
			return false

		ZenoEnums.CalibrationStep.SHOULDERS:
			if not _left_shoulder_captured:
				working_profile.left_shoulder_local_m = current_body_frame.to_local_spec(left_hand_spec)
				_left_shoulder_captured = true
				return false
			else:
				working_profile.right_shoulder_local_m = current_body_frame.to_local_spec(right_hand_spec)
				var w := working_profile.right_shoulder_local_m.distance_to(working_profile.left_shoulder_local_m)
				working_profile.shoulder_width_m = clampf(w, 0.28, 0.60)
				working_profile.update_shoulder_positions_from_width()
				current_step = ZenoEnums.CalibrationStep.LEFT_REACH
				return false

		ZenoEnums.CalibrationStep.LEFT_REACH:
			var local_l := current_body_frame.to_local_spec(left_hand_spec)
			working_profile.left_enabled = true
			working_profile.left_reach_forward_m = clampf(maxf(0.35, local_l.z), 0.30, 0.85)
			var arm_l := local_l.distance_to(working_profile.left_shoulder_local_m)
			working_profile.left_arm_length_m = clampf(maxf(0.45, arm_l), 0.35, 0.85)
			current_step = ZenoEnums.CalibrationStep.RIGHT_REACH
			return false

		ZenoEnums.CalibrationStep.RIGHT_REACH:
			var local_r := current_body_frame.to_local_spec(right_hand_spec)
			working_profile.right_enabled = true
			working_profile.right_reach_forward_m = clampf(maxf(0.35, local_r.z), 0.30, 0.85)
			var arm_r := local_r.distance_to(working_profile.right_shoulder_local_m)
			working_profile.right_arm_length_m = clampf(maxf(0.45, arm_r), 0.35, 0.85)
			current_step = ZenoEnums.CalibrationStep.LAP_POINT
			return false

		ZenoEnums.CalibrationStep.LAP_POINT:
			var mid_world := (left_hand_spec + right_hand_spec) * 0.5
			var lap_local := current_body_frame.to_local_spec(mid_world)
			if lap_local.y > -0.10:
				lap_local = Vector3(0.0, -0.45, 0.20)
			working_profile.lap_point_from_chest_m = lap_local
			current_step = ZenoEnums.CalibrationStep.OBSTACLES
			return false

		ZenoEnums.CalibrationStep.OBSTACLES:
			current_step = ZenoEnums.CalibrationStep.COMPLETE
			return true

		ZenoEnums.CalibrationStep.MODULE_TWIST:
			var mid_local := current_body_frame.to_local_spec((left_hand_spec + right_hand_spec) * 0.5)
			var yaw_deg := absf(MechanicsMath.m04_compute_aim_yaw_deg(mid_local))
			if yaw_deg < 15.0:
				yaw_deg = 45.0
			if not _module_left_captured:
				working_profile.twist_deg_l = clampf(yaw_deg, 15.0, 60.0)
				_module_left_captured = true
				return false
			else:
				working_profile.twist_deg_r = clampf(yaw_deg, 15.0, 60.0)
				working_profile.twist_calibrated = true
				current_step = ZenoEnums.CalibrationStep.COMPLETE
				return true

		ZenoEnums.CalibrationStep.MODULE_NECK:
			var local_fwd := current_body_frame.rotate_world_to_local_spec(head_fwd_spec)
			var neck_yaw_deg := absf(rad_to_deg(atan2(local_fwd.x, maxf(0.01, local_fwd.z))))
			if neck_yaw_deg < 20.0:
				neck_yaw_deg = 65.0
			if not _module_left_captured:
				working_profile.neck_deg_l = clampf(neck_yaw_deg, 20.0, 80.0)
				_module_left_captured = true
				return false
			else:
				working_profile.neck_deg_r = clampf(neck_yaw_deg, 20.0, 80.0)
				working_profile.neck_calibrated = true
				current_step = ZenoEnums.CalibrationStep.COMPLETE
				return true

		ZenoEnums.CalibrationStep.MODULE_LEAN:
			var head_local := current_body_frame.to_local_spec(head_pos_spec)
			var dx := absf(head_local.x - seat_anchor_local_spec.x)
			if dx < 0.08:
				dx = 0.24
			if not _module_left_captured:
				working_profile.lean_m_l = clampf(dx, 0.10, 0.30)
				_module_left_captured = true
				return false
			else:
				working_profile.lean_m_r = clampf(dx, 0.10, 0.30)
				working_profile.lean_calibrated = true
				current_step = ZenoEnums.CalibrationStep.COMPLETE
				return true

	return true

func mark_obstacle_point(hand_world_spec: Vector3) -> void:
	var obs_local := current_body_frame.to_local_spec(hand_world_spec)
	working_profile.obstacles.append(obs_local)

func skip_current_step() -> bool:
	match current_step:
		ZenoEnums.CalibrationStep.CHAIR_CHECK:
			is_swivel_chair = true
			current_step = ZenoEnums.CalibrationStep.CHEST_POINT
			return false
		ZenoEnums.CalibrationStep.CHEST_POINT:
			working_profile.chest_offset_from_head_m = Vector3(0.0, -ComfortProfile.DEFAULT_CHEST_OFFSET_BELOW_HEAD_M, 0.08)
			current_step = ZenoEnums.CalibrationStep.SHOULDERS
			return false
		ZenoEnums.CalibrationStep.SHOULDERS:
			working_profile.shoulder_width_m = ComfortProfile.DEFAULT_SHOULDER_WIDTH_M
			working_profile.update_shoulder_positions_from_width()
			current_step = ZenoEnums.CalibrationStep.LEFT_REACH
			return false
		ZenoEnums.CalibrationStep.LEFT_REACH:
			# GP-CAL-03: Skipping a hand disables that hand and forces one-hand mode
			working_profile.left_enabled = false
			current_step = ZenoEnums.CalibrationStep.RIGHT_REACH
			return false
		ZenoEnums.CalibrationStep.RIGHT_REACH:
			if working_profile.left_enabled:
				working_profile.right_enabled = false
			current_step = ZenoEnums.CalibrationStep.LAP_POINT
			return false
		ZenoEnums.CalibrationStep.OBSTACLES:
			current_step = ZenoEnums.CalibrationStep.COMPLETE
			return true
		_:
			return false
