class_name MechanicsMath
extends RefCounted

## Pure mathematical formulas and evaluators for all 10 ZenoFit mechanics (M01–M10).
## Matches 03-m01 through 12-m10 and 16-acceptance-tests.md (AT-01, AT-02, AT-03, AT-12, AT-19..AT-25).

# ==============================================================================
# §6.1 M01 — Seated Boxing ("Asteroid Brawler") [AT-01, AT-12]
# ==============================================================================
static func m01_compute_asteroid_params(
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

static func m01_is_solid_hit(hand_speed_mps: float, v_solid_mps: float = 0.30, touch_mode: bool = false) -> bool:
	if touch_mode:
		return true
	return hand_speed_mps >= v_solid_mps - 1e-6

# ==============================================================================
# §6.2 M02 — Overhead Reach ("Fruit Harvester") [AT-03]
# ==============================================================================
static func m02_compute_fruit_placement(
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

	# Reduce phi if gaze elevation exceeds max_gaze_elevation_deg (45°) (AT-03)
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
# §6.3 M03 — Side Arm Raise ("Glider Pilot") [AT-02]
# ==============================================================================
static func m03_compute_wing_target_offset(
	arm_length_m: float,
	k: float,
	theta_deg: float,
	hand: int
) -> Vector2:
	var clamped_k := clampf(k, 0.10, ComfortProfile.MAX_REACH_FACTOR_K)
	var clamped_theta := clampf(theta_deg, 0.0, 90.0)
	var r := clamped_k * arm_length_m
	var rad := deg_to_rad(clamped_theta)
	var sign_x := -1.0 if hand == ZenoEnums.Hand.LEFT else 1.0
	var hand_x := sign_x * r * sin(rad)
	var hand_y := -r * cos(rad)
	return Vector2(hand_x, hand_y)

static func m03_compute_steering(
	left_hand_spec: Vector3,
	right_hand_spec: Vector3,
	steering_gain_k: float = 0.10
) -> Dictionary:
	var dx := maxf(0.05, right_hand_spec.x - left_hand_spec.x)
	var dy := right_hand_spec.y - left_hand_spec.y
	var roll_deg := rad_to_deg(atan2(dy, dx))
	var v_lat := steering_gain_k * roll_deg
	return {
		"roll_deg": roll_deg,
		"v_lat": v_lat
	}

# ==============================================================================
# §6.4 M04 — Trunk Twist ("Turret Gunner") [AT-19]
# ==============================================================================
static func m04_compute_turret_target(
	psi_max_side_deg: float,
	k: float,
	side_sign: float = 1.0, # +1 right, -1 left, or magnitude if caller inspects abs
	distance_d_m: float = 1.5,
	hard_cap_deg: float = 60.0
) -> Dictionary:
	var clamped_k := clampf(k, 0.10, ComfortProfile.MAX_REACH_FACTOR_K)
	var psi_mag_deg := minf(clamped_k * absf(psi_max_side_deg), hard_cap_deg)
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

static func m04_compute_aim_yaw_deg(mid_local_spec: Vector3) -> float:
	return rad_to_deg(atan2(mid_local_spec.x, maxf(0.001, mid_local_spec.z)))

static func m04_is_aim_locked(aim_yaw_deg: float, target_yaw_deg: float, tolerance_deg: float = 6.0) -> bool:
	return absf(aim_yaw_deg - target_yaw_deg) <= tolerance_deg + 1e-5

# ==============================================================================
# §6.5 M05 — Seated Row ("Cosmic Tug-of-War") [AT-20]
# ==============================================================================
static func m05_compute_row_params(
	reach_forward_m: float,
	k: float,
	debris_distance_d_m: float = 1.0,
	target_strokes_n: int = 7,
	z_end_m: float = 0.15
) -> Dictionary:
	var clamped_k := clampf(k, 0.10, ComfortProfile.MAX_REACH_FACTOR_K)
	var z_start := clamped_k * reach_forward_m
	var s := maxf(0.02, z_start - z_end_m)
	var g := minf(1.0, debris_distance_d_m / (float(maxi(1, target_strokes_n)) * s))
	var progress_per_stroke := g * s
	return {
		"z_start": z_start,
		"z_end": z_end_m,
		"stroke_length_s": s,
		"gain_g": g,
		"progress_per_stroke": progress_per_stroke
	}

# ==============================================================================
# §6.6 M06 — Forward Press ("Force Blast") [AT-21]
# ==============================================================================
static func m06_compute_plane_z(
	reach_left_m: float,
	reach_right_m: float,
	k: float,
	two_hand_mode: bool = true
) -> float:
	var clamped_k := clampf(k, 0.10, ComfortProfile.MAX_REACH_FACTOR_K)
	var base_reach := minf(reach_left_m, reach_right_m) if two_hand_mode else maxf(reach_left_m, reach_right_m)
	return clamped_k * base_reach

static func m06_compute_charge_and_points(
	t_hold_s: float,
	t_full_s: float = 2.0,
	is_synchronized: bool = false,
	sync_bonus: int = 25
) -> Dictionary:
	var charge := clampf(t_hold_s / maxf(0.1, t_full_s), 0.0, 1.0)
	var base_pts := int(round(100.0 * charge))
	var total_pts := base_pts + (sync_bonus if is_synchronized else 0)
	return {
		"charge": charge,
		"base_points": base_pts,
		"total_points": total_pts
	}

# ==============================================================================
# §6.7 M07 — Arm Circles ("Shield Generator Crank") [AT-22]
# ==============================================================================
static func m07_evaluate_crank(
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
# §6.8 M08 — Neck Mobility and Far Focus ("Recon Scanner") [AT-23]
# ==============================================================================
static func m08_step_scan_dwell(
	current_dwell_s: float,
	reticle_error_deg: float,
	head_angular_speed_deg_s: float,
	dt: float,
	reticle_tolerance_deg: float = 3.0,
	max_head_speed_deg_s: float = 60.0,
	required_dwell_s: float = 1.0
) -> Dictionary:
	var new_dwell := current_dwell_s
	var show_slower_cue := false
	var paused_dwell := false

	if reticle_error_deg <= reticle_tolerance_deg + 1e-5:
		if head_angular_speed_deg_s <= max_head_speed_deg_s + 1e-5:
			new_dwell += dt
		else:
			# Case study & AT-23: If user turns > 60 deg/s, dwell timer PAUSES (does not reset) and "slower" cue shows
			paused_dwell = true
			show_slower_cue = true
	else:
		if head_angular_speed_deg_s > max_head_speed_deg_s + 1e-5:
			paused_dwell = true
			show_slower_cue = true
		else:
			new_dwell = maxf(0.0, current_dwell_s - dt * 0.5)

	var scan_complete := new_dwell >= required_dwell_s - 1e-5
	return {
		"dwell_s": new_dwell,
		"paused": paused_dwell,
		"show_slower_cue": show_slower_cue,
		"scan_complete": scan_complete
	}

# ==============================================================================
# §6.9 M09 — Elbow Flexion and Wrist Pour ("Potion Brewer") [AT-24]
# ==============================================================================
static func m09_compute_curl_distances(arm_length_m: float) -> Dictionary:
	return {
		"d_curl": 0.35 * arm_length_m,
		"d_ext": 0.85 * arm_length_m
	}

static func m09_compute_visual_drag(
	dt: float,
	tau_s: float = 0.20,
	hand_speed_mps: float = 0.50
) -> Dictionary:
	var alpha := 1.0 - exp(-dt / maxf(0.001, tau_s))
	var steady_lag_m := hand_speed_mps * tau_s
	return {
		"gap_closure_ratio": alpha,
		"gap_closure_percent": alpha * 100.0,
		"steady_lag_m": steady_lag_m
	}

# ==============================================================================
# §6.10 M10 — Overhead Reach with Side Bend ("Laser Evader") [AT-25]
# ==============================================================================
static func m10_compute_gap_and_evaluate(
	delta_x_max_side_m: float,
	k: float,
	x_head_m: float,
	side_sign: float = 1.0,
	gap_cap_m: float = 0.25,
	success_tolerance_m: float = 0.08
) -> Dictionary:
	var clamped_k := clampf(k, 0.10, ComfortProfile.MAX_REACH_FACTOR_K)
	var gap_mag := minf(clamped_k * absf(delta_x_max_side_m), gap_cap_m)
	var gap_centre := side_sign * gap_mag
	var lean_pause_threshold := minf(absf(delta_x_max_side_m) + 0.05, 0.30)
	var in_gap := absf(x_head_m - gap_centre) <= success_tolerance_m + 1e-5
	var within_safe_lean := absf(x_head_m) < lean_pause_threshold - 1e-5
	return {
		"gap_centre": gap_centre,
		"lean_pause_threshold": lean_pause_threshold,
		"in_gap": in_gap,
		"within_safe_lean": within_safe_lean,
		"success": in_gap and within_safe_lean
	}
