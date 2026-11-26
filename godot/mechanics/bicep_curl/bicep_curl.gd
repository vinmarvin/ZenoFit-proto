class_name BicepCurlMechanic
extends DirectionalTwoSetMechanic

## Bicep Curl (Biceps — Two-Set Elbow Flexion/Extension Target Hit + Mechanical Tension).
## Set 1: Elbow Flexion (lowered arm -> shoulder level).
## Set 2: Elbow Extension (shoulder level -> lowered arm).

func _get_set_direction_label(set_num: int) -> String:
	return "Elbow Flexion" if set_num == 1 else "Elbow Extension"

func _get_initial_cue() -> String:
	return "Set 1: Start with arms lowered, then curl up toward shoulders"

func _build_calibrated_waypoints() -> void:
	_use_box_targets = false
	var k := clampf(preset.reach_factor_k, 0.35, ComfortProfile.MAX_REACH_FACTOR_K)

	_left_waypoints = _build_curl_arc(profile.get_shoulder_local(ZenoEnums.Hand.LEFT), profile.get_arm_length_m(ZenoEnums.Hand.LEFT), k, -1.0)
	_right_waypoints = _build_curl_arc(profile.get_shoulder_local(ZenoEnums.Hand.RIGHT), profile.get_arm_length_m(ZenoEnums.Hand.RIGHT), k, 1.0)

func _build_curl_arc(shoulder: Vector3, arm_len: float, k: float, side_sign: float) -> Array[Vector3]:
	var x_pos := shoulder.x + side_sign * 0.02
	var y_bot := clampf(shoulder.y - arm_len * k * 0.42, -0.30, -0.06)
	var y_top := clampf(shoulder.y + 0.04, 0.04, 0.22)
	var z_end := 0.26
	var z_mid := 0.36
	var pts: Array[Vector3] = []
	for i in range(5):
		var t := float(i) / 4.0
		var y := lerpf(y_bot, y_top, t)
		var z := lerpf(z_end, z_mid, sin(t * PI))
		pts.append(Vector3(x_pos, y, z))
	return pts

