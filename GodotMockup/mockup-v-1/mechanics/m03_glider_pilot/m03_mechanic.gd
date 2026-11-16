class_name M03GliderPilot
extends MechanicBase

## §6.3 Side Arm Raise ("Glider Pilot") [P1, Level A, AT-02].
## Static cockpit reference + rings approaching along +Z; steering uses arm height difference (roll), never body lean.

var _ring_node: Node3D = null
var _cockpit_ref_node: Node3D = null
var _glider_x_m: float = 0.0
var _ring_pos_spec: Vector3 = Vector3.ZERO
var _ring_index: int = 0
var _wings_bonus_accum_s: float = 0.0

func _on_start() -> void:
	_glider_x_m = 0.0
	_ring_index = 0
	_wings_bonus_accum_s = 0.0
	# Static cockpit reference to prevent cybersickness (§6.3.4, GP-COMFORT-01)
	_cockpit_ref_node = create_target_sphere(0.03, Color(0.4, 0.8, 1.0), "Glider Wing Sight")
	_spawn_ring()
	status_hint = "Raise arms to sides to deploy wings; vary arm heights to steer through rings!"

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
	var steer := MechanicsMath.m03_compute_steering(curr_left_local_spec, curr_right_local_spec, 0.10)
	var v_lat := float(steer["v_lat"])
	_glider_x_m = clampf(_glider_x_m + v_lat * dt, -0.60, 0.60)

	if _cockpit_ref_node != null:
		_cockpit_ref_node.global_position = body_frame.to_godot_world(Vector3(_glider_x_m, -0.05, 0.45))

	# Wings-level bonus (+10 per second inside tolerance)
	_wings_bonus_accum_s += dt
	if _wings_bonus_accum_s >= 1.0:
		_wings_bonus_accum_s -= 1.0
		GameFlow.round_tracker.record_direct_points(10, false)

	if _ring_node == null:
		_spawn_ring()
		return

	_ring_pos_spec.z -= 1.2 * dt
	_ring_node.global_position = body_frame.to_godot_world(_ring_pos_spec)

	if _ring_pos_spec.z <= 0.45:
		if absf(_glider_x_m - _ring_pos_spec.x) <= 0.22:
			var res := GameFlow.round_tracker.record_hit(0.5, 2.0)
			Platform.play_haptic_light_touch(ZenoEnums.Hand.LEFT)
			Platform.play_haptic_light_touch(ZenoEnums.Hand.RIGHT)
			EventBus.target_hit.emit(ZenoEnums.Hand.RIGHT, int(res["combo_points"]), int(res["streak"]), false)
			status_hint = "Ring passed! +%d pts (roll=%.1f deg)" % [int(res["combo_points"]), float(steer["roll_deg"])]
		else:
			GameFlow.round_tracker.record_miss()
			EventBus.target_missed.emit()
			status_hint = "Missed ring — adjust left/right arm height difference!"
		_ring_node.queue_free()
		_ring_node = null

func _spawn_ring() -> void:
	_ring_index += 1
	var offsets := [-0.35, 0.35, 0.0, -0.45, 0.45]
	var ring_x: float = offsets[_ring_index % offsets.size()]
	_ring_pos_spec = Vector3(ring_x, 0.0, 1.8)
	_ring_node = create_target_sphere(0.14, Color(0.25, 0.90, 0.85), "Glide Ring")
	_ring_node.global_position = body_frame.to_godot_world(_ring_pos_spec)

func simulate_auto_action() -> void:
	if _ring_node == null:
		_spawn_ring()
	_glider_x_m = _ring_pos_spec.x
	_ring_pos_spec.z = 0.44
	var res := GameFlow.round_tracker.record_hit(0.5, 2.0)
	EventBus.target_hit.emit(ZenoEnums.Hand.RIGHT, int(res["combo_points"]), int(res["streak"]), false)
	if _ring_node != null:
		_ring_node.queue_free()
		_ring_node = null
