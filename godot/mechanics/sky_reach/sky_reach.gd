class_name SkyReachMechanic
extends MechanicBase

## Sky Reach (Diagonal Overhead Reach <= 45 deg Gaze Elevation).
## Reaches diagonally forward-up to catch gently descending glowing lanterns.

const MINT_LANTERN := Color(0.45, 0.90, 0.78)
const GOLD_LANTERN := Color(0.98, 0.85, 0.36)

var _active_node: Node3D = null
var _active_hand: int = ZenoEnums.Hand.LEFT
var _catch_pos_spec: Vector3 = Vector3.ZERO
var _curr_pos_spec: Vector3 = Vector3.ZERO
var _is_golden: bool = false
var _elapsed_s: float = 0.0
var _spawn_count: int = 0

func _on_start() -> void:
	_spawn_count = 0
	_spawn_lantern()
	status_hint = ZenoEnums.get_exercise_cue(exercise_id)

func update_mechanic(
	dt: float,
	_head_local_spec: Vector3,
	_head_fwd_local_spec: Vector3,
	_head_speed_deg_s: float,
	prev_left_local_spec: Vector3,
	curr_left_local_spec: Vector3,
	_left_speed_mps: float,
	prev_right_local_spec: Vector3,
	curr_right_local_spec: Vector3,
	_right_speed_mps: float,
	_left_roll_deg: float,
	_right_roll_deg: float
) -> void:
	if _active_node == null:
		_spawn_lantern()
		return

	_elapsed_s += dt
	_curr_pos_spec.y -= 0.34 * dt
	_set_node_world_pos(_active_node, _curr_pos_spec)
	_active_node.rotate_y(dt * 1.1)

	var req_hand := ZenoEnums.TargetHand.LEFT if _active_hand == ZenoEnums.Hand.LEFT else ZenoEnums.TargetHand.RIGHT
	var hit_radius := get_effective_hit_radius(preset.target_radius_m + 0.02)
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
		_catch_lantern(used_hand)
		return

	if _curr_pos_spec.y < _catch_pos_spec.y - 0.26:
		_record_miss_and_notify()
		status_hint = "Reach smoothly upward as it descends"
		_retire_node(_active_node)
		_active_node = null

func _spawn_lantern() -> void:
	_active_hand = pick_hand_for_spawn(_spawn_count)
	_spawn_count += 1
	_is_golden = (_spawn_count % 4 == 0)
	var arm_len := profile.get_arm_length_m(_active_hand)
	var shoulder := profile.get_shoulder_local(_active_hand)
	var placement := MechanicsMath.sky_reach_placement(
		arm_len, preset.reach_factor_k, preset.reach_elevation_phi_deg, shoulder
	)
	var candidate: Vector3 = placement["position"]
	var jitter_x := 0.05 if (_spawn_count % 2 == 0) else -0.04
	candidate.x += jitter_x
	var resolved := profile.resolve_obstacle_free_position(candidate, preset.target_radius_m)
	_catch_pos_spec = resolved["position"]
	_curr_pos_spec = _catch_pos_spec + Vector3(0.0, 0.24, 0.0)
	_elapsed_s = 0.0

	var col := GOLD_LANTERN if _is_golden else MINT_LANTERN
	_active_node = create_lantern_prop(col, 1.05 if _is_golden else 0.90)
	_set_node_world_pos(_active_node, _curr_pos_spec)
	status_hint = "Reach up with your %s hand" % ("left" if _active_hand == ZenoEnums.Hand.LEFT else "right")

func _catch_lantern(hand: int) -> void:
	var bonus := 50 if _is_golden else 0
	var res := _record_hit_and_notify(hand, _elapsed_s, 1.4, _is_golden, bonus)
	_play_haptic("play_haptic_light_touch", hand)
	status_hint = "Nice reach! +%d" % int(res["combo_points"])
	if _active_node != null:
		_retire_node(_active_node)
		_active_node = null

func simulate_auto_action() -> void:
	if _active_node == null:
		_spawn_lantern()
	_elapsed_s = 0.4
	_catch_lantern(_active_hand)
