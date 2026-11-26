class_name OrbitFlowMechanic
extends MechanicBase

## Orbit Flow (Smooth Shoulder Circles — Signed-Angle Anti-Cheat + Cadence Guide).
## Replaces untrackable Shoulder Rolls with full-shoulder circular arm motion.

const RING_LEFT_COL := Color(0.32, 0.85, 0.72)
const RING_RIGHT_COL := Color(0.95, 0.68, 0.28)
const SPARK_COL := Color(0.92, 0.98, 0.88)

var _left_ring: Node3D = null
var _right_ring: Node3D = null
var _left_spark: Node3D = null
var _right_spark: Node3D = null
var _center_l_spec: Vector3 = Vector3(-0.22, 0.04, 0.40)
var _center_r_spec: Vector3 = Vector3(0.22, 0.04, 0.40)

var _clockwise: bool = true
var _dir_timer_s: float = 0.0
var _guide_phase: float = 0.0
var _has_prev_l: bool = false
var _has_prev_r: bool = false
var _prev_ang_l: float = 0.0
var _prev_ang_r: float = 0.0
var _signed_progress_rad: float = 0.0
var _loop_elapsed_s: float = 0.0

func _on_start() -> void:
	_clockwise = true
	_dir_timer_s = 0.0
	_guide_phase = 0.0
	_has_prev_l = false
	_has_prev_r = false
	_signed_progress_rad = 0.0
	_loop_elapsed_s = 0.0

	var r := preset.orbit_radius_m
	if hand_mode != ZenoEnums.HandMode.RIGHT_ONLY:
		_left_ring = create_glow_ring(r, 0.016, RING_LEFT_COL, 0.75)
		_set_node_world_pos(_left_ring, _center_l_spec)
		_left_spark = create_glow_orb(0.028, SPARK_COL, 0.95)
	if hand_mode != ZenoEnums.HandMode.LEFT_ONLY:
		_right_ring = create_glow_ring(r, 0.016, RING_RIGHT_COL, 0.75)
		_set_node_world_pos(_right_ring, _center_r_spec)
		_right_spark = create_glow_orb(0.028, SPARK_COL, 0.95)
	status_hint = ZenoEnums.get_exercise_cue(exercise_id)

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
	_left_roll_deg: float,
	_right_roll_deg: float
) -> void:
	_dir_timer_s += dt
	_loop_elapsed_s += dt
	if _dir_timer_s >= 10.0:
		_dir_timer_s = 0.0
		_clockwise = not _clockwise
		_signed_progress_rad = 0.0
		status_hint = "Switch direction — circle smoothly %s" % ("forward" if _clockwise else "backward")

	var dir_sign := 1.0 if _clockwise else -1.0
	_guide_phase += dt * preset.orbit_cadence_hz * TAU * dir_sign
	var r := preset.orbit_radius_m
	if _left_spark != null:
		_set_node_world_pos(_left_spark, _center_l_spec + Vector3(0.0, r * sin(_guide_phase), r * cos(_guide_phase) * 0.45))
	if _right_spark != null:
		_set_node_world_pos(_right_spark, _center_r_spec + Vector3(0.0, r * sin(_guide_phase), r * cos(_guide_phase) * 0.45))

	var min_r := maxf(0.10, r * 0.55)
	var step_delta := 0.0

	if hand_mode == ZenoEnums.HandMode.LEFT_ONLY:
		step_delta = _step_hand_orbit(curr_left_local_spec, _center_l_spec, dir_sign, min_r, true)
	elif hand_mode == ZenoEnums.HandMode.RIGHT_ONLY:
		step_delta = _step_hand_orbit(curr_right_local_spec, _center_r_spec, dir_sign, min_r, false)
	else:
		var dl := _step_hand_orbit(curr_left_local_spec, _center_l_spec, dir_sign, min_r, true)
		var dr := _step_hand_orbit(curr_right_local_spec, _center_r_spec, dir_sign, min_r, false)
		step_delta = (dl + dr) * 0.5

	_signed_progress_rad = maxf(0.0, _signed_progress_rad + step_delta)
	if _signed_progress_rad >= TAU:
		_signed_progress_rad -= TAU
		_complete_circle()

func _step_hand_orbit(hand_spec: Vector3, center_spec: Vector3, dir_sign: float, min_r: float, is_left: bool) -> float:
	var hand_xy := Vector2(hand_spec.x, hand_spec.y)
	var center_xy := Vector2(center_spec.x, center_spec.y)
	var ang := atan2(hand_xy.y - center_xy.y, hand_xy.x - center_xy.x)
	var has_prev := _has_prev_l if is_left else _has_prev_r
	var prev_ang := _prev_ang_l if is_left else _prev_ang_r
	if is_left:
		_prev_ang_l = ang
		_has_prev_l = true
	else:
		_prev_ang_r = ang
		_has_prev_r = true
	if not has_prev:
		return 0.0
	var eval := MechanicsMath.orbit_flow_evaluate_signed(prev_ang, ang, hand_xy, center_xy, dir_sign, min_r)
	return float(eval["effective_delta_rad"])

func _complete_circle() -> void:
	var measured_hz := 1.0 / maxf(0.25, _loop_elapsed_s)
	var cad := MechanicsMath.orbit_flow_cadence(measured_hz, preset.orbit_cadence_hz, preset.orbit_radius_m, 0.30)
	var in_band := bool(cad["in_band"])
	var res := _record_direct_hit_and_notify(ZenoEnums.Hand.RIGHT, 130 if in_band else 100, in_band)
	_play_haptic("play_haptic_light_touch", ZenoEnums.Hand.LEFT)
	_play_haptic("play_haptic_light_touch", ZenoEnums.Hand.RIGHT)
	status_hint = "Smooth circle! +%d" % int(res["combo_points"])
	_loop_elapsed_s = 0.0

func simulate_auto_action() -> void:
	_loop_elapsed_s = 1.0 / maxf(0.1, preset.orbit_cadence_hz)
	_complete_circle()
