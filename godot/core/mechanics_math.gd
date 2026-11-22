class_name MechanicsMath
extends RefCounted

## Pure mathematical formulas and evaluators for all 10 ZenoFit mechanics (M01–M10).
## Matches 03-m01 through 12-m10 and 16-acceptance-tests.md (AT-01, AT-02, AT-03, AT-12, AT-19..AT-25).

# ==============================================================================
# §6.1 M01 — Seated Boxing ("Makiwara Strikes") [AT-01, AT-12]
# ==============================================================================
static func m01_compute_makiwara_params(
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
# §6.2 M02 — Overhead Reach ("Sakura Catch") [AT-03]
# ==============================================================================
static func m02_compute_petal_placement(
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
# §6.3 M03 — Side Arm Raise ("Crane Wings") [AT-02]
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
# §6.4 M04 — Trunk Twist ("Bokken Guard") [AT-19]
# ==============================================================================
static func m04_compute_guard_target(
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
# §6.5 M05 — Seated Row ("Temple Bell Pull") [AT-20]
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
# §6.6 M06 — Forward Press ("Ki Palm Push") [AT-21]
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
# §6.7 M07 — Arm Circles ("Zen Water Wheel") [AT-22]
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
# §6.8 M08 — Neck Mobility and Far Focus ("Zen Horizon Watch") [AT-23]
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
# §6.9 M09 — Elbow Flexion and Wrist Pour ("Tea Ceremony Pour") [AT-24]
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
# §6.10 M10 — Overhead Reach with Side Bend ("Bamboo Sway") [AT-25]
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

# ==============================================================================
# v0.4 Anti-Cheat Kinematics Validation [AT-29 .. AT-34]
# ==============================================================================

## AT-29 (M01 Makiwara Strikes): Forward extension threshold + forward velocity vector.
static func m01_is_valid_punch(
	curr_hand_local_z: float,
	hand_fwd_speed_mps: float,
	origin_z_m: float = 0.0,
	min_ext_z_m: float = 0.25,
	v_min_mps: float = 0.25,
	touch_mode: bool = false
) -> bool:
	var forward_ext := curr_hand_local_z - origin_z_m
	if forward_ext < min_ext_z_m - 1e-5:
		return false
	if touch_mode:
		return true
	return hand_fwd_speed_mps >= v_min_mps - 1e-5

## AT-30 (M03 Crane Wings): Enforces full wingspan + shoulder-height elevation before steering.
static func m03_evaluate_wings_and_steering(
	left_hand_local: Vector3,
	right_hand_local: Vector3,
	shoulder_y_local: float,
	min_span_m: float,
	k_wing_span: float = 0.70,
	k_wing_height: float = 0.05,
	steering_gain_k: float = 0.10
) -> Dictionary:
	var span := absf(right_hand_local.x - left_hand_local.x)
	var min_required_span := k_wing_span * maxf(0.25, min_span_m)
	var span_ok := span >= min_required_span - 1e-5
	var min_y := shoulder_y_local + k_wing_height
	var height_ok := left_hand_local.y >= min_y - 1e-5 and right_hand_local.y >= min_y - 1e-5
	var wings_deployed := span_ok and height_ok
	var steer := m03_compute_steering(left_hand_local, right_hand_local, steering_gain_k)
	var v_lat := float(steer.get("v_lat", 0.0)) if wings_deployed else 0.0
	var roll_deg := float(steer.get("roll_deg", 0.0)) if wings_deployed else 0.0
	return {
		"wings_deployed": wings_deployed,
		"span_ok": span_ok,
		"height_ok": height_ok,
		"span_m": span,
		"v_lat": v_lat,
		"roll_deg": roll_deg,
		"steering": v_lat,
		"height_diff_m": right_hand_local.y - left_hand_local.y
	}

## AT-31 (M04 Bokken Guard): Both hands stay inside chest guard sphere so lateral arm swing cannot fake trunk twist.
static func m04_is_valid_torso_aim(
	left_hand_local: Vector3,
	right_hand_local: Vector3,
	chest_center_local: Vector3 = Vector3.ZERO,
	guard_radius_m: float = 0.32
) -> Dictionary:
	var dist_l := left_hand_local.distance_to(chest_center_local)
	var dist_r := right_hand_local.distance_to(chest_center_local)
	var in_guard := dist_l <= guard_radius_m + 1e-5 and dist_r <= guard_radius_m + 1e-5
	var mid := (left_hand_local + right_hand_local) * 0.5
	var aim_yaw := m04_compute_aim_yaw_deg(mid)
	return {
		"hands_in_guard": in_guard,
		"left_dist_m": dist_l,
		"right_dist_m": dist_r,
		"aim_yaw_deg": aim_yaw
	}

## AT-32 (M05 Temple Bell Pull): Bilateral pull validation in BOTH_HANDS mode so single-hand pull yields 0 progress.
static func m05_step_bilateral_row(
	left_z: float,
	prev_left_z: float,
	right_z: float,
	prev_right_z: float,
	reach_forward_m: float,
	gain_g: float,
	hand_mode: int = ZenoEnums.HandMode.BOTH_HANDS
) -> Dictionary:
	var pull_l := maxf(0.0, prev_left_z - left_z)
	var pull_r := maxf(0.0, prev_right_z - right_z)
	var pull_z := 0.0
	var bilateral_valid := true
	if hand_mode == ZenoEnums.HandMode.LEFT_ONLY:
		pull_z = pull_l
	elif hand_mode == ZenoEnums.HandMode.RIGHT_ONLY:
		pull_z = pull_r
	else:
		# Strict bilateral coordination: minimum pull between both hands must be positive
		pull_z = minf(pull_l, pull_r)
		bilateral_valid = pull_l > 1e-4 and pull_r > 1e-4
	var stroke_norm := clampf(pull_z / maxf(0.25, reach_forward_m - 0.15), 0.0, 1.0)
	var rope_advance_m := pull_z * gain_g
	return {
		"bilateral_valid": bilateral_valid,
		"effective_pull_m": pull_z,
		"rope_advance_m": rope_advance_m,
		"stroke_norm": stroke_norm
	}

## AT-33 (M06 Ki Palm Push): Retract-before-charge hysteresis prevents static holding from chain-scoring.
static func m06_check_retract_hysteresis(
	currently_ready: bool,
	left_z: float,
	right_z: float,
	chest_z: float = 0.0,
	z_plane: float = 0.40,
	retract_ratio: float = 0.35,
	two_hand_mode: bool = true,
	left_enabled: bool = true,
	right_enabled: bool = true
) -> Dictionary:
	var z_retract := chest_z + retract_ratio * maxf(0.10, z_plane - chest_z)
	var left_retracted := (not left_enabled) or left_z <= z_retract + 1e-5
	var right_retracted := (not right_enabled) or right_z <= z_retract + 1e-5
	var hands_retracted := left_retracted and right_retracted
	var ready := currently_ready or hands_retracted

	var at_plane := false
	if two_hand_mode and left_enabled and right_enabled:
		at_plane = left_z >= z_plane - 0.03 and right_z >= z_plane - 0.03
	elif left_enabled and (not right_enabled or not two_hand_mode):
		at_plane = left_z >= z_plane - 0.03 or (right_enabled and right_z >= z_plane - 0.03)
	elif right_enabled:
		at_plane = right_z >= z_plane - 0.03

	return {
		"ready_to_charge": ready,
		"hands_retracted": hands_retracted,
		"hands_at_plane": at_plane and ready,
		"z_retract": z_retract
	}

## AT-34 (M07 Zen Water Wheel): Enforces signed crank progress & minimum orbit radius so tiny wrist oscillations do not advance loops.
static func m07_evaluate_signed_crank(
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

## M09 (Tea Ceremony Pour): Requires reach->curl completion before pouring via wrist roll (>= 60 deg).
static func m09_can_pour(
	hand_local: Vector3,
	shoulder_local: Vector3,
	d_curl: float,
	was_curled: bool,
	roll_deg: float,
	pour_thresh_deg: float = 60.0
) -> bool:
	var dist := hand_local.distance_to(shoulder_local)
	var in_curl_zone := dist <= d_curl + 0.08
	return was_curled and in_curl_zone and absf(roll_deg) >= pour_thresh_deg - 1e-4

## M10 (Bamboo Sway): Requires active hands to stay lifted near the overhead bamboo rail during side bend.
static func m10_are_hands_on_rail(
	left_hand_local: Vector3,
	right_hand_local: Vector3,
	rail_local: Vector3,
	left_enabled: bool = true,
	right_enabled: bool = true,
	yz_tolerance_m: float = 0.24
) -> bool:
	var l_ok := (not left_enabled) or (absf(left_hand_local.y - rail_local.y) <= yz_tolerance_m and absf(left_hand_local.z - rail_local.z) <= yz_tolerance_m)
	var r_ok := (not right_enabled) or (absf(right_hand_local.y - rail_local.y) <= yz_tolerance_m and absf(right_hand_local.z - rail_local.z) <= yz_tolerance_m)
	return l_ok and r_ok
