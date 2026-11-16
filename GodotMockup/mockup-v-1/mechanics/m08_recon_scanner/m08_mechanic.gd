class_name M08ReconScanner
extends MechanicBase

## §6.8 Neck Mobility and Far Focus ("Recon Scanner") [P2, Safety Level B, AT-23].

var _target_node: Node3D = null
var _target_yaw_deg: float = 40.0
var _dwell_s: float = 0.0
var _smooth_all_the_way: bool = true
var _spawn_idx: int = 0

func _on_start() -> void:
	_spawn_idx = 0
	_spawn_recon_target()
	status_hint = "Turn head slowly (<=60 deg/s) to rest head reticle on horizon target for 1.0 s!"

func update_mechanic(
	dt: float,
	_head_local_spec: Vector3,
	head_fwd_local_spec: Vector3,
	head_speed_deg_s: float,
	_prev_left_local_spec: Vector3,
	_curr_left_local_spec: Vector3,
	_left_speed_mps: float,
	_prev_right_local_spec: Vector3,
	_curr_right_local_spec: Vector3,
	_right_speed_mps: float,
	_left_roll_deg: float,
	_right_roll_deg: float
) -> void:
	if _target_node == null:
		_spawn_recon_target()
		return

	var head_yaw_deg := rad_to_deg(atan2(head_fwd_local_spec.x, maxf(0.01, head_fwd_local_spec.z)))
	var err_deg := absf(head_yaw_deg - _target_yaw_deg)

	var step := MechanicsMath.m08_step_scan_dwell(_dwell_s, err_deg, head_speed_deg_s, dt, 3.0, 60.0, 1.0)
	_dwell_s = float(step["dwell_s"])
	if bool(step["show_slower_cue"]):
		_smooth_all_the_way = false
		status_hint = "Slower! Turn head <= 60 deg/s (dwell timer paused at %.2f s)" % _dwell_s
		EventBus.safety_cue.emit("Slower head turn (<= 60 deg/s)")
	elif err_deg <= 3.0:
		status_hint = "Scanning target... %.0f%%" % (_dwell_s * 100.0)

	if bool(step["scan_complete"]):
		var bonus := 10 if _smooth_all_the_way else 0
		var res := GameFlow.round_tracker.record_hit(0.5, 2.0, false, bonus)
		Platform.play_haptic_light_touch(ZenoEnums.Hand.RIGHT)
		EventBus.target_hit.emit(ZenoEnums.Hand.RIGHT, int(res["combo_points"]), int(res["streak"]), _smooth_all_the_way)
		status_hint = "Recon Scan Complete! +%d pts" % int(res["combo_points"])
		_target_node.queue_free()
		_target_node = null

func _spawn_recon_target() -> void:
	var go_left := (_spawn_idx % 2 == 0)
	_spawn_idx += 1
	var max_neck := profile.neck_deg_l if go_left else profile.neck_deg_r
	var sign_dir := -1.0 if go_left else 1.0
	_target_yaw_deg = sign_dir * clampf(preset.reach_factor_k * max_neck, 15.0, 65.0)
	_dwell_s = 0.0
	_smooth_all_the_way = true

	var d := 2.4 # Displayed on readable horizon ring inside arena
	var rad := deg_to_rad(_target_yaw_deg)
	var pos_spec := Vector3(d * sin(rad), 0.15, d * cos(rad))
	_target_node = create_target_sphere(0.18, Color(0.45, 1.0, 0.65), "Recon %.0f°" % _target_yaw_deg)
	_target_node.global_position = body_frame.to_godot_world(pos_spec)

func simulate_auto_action() -> void:
	if _target_node == null:
		_spawn_recon_target()
	var res := GameFlow.round_tracker.record_hit(0.5, 2.0, false, 10)
	EventBus.target_hit.emit(ZenoEnums.Hand.RIGHT, int(res["combo_points"]), int(res["streak"]), true)
	if _target_node != null:
		_target_node.queue_free()
		_target_node = null
