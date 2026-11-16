class_name M01AsteroidBrawler
extends MechanicBase

## §6.1 Seated Boxing ("Asteroid Brawler") [P0, Level A, AT-01, AT-12].

var _active_node: Node3D = null
var _active_hand: int = ZenoEnums.Hand.LEFT
var _spawn_pos_spec: Vector3 = Vector3.ZERO
var _hit_pos_spec: Vector3 = Vector3.ZERO
var _curr_pos_spec: Vector3 = Vector3.ZERO
var _speed_mps: float = 0.99
var _elapsed_s: float = 0.0
var _lifetime_s: float = 2.0
var _beat_timer_s: float = 0.25
var _spawn_count: int = 0

func _on_start() -> void:
	_beat_timer_s = 0.20
	_spawn_count = 0
	status_hint = "Punch asteroids on the beat! (Tab = Auto-Punch)"

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
	if _active_node != null:
		_elapsed_s += dt
		_curr_pos_spec.z -= _speed_mps * dt
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
			var spd := left_speed_mps if hit_l else right_speed_mps
			_resolve_hit(used_hand, spd)
			return

		# Burst harmlessly at z_miss = 0.20 m or lifetime expiry (§6.1.2)
		if _curr_pos_spec.z <= 0.20 or _elapsed_s >= _lifetime_s:
			_resolve_miss()
		return

	_beat_timer_s -= dt
	if _beat_timer_s <= 0.0:
		_spawn_asteroid()
		_beat_timer_s = GameFlow.adaptive_tempo.get_current_interval_seconds()

func _spawn_asteroid() -> void:
	_active_hand = pick_hand_for_spawn(_spawn_count)
	_spawn_count += 1
	var rf := profile.get_reach_forward_m(_active_hand)
	var params := MechanicsMath.m01_compute_asteroid_params(rf, preset.reach_factor_k, 1.5, 1.0)
	var lane_x := -0.10 if _active_hand == ZenoEnums.Hand.LEFT else 0.10
	var candidate_hit := Vector3(lane_x, 0.0, float(params["z_hit"]))
	var resolved := profile.resolve_obstacle_free_position(candidate_hit, preset.target_radius_m)
	if not bool(resolved["valid"]):
		return
	_hit_pos_spec = resolved["position"]
	_spawn_pos_spec = Vector3(_hit_pos_spec.x, _hit_pos_spec.y, 1.5)
	_curr_pos_spec = _spawn_pos_spec
	_speed_mps = float(params["v_a"])
	_elapsed_s = 0.0
	_lifetime_s = ZenoScoring.compute_lifetime_seconds(preset.target_lifetime_beats, GameFlow.adaptive_tempo.current_bpm)

	var col := Color(0.20, 0.65, 1.0) if _active_hand == ZenoEnums.Hand.LEFT else Color(1.0, 0.55, 0.20)
	var badge := "L Punch" if _active_hand == ZenoEnums.Hand.LEFT else "R Punch"
	_active_node = create_target_sphere(preset.target_radius_m, col, badge)
	_active_node.global_position = body_frame.to_godot_world(_curr_pos_spec)

func _resolve_hit(hand: int, speed_mps: float) -> void:
	var is_solid := MechanicsMath.m01_is_solid_hit(speed_mps, 0.30, false)
	var res := GameFlow.round_tracker.record_hit(_elapsed_s, _lifetime_s, is_solid)
	GameFlow.adaptive_tempo.record_target_outcome(true)
	if is_solid:
		Platform.play_haptic_solid_boxing(hand)
	else:
		Platform.play_haptic_light_boxing(hand)
	EventBus.target_hit.emit(hand, int(res["combo_points"]), int(res["streak"]), is_solid)
	status_hint = "%s HIT! +%d pts (v=%.2f m/s)" % ["SOLID" if is_solid else "LIGHT", int(res["combo_points"]), speed_mps]
	if _active_node != null:
		_active_node.queue_free()
		_active_node = null

func _resolve_miss() -> void:
	GameFlow.round_tracker.record_miss()
	GameFlow.adaptive_tempo.record_target_outcome(false)
	EventBus.target_missed.emit()
	status_hint = "Asteroid burst harmlessly at z=0.20 m"
	if _active_node != null:
		_active_node.queue_free()
		_active_node = null

func simulate_auto_action() -> void:
	if _active_node == null:
		_spawn_asteroid()
	if _active_node != null:
		_elapsed_s = 0.45
		_resolve_hit(_active_hand, 0.45)
