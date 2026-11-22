class_name M05TempleBellPull
extends MechanicBase

## §6.5 Seated Row ("Temple Bell Pull") [P1, Level A, AT-20, AT-32].

var _bell_node: Node3D = null
var _remaining_rope_m: float = 1.0
var _stroke_started: bool = false
var _early_bonus_awarded: bool = false
var _left_pull_accum_m: float = 0.0
var _right_pull_accum_m: float = 0.0

func _on_start() -> void:
	_remaining_rope_m = 1.0
	_stroke_started = false
	_early_bonus_awarded = false
	_left_pull_accum_m = 0.0
	_right_pull_accum_m = 0.0
	_bell_node = create_dojo_box(Vector3(0.28, 0.34, 0.28), Color(0.85, 0.70, 0.28), "Temple Bell (1.00 m)")
	_update_bell_visual()
	status_hint = "Reach forward then pull bell rope back toward waist with active hands!"

func update_mechanic(
	_dt: float,
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
	var active_hand := pick_hand_for_spawn(0)
	var spd := maxf(left_speed_mps, right_speed_mps)
	if spd > 1.5:
		EventBus.safety_cue.emit("Pull the temple rope smoothly!")

	var rf := profile.get_reach_forward_m(active_hand)
	var params := MechanicsMath.m05_compute_row_params(rf, preset.reach_factor_k)
	var z_start := float(params["z_start"])
	var z_end := float(params["z_end"])
	var gain_g := float(params["gain_g"])

	var both_active := (hand_mode == ZenoEnums.HandMode.BOTH_HANDS and profile.left_enabled and profile.right_enabled)
	var start_ready := false
	var end_reached := false
	if both_active:
		start_ready = curr_left_local_spec.z >= z_start - 0.06 and curr_right_local_spec.z >= z_start - 0.06
		end_reached = curr_left_local_spec.z <= z_end + 0.06 and curr_right_local_spec.z <= z_end + 0.06
	elif active_hand == ZenoEnums.Hand.LEFT:
		start_ready = curr_left_local_spec.z >= z_start - 0.06
		end_reached = curr_left_local_spec.z <= z_end + 0.06
	else:
		start_ready = curr_right_local_spec.z >= z_start - 0.06
		end_reached = curr_right_local_spec.z <= z_end + 0.06

	if not _stroke_started and start_ready:
		_stroke_started = true
		_left_pull_accum_m = 0.0
		_right_pull_accum_m = 0.0
		status_hint = "Rope gripped! Pull steadily back toward your waist..."
	elif _stroke_started:
		var step := MechanicsMath.m05_step_bilateral_row(
			curr_left_local_spec.z, prev_left_local_spec.z,
			curr_right_local_spec.z, prev_right_local_spec.z,
			rf, gain_g, hand_mode
		)
		_left_pull_accum_m += maxf(0.0, prev_left_local_spec.z - curr_left_local_spec.z)
		_right_pull_accum_m += maxf(0.0, prev_right_local_spec.z - curr_right_local_spec.z)
		if end_reached:
			if both_active and (_left_pull_accum_m < 0.12 or _right_pull_accum_m < 0.12):
				status_hint = "Pull with BOTH hands smoothly!"
				_stroke_started = false
			else:
				_complete_stroke(active_hand, float(params["progress_per_stroke"]))

func _complete_stroke(hand: int, progress_m: float) -> void:
	_stroke_started = false
	_remaining_rope_m = maxf(0.0, _remaining_rope_m - progress_m)
	var extra := 0
	if _remaining_rope_m <= 0.01 and not _early_bonus_awarded:
		_early_bonus_awarded = true
		extra = 100
		_remaining_rope_m = 1.0 # Reset rope for next bell chime
	var res := GameFlow.round_tracker.record_hit(0.6, 2.0, false, extra)
	Platform.play_haptic(hand, 0.25, 0.08)
	EventBus.target_hit.emit(hand, int(res["combo_points"]), int(res["streak"]), extra > 0)
	status_hint = "Bell Rope Pulled! Remaining: %.2f m (+%d pts)" % [_remaining_rope_m, int(res["combo_points"])]
	_update_bell_visual()

func _update_bell_visual() -> void:
	if _bell_node != null:
		_bell_node.global_position = body_frame.to_godot_world(Vector3(0.0, 0.22 + (1.0 - _remaining_rope_m) * 0.10, 0.45 + _remaining_rope_m * 0.70))

func simulate_auto_action() -> void:
	var active_hand := pick_hand_for_spawn(0)
	var params := MechanicsMath.m05_compute_row_params(profile.get_reach_forward_m(active_hand), preset.reach_factor_k)
	_complete_stroke(active_hand, float(params["progress_per_stroke"]))
