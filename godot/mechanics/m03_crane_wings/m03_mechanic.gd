class_name M03CraneWings
extends MechanicBase

## §6.3 Side Arm Raise ("Crane Wings") [P1, Level A, AT-02, AT-30].
## Static dojo gate reference + wind rings approaching along +Z; steering enforces full wingspan above shoulders.

var _ring_node: Node3D = null
var _crane_sight_node: Node3D = null
var _crane_x_m: float = 0.0
var _ring_pos_spec: Vector3 = Vector3.ZERO
var _ring_index: int = 0
var _wings_bonus_accum_s: float = 0.0

func _on_start() -> void:
	_crane_x_m = 0.0
	_ring_index = 0
	_wings_bonus_accum_s = 0.0
	_crane_sight_node = create_target_sphere(0.035, Color(0.95, 0.90, 0.55), "Crane Sight")
	_spawn_ring()
	status_hint = "Spread BOTH arms wide above shoulder height to deploy Crane Wings!"

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
	var shoulder_y := 0.5 * (profile.left_shoulder_local_m.y + profile.right_shoulder_local_m.y)
	var calibrated_span := profile.shoulder_width_m + profile.left_arm_length_m + profile.right_arm_length_m
	# AT-30 anti-cheat: arms must span >= 0.70 * calibrated_span AND lift >= shoulder_y + 0.05 m
	var eval := MechanicsMath.m03_evaluate_wings_and_steering(
		curr_left_local_spec, curr_right_local_spec, shoulder_y, calibrated_span, 0.70, 0.05, 0.10
	)
	var wings_deployed := bool(eval["wings_deployed"])
	if wings_deployed:
		var v_lat := float(eval["steering"]) * 2.0
		_crane_x_m = clampf(_crane_x_m + v_lat * dt, -0.60, 0.60)
		_wings_bonus_accum_s += dt
		if _wings_bonus_accum_s >= 1.0:
			_wings_bonus_accum_s -= 1.0
			GameFlow.round_tracker.record_direct_points(10, false)
	else:
		_wings_bonus_accum_s = 0.0
		if not bool(eval["span_ok"]):
			status_hint = "Spread BOTH arms wider (full wingspan)!"
		elif not bool(eval["height_ok"]):
			status_hint = "Raise BOTH arms above shoulder height!"

	if _crane_sight_node != null:
		_crane_sight_node.global_position = body_frame.to_godot_world(Vector3(_crane_x_m, -0.05, 0.45))

	if _ring_node == null:
		_spawn_ring()
		return

	_ring_pos_spec.z -= 1.2 * dt
	_ring_node.global_position = body_frame.to_godot_world(_ring_pos_spec)

	if _ring_pos_spec.z <= 0.45:
		if wings_deployed and absf(_crane_x_m - _ring_pos_spec.x) <= 0.22:
			var res := GameFlow.round_tracker.record_hit(0.5, 2.0)
			Platform.play_haptic_light_touch(ZenoEnums.Hand.LEFT)
			Platform.play_haptic_light_touch(ZenoEnums.Hand.RIGHT)
			EventBus.target_hit.emit(ZenoEnums.Hand.RIGHT, int(res["combo_points"]), int(res["streak"]), false)
			status_hint = "Crane Ring Cleared! +%d pts" % int(res["combo_points"])
		else:
			GameFlow.round_tracker.record_miss()
			EventBus.target_missed.emit()
			status_hint = "Keep Crane Wings spread high above shoulders to clear rings!" if not wings_deployed else "Missed wind ring — tilt arm height gently!"
		_ring_node.queue_free()
		_ring_node = null

func _spawn_ring() -> void:
	_ring_index += 1
	var offsets := [-0.35, 0.35, 0.0, -0.45, 0.45]
	var ring_x: float = offsets[_ring_index % offsets.size()]
	_ring_pos_spec = Vector3(ring_x, 0.0, 1.8)
	_ring_node = create_dojo_ring(0.18, 0.03, Color(0.25, 0.90, 0.72), "Wind Ring")
	_ring_node.global_position = body_frame.to_godot_world(_ring_pos_spec)

func simulate_auto_action() -> void:
	if _ring_node == null:
		_spawn_ring()
	_crane_x_m = _ring_pos_spec.x
	_ring_pos_spec.z = 0.44
	var res := GameFlow.round_tracker.record_hit(0.5, 2.0)
	EventBus.target_hit.emit(ZenoEnums.Hand.RIGHT, int(res["combo_points"]), int(res["streak"]), false)
	if _ring_node != null:
		_ring_node.queue_free()
		_ring_node = null
