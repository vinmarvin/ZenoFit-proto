class_name M04BokkenGuard
extends MechanicBase

## §6.4 Trunk Twist ("Bokken Guard") [P2, Safety Level B, AT-19, AT-31].

var _target_node: Node3D = null
var _target_yaw_deg: float = 35.0
var _lock_timer_s: float = 0.0
var _spawn_idx: int = 0

func _on_start() -> void:
	_spawn_idx = 0
	_spawn_guard_target()
	status_hint = "Keep BOTH hands near chest guard (<= 0.32 m) & rotate torso to face marker for 0.3 s!"

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
	if _target_node == null:
		_spawn_guard_target()
		return

	# AT-31 anti-cheat: both hands must stay inside chest guard sphere so lateral arm swinging does not fake torso twist
	var aim := MechanicsMath.m04_is_valid_torso_aim(curr_left_local_spec, curr_right_local_spec, Vector3.ZERO, 0.32)
	if not bool(aim["hands_in_guard"]):
		status_hint = "Hold BOTH hands tucked near chest center (<= 0.32 m) — turn your torso!"
		_lock_timer_s = maxf(0.0, _lock_timer_s - dt * 0.5)
		return

	var aim_yaw_deg := float(aim["aim_yaw_deg"])
	if MechanicsMath.m04_is_aim_locked(aim_yaw_deg, _target_yaw_deg, 6.0):
		_lock_timer_s += dt
		if _lock_timer_s >= 0.30:
			var res := GameFlow.round_tracker.record_hit(0.6, 2.0)
			Platform.play_haptic_light_touch(ZenoEnums.Hand.LEFT)
			Platform.play_haptic_light_touch(ZenoEnums.Hand.RIGHT)
			EventBus.target_hit.emit(ZenoEnums.Hand.RIGHT, int(res["combo_points"]), int(res["streak"]), false)
			status_hint = "Bokken Guard Aligned! +%d pts" % int(res["combo_points"])
			_target_node.queue_free()
			_target_node = null
	else:
		_lock_timer_s = maxf(0.0, _lock_timer_s - dt * 0.5)

func _spawn_guard_target() -> void:
	var go_left := (_spawn_idx % 2 == 0)
	_spawn_idx += 1
	var max_deg := profile.twist_deg_l if go_left else profile.twist_deg_r
	var side_sign := -1.0 if go_left else 1.0
	var info := MechanicsMath.m04_compute_guard_target(max_deg, preset.reach_factor_k, side_sign, 1.5, 60.0)
	_target_yaw_deg = float(info["psi_t_deg"])
	_lock_timer_s = 0.0
	var pos_spec: Vector3 = info["position"]
	_target_node = create_dojo_box(Vector3(0.24, 0.24, 0.08), Color(0.95, 0.42, 0.28), "Guard %.0f°" % _target_yaw_deg)
	_target_node.global_position = body_frame.to_godot_world(pos_spec)
	_target_node.look_at(body_frame.to_godot_world(Vector3.ZERO), Vector3.UP)

func simulate_auto_action() -> void:
	if _target_node == null:
		_spawn_guard_target()
	var res := GameFlow.round_tracker.record_hit(0.5, 2.0)
	EventBus.target_hit.emit(ZenoEnums.Hand.RIGHT, int(res["combo_points"]), int(res["streak"]), false)
	if _target_node != null:
		_target_node.queue_free()
		_target_node = null
