class_name M06ForceBlast
extends MechanicBase

## §6.6 Forward Press ("Force Blast") [P0, Level A, AT-21].

var _plane_node: Node3D = null
var _plane_z_m: float = 0.35
var _hold_time_s: float = 0.0
var _cooldown_s: float = 0.0
var _was_pressing: bool = false

func _on_start() -> void:
	_hold_time_s = 0.0
	_cooldown_s = 0.0
	_was_pressing = false
	var two_hand := (hand_mode == ZenoEnums.HandMode.BOTH_HANDS and profile.left_enabled and profile.right_enabled)
	_plane_z_m = MechanicsMath.m06_compute_plane_z(
		profile.left_reach_forward_m,
		profile.right_reach_forward_m,
		preset.reach_factor_k,
		two_hand
	)
	_plane_node = create_target_sphere(0.15, Color(0.25, 0.85, 1.0), "Force Plane (Hold 2.0 s)")
	_plane_node.global_position = body_frame.to_godot_world(Vector3(0.0, 0.0, _plane_z_m))
	status_hint = "Push forward to z=%.2f m (+0.03 m depth) and hold for 2.0 s!" % _plane_z_m

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

	var req_z := _plane_z_m + 0.03
	var left_pressed := profile.left_enabled and curr_left_local_spec.z >= req_z
	var right_pressed := profile.right_enabled and curr_right_local_spec.z >= req_z
	var is_pressing := false
	var is_synced := false

	if hand_mode == ZenoEnums.HandMode.BOTH_HANDS and profile.left_enabled and profile.right_enabled:
		is_pressing = left_pressed and right_pressed
		is_synced = absf(curr_left_local_spec.z - curr_right_local_spec.z) <= 0.05
	elif hand_mode == ZenoEnums.HandMode.LEFT_ONLY or not profile.right_enabled:
		is_pressing = left_pressed
	else:
		is_pressing = right_pressed

	if is_pressing:
		if not _was_pressing:
			Platform.play_haptic_forward_press(ZenoEnums.Hand.LEFT)
			Platform.play_haptic_forward_press(ZenoEnums.Hand.RIGHT)
		_was_pressing = true
		_hold_time_s += dt
		var charge := clampf(_hold_time_s / 2.0, 0.0, 1.0)
		status_hint = "Charging Force Blast: %.0f%%" % (charge * 100.0)
		# Max hold 3.0 s or full charge completion at 2.0 s
		if _hold_time_s >= 2.0:
			_release_blast(is_synced)
	else:
		if _was_pressing and _hold_time_s >= 0.4:
			_release_blast(is_synced)
		_was_pressing = false
		_hold_time_s = maxf(0.0, _hold_time_s - dt * 0.5)

func _release_blast(is_synced: bool) -> void:
	var info := MechanicsMath.m06_compute_charge_and_points(_hold_time_s, 2.0, is_synced, 25)
	var pts := int(info["total_points"])
	var res := GameFlow.round_tracker.record_direct_points(pts, true)
	EventBus.target_hit.emit(ZenoEnums.Hand.RIGHT, int(res["combo_points"]), int(res["streak"]), is_synced)
	status_hint = "FORCE BLAST! +%d pts (charge=%.0f%%)" % [int(res["combo_points"]), float(info["charge"]) * 100.0]
	_hold_time_s = 0.0
	_was_pressing = false
	_cooldown_s = 1.0

func simulate_auto_action() -> void:
	_hold_time_s = 2.0
	_release_blast(true)
