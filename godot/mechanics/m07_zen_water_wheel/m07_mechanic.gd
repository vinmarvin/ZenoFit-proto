class_name M07ZenWaterWheel
extends MechanicBase

## §6.7 Arm Circles ("Zen Water Wheel") [P0, Level A, AT-22, AT-34].

var _left_wheel_node: Node3D = null
var _right_wheel_node: Node3D = null
var _wheel_energy: float = 50.0
var _direction_timer_s: float = 0.0
var _clockwise: bool = true
var _prev_angle_rad: float = 0.0
var _has_prev_angle: bool = false
var _signed_progress_rad: float = 0.0
var _in_band_accum_s: float = 0.0
var _full_bonus_awarded: bool = false

func _on_start() -> void:
	_wheel_energy = 50.0
	_direction_timer_s = 0.0
	_clockwise = true
	_has_prev_angle = false
	_signed_progress_rad = 0.0
	_in_band_accum_s = 0.0
	_full_bonus_awarded = false
	_left_wheel_node = create_dojo_ring(preset.m07_circle_radius_m, 0.025, Color(0.28, 0.78, 0.85), "L Water Wheel")
	_right_wheel_node = create_dojo_ring(preset.m07_circle_radius_m, 0.025, Color(0.92, 0.65, 0.25), "R Water Wheel")
	_left_wheel_node.global_position = body_frame.to_godot_world(Vector3(-0.22, 0.05, 0.40))
	_right_wheel_node.global_position = body_frame.to_godot_world(Vector3(0.22, 0.05, 0.40))
	status_hint = "Turn hands in steady circles (r=%.2f m, f=%.2f Hz) to spin the Zen Water Wheel!" % [preset.m07_circle_radius_m, preset.m07_cadence_hz]

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
	_direction_timer_s += dt
	if _direction_timer_s >= 10.0:
		_direction_timer_s -= 10.0
		_clockwise = not _clockwise
		_signed_progress_rad = 0.0
		status_hint = "Reverse wheel direction: %s!" % ("FORWARD / CW" if _clockwise else "REVERSE / CCW")

	var active_hand := pick_hand_for_spawn(1)
	var hand_pos := curr_left_local_spec if active_hand == ZenoEnums.Hand.LEFT else curr_right_local_spec
	var center_x := -0.22 if active_hand == ZenoEnums.Hand.LEFT else 0.22
	# Circular wheel orbit sits in Y-Z (vertical wheel in front of shoulder) or X-Y circle
	var center_yz := Vector2(0.05, 0.40)
	var hand_yz := Vector2(hand_pos.y, hand_pos.z)
	var rel_xy := Vector2(hand_pos.x - center_x, hand_pos.y - 0.05)
	var hand_orbit_vec := hand_yz - center_yz if (hand_yz - center_yz).length() >= rel_xy.length() else rel_xy
	var orbit_center := Vector2.ZERO
	var curr_angle := atan2(hand_orbit_vec.y, hand_orbit_vec.x)
	if not _has_prev_angle:
		_prev_angle_rad = curr_angle
		_has_prev_angle = true
		return

	var target_sign := -1.0 if _clockwise else 1.0
	# AT-34 anti-cheat: enforce minimum radius (>= 0.12 m) and monotonic signed direction
	var crank_dir := MechanicsMath.m07_evaluate_signed_crank(
		_prev_angle_rad, curr_angle, hand_orbit_vec, orbit_center, target_sign, 0.12
	)
	_prev_angle_rad = curr_angle
	_signed_progress_rad = maxf(0.0, _signed_progress_rad + float(crank_dir["effective_delta_rad"]))

	var measured_f_hz := absf(float(crank_dir["signed_delta_rad"]) / maxf(0.001, dt)) / TAU
	var eval := MechanicsMath.m07_evaluate_crank(measured_f_hz, preset.m07_cadence_hz, preset.m07_circle_radius_m, 0.25)

	if _left_wheel_node != null:
		_left_wheel_node.rotate_x(dt * (2.0 if bool(crank_dir["radius_ok"]) else 0.2))
	if _right_wheel_node != null:
		_right_wheel_node.rotate_x(dt * (2.0 if bool(crank_dir["radius_ok"]) else 0.2))

	if bool(crank_dir["radius_ok"]) and float(crank_dir["effective_delta_rad"]) > 0.0 and bool(eval["in_band"]):
		_wheel_energy = clampf(_wheel_energy + 10.0 * dt, 0.0, 100.0)
		_in_band_accum_s += dt
		if _in_band_accum_s >= 1.0 and _signed_progress_rad >= PI * 0.5:
			_in_band_accum_s -= 1.0
			_signed_progress_rad -= PI * 0.5
			var bonus := 100 if (_wheel_energy >= 100.0 and not _full_bonus_awarded) else 0
			if bonus > 0:
				_full_bonus_awarded = true
			var res := GameFlow.round_tracker.record_direct_points(10 + bonus, true)
			Platform.play_haptic_light_touch(active_hand)
			EventBus.target_hit.emit(active_hand, int(res["combo_points"]), int(res["streak"]), bonus > 0)
	else:
		_wheel_energy = clampf(_wheel_energy - 4.0 * dt, 0.0, 100.0)

func simulate_auto_action() -> void:
	_wheel_energy = minf(100.0, _wheel_energy + 20.0)
	var res := GameFlow.round_tracker.record_direct_points(50, true)
	Platform.play_haptic_light_touch(ZenoEnums.Hand.RIGHT)
	EventBus.target_hit.emit(ZenoEnums.Hand.RIGHT, int(res["combo_points"]), int(res["streak"]), false)
	status_hint = "Zen Water Wheel In-Band! Energy=%.0f%% (+%d pts)" % [_wheel_energy, int(res["combo_points"])]
