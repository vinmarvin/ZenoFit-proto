class_name BoardSmashMechanic
extends MechanicBase

## Board Smash (Seated Boxing: Front Jab/Cross, Side Hook, High Uppercut).
## Uses KarateBoard.glb (Board_Intact -> Board_Half_Left/Right + Splinter_1..6 + Break anim).

const MINT_LEFT := Color(0.32, 0.85, 0.72)
const AMBER_RIGHT := Color(0.95, 0.68, 0.28)
const HIT_THRESHOLD_Z_MIN: float = 0.18

var _active_board: KarateBoardProp = null
var _active_hand: int = ZenoEnums.Hand.LEFT
var _pattern: String = "front"
var _spawn_pos_spec: Vector3 = Vector3.ZERO
var _hit_pos_spec: Vector3 = Vector3.ZERO
var _curr_pos_spec: Vector3 = Vector3.ZERO
var _speed_mps: float = 0.95
var _elapsed_s: float = 0.0
var _lifetime_s: float = 2.0
var _beat_timer_s: float = 0.20
var _spawn_count: int = 0

func _on_start() -> void:
	_beat_timer_s = 0.20
	_spawn_count = 0
	status_hint = ZenoEnums.get_exercise_cue(exercise_id)

func update_mechanic(
	dt: float,
	_head_local_spec: Vector3,
	_head_fwd_local_spec: Vector3,
	_head_speed_deg_s: float,
	prev_left_local_spec: Vector3,
	curr_left_local_spec: Vector3,
	left_speed_mps: float,
	prev_right_local_spec: Vector3,
	curr_right_local_spec: Vector3,
	right_speed_mps: float,
	_left_roll_deg: float,
	_right_roll_deg: float
) -> void:
	if _active_board == null:
		_beat_timer_s -= dt
		if _beat_timer_s <= 0.0:
			_spawn_board()
		return

	_elapsed_s += dt
	_curr_pos_spec.z -= _speed_mps * dt
	_set_node_world_pos(_active_board, _curr_pos_spec)

	var req_hand := ZenoEnums.TargetHand.LEFT if _active_hand == ZenoEnums.Hand.LEFT else ZenoEnums.TargetHand.RIGHT
	var hit_radius := get_effective_hit_radius(maxf(0.13, preset.target_radius_m + 0.03))
	var hit_l := ZenoGeometry.check_valid_hand_hit(
		ZenoEnums.Hand.LEFT, profile.left_enabled, hand_mode, req_hand,
		_curr_pos_spec, hit_radius, prev_left_local_spec, curr_left_local_spec
	)
	var hit_r := ZenoGeometry.check_valid_hand_hit(
		ZenoEnums.Hand.RIGHT, profile.right_enabled, hand_mode, req_hand,
		_curr_pos_spec, hit_radius, prev_right_local_spec, curr_right_local_spec
	)

	if hit_l or hit_r:
		var used_hand := ZenoEnums.Hand.LEFT if hit_l else ZenoEnums.Hand.RIGHT
		var curr_hand_pos := curr_left_local_spec if hit_l else curr_right_local_spec
		var speed_mps := left_speed_mps if hit_l else right_speed_mps
		if not MechanicsMath.board_smash_is_valid_strike(curr_hand_pos, speed_mps, _pattern, 0.22, 0.25):
			status_hint = "Lift and punch forward through the board" if _pattern == "uppercut" else "Extend a crisp punch forward"
		else:
			var is_solid := MechanicsMath.board_smash_is_solid_hit(speed_mps, 0.45)
			_strike_board(used_hand, is_solid)
			return

	if _curr_pos_spec.z <= HIT_THRESHOLD_Z_MIN or _elapsed_s >= _lifetime_s:
		_record_miss_and_notify()
		_tempo().record_target_outcome(false)
		status_hint = "Stay on beat and reach smoothly"
		_retire_node(_active_board)
		_active_board = null
		_beat_timer_s = maxf(0.18, _tempo().get_current_interval_seconds() * 0.28)

func _spawn_board() -> void:
	_active_hand = pick_hand_for_spawn(_spawn_count)
	_spawn_count += 1

	if preset.tier == ZenoEnums.DifficultyTier.GENTLE:
		_pattern = "front"
	else:
		var mod := _spawn_count % 4
		if mod == 3:
			_pattern = "hook"
		elif mod == 0:
			_pattern = "uppercut"
		else:
			_pattern = "front"

	var rf := profile.get_reach_forward_m(_active_hand)
	var params := MechanicsMath.board_smash_params(rf, preset.reach_factor_k, 1.45, 1.0)
	_speed_mps = float(params["v_a"])
	var z_hit := float(params["z_hit"])
	var side_sign := -1.0 if _active_hand == ZenoEnums.Hand.LEFT else 1.0

	var target_x := side_sign * 0.12
	var target_y := 0.04
	var local_rot_deg := Vector3.ZERO
	if _pattern == "hook":
		target_x = side_sign * 0.24
		z_hit = maxf(0.28, z_hit * 0.90)
		local_rot_deg = Vector3(0.0, -side_sign * 44.0, 0.0)
		status_hint = "Hook wide from the side"
	elif _pattern == "uppercut":
		target_x = side_sign * 0.14
		target_y = 0.22
		z_hit = maxf(0.28, z_hit * 0.90)
		local_rot_deg = Vector3(28.0, 0.0, 0.0)
		status_hint = "Lift upward to break the high board"
	else:
		status_hint = "Punch straight through the board"

	var candidate := Vector3(target_x, target_y, z_hit)
	var resolved := profile.resolve_obstacle_free_position(candidate, preset.target_radius_m)
	_hit_pos_spec = resolved["position"]
	_spawn_pos_spec = Vector3(_hit_pos_spec.x, _hit_pos_spec.y, float(params["z0"]))
	_curr_pos_spec = _spawn_pos_spec
	_elapsed_s = 0.0
	_lifetime_s = ZenoScoring.compute_lifetime_seconds(preset.target_lifetime_beats, _tempo().current_bpm)

	var col := MINT_LEFT if _active_hand == ZenoEnums.Hand.LEFT else AMBER_RIGHT
	var board := KarateBoardProp.new()
	board.setup_board(col)
	if arena_root != null:
		arena_root.add_child(board)
	_set_node_world_pos(board, _curr_pos_spec)
	_set_node_world_rot(board, Vector3(
		deg_to_rad(local_rot_deg.x),
		body_frame.get_godot_yaw_rad() + deg_to_rad(local_rot_deg.y),
		deg_to_rad(local_rot_deg.z)
	))
	_active_board = board

func _strike_board(hand: int, is_solid: bool) -> void:
	var res := _record_hit_and_notify(hand, _elapsed_s, _lifetime_s, is_solid)
	_tempo().record_target_outcome(true)
	_play_haptic("play_haptic_solid_strike" if is_solid else "play_haptic_light_strike", hand)
	status_hint = "%s Break! +%d" % ["Solid" if is_solid else "Clean", int(res["combo_points"])]
	if _active_board != null:
		_active_board.trigger_break()
		if not _active_board.is_inside_tree():
			_retire_node(_active_board)
		_active_board = null
	_beat_timer_s = maxf(0.18, _tempo().get_current_interval_seconds() * 0.25)

func simulate_auto_action() -> void:
	if _active_board == null:
		_spawn_board()
	_elapsed_s = 0.35
	_strike_board(_active_hand, true)
