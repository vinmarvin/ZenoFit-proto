class_name M02FruitHarvester
extends MechanicBase

## §6.2 Overhead Reach ("Fruit Harvester") [P1, Level A, AT-03].

var _active_node: Node3D = null
var _active_hand: int = ZenoEnums.Hand.LEFT
var _catch_pos_spec: Vector3 = Vector3.ZERO
var _curr_pos_spec: Vector3 = Vector3.ZERO
var _is_golden: bool = false
var _elapsed_s: float = 0.0
var _spawn_count: int = 0

func _on_start() -> void:
	_spawn_count = 0
	_spawn_fruit()
	status_hint = "Reach diagonally forward-up to harvest fruit! (Tab = Auto-Harvest)"

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
		_spawn_fruit()
		return

	_elapsed_s += dt
	# Fall speed v_f = 0.4 m/s across ±0.25 m window (1.25 s)
	_curr_pos_spec.y -= 0.40 * dt
	_active_node.global_position = body_frame.to_godot_world(_curr_pos_spec)

	var req_hand := ZenoEnums.TargetHand.LEFT if _active_hand == ZenoEnums.Hand.LEFT else ZenoEnums.TargetHand.RIGHT
	var hit_l := ZenoGeometry.check_valid_hand_hit(
		ZenoEnums.Hand.LEFT, profile.left_enabled, hand_mode, req_hand,
		_curr_pos_spec, preset.target_radius_m, prev_left_local_spec, curr_left_local_spec
	)
	var hit_r := ZenoGeometry.check_valid_hand_hit(
		ZenoEnums.Hand.RIGHT, profile.right_enabled, hand_mode, req_hand,
		_curr_pos_spec, preset.target_radius_m, prev_right_local_spec, curr_right_local_spec
	)
	if hit_l or hit_r:
		var used_hand := ZenoEnums.Hand.LEFT if hit_l else ZenoEnums.Hand.RIGHT
		_harvest_fruit(used_hand)
		return

	if _curr_pos_spec.y < _catch_pos_spec.y - 0.25:
		GameFlow.round_tracker.record_miss()
		EventBus.target_missed.emit()
		_active_node.queue_free()
		_active_node = null

func _spawn_fruit() -> void:
	_active_hand = pick_hand_for_spawn(_spawn_count)
	_spawn_count += 1
	_is_golden = (_spawn_count % 4 == 0)
	var arm_len := profile.get_arm_length_m(_active_hand)
	var shoulder := profile.get_shoulder_local(_active_hand)
	var placement := MechanicsMath.m02_compute_fruit_placement(
		arm_len, preset.reach_factor_k, preset.m02_elevation_phi_deg, shoulder
	)
	var candidate: Vector3 = placement["position"]
	var resolved := profile.resolve_obstacle_free_position(candidate, preset.target_radius_m)
	_catch_pos_spec = resolved["position"]
	_curr_pos_spec = _catch_pos_spec + Vector3(0.0, 0.25, 0.0)
	_elapsed_s = 0.0

	var col := Color(1.0, 0.85, 0.15) if _is_golden else Color(0.35, 0.95, 0.45)
	var label := ("Golden Fruit (" if _is_golden else "Fruit (") + ("L)" if _active_hand == ZenoEnums.Hand.LEFT else "R)")
	_active_node = create_target_sphere(preset.target_radius_m, col, label)
	_active_node.global_position = body_frame.to_godot_world(_curr_pos_spec)

func _harvest_fruit(hand: int) -> void:
	var bonus := 50 if _is_golden else 0
	var res := GameFlow.round_tracker.record_hit(_elapsed_s, 1.25, false, bonus)
	Platform.play_haptic_light_touch(hand)
	EventBus.target_hit.emit(hand, int(res["combo_points"]), int(res["streak"]), _is_golden)
	status_hint = "Harvested %s! +%d pts" % ["Golden Fruit" if _is_golden else "Fruit", int(res["combo_points"])]
	if _active_node != null:
		_active_node.queue_free()
		_active_node = null

func simulate_auto_action() -> void:
	if _active_node == null:
		_spawn_fruit()
	_elapsed_s = 0.4
	_harvest_fruit(_active_hand)
