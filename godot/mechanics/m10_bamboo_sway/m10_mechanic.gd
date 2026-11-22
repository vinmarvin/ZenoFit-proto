class_name M10BambooSway
extends MechanicBase

## §6.10 Overhead Reach with Side Bend ("Bamboo Sway") [P2, Safety Level B, AT-25].

var _rail_node: Node3D = null
var _gap_node: Node3D = null
var _rail_pos_local_spec: Vector3 = Vector3(0.0, 0.36, 0.36)
var _gap_centre_x_m: float = 0.20
var _wall_z_m: float = 1.6
var _max_side_lean_m: float = 0.28
var _side_sign: float = 1.0
var _spawn_idx: int = 0

func _on_start() -> void:
	_spawn_idx = 0
	_rail_pos_local_spec = Vector3(0.0, 0.36, 0.36)
	_rail_node = create_dojo_box(Vector3(0.80, 0.05, 0.05), Color(0.45, 0.82, 0.36), "Overhead Bamboo Bar (Hold)")
	_rail_node.global_position = body_frame.to_godot_world(_rail_pos_local_spec)
	_spawn_bamboo_gap()
	status_hint = "Hold BOTH hands up on the overhead bamboo bar and sway gently into the safe gap (<=0.25 m)!"

func update_mechanic(
	dt: float,
	head_local_spec: Vector3,
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
	if _gap_node == null:
		_spawn_bamboo_gap()
		return

	_wall_z_m -= 0.45 * dt
	_gap_node.global_position = body_frame.to_godot_world(Vector3(_gap_centre_x_m, 0.15, _wall_z_m))

	var hands_up := MechanicsMath.m10_are_hands_on_rail(
		curr_left_local_spec, curr_right_local_spec, _rail_pos_local_spec,
		profile.left_enabled, profile.right_enabled, 0.24
	)
	if not hands_up:
		status_hint = "Raise active hands up onto the overhead bamboo bar!"

	if _wall_z_m <= 0.15:
		var x_head := head_local_spec.x - GameFlow.seat_anchor_local_spec.x
		var eval := MechanicsMath.m10_compute_gap_and_evaluate(
			_max_side_lean_m, preset.reach_factor_k, x_head, _side_sign, 0.25, 0.08
		)
		if hands_up and bool(eval["success"]):
			var res := GameFlow.round_tracker.record_hit(0.5, 2.0)
			Platform.play_haptic_light_touch(ZenoEnums.Hand.LEFT)
			Platform.play_haptic_light_touch(ZenoEnums.Hand.RIGHT)
			EventBus.target_hit.emit(ZenoEnums.Hand.RIGHT, int(res["combo_points"]), int(res["streak"]), false)
			status_hint = "Bamboo Screen Swayed! +%d pts (gap=%.2f m)" % [int(res["combo_points"]), _gap_centre_x_m]
		else:
			GameFlow.round_tracker.record_miss()
			EventBus.target_missed.emit()
			status_hint = "Keep hands on bamboo bar!" if not hands_up else ("Missed safe gap (target x=%.2f m)" % _gap_centre_x_m)
		_gap_node.queue_free()
		_gap_node = null

func _spawn_bamboo_gap() -> void:
	var go_left := (_spawn_idx % 2 == 0)
	_spawn_idx += 1
	_side_sign = -1.0 if go_left else 1.0
	_max_side_lean_m = profile.lean_m_l if go_left else profile.lean_m_r
	var eval := MechanicsMath.m10_compute_gap_and_evaluate(
		_max_side_lean_m, preset.reach_factor_k, 0.0, _side_sign, 0.25, 0.08
	)
	_gap_centre_x_m = float(eval["gap_centre"])
	_wall_z_m = 1.4
	_gap_node = create_dojo_ring(0.18, 0.03, Color(0.35, 0.95, 0.55), "Safe Gap x=%.2f m" % _gap_centre_x_m)
	_gap_node.global_position = body_frame.to_godot_world(Vector3(_gap_centre_x_m, 0.15, _wall_z_m))

func simulate_auto_action() -> void:
	if _gap_node == null:
		_spawn_bamboo_gap()
	var res := GameFlow.round_tracker.record_hit(0.5, 2.0)
	EventBus.target_hit.emit(ZenoEnums.Hand.RIGHT, int(res["combo_points"]), int(res["streak"]), false)
	status_hint = "Bamboo Screen Swayed! +%d pts" % int(res["combo_points"])
	if _gap_node != null:
		_gap_node.queue_free()
		_gap_node = null
