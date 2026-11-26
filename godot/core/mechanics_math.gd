class_name MechanicsMath
extends RefCounted

## Pure mathematical formulas and anti-cheat kinematics evaluators for all 7 curated
## ZenoFit v1.0 exercises: BoardSmash, WideSplit, SkyReach, OrbitFlow, WristTwist,
## TorsoTwist, and HorizonGaze.

# ==============================================================================
# 1. Board Smash (Seated Boxing: Front Jab/Cross, Side Hook, High Uppercut)
# ==============================================================================
static func board_smash_params(
	reach_forward_m: float,
	k: float,
	z0_m: float = 1.5,
	t_lead_s: float = 1.0
) -> Dictionary:
	var clamped_k := clampf(k, 0.10, ComfortProfile.MAX_REACH_FACTOR_K)
	var z_hit := clamped_k * reach_forward_m
	var v_a := (z0_m - z_hit) / maxf(0.05, t_lead_s)
	return {
		"z_hit": z_hit,
		"v_a": v_a,
		"z0": z0_m,
		"t_lead": t_lead_s
	}

static func board_smash_is_valid_strike(
	curr_local_pos: Vector3,
	hand_speed_mps: float,
	pattern: String = "front",
	min_ext_z: float = 0.22,
	min_speed: float = 0.25
) -> bool:
	if curr_local_pos.z < min_ext_z - 1e-5:
		return false
	if hand_speed_mps < min_speed - 1e-5:
		return false
	if pattern == "uppercut" and curr_local_pos.y < 0.02 - 1e-5:
		return false
	return true

static func board_smash_is_solid_hit(hand_speed_mps: float, v_solid_mps: float = 0.45) -> bool:
	return hand_speed_mps >= v_solid_mps - 1e-6

# ==============================================================================
# 2. Wide Split (Chest Opener & Upper Back — Scapular Plane Twin Boards)
# ==============================================================================
static func wide_split_compute_targets(
	shoulder_width_m: float,
	arm_length_m: float,
	k: float,
	scapular_deg: float = 20.0
) -> Dictionary:
	var clamped_k := clampf(k, 0.10, ComfortProfile.MAX_REACH_FACTOR_K)
	var r := clamped_k * arm_length_m
	var scap_rad := deg_to_rad(clampf(scapular_deg, 10.0, 40.0))
	var half_w := clampf(shoulder_width_m * 0.5, 0.14, 0.28)
	var x_mag := half_w + r * cos(scap_rad) * 0.65
	var z_pos := maxf(0.28, r * sin(scap_rad) + 0.20)
	return {
		"left_pos": Vector3(-x_mag, 0.06, z_pos),
		"right_pos": Vector3(x_mag, 0.06, z_pos),
		"target_span": x_mag * 2.0
	}

static func wide_split_evaluate(
	left_local: Vector3,
	right_local: Vector3,
	currently_primed: bool,
	chest_prime_gap_m: float = 0.34,
	split_target_span_m: float = 0.72,
	hand_mode: int = ZenoEnums.HandMode.BOTH_HANDS
) -> Dictionary:
	if hand_mode == ZenoEnums.HandMode.LEFT_ONLY:
		var in_center_l := absf(left_local.x) <= chest_prime_gap_m * 0.65 and left_local.z >= 0.15
		var primed_l := currently_primed or in_center_l
		var done_l := primed_l and left_local.x <= -(split_target_span_m * 0.5)
		return {"primed": primed_l, "in_center": in_center_l, "split_complete": done_l, "span_m": absf(left_local.x) * 2.0}
	if hand_mode == ZenoEnums.HandMode.RIGHT_ONLY:
		var in_center_r := absf(right_local.x) <= chest_prime_gap_m * 0.65 and right_local.z >= 0.15
		var primed_r := currently_primed or in_center_r
		var done_r := primed_r and right_local.x >= (split_target_span_m * 0.5)
		return {"primed": primed_r, "in_center": in_center_r, "split_complete": done_r, "span_m": absf(right_local.x) * 2.0}

	var span := absf(right_local.x - left_local.x)
	var in_center := span <= chest_prime_gap_m + 1e-5 and left_local.z >= 0.15 and right_local.z >= 0.15
	var primed := currently_primed or in_center
	var split_complete := primed and span >= split_target_span_m - 1e-5
	return {
		"primed": primed,
		"in_center": in_center,
		"split_complete": split_complete,
		"span_m": span
	}

# ==============================================================================
# 3. Sky Reach (Diagonal Overhead Reach <= 45 deg Gaze Elevation)
# ==============================================================================
static func sky_reach_placement(
	arm_length_m: float,
	k: float,
	requested_phi_deg: float,
	shoulder_local_spec: Vector3 = Vector3(0.20, 0.12, 0.0),
	y_eye_m: float = 0.25,
	max_gaze_elevation_deg: float = 45.0
) -> Dictionary:
	var clamped_k := clampf(k, 0.10, ComfortProfile.MAX_REACH_FACTOR_K)
	var r := clamped_k * arm_length_m
	var phi_deg := clampf(requested_phi_deg, 10.0, 55.0)
	var y := 0.0
	var z := 0.0
	var gaze_deg := 0.0

	while phi_deg >= 5.0:
		var phi_rad := deg_to_rad(phi_deg)
		y = shoulder_local_spec.y + r * sin(phi_rad)
		z = shoulder_local_spec.z + r * cos(phi_rad)
		gaze_deg = rad_to_deg(atan2(y - y_eye_m, maxf(0.01, z)))
		if gaze_deg <= max_gaze_elevation_deg + 1e-4:
			break
		phi_deg -= 1.0

	return {
		"position": Vector3(shoulder_local_spec.x, y, z),
		"x": shoulder_local_spec.x,
		"y": y,
		"z": z,
		"r": r,
		"phi_deg": phi_deg,
		"gaze_elevation_deg": gaze_deg
	}

# ==============================================================================
# 4. Orbit Flow (Shoulder Circles — Signed Angle & Cadence Band)
# ==============================================================================
static func orbit_flow_evaluate_signed(
	prev_angle_rad: float,
	curr_angle_rad: float,
	hand_yz: Vector2,
	center_yz: Vector2,
	target_dir_sign: float = 1.0,
	min_radius_m: float = 0.12
) -> Dictionary:
	var radius := hand_yz.distance_to(center_yz)
	var radius_ok := radius >= min_radius_m - 1e-5
	var delta_rad := wrapf(curr_angle_rad - prev_angle_rad, -PI, PI)
	var signed_delta := delta_rad * (1.0 if target_dir_sign >= 0.0 else -1.0)
	var effective_delta := signed_delta if radius_ok else 0.0
	return {
		"radius_m": radius,
		"radius_ok": radius_ok,
		"signed_delta_rad": signed_delta,
		"effective_delta_rad": effective_delta
	}

static func orbit_flow_cadence(
	measured_f_hz: float,
	f_target_hz: float = 0.75,
	radius_r_m: float = 0.18,
	band_tolerance_ratio: float = 0.25
) -> Dictionary:
	var deviation_ratio := absf(measured_f_hz - f_target_hz) / maxf(0.01, f_target_hz)
	var in_band := deviation_ratio <= band_tolerance_ratio + 1e-6
	var hand_speed_v := TAU * radius_r_m * f_target_hz
	return {
		"deviation_ratio": deviation_ratio,
		"in_band": in_band,
		"target_hand_speed_mps": hand_speed_v
	}

# ==============================================================================
# 5. Wrist Twist (Anti-RSI Forearm Steady + Wrist Roll)
# ==============================================================================
static func wrist_twist_evaluate(
	hand_local: Vector3,
	anchor_local: Vector3,
	roll_deg: float,
	target_deg: float,
	anchor_radius_m: float = 0.20,
	tol_deg: float = 14.0
) -> Dictionary:
	var dist := hand_local.distance_to(anchor_local)
	var in_zone := dist <= anchor_radius_m + 1e-5
	var err_deg := absf(wrapf(roll_deg - target_deg, -180.0, 180.0))
	var angle_reached := in_zone and err_deg <= tol_deg + 1e-5
	return {
		"in_zone": in_zone,
		"angle_reached": angle_reached,
		"error_deg": err_deg,
		"dist_m": dist
	}

# ==============================================================================
# 6. Torso Twist (Seated Spinal Twist — Chest Guard + Head-Hand Sync)
# ==============================================================================
static func torso_twist_target(
	max_side_deg: float,
	k: float,
	side_sign: float = 1.0,
	distance_d_m: float = 1.25,
	hard_cap_deg: float = 55.0
) -> Dictionary:
	var clamped_k := clampf(k, 0.10, ComfortProfile.MAX_REACH_FACTOR_K)
	var psi_mag_deg := minf(clamped_k * absf(max_side_deg), hard_cap_deg)
	var psi_t_deg := side_sign * psi_mag_deg
	var psi_rad := deg_to_rad(psi_t_deg)
	var x := distance_d_m * sin(psi_rad)
	var z := distance_d_m * cos(psi_rad)
	return {
		"psi_t_deg": psi_t_deg,
		"psi_mag_deg": psi_mag_deg,
		"x": x,
		"z": z,
		"position": Vector3(x, 0.0, z)
	}

static func torso_twist_evaluate(
	left_local: Vector3,
	right_local: Vector3,
	head_fwd_local: Vector3,
	target_yaw_deg: float,
	guard_radius_m: float = 0.32,
	yaw_tol_deg: float = 8.0,
	head_sync_tol_deg: float = 22.0,
	hand_mode: int = ZenoEnums.HandMode.BOTH_HANDS
) -> Dictionary:
	var left_ok := (hand_mode == ZenoEnums.HandMode.RIGHT_ONLY) or (left_local.distance_to(Vector3.ZERO) <= guard_radius_m + 1e-5)
	var right_ok := (hand_mode == ZenoEnums.HandMode.LEFT_ONLY) or (right_local.distance_to(Vector3.ZERO) <= guard_radius_m + 1e-5)
	var hands_in_guard := left_ok and right_ok

	var mid := left_local if hand_mode == ZenoEnums.HandMode.LEFT_ONLY else (
		right_local if hand_mode == ZenoEnums.HandMode.RIGHT_ONLY else (left_local + right_local) * 0.5
	)
	var aim_yaw_deg := rad_to_deg(atan2(mid.x, maxf(0.001, mid.z)))
	var head_yaw_deg := rad_to_deg(atan2(head_fwd_local.x, maxf(0.001, head_fwd_local.z)))
	var head_synced := absf(head_yaw_deg - aim_yaw_deg) <= head_sync_tol_deg + 1e-5
	var yaw_err := absf(aim_yaw_deg - target_yaw_deg)
	var aim_locked := hands_in_guard and head_synced and yaw_err <= yaw_tol_deg + 1e-5
	return {
		"hands_in_guard": hands_in_guard,
		"head_synced": head_synced,
		"aim_locked": aim_locked,
		"aim_yaw_deg": aim_yaw_deg,
		"head_yaw_deg": head_yaw_deg
	}

# ==============================================================================
# 7. Horizon Gaze (Gentle Neck Mobility <= 60 deg/s, Pitch <= 20 deg)
# ==============================================================================
static func horizon_gaze_step(
	current_dwell_s: float,
	yaw_err_deg: float,
	pitch_deg: float,
	head_angular_speed_deg_s: float,
	dt: float,
	yaw_tolerance_deg: float = 5.0,
	max_pitch_deg: float = 20.0,
	max_head_speed_deg_s: float = 60.0,
	required_dwell_s: float = 1.0
) -> Dictionary:
	var new_dwell := current_dwell_s
	var show_slower_cue := false
	var paused_dwell := false
	var on_target := absf(yaw_err_deg) <= yaw_tolerance_deg + 1e-5 and absf(pitch_deg) <= max_pitch_deg + 1e-5

	if head_angular_speed_deg_s > max_head_speed_deg_s + 1e-5:
		# Pauses dwell without resetting so user learns smooth neck pace
		paused_dwell = true
		show_slower_cue = true
	elif on_target:
		new_dwell += dt
	else:
		new_dwell = maxf(0.0, current_dwell_s - dt * 0.5)

	var scan_complete := new_dwell >= required_dwell_s - 1e-5
	return {
		"dwell_s": new_dwell,
		"paused": paused_dwell,
		"show_slower_cue": show_slower_cue,
		"on_target": on_target,
		"scan_complete": scan_complete
	}
