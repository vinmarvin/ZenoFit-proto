class_name HorizonGazeMechanic
extends MechanicBase

## Horizon Gaze (Gentle Seated Neck Mobility — Level B).
## Rewards slow controlled neck rotation (<= 60 deg/s, pitch <= 20 deg) across horizon lanterns.

const WARM_LANTERN_COL := Color(0.98, 0.84, 0.44)

var _target_node: Node3D = null
var _target_yaw_deg: float = 38.0
var _dwell_s: float = 0.0
var _smooth_all_the_way: bool = true
var _spawn_idx: int = 0

func _on_start() -> void:
	_spawn_idx = 0
	_spawn_lantern()
	status_hint = ZenoEnums.get_exercise_cue(exercise_id)

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
		_spawn_lantern()
		return

	var head_yaw_deg := rad_to_deg(atan2(head_fwd_local_spec.x, maxf(0.01, head_fwd_local_spec.z)))
	var head_pitch_deg := rad_to_deg(atan2(head_fwd_local_spec.y, maxf(0.01, Vector2(head_fwd_local_spec.x, head_fwd_local_spec.z).length())))
	var err_deg := absf(head_yaw_deg - _target_yaw_deg)

	var step := MechanicsMath.horizon_gaze_step(_dwell_s, err_deg, head_pitch_deg, head_speed_deg_s, dt, 6.0, 20.0, 60.0, 1.0)
	_dwell_s = float(step["dwell_s"])
	if bool(step["show_slower_cue"]):
		_smooth_all_the_way = false
		status_hint = "Turn your head a little slower"
		_emit_safety_cue("Turn your head a little slower")
	elif bool(step["on_target"]):
		status_hint = "Resting gaze on lantern... %.0f%%" % clampf(_dwell_s * 100.0, 0.0, 100.0)
	else:
		status_hint = "Look slowly toward the %s lantern" % ("left" if _target_yaw_deg < 0.0 else "right")

	if bool(step["scan_complete"]):
		var bonus := 15 if _smooth_all_the_way else 0
		var res := _record_hit_and_notify(ZenoEnums.Hand.RIGHT, 0.6, 2.0, _smooth_all_the_way, bonus)
		_play_haptic("play_haptic_light_touch", ZenoEnums.Hand.RIGHT)
		status_hint = "Smooth focus! +%d" % int(res["combo_points"])
		_retire_node(_target_node)
		_target_node = null

func _spawn_lantern() -> void:
	var go_left := (_spawn_idx % 2 == 0)
	_spawn_idx += 1
	var max_neck := profile.neck_deg_l if go_left else profile.neck_deg_r
	var sign_dir := -1.0 if go_left else 1.0
	_target_yaw_deg = sign_dir * clampf(preset.reach_factor_k * max_neck, 22.0, 52.0)
	_dwell_s = 0.0
	_smooth_all_the_way = true

	var d := 2.2
	var rad := deg_to_rad(_target_yaw_deg)
	var pos_spec := Vector3(d * sin(rad), 0.16, d * cos(rad))
	_target_node = create_lantern_prop(WARM_LANTERN_COL, 1.25)
	_set_node_world_pos(_target_node, pos_spec)

func simulate_auto_action() -> void:
	if _target_node == null:
		_spawn_lantern()
	var res := _record_hit_and_notify(ZenoEnums.Hand.RIGHT, 0.6, 2.0, true, 15)
	status_hint = "Smooth focus! +%d" % int(res["combo_points"])
	if _target_node != null:
		_retire_node(_target_node)
		_target_node = null
