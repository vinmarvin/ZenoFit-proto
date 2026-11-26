class_name LateralRaiseMechanic
extends DirectionalTwoSetMechanic

## Lateral Raise (Lateral Deltoid — Two-Set Side Raise/Lower Box Hit + Mechanical Tension).
## Set 1: Raising Movement (beside hips -> shoulder height).
## Set 2: Lowering Movement (shoulder height -> beside hips).

func _get_set_direction_label(set_num: int) -> String:
	return "Raising Movement" if set_num == 1 else "Lowering Movement"

func _get_initial_cue() -> String:
	return "Set 1: Start with hands at your sides, then raise out to shoulder height"

func _build_calibrated_waypoints() -> void:
	_use_box_targets = true
	var k := clampf(preset.reach_factor_k, 0.35, ComfortProfile.MAX_REACH_FACTOR_K)

	_left_waypoints = _build_lateral_arc(profile.get_shoulder_local(ZenoEnums.Hand.LEFT), profile.get_arm_length_m(ZenoEnums.Hand.LEFT), k, -1.0)
	_right_waypoints = _build_lateral_arc(profile.get_shoulder_local(ZenoEnums.Hand.RIGHT), profile.get_arm_length_m(ZenoEnums.Hand.RIGHT), k, 1.0)

func _build_lateral_arc(shoulder: Vector3, arm_len: float, k: float, side_sign: float) -> Array[Vector3]:
	var x_low := shoulder.x + side_sign * 0.04
	var x_high := shoulder.x + side_sign * clampf(arm_len * k * 0.62, 0.24, 0.44)
	var y_low := clampf(shoulder.y - arm_len * k * 0.40, -0.30, -0.06)
	var y_high := clampf(shoulder.y + 0.02, 0.02, 0.20)
	var z_pos := 0.24
	var pts: Array[Vector3] = []
	for i in range(5):
		var t := float(i) / 4.0
		var arc := sin(t * PI * 0.5)
		var x := lerpf(x_low, x_high, arc)
		var y := lerpf(y_low, y_high, t)
		pts.append(Vector3(x, y, z_pos))
	return pts

