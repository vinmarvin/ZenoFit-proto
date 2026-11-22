class_name ZenoAcceptanceSuite
extends RefCounted

## Automated Acceptance Test Suite for ZenoFit (Godot 4.7).
## Verifies SpecSpace (§3.1) + AT-01 through AT-16 and AT-19 through AT-28 from
## MarkdownGuideForAIReconstruction/16-acceptance-tests.md using the EXACT spec numbers.

var passed_count: int = 0
var failed_count: int = 0
var results_log: Array[String] = []

func _assert_near(test_id: String, actual: float, expected: float, tol: float, label: String) -> void:
	if absf(actual - expected) <= tol:
		passed_count += 1
		results_log.append("[PASS] %s (%s): actual=%.4f, expected=%.4f (±%.4f)" % [test_id, label, actual, expected, tol])
	else:
		failed_count += 1
		results_log.append("[FAIL] %s (%s): actual=%.4f, expected=%.4f (±%.4f)" % [test_id, label, actual, expected, tol])

func _assert_true(test_id: String, cond: bool, label: String) -> void:
	if cond:
		passed_count += 1
		results_log.append("[PASS] %s (%s)" % [test_id, label])
	else:
		failed_count += 1
		results_log.append("[FAIL] %s (%s)" % [test_id, label])

func run_all() -> Dictionary:
	passed_count = 0
	failed_count = 0
	results_log.clear()

	test_spec_space_conversions()
	test_at01_makiwara_strikes()
	test_at02_crane_wings()
	test_at03_sakura_catch()
	test_at04_obstacle_exclusion()
	test_at05_tempo_interval()
	test_at06_adaptive_tempo_sequence()
	test_at07_single_hit_points()
	test_at08_five_target_case_study_and_combo()
	test_at09_auto_pause_lap()
	test_at10_lean_warning_and_m10_override()
	test_at11_disabled_right_hand()
	test_at12_seated_boxing_solid_vs_light()
	test_at13_segment_hit_anti_tunnelling()
	test_at14_manual_menu_pause_immediate()
	test_at15_json_persistence_and_quick_calibration()
	test_at16_recenter_pauses_and_requests_confirmation()
	test_at19_bokken_guard_trunk_twist()
	test_at20_temple_bell_pull_row()
	test_at21_ki_palm_push_forward_press()
	test_at22_zen_water_wheel_arm_circles()
	test_at23_zen_horizon_watch_neck_mobility()
	test_at24_tea_ceremony_pour_curl_and_drag()
	test_at25_bamboo_sway_side_bend()
	test_at26_score_attack_balanced_draw_and_no_trunk()
	test_at27_combo_multiplier_formula()
	test_at28_decline_stable_chair_substitutes_level_a()
	test_at29_m01_punch_anti_cheat()
	test_at30_m03_crane_wings_anti_cheat()
	test_at31_m04_bokken_guard_chest_anti_cheat()
	test_at32_m05_temple_bell_bilateral_anti_cheat()
	test_at33_m06_ki_palm_retract_hysteresis()
	test_at34_m07_water_wheel_signed_orbit_anti_cheat()
	test_at35_dojo_rank_personal_best_no_belts()
	test_v04_flow_routines_chair_check_and_fov_lap()
	test_v04_zen_dojo_environment_glb_and_scripts()
	test_integration_all_10_mechanics_and_mascot()

	return {
		"passed": passed_count,
		"failed": failed_count,
		"log": results_log
	}

func test_spec_space_conversions() -> void:
	# 03-godot-build.md §3.1: z=+0.51 in spec -> z=-0.51 in Godot; psi_max_R=+40° -> -40° in Godot
	var p_godot := SpecSpace.to_godot(Vector3(0.10, 0.20, 0.51))
	_assert_near("SPEC-SPACE-Z", p_godot.z, -0.51, 0.0001, "Spec +0.51 m forward maps to Godot -0.51 m")
	var yaw_godot_deg := SpecSpace.yaw_deg_to_godot_deg(40.0)
	_assert_near("SPEC-SPACE-YAW", yaw_godot_deg, -40.0, 0.0001, "Spec +40 deg right turn maps to Godot -40 deg")

func test_at01_makiwara_strikes() -> void:
	# AT-01: Given R_f = 0.60, k = 0.85, z0 = 1.5, t_lead = 1.0 -> z_hit = 0.51 ± 0.001, v_a = 0.99 ± 0.001
	var p1 := MechanicsMath.m01_compute_makiwara_params(0.60, 0.85, 1.5, 1.0)
	_assert_near("AT-01", float(p1["z_hit"]), 0.51, 0.001, "z_hit for R_f=0.60, k=0.85")
	_assert_near("AT-01", float(p1["v_a"]), 0.99, 0.001, "v_a for R_f=0.60, k=0.85")
	var p_rani := MechanicsMath.m01_compute_makiwara_params(0.42, 0.75, 1.5, 1.0)
	_assert_near("AT-01", float(p_rani["v_a"]), 1.185, 0.001, "Rani v_R for R_f,R=0.42, k=0.75")

func test_at02_crane_wings() -> void:
	# AT-02: Given L_arm = 0.60, k = 0.85, theta = 60° -> x = 0.442 ± 0.001, y = -0.255 ± 0.001
	var offset := MechanicsMath.m03_compute_wing_target_offset(0.60, 0.85, 60.0, ZenoEnums.Hand.RIGHT)
	_assert_near("AT-02", offset.x, 0.442, 0.001, "Crane Wings x offset")
	_assert_near("AT-02", offset.y, -0.255, 0.001, "Crane Wings y offset")
	var steer := MechanicsMath.m03_compute_steering(Vector3(-0.50, 0.0, 0.40), Vector3(0.50, 0.10, 0.40), 0.10)
	_assert_near("AT-02", float(steer["roll_deg"]), 5.7, 0.1, "Crane Wings roll_deg")
	_assert_near("AT-02", float(steer["v_lat"]), 0.57, 0.01, "Crane Wings v_lat")

func test_at03_sakura_catch() -> void:
	# AT-03: Given L_arm = 0.60, k = 0.85, phi = 45°, shoulder y = 0.12 -> y = 0.481 ± 0.002, z = 0.361 ± 0.002, gaze = 32.6° ± 0.2
	var res := MechanicsMath.m02_compute_petal_placement(0.60, 0.85, 45.0, Vector3(0.20, 0.12, 0.0), 0.25, 45.0)
	_assert_near("AT-03", float(res["y"]), 0.481, 0.002, "Sakura petal y")
	_assert_near("AT-03", float(res["z"]), 0.361, 0.002, "Sakura petal z")
	_assert_near("AT-03", float(res["gaze_elevation_deg"]), 32.6, 0.2, "Sakura gaze elevation deg")
	# If gaze > 45° the spawner reduces phi
	var high_res := MechanicsMath.m02_compute_petal_placement(0.60, 0.85, 55.0, Vector3(0.20, 0.30, 0.0), 0.25, 45.0)
	_assert_true("AT-03", float(high_res["gaze_elevation_deg"]) <= 45.0 + 1e-3, "Gaze elevation clamped <= 45 deg")

func test_at04_obstacle_exclusion() -> void:
	var profile := ComfortProfile.create_default()
	var obs := Vector3(0.0, 0.0, 0.45)
	profile.obstacles.append(obs)
	var r_ex := 0.12
	var target_r := 0.10
	_assert_true("AT-04", profile.is_violating_obstacle_zone(obs, target_r, r_ex), "Candidate at obstacle center is rejected")
	var resolved := profile.resolve_obstacle_free_position(obs, target_r, r_ex, 16)
	_assert_true("AT-04", bool(resolved["valid"]), "Spawner resolves obstacle-free position")
	var pos: Vector3 = resolved["position"]
	_assert_true("AT-04", pos.distance_to(obs) >= r_ex + target_r - 1e-4, "Resolved position is outside r_ex + targetRadius")

func test_at05_tempo_interval() -> void:
	_assert_near("AT-05", AdaptiveTempo.get_beat_interval_seconds(60.0), 1.0, 0.0001, "BPM 60 -> 1.0 s")
	_assert_near("AT-05", AdaptiveTempo.get_beat_interval_seconds(75.0), 0.8, 0.0001, "BPM 75 -> 0.8 s")

func test_at06_adaptive_tempo_sequence() -> void:
	var tempo := AdaptiveTempo.new(60.0, 80.0, 8)
	_assert_near("AT-06", tempo.evaluate_window(7, 8), 65.0, 0.001, "87.5% -> 65 BPM")
	_assert_near("AT-06", tempo.evaluate_window(6, 8), 65.0, 0.001, "75.0% -> hold 65 BPM")
	_assert_near("AT-06", tempo.evaluate_window(4, 8), 60.0, 0.001, "50.0% -> 60 BPM")

func test_at07_single_hit_points() -> void:
	var pts := ZenoScoring.compute_base_hit_points(0.5, 2.0)
	_assert_near("AT-07", float(pts), 137.0, 0.001, "lifetime=2.0s, t_hit=0.5s -> 137 pts")

func test_at08_five_target_case_study_and_combo() -> void:
	var tracker := ZenoScoring.RoundScoreTracker.new()
	var lifetime := ZenoScoring.compute_lifetime_seconds(2, 60.0)
	tracker.record_hit(0.4, lifetime) # 140
	tracker.record_hit(1.0, lifetime) # base 125, combo floor(125*1.05)=131
	tracker.record_miss()             # 0
	tracker.record_hit(0.2, lifetime) # 145
	tracker.record_hit(1.8, lifetime) # base 105, combo floor(105*1.05)=110
	_assert_near("AT-08", float(tracker.base_total_score), 515.0, 0.001, "Base total = 515")
	_assert_near("AT-08", tracker.get_accuracy_percent(), 80.0, 0.01, "Accuracy = 80%")
	_assert_near("AT-08", float(tracker.combo_total_score), 526.0, 0.001, "Combo round score = 526")

func test_at09_auto_pause_lap() -> void:
	var mon := SafetyMonitors.AutoPauseMonitor.new(0.15, 2.0)
	var lap := Vector3(0.0, -0.45, 0.20)
	var inside := Vector3(0.0, -0.45, 0.32) # 0.12 m <= 0.15 m
	var outside := Vector3(0.0, 0.0, 0.40)
	_assert_true("AT-09", not mon.evaluate(inside, outside, lap, 2.5), "One hand outside does not pause")
	_assert_true("AT-09", not mon.evaluate(inside, inside, lap, 1.0), "1.0 s in lap not paused yet")
	_assert_true("AT-09", mon.evaluate(inside, inside, lap, 1.0), "2.0 s both hands in lap pauses")

func test_at10_lean_warning_and_m10_override() -> void:
	var mon := SafetyMonitors.LeanMonitor.new(0.20, 0.50)
	_assert_true("AT-10", not mon.evaluate(0.12, 0.0, 0.60), "|Δx|=0.12 m for 0.6s -> no warning")
	_assert_true("AT-10", mon.evaluate(0.22, 0.0, 0.60), "|Δx|=0.22 m for 0.6s -> lean warning")
	var m10_thresh := SafetyMonitors.LeanMonitor.get_m10_override_threshold(0.20)
	_assert_near("AT-10", m10_thresh, 0.25, 0.001, "M10 threshold min(0.20+0.05, 0.30) = 0.25")

func test_at11_disabled_right_hand() -> void:
	var profile := ComfortProfile.create_default()
	profile.left_enabled = true
	profile.right_enabled = false
	var mode := profile.get_effective_hand_mode(ZenoEnums.HandMode.BOTH_HANDS)
	_assert_true("AT-11", mode == ZenoEnums.HandMode.LEFT_ONLY, "Disabled right hand forces LEFT_ONLY mode")
	var right_hit := ZenoGeometry.check_valid_hand_hit(
		ZenoEnums.Hand.RIGHT, profile.right_enabled, mode, ZenoEnums.TargetHand.LEFT,
		Vector3.ZERO, 0.10, Vector3.ZERO, Vector3.ZERO
	)
	_assert_true("AT-11", not right_hit, "Right controller is ignored when disabled")

func test_at12_seated_boxing_solid_vs_light() -> void:
	var solid := MechanicsMath.m01_is_solid_hit(0.40, 0.30, false)
	var light := MechanicsMath.m01_is_solid_hit(0.20, 0.30, false)
	_assert_true("AT-12", solid, "0.4 m/s >= 0.30 -> solid hit")
	_assert_true("AT-12", not light, "0.2 m/s < 0.30 -> light hit")
	var pts_solid := ZenoScoring.compute_base_hit_points(0.5, 2.0, solid)
	var pts_light := ZenoScoring.compute_base_hit_points(0.5, 2.0, light)
	_assert_true("AT-12", pts_solid == 162 and pts_light == 137, "Both score; solid adds +25 bonus")

func test_at13_segment_hit_anti_tunnelling() -> void:
	var centre := Vector3(0.0, 0.0, 0.45)
	var p0 := Vector3(0.02, 0.0, 0.20)
	var p1 := Vector3(0.02, 0.0, 0.70)
	var hit := ZenoGeometry.segment_hit(p0, p1, centre, 0.08, 0.04)
	_assert_true("AT-13", hit, "Fast hand crossing target in 1 frame registers segment hit without tunnelling")

func test_at14_manual_menu_pause_immediate() -> void:
	var flow := GameFlowController.new()
	flow.has_valid_calibration = true
	flow.settings["no_trunk_mode"] = true
	flow.begin_session()
	flow.advance_round_timer(4.1) # enter ROUND_PLAY
	var timer_before := flow.round_timer_s
	var paused := flow.pause_session(ZenoEnums.PauseReason.MANUAL, "Menu pressed")
	flow.advance_round_timer(1.0) # timer must not advance while paused
	_assert_true("AT-14", paused and flow.current_state == ZenoEnums.AppState.PAUSED, "Pauses within 1 frame")
	_assert_near("AT-14", flow.round_timer_s, timer_before, 0.0001, "Round timer frozen while paused")
	flow._exit_tree()
	flow.free()

func test_at15_json_persistence_and_quick_calibration() -> void:
	var temp_dir := "/tmp/zenofit_at15_" + str(Time.get_ticks_usec())
	DirAccess.make_dir_recursive_absolute(temp_dir)
	var svc := SaveServiceClass.new(temp_dir)
	var p := ComfortProfile.create_default()
	p.left_reach_forward_m = 0.55
	p.right_reach_forward_m = 0.42
	svc.save_calibration_profile(p)
	svc.append_session_record({"score": 526}, 10)

	var svc2 := SaveServiceClass.new(temp_dir)
	var loaded := svc2.try_load_calibration_profile()
	var sessions := svc2.load_recent_sessions(10)
	_assert_true("AT-15", bool(loaded["loaded"]) and sessions.size() == 1, "Saved profile & session history reload after restart")

	# Returning user quick check (GP-CAL-11) completes in 1 confirm step (<= 15 s)
	var cal := CalibrationController.new(loaded["profile"])
	cal.start_returning_user_quick_check()
	var done := cal.confirm_current_step(Vector3(0, 1.2, 0), Vector3(0, 0, 1), Vector3.ZERO, Vector3.ZERO)
	_assert_true("AT-15", done, "Returning user quick seat check finishes in 1 confirmation (<= 15 s)")
	svc.delete_all_saved_data()
	DirAccess.remove_absolute(temp_dir)
	svc.free()
	svc2.free()

func test_at16_recenter_pauses_and_requests_confirmation() -> void:
	var flow := GameFlowController.new()
	flow.has_valid_calibration = true
	flow.settings["no_trunk_mode"] = true
	flow.begin_session()
	flow.advance_round_timer(4.1)
	flow.pause_session(ZenoEnums.PauseReason.RECENTER_REQUIRED, "Sit comfortably and confirm")
	_assert_true(
		"AT-16",
		flow.current_state == ZenoEnums.AppState.PAUSED and flow.current_pause_reason == ZenoEnums.PauseReason.RECENTER_REQUIRED,
		"Recenter pauses round and requests seat re-confirmation"
	)
	flow._exit_tree()
	flow.free()

func test_at19_bokken_guard_trunk_twist() -> void:
	# AT-19: Given psi_max,L = 50°, k = 0.85 -> target yaw = 42.5°, x = 1.013 ± 0.002, z = 1.106 ± 0.002 at D = 1.5; aim 40° locks
	var info := MechanicsMath.m04_compute_guard_target(50.0, 0.85, 1.0, 1.5, 60.0)
	_assert_near("AT-19", float(info["psi_t_deg"]), 42.5, 0.01, "Bokken Guard target yaw = 42.5 deg")
	_assert_near("AT-19", float(info["x"]), 1.013, 0.002, "Bokken Guard target x = 1.013 m")
	_assert_near("AT-19", float(info["z"]), 1.106, 0.002, "Bokken Guard target z = 1.106 m")
	_assert_true("AT-19", MechanicsMath.m04_is_aim_locked(40.0, 42.5, 6.0), "Aim 40 deg locks onto 42.5 deg (error 2.5 <= 6)")

func test_at20_temple_bell_pull_row() -> void:
	# AT-20: Given R_f = 0.60, k = 0.75, D = 1.0, N = 7 -> g = 0.476 ± 0.001. For R_f,R = 0.42: g = 0.866 ± 0.001
	var r1 := MechanicsMath.m05_compute_row_params(0.60, 0.75, 1.0, 7, 0.15)
	var r2 := MechanicsMath.m05_compute_row_params(0.42, 0.75, 1.0, 7, 0.15)
	_assert_near("AT-20", float(r1["gain_g"]), 0.476, 0.001, "Row gain g for R_f=0.60")
	_assert_near("AT-20", float(r2["gain_g"]), 0.866, 0.001, "Row gain g for R_f,R=0.42")

func test_at21_ki_palm_push_forward_press() -> void:
	# AT-21: Given t_hold = 1.5 s, T_full = 2.0 s -> charge = 0.75, points = 75. Two-hand plane uses min(R_f,L, R_f,R)
	var info := MechanicsMath.m06_compute_charge_and_points(1.5, 2.0, false)
	_assert_near("AT-21", float(info["charge"]), 0.75, 0.001, "Ki Palm Push charge = 0.75")
	_assert_near("AT-21", float(info["base_points"]), 75.0, 0.001, "Ki Palm Push points = 75")
	var plane_z := MechanicsMath.m06_compute_plane_z(0.55, 0.42, 0.75, true)
	_assert_near("AT-21", plane_z, 0.315, 0.001, "Two-hand plane uses min(0.55, 0.42) * 0.75 = 0.315 m")

func test_at22_zen_water_wheel_arm_circles() -> void:
	# AT-22: Given f_target = 0.75 Hz, measured 0.90 Hz -> in band (20%); 1.00 Hz -> out of band (33%). v = 0.848 ± 0.001
	var c1 := MechanicsMath.m07_evaluate_crank(0.90, 0.75, 0.18, 0.25)
	var c2 := MechanicsMath.m07_evaluate_crank(1.00, 0.75, 0.18, 0.25)
	_assert_true("AT-22", bool(c1["in_band"]), "0.90 Hz is in band (20% <= 25%)")
	_assert_true("AT-22", not bool(c2["in_band"]), "1.00 Hz is out of band (33.3% > 25%)")
	_assert_near("AT-22", float(c1["target_hand_speed_mps"]), 0.848, 0.001, "v = 2*pi*0.18*0.75 = 0.848 m/s")

func test_at23_zen_horizon_watch_neck_mobility() -> void:
	# AT-23: Given head speed 90 deg/s during scan -> dwell timer pauses (does not reset) and "slower" cue shows
	var step := MechanicsMath.m08_step_scan_dwell(0.55, 1.5, 90.0, 0.10, 3.0, 60.0, 1.0)
	_assert_near("AT-23", float(step["dwell_s"]), 0.55, 0.0001, "Dwell timer pauses at 0.55 s without resetting")
	_assert_true("AT-23", bool(step["paused"]) and bool(step["show_slower_cue"]), "Shows slower cue at 90 deg/s")

func test_at24_tea_ceremony_pour_curl_and_drag() -> void:
	# AT-24: Given tau = 0.20 s, dt = 1/72 -> per-frame gap closure = 6.7% ± 0.1; steady lag at 0.5 m/s = 0.10 m; L_arm=0.52 -> d_curl=0.182, d_ext=0.442
	var drag := MechanicsMath.m09_compute_visual_drag(1.0 / 72.0, 0.20, 0.50)
	_assert_near("AT-24", float(drag["gap_closure_percent"]), 6.7, 0.1, "Per-frame gap closure = 6.7%")
	_assert_near("AT-24", float(drag["steady_lag_m"]), 0.10, 0.001, "Steady lag = 0.10 m")
	var dists := MechanicsMath.m09_compute_curl_distances(0.52)
	_assert_near("AT-24", float(dists["d_curl"]), 0.182, 0.001, "d_curl for L_arm=0.52 is 0.182 m")
	_assert_near("AT-24", float(dists["d_ext"]), 0.442, 0.001, "d_ext for L_arm=0.52 is 0.442 m")

func test_at25_bamboo_sway_side_bend() -> void:
	# AT-25: Given delta_x_max,R = 0.28, k = 0.85 -> gap centre g = 0.238 ± 0.001 (<= 0.25 cap); head at 0.30 -> fail, at 0.22 -> success
	var at_030 := MechanicsMath.m10_compute_gap_and_evaluate(0.28, 0.85, 0.30, 1.0, 0.25, 0.08)
	var at_022 := MechanicsMath.m10_compute_gap_and_evaluate(0.28, 0.85, 0.22, 1.0, 0.25, 0.08)
	_assert_near("AT-25", float(at_022["gap_centre"]), 0.238, 0.001, "Gap centre g = 0.238 m")
	_assert_true("AT-25", not bool(at_030["success"]), "Head at 0.30 m fails")
	_assert_true("AT-25", bool(at_022["success"]), "Head at 0.22 m succeeds")

func test_at26_score_attack_balanced_draw_and_no_trunk() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var draw1 := SessionDraw.draw_five_mechanics(false, [], rng)
	var groups_seen := {}
	for m in draw1:
		groups_seen[ZenoEnums.get_mechanic_group(m)] = true
	_assert_true("AT-26", draw1.size() == 5 and groups_seen.size() == 3, "5 distinct mechanics covering all 3 body groups")

	var draw_no_trunk := SessionDraw.draw_five_mechanics(true, [], rng)
	var has_level_b := false
	for m in draw_no_trunk:
		if ZenoEnums.get_mechanic_safety_level(m) == ZenoEnums.SafetyLevel.LEVEL_B:
			has_level_b = true
	_assert_true("AT-26", draw_no_trunk.size() == 5 and not has_level_b, "No-trunk mode excludes all Level B mechanics")

func test_at27_combo_multiplier_formula() -> void:
	# AT-27: Given streak_before = 10, base 137 -> hit points = 205
	var pts := ZenoScoring.compute_combo_hit_points(137, 10)
	_assert_near("AT-27", float(pts), 205.0, 0.001, "streak_before=10, base=137 -> 205 pts")

func test_at28_decline_stable_chair_substitutes_level_a() -> void:
	# AT-28: Given the user declines stable-chair confirmation, the Level B round is skipped and a Level A mechanic is substituted
	var lineup: Array[int] = [
		ZenoEnums.MechanicId.M01_MAKIWARA_STRIKES,
		ZenoEnums.MechanicId.M04_BOKKEN_GUARD, # Level B at index 1
		ZenoEnums.MechanicId.M06_KI_PALM_PUSH,
		ZenoEnums.MechanicId.M07_ZEN_WATER_WHEEL,
		ZenoEnums.MechanicId.M02_SAKURA_CATCH
	]
	var sub := SessionDraw.substitute_level_a_mechanic(lineup, 1)
	_assert_true(
		"AT-28",
		ZenoEnums.get_mechanic_safety_level(sub) == ZenoEnums.SafetyLevel.LEVEL_A and lineup[1] == sub,
		"Declining stable chair substitutes unused Level A mechanic (%s)" % ZenoEnums.get_mechanic_title(sub)
	)

func test_at29_m01_punch_anti_cheat() -> void:
	_assert_true("AT-29", not MechanicsMath.m01_is_valid_punch(0.12, 1.2, 0.0, 0.25, 0.25, false), "Wrist flick near chest (z=0.12 m) rejected")
	_assert_true("AT-29", not MechanicsMath.m01_is_valid_punch(0.42, 0.05, 0.0, 0.25, 0.25, false), "Zero forward punch velocity rejected")
	_assert_true("AT-29", MechanicsMath.m01_is_valid_punch(0.42, 0.45, 0.0, 0.25, 0.25, false), "Extended forward punch (z=0.42 m, v=0.45 m/s) accepted")

func test_at30_m03_crane_wings_anti_cheat() -> void:
	var tucked := MechanicsMath.m03_evaluate_wings_and_steering(Vector3(-0.20, -0.05, 0.30), Vector3(0.20, 0.15, 0.30), 0.12, 1.40, 0.70, 0.05, 0.10)
	_assert_true("AT-30", not bool(tucked["wings_deployed"]) and is_zero_approx(float(tucked["steering"])), "Tucked narrow elbows fail wing deploy and freeze steering")
	var spread := MechanicsMath.m03_evaluate_wings_and_steering(Vector3(-0.55, 0.20, 0.20), Vector3(0.55, 0.30, 0.20), 0.12, 1.40, 0.70, 0.05, 0.10)
	_assert_true("AT-30", bool(spread["wings_deployed"]) and float(spread["steering"]) > 0.0, "Full wingspan >= shoulder_y + 0.05 enables steering")

func test_at31_m04_bokken_guard_chest_anti_cheat() -> void:
	var arm_swing := MechanicsMath.m04_is_valid_torso_aim(Vector3(0.45, 0.0, 0.25), Vector3(0.55, 0.0, 0.25), Vector3.ZERO, 0.32)
	_assert_true("AT-31", not bool(arm_swing["hands_in_guard"]), "Swinging extended arms sideways outside chest guard (r=0.32 m) fails")
	var chest_guard := MechanicsMath.m04_is_valid_torso_aim(Vector3(0.08, 0.0, 0.22), Vector3(0.18, 0.0, 0.18), Vector3.ZERO, 0.32)
	_assert_true("AT-31", bool(chest_guard["hands_in_guard"]), "Keeping both hands near chest guard succeeds")

func test_at32_m05_temple_bell_bilateral_anti_cheat() -> void:
	var single_only := MechanicsMath.m05_step_bilateral_row(0.25, 0.45, 0.45, 0.45, 0.60, 0.476, ZenoEnums.HandMode.BOTH_HANDS)
	_assert_true("AT-32", not bool(single_only["bilateral_valid"]) and is_zero_approx(float(single_only["rope_advance_m"])), "1-hand pull in BOTH_HANDS mode yields 0 progress")
	var both_pulled := MechanicsMath.m05_step_bilateral_row(0.25, 0.45, 0.27, 0.45, 0.60, 0.476, ZenoEnums.HandMode.BOTH_HANDS)
	_assert_true("AT-32", bool(both_pulled["bilateral_valid"]) and float(both_pulled["rope_advance_m"]) > 0.05, "Bilateral rope pull advances temple bell")
	var one_hand_ok := MechanicsMath.m05_step_bilateral_row(0.25, 0.45, 0.45, 0.45, 0.60, 0.476, ZenoEnums.HandMode.LEFT_ONLY)
	_assert_true("AT-32", bool(one_hand_ok["bilateral_valid"]) and float(one_hand_ok["rope_advance_m"]) > 0.05, "Single-hand mode (disabled hand) still permits 1-hand pull")

func test_at33_m06_ki_palm_retract_hysteresis() -> void:
	var camp := MechanicsMath.m06_check_retract_hysteresis(false, 0.42, 0.42, 0.0, 0.40, 0.35, true, true, true)
	_assert_true("AT-33", not bool(camp["ready_to_charge"]) and not bool(camp["hands_at_plane"]), "Camping extended hands cannot re-charge without retracting")
	var retract := MechanicsMath.m06_check_retract_hysteresis(false, 0.12, 0.12, 0.0, 0.40, 0.35, true, true, true)
	_assert_true("AT-33", bool(retract["ready_to_charge"]), "Retracting <= z_retract resets Ki push readiness")

func test_at34_m07_water_wheel_signed_orbit_anti_cheat() -> void:
	var tremor := MechanicsMath.m07_evaluate_signed_crank(0.0, 0.4, Vector2(0.05, 0.0), Vector2.ZERO, 1.0, 0.12)
	_assert_true("AT-34", not bool(tremor["radius_ok"]) and is_zero_approx(float(tremor["effective_delta_rad"])), "Mini wrist tremor (r=0.05 m < 0.12 m) yields 0 crank progress")
	var fwd := MechanicsMath.m07_evaluate_signed_crank(0.0, 0.6, Vector2(0.18, 0.0), Vector2.ZERO, 1.0, 0.12)
	var back := MechanicsMath.m07_evaluate_signed_crank(0.6, 0.0, Vector2(0.18, 0.0), Vector2.ZERO, 1.0, 0.12)
	_assert_near("AT-34", float(fwd["effective_delta_rad"]) + float(back["effective_delta_rad"]), 0.0, 0.001, "Oscillating back and forth cancels to 0 net progress")

func test_at35_dojo_rank_personal_best_no_belts() -> void:
	_assert_true("AT-35", ZenoScoring.compute_dojo_rank(92.0) == "Zen Master", "92% -> Zen Master")
	_assert_true("AT-35", ZenoScoring.compute_dojo_rank(76.0) == "S", "76% -> S")
	_assert_true("AT-35", ZenoScoring.compute_dojo_rank(60.0) == "A", "60% -> A")
	_assert_true("AT-35", ZenoScoring.compute_dojo_rank(40.0) == "B", "40% -> B")
	_assert_true("AT-35", ZenoScoring.compute_dojo_rank(20.0) == "C", "20% -> C")

	var temp_dir := "/tmp/zenofit_at35_" + str(Time.get_ticks_usec())
	DirAccess.make_dir_recursive_absolute(temp_dir)
	var svc := SaveServiceClass.new(temp_dir)
	var r1 := svc.update_personal_best(ZenoEnums.RoutineId.FULL_UPPER_DOJO, 6, 420, 68.0, "A")
	var r2 := svc.update_personal_best(ZenoEnums.RoutineId.FULL_UPPER_DOJO, 6, 510, 82.0, "S")
	var r3 := svc.update_personal_best(ZenoEnums.RoutineId.FULL_UPPER_DOJO, 6, 390, 62.0, "B")
	_assert_true("AT-35", bool(r1["is_new_best"]) and bool(r2["is_new_best"]) and not bool(r3["is_new_best"]) and int(r3["new_best"]) == 510, "Personal Best tracks new high scores accurately")
	svc.delete_all_saved_data()
	DirAccess.remove_absolute(temp_dir)
	svc.free()

func test_v04_flow_routines_chair_check_and_fov_lap() -> void:
	# Test CalibrationController 8-step Chair Check
	var cal := CalibrationController.new()
	cal.start_full_calibration()
	cal.confirm_current_step(Vector3(0, 1.2, 0), Vector3(0, 0, 1), Vector3.ZERO, Vector3.ZERO)
	_assert_true("V04-CAL", cal.current_step == ZenoEnums.CalibrationStep.CHAIR_CHECK, "Step 2 enters CHAIR_CHECK")
	cal.skip_current_step()
	_assert_true("V04-CAL", cal.is_swivel_chair and cal.current_step == ZenoEnums.CalibrationStep.CHEST_POINT, "Skipping CHAIR_CHECK flags swivel chair safely")

	# Test AutoPause FoV tracking-loss fallback
	var ap := SafetyMonitors.AutoPauseMonitor.new(0.15, 2.0)
	var lap := Vector3(0.0, -0.45, 0.20)
	ap.evaluate(Vector3(-0.1, -0.30, 0.25), Vector3(0.1, -0.30, 0.25), lap, 0.1, true, true, -0.15)
	_assert_true("V04-FOV", ap.evaluate(Vector3.ZERO, Vector3.ZERO, lap, 2.0, false, false, -0.15), "Lower-zone FoV tracking loss triggers 2s lap Auto-Pause fallback")
	ap.reset()
	ap.evaluate(Vector3(-0.2, 0.30, 0.30), Vector3(0.2, 0.30, 0.30), lap, 0.1, true, true, -0.15)
	_assert_true("V04-FOV", not ap.evaluate(Vector3.ZERO, Vector3.ZERO, lap, 2.5, false, false, -0.15), "Overhead FoV tracking loss above chest does NOT falsely trigger lap pause")

	# Test Routine Picker -> Warm-Up -> Skip -> 3-round session
	var flow := GameFlowController.new()
	flow.has_valid_calibration = true
	flow.open_routine_picker_from_menu()
	_assert_true("V04-FLOW", flow.current_state == ZenoEnums.AppState.ROUTINE_PICKER, "Main Menu Play opens Routine Picker")
	flow.select_routine_and_start(ZenoEnums.RoutineId.SHOULDER_NECK_REFRESH, 3, true)
	_assert_true("V04-FLOW", flow.current_state == ZenoEnums.AppState.WARM_UP, "Selecting Warm-Up enters WARM_UP state")
	flow.skip_warmup()
	_assert_true("V04-FLOW", flow.current_state == ZenoEnums.AppState.ROUND_INTRO and flow.session_lineup.size() == 3, "Skipping warm-up starts 3-round 3-min routine")

	# Test configurable HUD distance clamping + stationary World-Space HUD & Zeno non-overlap
	var d_near := flow.adjust_hud_distance(-2.0)
	_assert_near("V04-HUD", d_near, 0.90, 0.001, "HUD distance clamps at minimum 0.90 m")
	var d_far := flow.adjust_hud_distance(2.0)
	_assert_near("V04-HUD", d_far, 2.00, 0.001, "HUD distance clamps at maximum 2.00 m")
	flow.adjust_hud_distance(-0.65) # back to 1.35 m
	_assert_near("V04-HUD", float(flow.settings.get("hud_distance_m", 0.0)), 1.35, 0.001, "HUD distance resets cleanly to 1.35 m")

	var bf := BodyFrame.new()
	var ui := ZenoWorldUI.new()
	ui.flow_override = flow
	flow.current_state = ZenoEnums.AppState.RESULTS
	ui.update_ui_display(bf, null, null, Vector3(0.0, 1.2, 0.0), Vector3(0.0, 0.0, -1.0), 0.1)
	var pos_ahead := ui.position
	ui.update_ui_display(bf, null, null, Vector3(0.15, 1.3, 0.1), Vector3(0.707, 0.0, -0.707), 0.1)
	var pos_turned := ui.position
	_assert_near("V04-HUD", pos_ahead.distance_to(pos_turned), 0.0, 0.001, "Stationary World-Space HUD stays fixed when camera looks 45 deg right")

	var zeno := FloatingMascotCoach.new()
	zeno._build_mascot_hierarchy()
	zeno.update_coach(0.05, bf, Vector3.ZERO, Vector3.ZERO)
	_assert_true(
		"V04-HUD",
		zeno.position.x > 0.70 and zeno.position.z > pos_ahead.z + 0.15,
		"Zeno stands outside right board edge (x=%.2f > 0.70) and in front of board plane (z=%.2f > %.2f)" % [zeno.position.x, zeno.position.z, pos_ahead.z + 0.15]
	)
	var bubble := zeno.find_child("CoachBubble", true, false) as Label3D
	_assert_true(
		"V04-HUD",
		bubble != null and bubble.position.y >= 0.62 and bubble.vertical_alignment == VERTICAL_ALIGNMENT_BOTTOM,
		"Zeno CoachBubble sits cleanly above HQ head (y=%.2f >= 0.62, bottom-aligned)" % (bubble.position.y if bubble != null else 0.0)
	)

	# Verify Beat-Saber 3D panel ray-quad hit & miss math
	var panel := DojoPanel3D.new()
	panel.setup_panel(1.12, 0.80, Vector2i(780, 560))
	panel.position = Vector3(0.0, 0.25, -1.35)
	var hit_center := panel.intersect_ray(Vector3(0.0, 0.25, 0.0), Vector3(0.0, 0.0, -1.0))
	var miss_side := panel.intersect_ray(Vector3(0.0, 0.25, 0.0), Vector3(0.9, 0.0, -0.4))
	_assert_true(
		"V04-HUD",
		bool(hit_center["hit"]) and not bool(miss_side["hit"]),
		"DojoPanel3D ray-quad intersection hits center panel and ignores off-panel rays"
	)
	panel.free()
	zeno.free()
	ui.free()
	flow._exit_tree()
	flow.free()

func test_v04_zen_dojo_environment_glb_and_scripts() -> void:
	# Verify Environment.glb loads cleanly, strips 28 stray modular nodes, disables shadows, and compiles cleanly
	var env_node: Node3D = DojoEnvironmentLoader.load_and_clean_dojo_environment()
	_assert_true("DOJO-ENV", env_node != null, "Environment.glb instantiates as ZenDojoEnvironment node")
	if env_node != null:
		var root_node := env_node.find_child("RootNode", true, false)
		var group_count := root_node.get_child_count() if root_node != null else 0
		var stray := env_node.find_child("pCube36", true, false)
		var shadows_ok := true
		var mesh_count := 0
		var queue: Array[Node] = [env_node]
		while not queue.is_empty():
			var n: Node = queue.pop_back()
			if n is MeshInstance3D:
				mesh_count += 1
				if (n as MeshInstance3D).cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF:
					shadows_ok = false
			for c in n.get_children():
				queue.append(c)
		_assert_true("DOJO-ENV", group_count == 6 and stray == null, "Stripped stray modular kitbash nodes; kept 6 Zen Dojo room groups")
		_assert_true("DOJO-ENV", mesh_count > 0 and shadows_ok, "All %d Zen Dojo meshes have shadow casting disabled for mobile VR budget" % mesh_count)
		env_node.free()

func test_integration_all_10_mechanics_and_mascot() -> void:
	var coach := FloatingMascotCoach.new()
	coach.use_high_quality_model = true
	coach._build_mascot_hierarchy()
	_assert_true(
		"MASCOT-HQ",
		coach.loaded_model_path == FloatingMascotCoach.MASCOT_HQ_GLB_PATH and coach.find_child("EyeHappy_L", true, false) != null,
		"High-Quality mode loads Zeno_WithTexture.glb with expressive eyes and native rig"
	)
	var bf := BodyFrame.new()
	for m in SessionDraw.get_all_mechanics():
		coach.set_demo_mechanic(m)
		coach.update_coach(0.05, bf, Vector3.ZERO, Vector3.ZERO)
	coach.update_coach(0.05, bf, coach.position + Vector3(0.0, 0.22, 0.0), Vector3.ZERO)
	_assert_true("MASCOT-COACH", coach.poke_count >= 1, "HQ Zeno animates all 10 demos and reacts to hand poke")

	# Verify runtime switch to Low-Poly Performance LOD
	coach.set_quality_mode(false)
	_assert_true(
		"MASCOT-LOD",
		coach.loaded_model_path == FloatingMascotCoach.MASCOT_LOW_POLY_GLB_PATH,
		"Low-Poly optimization toggle switches cleanly to Floating Mascots.glb"
	)
	coach.set_demo_mechanic(ZenoEnums.MechanicId.M01_MAKIWARA_STRIKES)
	coach.update_coach(0.05, bf, Vector3.ZERO, Vector3.ZERO)
	var shadows_disabled := true
	var q: Array[Node] = [coach]
	while not q.is_empty():
		var node: Node = q.pop_back()
		if node is MeshInstance3D and (node as MeshInstance3D).cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF:
			shadows_disabled = false
		for ch in node.get_children():
			q.append(ch)
	_assert_true("MASCOT-LOD", shadows_disabled, "All Mascot meshes have real-time shadow casting disabled in both LODs")
	coach.free()

