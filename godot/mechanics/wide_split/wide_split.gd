class_name WideSplitMechanic
extends MechanicBase

## Wide Split (Chest Opener & Upper Back — Twin KarateBoard.glb in scapular plane).
## Bring hands together at chest center, then open wide to shatter both side boards.

const MINT_COLOR := Color(0.32, 0.85, 0.72)
const AMBER_COLOR := Color(0.95, 0.68, 0.28)
const GOLD_COLOR := Color(0.95, 0.84, 0.42)

var _left_board: KarateBoardProp = null
var _right_board: KarateBoardProp = null
var _prime_ring: Node3D = null
var _targets: Dictionary = {}
var _primed: bool = false
var _respawn_timer_s: float = 0.0
var _cycle_elapsed_s: float = 0.0

func _on_start() -> void:
	_primed = false
	_respawn_timer_s = 0.0
	_cycle_elapsed_s = 0.0
	_targets = MechanicsMath.wide_split_compute_targets(
		profile.shoulder_width_m,
		minf(profile.left_arm_length_m, profile.right_arm_length_m),
		preset.reach_factor_k,
		20.0
	)
	_prime_ring = create_glow_ring(0.14, 0.015, GOLD_COLOR, 0.72)
	var lp: Vector3 = _targets["left_pos"]
	_set_node_world_pos(_prime_ring, Vector3(0.0, lp.y, lp.z))
	_spawn_pair()
	status_hint = "Bring hands near the center ring"

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
	if _respawn_timer_s > 0.0:
		_respawn_timer_s -= dt
		if _respawn_timer_s <= 0.0:
			_spawn_pair()
		return

	_cycle_elapsed_s += dt
	var target_span := float(_targets.get("target_span", 0.72)) * 0.86
	var eval := MechanicsMath.wide_split_evaluate(
		curr_left_local_spec, curr_right_local_spec, _primed, 0.36, target_span, hand_mode
	)
	var was_primed := _primed
	_primed = bool(eval["primed"])
	if _primed and not was_primed:
		_play_haptic("play_haptic_light_touch", ZenoEnums.Hand.LEFT)
		_play_haptic("play_haptic_light_touch", ZenoEnums.Hand.RIGHT)
		status_hint = "Now open both arms wide to split!"

	if bool(eval["split_complete"]):
		_trigger_split_hit()

func _spawn_pair() -> void:
	_primed = false
	_cycle_elapsed_s = 0.0
	var lp: Vector3 = _targets["left_pos"]
	var rp: Vector3 = _targets["right_pos"]

	if hand_mode != ZenoEnums.HandMode.RIGHT_ONLY:
		_left_board = KarateBoardProp.new()
		_left_board.setup_board(MINT_COLOR)
		if arena_root != null:
			arena_root.add_child(_left_board)
		_set_node_world_pos(_left_board, lp)
		_left_board.rotation.y = body_frame.get_godot_yaw_rad() + deg_to_rad(72.0)

	if hand_mode != ZenoEnums.HandMode.LEFT_ONLY:
		_right_board = KarateBoardProp.new()
		_right_board.setup_board(AMBER_COLOR)
		if arena_root != null:
			arena_root.add_child(_right_board)
		_set_node_world_pos(_right_board, rp)
		_right_board.rotation.y = body_frame.get_godot_yaw_rad() - deg_to_rad(72.0)

	status_hint = "Bring hands together near center"

func _trigger_split_hit() -> void:
	var res := _record_hit_and_notify(ZenoEnums.Hand.RIGHT, minf(_cycle_elapsed_s, 1.5), 2.5, true)
	_play_haptic("play_haptic_solid_strike", ZenoEnums.Hand.LEFT)
	_play_haptic("play_haptic_solid_strike", ZenoEnums.Hand.RIGHT)
	status_hint = "Wide Split! +%d" % int(res["combo_points"])
	if _left_board != null:
		_left_board.trigger_break()
		if not _left_board.is_inside_tree():
			_retire_node(_left_board)
		_left_board = null
	if _right_board != null:
		_right_board.trigger_break()
		if not _right_board.is_inside_tree():
			_retire_node(_right_board)
		_right_board = null
	_respawn_timer_s = 0.65

func simulate_auto_action() -> void:
	if _left_board == null and _right_board == null:
		_spawn_pair()
	_trigger_split_hit()
