class_name M07ShieldCrank
extends MechanicBase

## §6.7 Arm Circles ("Shield Generator Crank") [P0, Level A, AT-22].

var _left_crank_node: Node3D = null
var _right_crank_node: Node3D = null
var _shield_energy: float = 50.0
var _direction_timer_s: float = 0.0
var _clockwise: bool = true
var _prev_angle_rad: float = 0.0
var _in_band_accum_s: float = 0.0
var _full_bonus_awarded: bool = false

func _on_start() -> void:
	_shield_energy = 50.0
	_direction_timer_s = 0.0
	_clockwise = true
	_in_band_accum_s = 0.0
	_full_bonus_awarded = false
	_left_crank_node = create_target_sphere(0.08, Color(0.3, 0.85, 1.0), "L Crank")
	_right_crank_node = create_target_sphere(0.08, Color(1.0, 0.65, 0.25), "R Crank")
	_left_crank_node.global_position = body_frame.to_godot_world(Vector3(-0.22, 0.05, 0.40))
	_right_crank_node.global_position = body_frame.to_godot_world(Vector3(0.22, 0.05, 0.40))
	status_hint = "Move hands in slow circles (f=%.2f Hz, r=%.2f m) around cranks!" % [preset.m07_cadence_hz, preset.m07_circle_radius_m]

func update_mechanic(
	dt: float,
	_head_local_spec: Vector3,
	_head_fwd_local_spec: Vector3,
	_head_speed_deg_s: float,
	_prev_left_local_spec: Vector3,
	_curr_left_local_spec: Vector3,
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
		status_hint = "Switch circle direction: %s!" % ("CLOCKWISE" if _clockwise else "COUNTER-CLOCKWISE")

	var crank_c := Vector3(0.22, 0.05, 0.40)
	var rel := curr_right_local_spec - crank_c
	var angle := atan2(rel.y, rel.x)
	var d_angle := wrapf(angle - _prev_angle_rad, -PI, PI)
	_prev_angle_rad = angle

	var measured_f_hz := absf(d_angle / maxf(0.001, dt)) / TAU
	var radial_dist := Vector2(rel.x, rel.y).length()
	var on_circle := absf(radial_dist - preset.m07_circle_radius_m) <= 0.06
	var eval := MechanicsMath.m07_evaluate_crank(measured_f_hz, preset.m07_cadence_hz, preset.m07_circle_radius_m, 0.25)

	if on_circle and bool(eval["in_band"]):
		_shield_energy = clampf(_shield_energy + 10.0 * dt, 0.0, 100.0)
		_in_band_accum_s += dt
		if _in_band_accum_s >= 1.0:
			_in_band_accum_s -= 1.0
			var bonus := 100 if (_shield_energy >= 100.0 and not _full_bonus_awarded) else 0
			if bonus > 0:
				_full_bonus_awarded = true
			var res := GameFlow.round_tracker.record_direct_points(10 + bonus, true)
			Platform.play_haptic_light_touch(ZenoEnums.Hand.RIGHT)
			EventBus.target_hit.emit(ZenoEnums.Hand.RIGHT, int(res["combo_points"]), int(res["streak"]), bonus > 0)
	else:
		_shield_energy = clampf(_shield_energy - 5.0 * dt, 0.0, 100.0)

func simulate_auto_action() -> void:
	_shield_energy = minf(100.0, _shield_energy + 20.0)
	var res := GameFlow.round_tracker.record_direct_points(50, true)
	Platform.play_haptic_light_touch(ZenoEnums.Hand.RIGHT)
	EventBus.target_hit.emit(ZenoEnums.Hand.RIGHT, int(res["combo_points"]), int(res["streak"]), false)
	status_hint = "Shield Crank In-Band! Energy=%.0f%% (+%d pts)" % [_shield_energy, int(res["combo_points"])]
