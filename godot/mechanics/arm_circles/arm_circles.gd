class_name ArmCirclesMechanic
extends TwoSetTensionMechanic

## Arm Circles (Shoulders — Two-Set Clockwise & Counterclockwise + Mechanical Tension Ring).
## Set 1: Clockwise rotation along the circular tension ring & checkpoint targets.
## Set 2: Counterclockwise rotation along the circular tension ring & checkpoint targets.

const COL_LEFT_ORB := Color(0.32, 0.85, 0.72)
const COL_RIGHT_ORB := Color(0.95, 0.68, 0.28)
const CHECKPOINTS_PER_CIRCLE: int = 4

var _center_l_spec: Vector3 = Vector3(-0.22, 0.06, 0.36)
var _center_r_spec: Vector3 = Vector3(0.22, 0.06, 0.36)
var _radius_m: float = 0.17

var _left_target_orb: Node3D = null
var _right_target_orb: Node3D = null
var _checkpoint_idx: int = 0
var _left_ckpt_hit: bool = false
var _right_ckpt_hit: bool = false

var _has_prev_l: bool = false
var _has_prev_r: bool = false
var _prev_ang_l: float = 0.0
var _prev_ang_r: float = 0.0
var _circle_elapsed_s: float = 0.0

func _get_set_direction_label(set_num: int) -> String:
	return "Clockwise" if set_num == 1 else "Counterclockwise"

func _on_start() -> void:
	_reset_two_set_state()
	_has_prev_l = false
	_has_prev_r = false
	_checkpoint_idx = 0
	_circle_elapsed_s = 0.0

	var k := clampf(preset.reach_factor_k, 0.35, ComfortProfile.MAX_REACH_FACTOR_K)
	var sl := profile.get_shoulder_local(ZenoEnums.Hand.LEFT)
	var sr := profile.get_shoulder_local(ZenoEnums.Hand.RIGHT)
	var side_offset := clampf(minf(profile.left_arm_length_m, profile.right_arm_length_m) * k * 0.48, 0.26, 0.36)
	_center_l_spec = Vector3(sl.x - side_offset, clampf(sl.y, 0.0, 0.16), 0.26)
	_center_r_spec = Vector3(sr.x + side_offset, clampf(sr.y, 0.0, 0.16), 0.26)
	_radius_m = clampf(minf(profile.left_arm_length_m, profile.right_arm_length_m) * k * 0.30, 0.14, 0.20)

	var tol := _get_tension_tolerance_m()
	if _uses_left_hand():
		_left_tension_guide = MechanicalTensionGuide.new()
		_left_tension_guide.setup_circle(arena_root, body_frame, _center_l_spec, _radius_m, tol, "yz")
		_left_target_orb = create_glow_orb(0.055, COL_LEFT_ORB, 0.92)
	if _uses_right_hand():
		_right_tension_guide = MechanicalTensionGuide.new()
		_right_tension_guide.setup_circle(arena_root, body_frame, _center_r_spec, _radius_m, tol, "yz")
		_right_target_orb = create_glow_orb(0.055, COL_RIGHT_ORB, 0.92)

	_place_checkpoint_targets()
	status_hint = "Set 1: Extend arms to the sides and circle clockwise"

func _on_set_changed(new_set: int) -> void:
	_checkpoint_idx = 0
	_circle_elapsed_s = 0.0
	_has_prev_l = false
	_has_prev_r = false
	_place_checkpoint_targets()
	status_hint = "Set %d: Circle %s along the tension ring" % [new_set, _get_set_direction_label(new_set)]

func _get_checkpoint_pos(center_spec: Vector3, idx: int) -> Vector3:
	# Side Y-Z plane: Clockwise (Set 1) moves forward-down-back-up; Counterclockwise (Set 2) reverses
	var dir_sign := -1.0 if current_set == 1 else 1.0
	var ang := (PI * 0.5) + dir_sign * float(idx) * (TAU / float(CHECKPOINTS_PER_CIRCLE))
	return center_spec + Vector3(0.0, sin(ang) * _radius_m, cos(ang) * _radius_m)

func _place_checkpoint_targets() -> void:
	_left_ckpt_hit = false
	_right_ckpt_hit = false
	if _left_target_orb != null:
		_left_target_orb.visible = true
		_set_node_world_pos(_left_target_orb, _get_checkpoint_pos(_center_l_spec, _checkpoint_idx))
	if _right_target_orb != null:
		_right_target_orb.visible = true
		_set_node_world_pos(_right_target_orb, _get_checkpoint_pos(_center_r_spec, _checkpoint_idx))

func update_mechanic(
	dt: float,
	_head_local_spec: Vector3,
	_head_fwd_local_spec: Vector3,
	_head_speed_deg_s: float,
	prev_left_local_spec: Vector3,
	curr_left_local_spec: Vector3,
	_left_speed_mps: float,
	prev_right_local_spec: Vector3,
	curr_right_local_spec: Vector3,
	_right_speed_mps: float,
	_left_roll_deg: float,
	_right_roll_deg: float
) -> void:
	if _completed:
		return
	if _step_transition(dt):
		return

	_circle_elapsed_s += dt
	var tol := _get_tension_tolerance_m()
	var dir_sign := -1.0 if current_set == 1 else 1.0
	var reverse_flow := (current_set == 1)
	var hit_r := get_effective_hit_radius(preset.target_radius_m + 0.03)

	var left_in_zone := true
	var right_in_zone := true
	var dir_ok := true

	if _uses_left_hand() and _left_tension_guide != null:
		var eval_l := _left_tension_guide.evaluate_hand(curr_left_local_spec, tol)
		left_in_zone = bool(eval_l["in_zone"])
		_left_tension_guide.update_visual_feedback(dt, left_in_zone, reverse_flow, true)
		if not _check_signed_direction(curr_left_local_spec, _center_l_spec, dir_sign, true):
			dir_ok = false

	if _uses_right_hand() and _right_tension_guide != null:
		var eval_r := _right_tension_guide.evaluate_hand(curr_right_local_spec, tol)
		right_in_zone = bool(eval_r["in_zone"])
		_right_tension_guide.update_visual_feedback(dt, right_in_zone, reverse_flow, true)
		if not _check_signed_direction(curr_right_local_spec, _center_r_spec, dir_sign, false):
			dir_ok = false

	var both_in_zone := left_in_zone and right_in_zone
	_record_tension_sample(both_in_zone)

	if _uses_left_hand() and not _left_ckpt_hit:
		var ckpt_l := _get_checkpoint_pos(_center_l_spec, _checkpoint_idx)
		if ZenoGeometry.segment_hit(prev_left_local_spec, curr_left_local_spec, ckpt_l, hit_r):
			_left_ckpt_hit = true
			if _left_target_orb != null:
				_left_target_orb.visible = false
			spawn_hit_vfx(ckpt_l, Color(1.0, 0.84, 0.32))

	if _uses_right_hand() and not _right_ckpt_hit:
		var ckpt_r := _get_checkpoint_pos(_center_r_spec, _checkpoint_idx)
		if ZenoGeometry.segment_hit(prev_right_local_spec, curr_right_local_spec, ckpt_r, hit_r):
			_right_ckpt_hit = true
			if _right_target_orb != null:
				_right_target_orb.visible = false
			spawn_hit_vfx(ckpt_r, Color(1.0, 0.84, 0.32))

	if not both_in_zone:
		status_hint = "Stay on the circular tension ring!"
	elif not dir_ok:
		status_hint = "Follow the %s flow direction!" % _get_set_direction_label(current_set)
	else:
		status_hint = "Set %d: Circle %s (%d/%d)" % [current_set, _get_set_direction_label(current_set), reps_in_set, REPS_PER_SET]

	if (_left_ckpt_hit or not _uses_left_hand()) and (_right_ckpt_hit or not _uses_right_hand()):
		_checkpoint_idx += 1
		if _checkpoint_idx >= CHECKPOINTS_PER_CIRCLE:
			_checkpoint_idx = 0
			var used_hand := ZenoEnums.Hand.LEFT if hand_mode == ZenoEnums.HandMode.LEFT_ONLY else ZenoEnums.Hand.RIGHT
			_complete_rep(used_hand, _circle_elapsed_s, _get_set_direction_label(current_set))
			_circle_elapsed_s = 0.0
			if not _completed and not _in_set_transition:
				_place_checkpoint_targets()
			else:
				if _left_target_orb != null:
					_left_target_orb.visible = false
				if _right_target_orb != null:
					_right_target_orb.visible = false
		else:
			_play_haptic("play_haptic_light_touch", ZenoEnums.Hand.RIGHT)
			_place_checkpoint_targets()

func _check_signed_direction(hand_spec: Vector3, center_spec: Vector3, dir_sign: float, is_left: bool) -> bool:
	var hand_yz := Vector2(hand_spec.z, hand_spec.y)
	var center_yz := Vector2(center_spec.z, center_spec.y)
	var ang := atan2(hand_yz.y - center_yz.y, hand_yz.x - center_yz.x)
	var has_prev := _has_prev_l if is_left else _has_prev_r
	var prev_ang := _prev_ang_l if is_left else _prev_ang_r
	if is_left:
		_prev_ang_l = ang
		_has_prev_l = true
	else:
		_prev_ang_r = ang
		_has_prev_r = true
	if not has_prev:
		return true
	var eval := MechanicsMath.orbit_flow_evaluate_signed(prev_ang, ang, hand_yz, center_yz, dir_sign, _radius_m * 0.45)
	return float(eval["signed_delta_rad"]) >= -0.06

func simulate_auto_action() -> void:
	if _completed:
		return
	if _in_set_transition:
		_transition_timer_s = 0.0
		_step_transition(0.02)
		return
	_record_tension_sample(true)
	_complete_rep(ZenoEnums.Hand.RIGHT, 1.0, _get_set_direction_label(current_set))
	if not _completed and not _in_set_transition:
		_place_checkpoint_targets()

func clear_arena() -> void:
	if _left_target_orb != null:
		_retire_node(_left_target_orb)
		_left_target_orb = null
	if _right_target_orb != null:
		_retire_node(_right_target_orb)
		_right_target_orb = null
	super.clear_arena()

