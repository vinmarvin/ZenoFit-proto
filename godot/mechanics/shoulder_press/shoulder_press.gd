class_name ShoulderPressMechanic
extends DirectionalTwoSetMechanic

## Shoulder Press (Shoulders & Triceps — Two-Set Vertical Box Hit + Mechanical Tension).
## Set 1: Upward Movement (shoulder height -> overhead).
## Set 2: Downward Movement (overhead -> shoulder height).

func _get_set_direction_label(set_num: int) -> String:
	return "Upward Movement" if set_num == 1 else "Downward Movement"

func _get_initial_cue() -> String:
	return "Set 1: Hold hands at shoulder height, then press upward"

func _build_calibrated_waypoints() -> void:
	_use_box_targets = true
	var k := clampf(preset.reach_factor_k, 0.35, ComfortProfile.MAX_REACH_FACTOR_K)

	var sl := profile.get_shoulder_local(ZenoEnums.Hand.LEFT)
	var al := profile.get_arm_length_m(ZenoEnums.Hand.LEFT)
	var z_l := clampf(0.28, 0.22, 0.36)
	var y_low_l := clampf(sl.y + 0.02, -0.02, 0.16)
	var y_high_l := clampf(sl.y + al * k * 0.62, y_low_l + 0.20, 0.48)
	_left_waypoints = [
		Vector3(sl.x - 0.04, y_low_l, z_l),
		Vector3(sl.x - 0.03, lerpf(y_low_l, y_high_l, 0.5), z_l),
		Vector3(sl.x - 0.02, y_high_l, z_l)
	]

	var sr := profile.get_shoulder_local(ZenoEnums.Hand.RIGHT)
	var ar := profile.get_arm_length_m(ZenoEnums.Hand.RIGHT)
	var z_r := clampf(0.28, 0.22, 0.36)
	var y_low_r := clampf(sr.y + 0.02, -0.02, 0.16)
	var y_high_r := clampf(sr.y + ar * k * 0.62, y_low_r + 0.20, 0.48)
	_right_waypoints = [
		Vector3(sr.x + 0.04, y_low_r, z_r),
		Vector3(sr.x + 0.03, lerpf(y_low_r, y_high_r, 0.5), z_r),
		Vector3(sr.x + 0.02, y_high_r, z_r)
	]

