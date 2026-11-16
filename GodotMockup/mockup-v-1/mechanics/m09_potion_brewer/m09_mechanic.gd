class_name M09PotionBrewer
extends MechanicBase

## §6.9 Elbow Flexion and Wrist Pour ("Potion Brewer") [P1, Level A, AT-24].

var _ingredient_node: Node3D = null
var _cauldron_node: Node3D = null
var _ingredient_pos_spec: Vector3 = Vector3.ZERO
var _cauldron_x_m: float = 0.0
var _cauldron_dir: float = 1.0
var _has_grabbed: bool = false
var _has_curled: bool = false
var _pour_timer_s: float = 0.0
var _active_hand: int = ZenoEnums.Hand.RIGHT

func _on_start() -> void:
	_active_hand = pick_hand_for_spawn(0)
	_has_grabbed = false
	_has_curled = false
	_pour_timer_s = 0.0
	_cauldron_x_m = 0.0
	_cauldron_node = create_target_sphere(0.14, Color(0.55, 0.25, 0.90), "Cauldron")
	_spawn_ingredient()
	status_hint = "Reach ingredient (0.85*L_arm), curl to shoulder (<=0.35*L_arm), then roll wrist >=60° to pour!"

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
	left_roll_deg: float,
	right_roll_deg: float
) -> void:
	# Move cauldron ±0.15 m at 0.2 m/s at z = 0.30 m
	_cauldron_x_m += _cauldron_dir * 0.20 * dt
	if absf(_cauldron_x_m) >= 0.15:
		_cauldron_x_m = clampf(_cauldron_x_m, -0.15, 0.15)
		_cauldron_dir *= -1.0
	if _cauldron_node != null:
		_cauldron_node.global_position = body_frame.to_godot_world(Vector3(_cauldron_x_m, -0.05, 0.30))

	var hand_pos := curr_left_local_spec if _active_hand == ZenoEnums.Hand.LEFT else curr_right_local_spec
	var wrist_roll := absf(left_roll_deg if _active_hand == ZenoEnums.Hand.LEFT else right_roll_deg)
	var shoulder := profile.get_shoulder_local(_active_hand)
	var dist_to_shoulder := hand_pos.distance_to(shoulder)
	var dists := MechanicsMath.m09_compute_curl_distances(profile.get_arm_length_m(_active_hand))
	var d_curl := float(dists["d_curl"])

	if not _has_grabbed:
		if hand_pos.distance_to(_ingredient_pos_spec) <= 0.16:
			_has_grabbed = true
			Platform.play_haptic_light_touch(_active_hand)
			status_hint = "Ingredient grabbed! Curl toward shoulder (<= %.2f m)..." % d_curl
	else:
		# Visual drag: p_obj += (p_hand - p_obj) * (1 - exp(-dt / tau)), tau = 0.20 s
		var drag := MechanicsMath.m09_compute_visual_drag(dt, 0.20)
		_ingredient_pos_spec += (hand_pos - _ingredient_pos_spec) * float(drag["gap_closure_ratio"])
		if _ingredient_node != null:
			_ingredient_node.global_position = body_frame.to_godot_world(_ingredient_pos_spec)

		if not _has_curled and dist_to_shoulder <= d_curl + 0.05:
			_has_curled = true
			var res := GameFlow.round_tracker.record_hit(0.5, 2.0)
			Platform.play_haptic_light_touch(_active_hand)
			EventBus.target_hit.emit(_active_hand, int(res["combo_points"]), int(res["streak"]), false)
			status_hint = "Curl complete! Hold above cauldron & roll wrist >= 60° for 1.0 s to pour!"
		elif _has_curled:
			if wrist_roll >= 60.0:
				_pour_timer_s += dt
				if _pour_timer_s >= 1.0:
					var res := GameFlow.round_tracker.record_direct_points(50, true)
					Platform.play_haptic_forward_press(_active_hand)
					EventBus.target_hit.emit(_active_hand, int(res["combo_points"]), int(res["streak"]), true)
					status_hint = "Potion Poured! +50 bonus!"
					if _ingredient_node != null:
						_ingredient_node.queue_free()
					_spawn_ingredient()

func _spawn_ingredient() -> void:
	_active_hand = pick_hand_for_spawn(0)
	_has_grabbed = false
	_has_curled = false
	_pour_timer_s = 0.0
	var dists := MechanicsMath.m09_compute_curl_distances(profile.get_arm_length_m(_active_hand))
	var d_ext := float(dists["d_ext"])
	var shoulder := profile.get_shoulder_local(_active_hand)
	_ingredient_pos_spec = Vector3(shoulder.x, 0.0, minf(d_ext, profile.get_target_forward_distance(_active_hand, preset.reach_factor_k)))
	_ingredient_node = create_target_sphere(0.09, Color(0.25, 0.95, 0.60), "Vial")
	_ingredient_node.global_position = body_frame.to_godot_world(_ingredient_pos_spec)

func simulate_auto_action() -> void:
	var res := GameFlow.round_tracker.record_hit(0.5, 2.0, false, 50)
	Platform.play_haptic_forward_press(_active_hand)
	EventBus.target_hit.emit(_active_hand, int(res["combo_points"]), int(res["streak"]), true)
	status_hint = "Curl + Wrist Pour Complete! +%d pts" % int(res["combo_points"])
	if _ingredient_node != null:
		_ingredient_node.queue_free()
	_spawn_ingredient()
