class_name TorsoTwistMechanic
extends MechanicBase

## Torso Twist (Seated Spinal Twist on Standard Chair — Level B).
## Requires keeping hands inside chest guard (<= 0.32 m) AND turning head + chest together
## to shatter side KarateBoard.glb targets at ±35..50 deg.

const GUARD_RING_COL := Color(0.32, 0.85, 0.72)
const BOARD_ACCENT_COL := Color(0.95, 0.68, 0.28)

var _target_board: KarateBoardProp = null
var _guard_ring: Node3D = null
var _aim_beam: MeshInstance3D = null
var _target_yaw_deg: float = 35.0
var _lock_timer_s: float = 0.0
var _spawn_idx: int = 0
var _elapsed_s: float = 0.0

func _on_start() -> void:
	_spawn_idx = 0
	_guard_ring = create_glow_ring(0.16, 0.012, GUARD_RING_COL, 0.45)
	_set_node_world_pos(_guard_ring, Vector3(0.0, 0.0, 0.22))
	_aim_beam = create_aim_beam(GUARD_RING_COL)
	_spawn_side_board()
	status_hint = ZenoEnums.get_exercise_cue(exercise_id)

func update_mechanic(
	dt: float,
	_head_local_spec: Vector3,
	head_fwd_local_spec: Vector3,
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
	if _target_board == null:
		_spawn_side_board()
		return

	_elapsed_s += dt
	var eval := MechanicsMath.torso_twist_evaluate(
		curr_left_local_spec, curr_right_local_spec, head_fwd_local_spec,
		_target_yaw_deg, 0.32, 9.0, 22.0, hand_mode
	)

	var aim_yaw_deg := float(eval["aim_yaw_deg"])
	if _aim_beam != null:
		var beam_len := 1.15
		var rad := deg_to_rad(aim_yaw_deg)
		var mid_spec := Vector3(sin(rad) * (beam_len * 0.5), 0.02, cos(rad) * (beam_len * 0.5))
		_set_node_world_pos(_aim_beam, mid_spec)
		_set_node_world_rot(_aim_beam, Vector3(deg_to_rad(90.0), body_frame.get_godot_yaw_rad() + SpecSpace.yaw_deg_to_godot_rad(aim_yaw_deg), 0.0))

	if not bool(eval["hands_in_guard"]):
		_lock_timer_s = maxf(0.0, _lock_timer_s - dt * 0.5)
		status_hint = "Bring hands close to your chest"
		return

	if not bool(eval["head_synced"]):
		_lock_timer_s = maxf(0.0, _lock_timer_s - dt * 0.5)
		status_hint = "Turn your chest and head together"
		return

	if bool(eval["aim_locked"]):
		_lock_timer_s += dt
		status_hint = "Hold twist... %.0f%%" % clampf(_lock_timer_s / 0.35 * 100.0, 0.0, 100.0)
		if _lock_timer_s >= 0.35:
			_shatter_side_board()
	else:
		_lock_timer_s = maxf(0.0, _lock_timer_s - dt * 0.5)
		status_hint = "Rotate %s toward the board" % ("left" if _target_yaw_deg < 0.0 else "right")

func _spawn_side_board() -> void:
	var go_left := (_spawn_idx % 2 == 0)
	_spawn_idx += 1
	var max_deg := profile.twist_deg_l if go_left else profile.twist_deg_r
	var side_sign := -1.0 if go_left else 1.0
	var info := MechanicsMath.torso_twist_target(max_deg, preset.reach_factor_k, side_sign, 1.20, 55.0)
	_target_yaw_deg = float(info["psi_t_deg"])
	_lock_timer_s = 0.0
	_elapsed_s = 0.0

	var board := KarateBoardProp.new()
	board.setup_board(BOARD_ACCENT_COL)
	if arena_root != null:
		arena_root.add_child(board)
	_set_node_world_pos(board, info["position"])
	board.rotation.y = body_frame.get_godot_yaw_rad() + SpecSpace.yaw_deg_to_godot_rad(_target_yaw_deg)
	_target_board = board

func _shatter_side_board() -> void:
	var res := _record_hit_and_notify(ZenoEnums.Hand.RIGHT, minf(_elapsed_s, 1.8), 3.0, false)
	_play_haptic("play_haptic_solid_strike", ZenoEnums.Hand.LEFT if _target_yaw_deg < 0.0 else ZenoEnums.Hand.RIGHT)
	status_hint = "Great torso rotation! +%d" % int(res["combo_points"])
	if _target_board != null:
		_target_board.trigger_break()
		if not _target_board.is_inside_tree():
			_retire_node(_target_board)
		_target_board = null

func simulate_auto_action() -> void:
	if _target_board == null:
		_spawn_side_board()
	_elapsed_s = 0.5
	_shatter_side_board()
