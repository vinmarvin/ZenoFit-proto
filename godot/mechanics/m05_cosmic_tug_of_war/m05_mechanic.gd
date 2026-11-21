class_name M05CosmicTugOfWar
extends MechanicBase

## §6.5 Seated Row ("Cosmic Tug-of-War") [P1, Level A, AT-20].

var _debris_node: Node3D = null
var _remaining_debris_m: float = 1.0
var _stroke_started: bool = false
var _early_bonus_awarded: bool = false

func _on_start() -> void:
	_remaining_debris_m = 1.0
	_stroke_started = false
	_early_bonus_awarded = false
	_debris_node = create_target_sphere(0.16, Color(0.65, 0.50, 0.95), "Tethered Debris (1.00 m)")
	_update_debris_visual()
	status_hint = "Reach forward (z_start) then pull hands toward waist (z<=0.18 m) to reel debris in!"

func update_mechanic(
	_dt: float,
	_head_local_spec: Vector3,
	_head_fwd_local_spec: Vector3,
	_head_speed_deg_s: float,
	_prev_left_local_spec: Vector3,
	curr_left_local_spec: Vector3,
	left_speed_mps: float,
	_prev_right_local_spec: Vector3,
	curr_right_local_spec: Vector3,
	right_speed_mps: float,
	_left_roll_deg: float,
	_right_roll_deg: float
) -> void:
	var active_hand := pick_hand_for_spawn(0)
	var hand_z := curr_left_local_spec.z if active_hand == ZenoEnums.Hand.LEFT else curr_right_local_spec.z
	var spd := maxf(left_speed_mps, right_speed_mps)
	if spd > 1.5:
		EventBus.safety_cue.emit("Slow and smooth rowing strokes!")

	var params := MechanicsMath.m05_compute_row_params(profile.get_reach_forward_m(active_hand), preset.reach_factor_k)
	var z_start := float(params["z_start"])
	var z_end := float(params["z_end"])

	if not _stroke_started and hand_z >= z_start - 0.06:
		_stroke_started = true
		status_hint = "Tether grabbed! Now pull smoothly back to waist..."
	elif _stroke_started and hand_z <= z_end + 0.06:
		_complete_stroke(active_hand, float(params["progress_per_stroke"]))

func _complete_stroke(hand: int, progress_m: float) -> void:
	_stroke_started = false
	_remaining_debris_m = maxf(0.0, _remaining_debris_m - progress_m)
	var extra := 0
	if _remaining_debris_m <= 0.01 and not _early_bonus_awarded:
		_early_bonus_awarded = true
		extra = 100
		_remaining_debris_m = 1.0 # Spawn next debris tether
	var res := GameFlow.round_tracker.record_hit(0.6, 2.0, false, extra)
	Platform.play_haptic(hand, 0.15, 0.08)
	EventBus.target_hit.emit(hand, int(res["combo_points"]), int(res["streak"]), extra > 0)
	status_hint = "Row stroke complete! Remaining debris: %.2f m (+%d pts)" % [_remaining_debris_m, int(res["combo_points"])]
	_update_debris_visual()

func _update_debris_visual() -> void:
	if _debris_node != null:
		_debris_node.global_position = body_frame.to_godot_world(Vector3(0.0, 0.0, 0.35 + _remaining_debris_m * 0.8))

func simulate_auto_action() -> void:
	var active_hand := pick_hand_for_spawn(0)
	var params := MechanicsMath.m05_compute_row_params(profile.get_reach_forward_m(active_hand), preset.reach_factor_k)
	_complete_stroke(active_hand, float(params["progress_per_stroke"]))
