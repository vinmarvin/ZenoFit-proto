class_name DirectionalTwoSetMechanic
extends TwoSetTensionMechanic

## Shared directional two-set polyline mechanic with Target Hit / Box Hit + Mechanical Tension.
## Set 1 moves from start -> end along the calibrated tension path.
## Set 2 moves from end -> start along the calibrated tension path.

const COL_LEFT_TARGET := Color(0.32, 0.85, 0.72)
const COL_RIGHT_TARGET := Color(0.95, 0.68, 0.28)
const COL_PRIME_RING := Color(0.95, 0.84, 0.42)

var _left_waypoints: Array[Vector3] = []
var _right_waypoints: Array[Vector3] = []

var _left_prime_node: Node3D = null
var _right_prime_node: Node3D = null
var _left_target_node: Node3D = null
var _right_target_node: Node3D = null

var _left_primed: bool = false
var _right_primed: bool = false
var _left_hit: bool = false
var _right_hit: bool = false
var _rep_elapsed_s: float = 0.0
var _use_box_targets: bool = false

func _build_calibrated_waypoints() -> void:
	pass

func _on_start() -> void:
	_reset_two_set_state()
	_left_primed = false
	_right_primed = false
	_left_hit = false
	_right_hit = false
	_rep_elapsed_s = 0.0
	_build_calibrated_waypoints()
	_setup_tension_guides()
	_spawn_set_targets()
	status_hint = _get_initial_cue()

func _get_initial_cue() -> String:
	return "Position hands at the start rings to begin Set 1"

func _on_set_changed(new_set: int) -> void:
	_left_primed = false
	_right_primed = false
	_left_hit = false
	_right_hit = false
	_rep_elapsed_s = 0.0
	_spawn_set_targets()
	status_hint = "Set %d: %s" % [new_set, _get_set_direction_label(new_set)]

func _setup_tension_guides() -> void:
	var tol := _get_tension_tolerance_m()
	if _uses_left_hand() and _left_waypoints.size() >= 2:
		_left_tension_guide = MechanicalTensionGuide.new()
		_left_tension_guide.setup_polyline(arena_root, body_frame, _left_waypoints, tol)
	if _uses_right_hand() and _right_waypoints.size() >= 2:
		_right_tension_guide = MechanicalTensionGuide.new()
		_right_tension_guide.setup_polyline(arena_root, body_frame, _right_waypoints, tol)

func _get_prime_pos(waypoints: Array[Vector3]) -> Vector3:
	if waypoints.is_empty():
		return Vector3.ZERO
	return waypoints[0] if current_set == 1 else waypoints[waypoints.size() - 1]

func _get_target_pos(waypoints: Array[Vector3]) -> Vector3:
	if waypoints.is_empty():
		return Vector3.ZERO
	return waypoints[waypoints.size() - 1] if current_set == 1 else waypoints[0]

func _retire_targets() -> void:
	for n in [_left_prime_node, _right_prime_node, _left_target_node, _right_target_node]:
		if n != null:
			_retire_node(n)
	_left_prime_node = null
	_right_prime_node = null
	_left_target_node = null
	_right_target_node = null

func _create_target_visual(col: Color) -> Node3D:
	if _use_box_targets:
		return create_target_box(Vector3(0.11, 0.11, 0.11), col, 0.88)
	return create_glow_orb(0.062, col, 0.90)

func _spawn_set_targets() -> void:
	_retire_targets()
	_left_primed = false
	_right_primed = false
	_left_hit = false
	_right_hit = false
	_rep_elapsed_s = 0.0

	if _uses_left_hand() and _left_waypoints.size() >= 2:
		_left_prime_node = create_glow_ring(0.085, 0.012, COL_PRIME_RING, 0.72)
		_set_node_world_pos(_left_prime_node, _get_prime_pos(_left_waypoints))
		_left_target_node = _create_target_visual(COL_LEFT_TARGET)
		_set_node_world_pos(_left_target_node, _get_target_pos(_left_waypoints))
		_left_target_node.visible = false

	if _uses_right_hand() and _right_waypoints.size() >= 2:
		_right_prime_node = create_glow_ring(0.085, 0.012, COL_PRIME_RING, 0.72)
		_set_node_world_pos(_right_prime_node, _get_prime_pos(_right_waypoints))
		_right_target_node = _create_target_visual(COL_RIGHT_TARGET)
		_set_node_world_pos(_right_target_node, _get_target_pos(_right_waypoints))
		_right_target_node.visible = false

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
	if _completed:
		return
	if _step_transition(dt):
		return

	_rep_elapsed_s += dt
	var tol := _get_tension_tolerance_m()
	var reverse_flow := (current_set == 2)
	var hit_r := get_effective_hit_radius(preset.target_radius_m + 0.025)
	var prime_r := get_effective_hit_radius(0.11)

	var left_in_zone := true
	var right_in_zone := true

	if _uses_left_hand() and _left_tension_guide != null:
		var eval_l := _left_tension_guide.evaluate_hand(curr_left_local_spec, tol)
		left_in_zone = bool(eval_l["in_zone"])
		_left_tension_guide.update_visual_feedback(dt, left_in_zone, reverse_flow, true, true)

	if _uses_right_hand() and _right_tension_guide != null:
		var eval_r := _right_tension_guide.evaluate_hand(curr_right_local_spec, tol)
		right_in_zone = bool(eval_r["in_zone"])
		_right_tension_guide.update_visual_feedback(dt, right_in_zone, reverse_flow, true, true)

	var both_in_zone := left_in_zone and right_in_zone
	var any_primed := _left_primed or _right_primed
	if any_primed:
		_record_tension_sample(both_in_zone)

	# Prime check
	if _uses_left_hand() and not _left_primed:
		if ZenoGeometry.segment_hit(prev_left_local_spec, curr_left_local_spec, _get_prime_pos(_left_waypoints), prime_r):
			_left_primed = true
			if _left_prime_node != null:
				_left_prime_node.visible = false
			if _left_target_node != null:
				_left_target_node.visible = true
			spawn_prime_vfx(_get_prime_pos(_left_waypoints), COL_PRIME_RING)
			_play_haptic("play_haptic_light_touch", ZenoEnums.Hand.LEFT)

	if _uses_right_hand() and not _right_primed:
		if ZenoGeometry.segment_hit(prev_right_local_spec, curr_right_local_spec, _get_prime_pos(_right_waypoints), prime_r):
			_right_primed = true
			if _right_prime_node != null:
				_right_prime_node.visible = false
			if _right_target_node != null:
				_right_target_node.visible = true
			spawn_prime_vfx(_get_prime_pos(_right_waypoints), COL_PRIME_RING)
			_play_haptic("play_haptic_light_touch", ZenoEnums.Hand.RIGHT)

	# Target hit check (only while primed)
	if _uses_left_hand() and _left_primed and not _left_hit:
		if ZenoGeometry.segment_hit(prev_left_local_spec, curr_left_local_spec, _get_target_pos(_left_waypoints), hit_r):
			_left_hit = true
			if _left_target_node != null:
				_left_target_node.visible = false
			spawn_hit_vfx(_get_target_pos(_left_waypoints), Color(1.0, 0.84, 0.32))

	if _uses_right_hand() and _right_primed and not _right_hit:
		if ZenoGeometry.segment_hit(prev_right_local_spec, curr_right_local_spec, _get_target_pos(_right_waypoints), hit_r):
			_right_hit = true
			if _right_target_node != null:
				_right_target_node.visible = false
			spawn_hit_vfx(_get_target_pos(_right_waypoints), Color(1.0, 0.84, 0.32))

	if _left_target_node != null and _left_target_node.visible:
		_left_target_node.rotate_y(dt * 1.4)
	if _right_target_node != null and _right_target_node.visible:
		_right_target_node.rotate_y(-dt * 1.4)

	if not both_in_zone and any_primed:
		status_hint = "Keep hands inside the glowing tension path!"
	elif (_left_primed or not _uses_left_hand()) and (_right_primed or not _uses_right_hand()):
		if not ((_left_hit or not _uses_left_hand()) and (_right_hit or not _uses_right_hand())):
			var active_guide := _right_tension_guide if _right_tension_guide != null else _left_tension_guide
			var tempo_cue := active_guide.get_tempo_phase_label() if active_guide != null else ""
			status_hint = "Set %d: %s • %s" % [current_set, _get_set_direction_label(current_set), tempo_cue]

	var all_done := (_left_hit or not _uses_left_hand()) and (_right_hit or not _uses_right_hand())
	if all_done:
		var used_hand := ZenoEnums.Hand.LEFT if hand_mode == ZenoEnums.HandMode.LEFT_ONLY else ZenoEnums.Hand.RIGHT
		_complete_rep(used_hand, _rep_elapsed_s, _get_set_direction_label(current_set))
		if not _completed and not _in_set_transition:
			_spawn_set_targets()
		elif _in_set_transition:
			_retire_targets()

func simulate_auto_action() -> void:
	if _completed:
		return
	if _in_set_transition:
		_transition_timer_s = 0.0
		_step_transition(0.02)
		return
	_record_tension_sample(true)
	_complete_rep(ZenoEnums.Hand.RIGHT, 0.8, _get_set_direction_label(current_set))
	if not _completed and not _in_set_transition:
		_spawn_set_targets()
	elif _in_set_transition:
		_retire_targets()

func clear_arena() -> void:
	_retire_targets()
	super.clear_arena()

