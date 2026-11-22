class_name M06KiPalmPush
extends MechanicBase

## §6.6 Forward Press ("Ki Palm Push") [P0, Level A, AT-21, AT-33].

var _plane_node: Node3D = null
var _plane_z_m: float = 0.35
var _hold_time_s: float = 0.0
var _cooldown_s: float = 0.0
var _was_pressing: bool = false
var _ready_to_charge: bool = true

func _on_start() -> void:
	_hold_time_s = 0.0
	_cooldown_s = 0.0
	_was_pressing = false
	_ready_to_charge = true
	var two_hand := (hand_mode == ZenoEnums.HandMode.BOTH_HANDS and profile.left_enabled and profile.right_enabled)
	_plane_z_m = MechanicsMath.m06_compute_plane_z(
		profile.left_reach_forward_m,
		profile.right_reach_forward_m,
		preset.reach_factor_k,
		two_hand
	)
	_plane_node = create_dojo_box(Vector3(0.44, 0.30, 0.04), Color(0.25, 0.85, 0.95, 0.72), "Ki Barrier (Hold 2.0 s)", true)
	_plane_node.global_position = body_frame.to_godot_world(Vector3(0.0, 0.0, _plane_z_m))
	status_hint = "Push Ki barrier to z=%.2f m (+0.03 m depth) and hold steady for 2.0 s!" % _plane_z_m

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
	if _cooldown_s > 0.0:
		_cooldown_s = maxf(0.0, _cooldown_s - dt)
		return

	var two_hand := (hand_mode == ZenoEnums.HandMode.BOTH_HANDS and profile.left_enabled and profile.right_enabled)
	var req_z := _plane_z_m + 0.03
	# AT-33 anti-cheat: must retract toward chest after each Ki Palm Push before charging another
	var hyst := MechanicsMath.m06_check_retract_hysteresis(
		_ready_to_charge,
		curr_left_local_spec.z,
		curr_right_local_spec.z,
		0.0,
		req_z,
		0.35,
		two_hand,
		profile.left_enabled,
		profile.right_enabled
	)
	_ready_to_charge = bool(hyst["ready_to_charge"])
	if not _ready_to_charge:
		status_hint = "Retract hands toward chest (<= %.2f m) to prepare next Ki Push!" % float(hyst["z_retract"])
		return

	var is_pressing := bool(hyst["hands_at_plane"])
	var is_synced := two_hand and absf(curr_left_local_spec.z - curr_right_local_spec.z) <= 0.05

	if is_pressing:
		if not _was_pressing:
			Platform.play_haptic_forward_press(ZenoEnums.Hand.LEFT)
			Platform.play_haptic_forward_press(ZenoEnums.Hand.RIGHT)
		_was_pressing = true
		_hold_time_s += dt
		var charge := clampf(_hold_time_s / 2.0, 0.0, 1.0)
		status_hint = "Charging Ki Push: %.0f%%" % (charge * 100.0)
		if _hold_time_s >= 2.0:
			_release_ki_blast(is_synced)
	else:
		if _was_pressing and _hold_time_s >= 0.4:
			_release_ki_blast(is_synced)
		_was_pressing = false
		_hold_time_s = maxf(0.0, _hold_time_s - dt * 0.5)

func _release_ki_blast(is_synced: bool) -> void:
	var info := MechanicsMath.m06_compute_charge_and_points(_hold_time_s, 2.0, is_synced, 25)
	var pts := int(info["total_points"])
	var res := GameFlow.round_tracker.record_direct_points(pts, true)
	EventBus.target_hit.emit(ZenoEnums.Hand.RIGHT, int(res["combo_points"]), int(res["streak"]), is_synced)
	status_hint = "KI PALM PUSH! +%d pts (pull back to reset)" % int(res["combo_points"])
	_hold_time_s = 0.0
	_was_pressing = false
	_ready_to_charge = false
	_cooldown_s = 0.8

func simulate_auto_action() -> void:
	_hold_time_s = 2.0
	_ready_to_charge = true
	_release_ki_blast(true)
	_ready_to_charge = true
