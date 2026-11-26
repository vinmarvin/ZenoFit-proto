class_name WristTwistMechanic
extends MechanicBase

## Wrist Twist (Anti-RSI Forearm Steady + Controlled Wrist Rotation).
## Displays glowing dual dials tracking controller wrist roll to ±target_deg.

const DIAL_LEFT_COL := Color(0.32, 0.85, 0.72)
const DIAL_RIGHT_COL := Color(0.95, 0.68, 0.28)

var _left_dial: Dictionary = {}
var _right_dial: Dictionary = {}
var _anchor_l: Vector3 = Vector3(-0.22, -0.02, 0.42)
var _anchor_r: Vector3 = Vector3(0.22, -0.02, 0.42)
var _target_sign: float = 1.0
var _hold_s: float = 0.0
var _elapsed_s: float = 0.0

func _on_start() -> void:
	_target_sign = 1.0
	_hold_s = 0.0
	_elapsed_s = 0.0
	if hand_mode != ZenoEnums.HandMode.RIGHT_ONLY:
		_left_dial = create_dial_prop(0.13, DIAL_LEFT_COL)
		_set_node_world_pos(_left_dial["root"] as Node3D, _anchor_l)
	if hand_mode != ZenoEnums.HandMode.LEFT_ONLY:
		_right_dial = create_dial_prop(0.13, DIAL_RIGHT_COL)
		_set_node_world_pos(_right_dial["root"] as Node3D, _anchor_r)
	_update_target_markers()
	status_hint = ZenoEnums.get_exercise_cue(exercise_id)

func _update_target_markers() -> void:
	var target_deg := _target_sign * preset.wrist_target_deg
	if not _left_dial.is_empty():
		(_left_dial["target"] as Node3D).rotation.z = deg_to_rad(-target_deg)
	if not _right_dial.is_empty():
		(_right_dial["target"] as Node3D).rotation.z = deg_to_rad(-target_deg)

func update_mechanic(
	dt: float,
	_head_local_spec: Vector3,
	_head_fwd_local_spec: Vector3,
	_head_speed_deg_s: float,
	_prev_left_local_spec: Vector3,
	curr_left_local_spec: Vector3,
	_left_speed_mps: float,
	_prev_right_local_spec: Vector3,
	curr_right_local_spec: Vector3,
	_right_speed_mps: float,
	left_roll_deg: float,
	right_roll_deg: float
) -> void:
	_elapsed_s += dt
	var target_deg := _target_sign * preset.wrist_target_deg

	if not _left_dial.is_empty():
		(_left_dial["needle"] as Node3D).rotation.z = deg_to_rad(-left_roll_deg)
	if not _right_dial.is_empty():
		(_right_dial["needle"] as Node3D).rotation.z = deg_to_rad(-right_roll_deg)

	var l_eval := MechanicsMath.wrist_twist_evaluate(curr_left_local_spec, _anchor_l, left_roll_deg, target_deg)
	var r_eval := MechanicsMath.wrist_twist_evaluate(curr_right_local_spec, _anchor_r, right_roll_deg, target_deg)

	var in_zone := true
	var angle_ok := true
	if hand_mode == ZenoEnums.HandMode.LEFT_ONLY:
		in_zone = bool(l_eval["in_zone"])
		angle_ok = bool(l_eval["angle_reached"])
	elif hand_mode == ZenoEnums.HandMode.RIGHT_ONLY:
		in_zone = bool(r_eval["in_zone"])
		angle_ok = bool(r_eval["angle_reached"])
	else:
		in_zone = bool(l_eval["in_zone"]) and bool(r_eval["in_zone"])
		angle_ok = bool(l_eval["angle_reached"]) and bool(r_eval["angle_reached"])

	if not in_zone:
		_hold_s = maxf(0.0, _hold_s - dt * 0.5)
		status_hint = "Keep forearms steady inside the dials"
		return

	if angle_ok:
		_hold_s += dt
		status_hint = "Hold steady... %.0f%%" % clampf(_hold_s / 0.30 * 100.0, 0.0, 100.0)
		if _hold_s >= 0.30:
			_complete_twist()
	else:
		_hold_s = maxf(0.0, _hold_s - dt * 0.5)
		status_hint = "Rotate wrists %s to the gold marker" % ("clockwise" if _target_sign > 0.0 else "counter-clockwise")

func _complete_twist() -> void:
	var res := _record_hit_and_notify(ZenoEnums.Hand.RIGHT, _elapsed_s, 3.0, false)
	if hand_mode != ZenoEnums.HandMode.RIGHT_ONLY:
		_play_haptic("play_haptic_light_touch", ZenoEnums.Hand.LEFT)
	if hand_mode != ZenoEnums.HandMode.LEFT_ONLY:
		_play_haptic("play_haptic_light_touch", ZenoEnums.Hand.RIGHT)
	status_hint = "Clean wrist rotation! +%d" % int(res["combo_points"])
	_target_sign *= -1.0
	_hold_s = 0.0
	_elapsed_s = 0.0
	_update_target_markers()

func simulate_auto_action() -> void:
	_elapsed_s = 0.5
	_complete_twist()
