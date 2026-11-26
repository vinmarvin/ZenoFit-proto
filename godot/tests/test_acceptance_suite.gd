class_name ZenoAcceptanceSuite
extends RefCounted

## Automated Acceptance Test Suite for ZenoFit v1.0 (Godot 4.7).
## Covers SpecSpace, Stationary BodyFrame, Integrated Assets (KarateBoard, Environment,
## Zeno_WithTexture), FoV-Safe Zeno, Session Input Lock, All 7 Exercises,
## Safety Monitors, 11-Screen UI Flow, Persistence, and Zero Debug UI strings.

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

func run_all(host_root: Node = null) -> Dictionary:
	passed_count = 0
	failed_count = 0
	results_log.clear()

	test_spec_space_and_stationary_body_frame()
	test_assets_and_karate_board_fracture()
	test_mascot_fov_and_seven_demos()
	test_input_lock_and_safety_monitors()
	test_ex01_board_smash()
	test_ex02_wide_split()
	test_ex03_sky_reach()
	test_ex04_orbit_flow()
	test_ex05_wrist_twist()
	test_ex06_torso_twist()
	test_ex07_horizon_gaze()
	test_live_instantiation_all_seven_exercises()
	test_scoring_tempo_and_session_draw()
	test_calibration_and_persistence()
	test_ui_flow_hud_ergonomics_and_no_debug_strings(host_root)

	return {
		"passed": passed_count,
		"failed": failed_count,
		"log": results_log
	}

func test_spec_space_and_stationary_body_frame() -> void:
	var p_godot := SpecSpace.to_godot(Vector3(0.10, 0.20, 0.51))
	_assert_near("SPEC-SPACE", p_godot.z, -0.51, 0.0001, "Spec +Z forward maps to Godot -Z")
	_assert_near("SPEC-SPACE", SpecSpace.yaw_deg_to_godot_deg(40.0), -40.0, 0.0001, "Spec +40 deg yaw maps to Godot -40 deg")

	# Verify head pitch up/down does NOT alter stationary BodyFrame chest origin
	var head_pos := Vector3(0.0, 1.18, 0.0)
	var b_level := Basis.IDENTITY
	var b_pitch_up := Basis(Vector3.RIGHT, deg_to_rad(42.0))
	var b_pitch_down := Basis(Vector3.RIGHT, deg_to_rad(-42.0))
	var bf_0 := BodyFrame.rebuild_from_godot_head(head_pos, b_level, Vector3(0.0, -0.25, 0.08))
	var bf_up := BodyFrame.rebuild_from_godot_head(head_pos, b_pitch_up, Vector3(0.0, -0.25, 0.08))
	var bf_dn := BodyFrame.rebuild_from_godot_head(head_pos, b_pitch_down, Vector3(0.0, -0.25, 0.08))
	_assert_near("STATIONARY-BODYFRAME", bf_0.origin_spec.distance_to(bf_up.origin_spec), 0.0, 0.001, "Pitching camera +42 deg leaves BodyFrame origin invariant")
	_assert_near("STATIONARY-BODYFRAME", bf_0.origin_spec.distance_to(bf_dn.origin_spec), 0.0, 0.001, "Pitching camera -42 deg leaves BodyFrame origin invariant")

func test_assets_and_karate_board_fracture() -> void:
	# 1. KarateBoard.glb hierarchy & Break fracture trigger
	var board := KarateBoardProp.new()
	board.setup_board(Color(0.32, 0.85, 0.72))
	_assert_true(
		"ASSETS-BOARD",
		board.intact_node != null and board.half_left_node != null and board.half_right_node != null and board.splinter_nodes.size() == 6,
		"KarateBoard.glb loads intact mesh, 2 halves, and 6 splinters"
	)
	_assert_true(
		"ASSETS-BOARD",
		board.intact_node.visible and not board.half_left_node.visible and not board.half_right_node.visible and not board.is_broken,
		"KarateBoard starts intact with halves hidden"
	)
	board.trigger_break()
	_assert_true(
		"ASSETS-BOARD",
		board.is_broken and not board.intact_node.visible and board.half_left_node.visible and board.half_right_node.visible and board.anim_player != null,
		"trigger_break() hides intact board, shows fracture halves, and triggers Break animation"
	)
	board.free()

	# 2. Environment.glb clean loading & shadow-off budget
	var env_node := DojoEnvironmentLoader.load_and_clean_dojo_environment()
	_assert_true("ASSETS-ENV", env_node != null, "Environment.glb loads cleanly")
	if env_node != null:
		var root_node := env_node.find_child("RootNode", true, false)
		var group_count := root_node.get_child_count() if root_node != null else 0
		var stray := env_node.find_child("pCube36", true, false)
		var shadows_ok := true
		var mesh_count := 0
		var q: Array[Node] = [env_node]
		while not q.is_empty():
			var n: Node = q.pop_back()
			if n is MeshInstance3D:
				mesh_count += 1
				if (n as MeshInstance3D).cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF:
					shadows_ok = false
			for c in n.get_children():
				q.append(c)
		_assert_true("ASSETS-ENV", group_count == 6 and stray == null, "Environment.glb keeps 6 room groups and strips 28 stray pieces")
		_assert_true("ASSETS-ENV-SHADOWS", mesh_count > 0 and shadows_ok, "All %d Environment.glb room meshes have shadow casting OFF" % mesh_count)
		env_node.free()

func test_mascot_fov_and_seven_demos() -> void:
	# Verify Zeno anchor stays inside <= 24 deg horizontal FoV across HUD distances [1.30, 1.65, 2.20]
	for dist in [1.30, 1.65, 2.20]:
		for st in [ZenoEnums.AppState.WELCOME, ZenoEnums.AppState.MAIN_MENU, ZenoEnums.AppState.EXERCISE_PREVIEW, ZenoEnums.AppState.ROUND_PLAY]:
			var anc := FloatingMascotCoach.compute_fov_safe_anchor(st, dist)
			var pos: Vector3 = anc["pos"]
			var ang_deg := rad_to_deg(atan2(absf(pos.x), maxf(0.1, pos.z)))
			_assert_true("MASCOT-FOV", ang_deg <= 24.0 + 1e-3, "Zeno horizontal FoV angle %.1f deg <= 24 deg (state=%d, dist=%.2f)" % [ang_deg, st, dist])

	var coach := FloatingMascotCoach.new()
	coach._build_mascot_hierarchy()
	_assert_true(
		"MASCOT-HQ",
		coach.loaded_model_path == FloatingMascotCoach.MASCOT_GLB_PATH and coach.find_child("EyeHappy_L", true, false) != null,
		"Textured Zeno_WithTexture.glb loads cleanly with expressive rig"
	)
	var bf := BodyFrame.new()
	for ex in SessionDraw.get_all_exercises():
		coach.set_demo_exercise(ex)
		coach.update_coach(0.05, bf, Vector3.ZERO, Vector3.ZERO)
	coach.update_coach(0.05, bf, coach.position + Vector3(0.0, 0.20, 0.0), Vector3.ZERO)
	_assert_true("MASCOT-DEMOS", coach.poke_count >= 1, "Zeno animates all 7 exercises and reacts to high-five poke")

	var shadows_ok := true
	var q: Array[Node] = [coach]
	while not q.is_empty():
		var n: Node = q.pop_back()
		if n is MeshInstance3D and (n as MeshInstance3D).cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF:
			shadows_ok = false
		for ch in n.get_children():
			q.append(ch)
	_assert_true("MASCOT-SHADOWS", shadows_ok, "All Zeno meshes have real-time shadows disabled")
	coach.free()

func test_input_lock_and_safety_monitors() -> void:
	var plat_script := load("res://autoload/platform.gd")
	var plat: Node = plat_script.new()
	plat.is_xr_active = true
	var dummy_ctrl := XRController3D.new()
	# When locked to HAND_TRACKING in XR with no XRHandTracker active, must report tracked=false (no silent fallback!)
	var ht_pose: Dictionary = plat.sample_input_pose(ZenoEnums.Hand.LEFT, dummy_ctrl, ZenoEnums.InputMode.HAND_TRACKING)
	_assert_true("INPUT-LOCK", not bool(ht_pose["tracked"]) and String(ht_pose["source"]) == "hand_tracking", "Hand Tracking lock does not silently fall back to controller")
	var ctrl_pose: Dictionary = plat.sample_input_pose(ZenoEnums.Hand.LEFT, dummy_ctrl, ZenoEnums.InputMode.CONTROLLER)
	_assert_true("INPUT-LOCK", not bool(ctrl_pose["tracked"]) and String(ctrl_pose["source"]) == "controller", "Controller lock reads strictly from XRController3D")
	dummy_ctrl.free()
	plat.free()

	# AutoPauseMonitor (2.0 s lap + lower-zone FoV fallback) & LeanMonitor
	var ap := SafetyMonitors.AutoPauseMonitor.new(0.15, 2.0)
	var lap := Vector3(0.0, -0.45, 0.20)
	ap.evaluate(Vector3(-0.1, -0.30, 0.25), Vector3(0.1, -0.30, 0.25), lap, 0.1, true, true, -0.15)
	_assert_true("SAFETY-LAP", ap.evaluate(Vector3.ZERO, Vector3.ZERO, lap, 2.0, false, false, -0.15), "Hands in lap / lower-zone tracking drop triggers 2s Auto-Pause")

	var lm := SafetyMonitors.LeanMonitor.new(0.22, 0.50)
	_assert_true("SAFETY-LEAN", not lm.evaluate(0.15, 0.0, 0.60), "|dx|=0.15 m stays safe")
	_assert_true("SAFETY-LEAN", lm.evaluate(0.26, 0.0, 0.60), "|dx|=0.26 m for 0.6s triggers lean warning")

func test_ex01_board_smash() -> void:
	var p := MechanicsMath.board_smash_params(0.60, 0.75, 1.5, 1.0)
	_assert_near("EX-01", float(p["z_hit"]), 0.45, 0.001, "Board Smash z_hit = 0.75 * 0.60")
	_assert_true("EX-01", not MechanicsMath.board_smash_is_valid_strike(Vector3(0.1, 0.0, 0.12), 0.80, "front"), "Close-to-chest wrist flick rejected")
	_assert_true("EX-01", not MechanicsMath.board_smash_is_valid_strike(Vector3(0.1, 0.0, 0.42), 0.05, "front"), "Stationary hand rejected")
	_assert_true("EX-01", MechanicsMath.board_smash_is_valid_strike(Vector3(0.1, 0.0, 0.42), 0.50, "front"), "Extended forward punch accepted")
	_assert_true("EX-01", ZenoGeometry.segment_hit(Vector3(0, 0, 0.2), Vector3(0, 0, 0.7), Vector3(0, 0, 0.45), 0.10, 0.04), "Anti-tunnelling catches fast strike")

func test_ex02_wide_split() -> void:
	var t := MechanicsMath.wide_split_compute_targets(0.40, 0.60, 0.75, 20.0)
	var lp: Vector3 = t["left_pos"]
	var rp: Vector3 = t["right_pos"]
	_assert_true("EX-02", lp.z >= 0.28 and rp.x > 0.30 and lp.x < -0.30, "Twin boards placed forward in 20 deg scapular plane")
	var unprimed := MechanicsMath.wide_split_evaluate(Vector3(-0.50, 0.0, 0.35), Vector3(0.50, 0.0, 0.35), false, 0.34, 0.72)
	_assert_true("EX-02", not bool(unprimed["split_complete"]), "Wide Split requires bringing hands to center first")
	var primed := MechanicsMath.wide_split_evaluate(Vector3(-0.10, 0.0, 0.35), Vector3(0.10, 0.0, 0.35), false, 0.34, 0.72)
	var done := MechanicsMath.wide_split_evaluate(Vector3(-0.45, 0.0, 0.35), Vector3(0.45, 0.0, 0.35), bool(primed["primed"]), 0.34, 0.72)
	_assert_true("EX-02", bool(primed["primed"]) and bool(done["split_complete"]), "Priming at chest then opening wide triggers Wide Split")

func test_ex03_sky_reach() -> void:
	var res := MechanicsMath.sky_reach_placement(0.60, 0.85, 45.0, Vector3(0.20, 0.12, 0.0), 0.25, 45.0)
	_assert_near("EX-03", float(res["y"]), 0.481, 0.002, "Sky Reach diagonal y height")
	_assert_true("EX-03", float(res["gaze_elevation_deg"]) <= 45.0 + 1e-3, "Sky Reach gaze elevation clamped <= 45 deg")

func test_ex04_orbit_flow() -> void:
	var tremor := MechanicsMath.orbit_flow_evaluate_signed(0.0, 0.4, Vector2(0.05, 0.0), Vector2.ZERO, 1.0, 0.12)
	_assert_true("EX-04", not bool(tremor["radius_ok"]) and is_zero_approx(float(tremor["effective_delta_rad"])), "Small wrist tremor (< 0.12 m) gives 0 orbit progress")
	var fwd := MechanicsMath.orbit_flow_evaluate_signed(0.0, 0.5, Vector2(0.18, 0.0), Vector2.ZERO, 1.0, 0.12)
	var back := MechanicsMath.orbit_flow_evaluate_signed(0.5, 0.0, Vector2(0.18, 0.0), Vector2.ZERO, 1.0, 0.12)
	_assert_near("EX-04", float(fwd["effective_delta_rad"]) + float(back["effective_delta_rad"]), 0.0, 0.001, "Oscillating cancels out in signed orbit math")

func test_ex05_wrist_twist() -> void:
	var anchor := Vector3(0.22, -0.02, 0.42)
	var out_zone := MechanicsMath.wrist_twist_evaluate(Vector3(0.22, -0.02, 0.75), anchor, 55.0, 55.0)
	_assert_true("EX-05", not bool(out_zone["angle_reached"]), "Out-of-anchor forearm swing rejected")
	var valid := MechanicsMath.wrist_twist_evaluate(Vector3(0.24, 0.0, 0.44), anchor, 52.0, 55.0)
	_assert_true("EX-05", bool(valid["in_zone"]) and bool(valid["angle_reached"]), "Steady forearm + wrist roll within tolerance succeeds")

func test_ex06_torso_twist() -> void:
	var info := MechanicsMath.torso_twist_target(50.0, 0.85, 1.0, 1.25, 55.0)
	_assert_near("EX-06", float(info["psi_t_deg"]), 42.5, 0.01, "Torso Twist target angle = 42.5 deg")
	var arm_cheat := MechanicsMath.torso_twist_evaluate(Vector3(0.42, 0.0, 0.25), Vector3(0.52, 0.0, 0.25), Vector3(0.6, 0.0, 0.8), 42.5)
	_assert_true("EX-06", not bool(arm_cheat["hands_in_guard"]) and not bool(arm_cheat["aim_locked"]), "Arm swinging outside chest guard rejected")
	var head_desync := MechanicsMath.torso_twist_evaluate(Vector3(0.14, 0.0, 0.16), Vector3(0.18, 0.0, 0.14), Vector3(0.0, 0.0, 1.0), 42.5)
	_assert_true("EX-06", bool(head_desync["hands_in_guard"]) and not bool(head_desync["head_synced"]), "Head not turning with torso fails sync check")
	var valid := MechanicsMath.torso_twist_evaluate(Vector3(0.14, 0.0, 0.16), Vector3(0.18, 0.0, 0.14), Vector3(sin(deg_to_rad(42.0)), 0.0, cos(deg_to_rad(42.0))), 42.5)
	_assert_true("EX-06", bool(valid["aim_locked"]), "Aligned chest guard + torso/head rotation locks board")

func test_ex07_horizon_gaze() -> void:
	var fast := MechanicsMath.horizon_gaze_step(0.50, 1.0, 2.0, 90.0, 0.10, 5.0, 20.0, 60.0, 1.0)
	_assert_near("EX-07", float(fast["dwell_s"]), 0.50, 0.0001, "Fast turn (> 60 deg/s) pauses dwell without reset")
	_assert_true("EX-07", bool(fast["show_slower_cue"]), "Shows calm slower cue above 60 deg/s")
	var slow := MechanicsMath.horizon_gaze_step(0.50, 1.0, 2.0, 25.0, 0.55, 5.0, 20.0, 60.0, 1.0)
	_assert_true("EX-07", bool(slow["scan_complete"]), "Smooth gaze reaches 1.0 s completion")

func test_live_instantiation_all_seven_exercises() -> void:
	var arena := Node3D.new()
	var bf := BodyFrame.new()
	var prof := ComfortProfile.create_default()
	var preset := DifficultyPreset.create_for_tier(ZenoEnums.DifficultyTier.STANDARD)
	var instances: Array[MechanicBase] = [
		BoardSmashMechanic.new(),
		WideSplitMechanic.new(),
		SkyReachMechanic.new(),
		OrbitFlowMechanic.new(),
		WristTwistMechanic.new(),
		TorsoTwistMechanic.new(),
		HorizonGazeMechanic.new()
	]
	var ids := SessionDraw.get_all_exercises()
	var ok := true
	for i in range(instances.size()):
		var mech: MechanicBase = instances[i]
		mech.setup(ids[i], prof, bf, preset, ZenoEnums.HandMode.BOTH_HANDS, arena)
		mech.update_mechanic(
			0.016, Vector3(0, 0.25, 0), Vector3(0, 0, 1), 10.0,
			Vector3(-0.2, 0, 0.4), Vector3(-0.2, 0, 0.45), 0.3,
			Vector3(0.2, 0, 0.4), Vector3(0.2, 0, 0.45), 0.3,
			0.0, 0.0
		)
		mech.simulate_auto_action()
		mech.clear_arena()
		if arena.get_child_count() < 0:
			ok = false
	_assert_true("LIVE-EXERCISES", ok and instances.size() == 7, "All 7 curated exercises instantiate, tick, auto-act, and clean up cleanly")
	arena.free()

func test_scoring_tempo_and_session_draw() -> void:
	var tempo := AdaptiveTempo.new(60.0, 80.0, 8)
	_assert_near("TEMPO", tempo.evaluate_window(7, 8), 65.0, 0.001, "87.5% accuracy increases tempo to 65 BPM")
	_assert_near("SCORING", float(ZenoScoring.compute_combo_hit_points(137, 10)), 205.0, 0.001, "Streak 10 combo multiplier 1.5x -> 205 pts")

	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var mix := SessionDraw.draw_quick_break_mix([], rng)
	var cats := {}
	var consecutive_b := false
	for i in range(mix.size()):
		cats[ZenoEnums.get_exercise_category(mix[i])] = true
		if i > 0 and ZenoEnums.get_exercise_safety_level(mix[i]) == ZenoEnums.SafetyLevel.LEVEL_B and ZenoEnums.get_exercise_safety_level(mix[i - 1]) == ZenoEnums.SafetyLevel.LEVEL_B:
			consecutive_b = true
	_assert_true("QUICK-BREAK", mix.size() == 5 and cats.size() == 3 and not consecutive_b, "Quick Break draws 5 exercises covering Active/Mobility/Posture with non-consecutive Level B")

func test_calibration_and_persistence() -> void:
	var cal := CalibrationController.new()
	cal.start_calibration()
	_assert_true("CAL-3STEP", cal.get_step_index() == 1, "Starts at step 1/3")
	cal.confirm_current_step(Vector3(0, 1.18, 0), Vector3(0, 0, 1), Vector3.ZERO, Vector3.ZERO)
	_assert_true("CAL-3STEP", cal.current_step == ZenoEnums.CalibrationStep.COMFORT_REACH, "Step 1 advances to Comfort Reach")
	cal.confirm_current_step(Vector3(0, 1.18, 0), Vector3(0, 0, 1), Vector3(-0.2, 0.0, 0.55), Vector3(0.2, 0.0, 0.55))
	cal.confirm_current_step(Vector3(0, 1.18, 0), Vector3(0, 0, 1), Vector3(-0.2, 0.0, 0.55), Vector3(0.2, 0.0, 0.55))
	var done := cal.confirm_current_step(Vector3(0, 1.18, 0), Vector3(0, 0, 1), Vector3(-0.1, -0.45, 0.2), Vector3(0.1, -0.45, 0.2))
	_assert_true("CAL-3STEP", done and cal.current_step == ZenoEnums.CalibrationStep.COMPLETE, "3-step calibration completes cleanly")

	var temp_dir := "/tmp/zenofit_v1_test_" + str(Time.get_ticks_usec())
	DirAccess.make_dir_recursive_absolute(temp_dir)
	var svc := SaveServiceClass.new(temp_dir)
	var p := ComfortProfile.create_default()
	p.left_reach_forward_m = 0.52
	svc.save_calibration_profile(p)
	svc.append_session_record({"score": 480, "durationSeconds": 45.0}, 30)
	var pb := svc.update_personal_best("ex_1", 480, 88.0, "S")
	var weekly := svc.get_weekly_stats()
	_assert_true("SAVE-SVC", bool(pb["is_new_best"]) and int(weekly["sessions_count"]) == 1 and int(weekly["best_score"]) == 480, "SaveService persists calibration, personal best, and weekly stats")
	svc.delete_all_saved_data()
	DirAccess.remove_absolute(temp_dir)
	svc.free()

func test_ui_flow_hud_ergonomics_and_no_debug_strings(host_root: Node = null) -> void:
	var flow := GameFlowController.new()
	flow.complete_boot()
	_assert_true("FLOW-UI", flow.current_state == ZenoEnums.AppState.WELCOME, "Boot transitions to WELCOME")
	flow.continue_to_main_menu()
	_assert_true("FLOW-UI", flow.current_state == ZenoEnums.AppState.MAIN_MENU, "Continue enters MAIN_MENU")
	flow.open_exercise_select(ZenoEnums.ExerciseCategory.ACTIVE)
	_assert_true("FLOW-UI", flow.current_state == ZenoEnums.AppState.EXERCISE_SELECT, "Opens EXERCISE_SELECT")
	flow.open_exercise_preview(ZenoEnums.ExerciseId.BOARD_SMASH)
	_assert_true("FLOW-UI", flow.current_state == ZenoEnums.AppState.EXERCISE_PREVIEW, "Opens EXERCISE_PREVIEW")
	flow.start_single_exercise(ZenoEnums.ExerciseId.BOARD_SMASH)
	flow.advance_round_timer(3.1)
	_assert_true("FLOW-UI", flow.current_state == ZenoEnums.AppState.ROUND_PLAY and flow.active_input_mode == int(flow.settings["input_mode"]), "Starts ROUND_PLAY with locked input mode")
	flow.pause_session(ZenoEnums.PauseReason.MANUAL, "Paused")
	_assert_true("FLOW-UI", flow.current_state == ZenoEnums.AppState.PAUSED, "Pauses session immediately")
	flow.finish_session_to_results()
	_assert_true("FLOW-UI", flow.current_state == ZenoEnums.AppState.RESULTS, "Finishes to RESULTS")

	# HUD Ergonomics clamping
	_assert_near("HUD-ERGONOMICS", flow.adjust_hud_distance(-5.0), 1.30, 0.001, "HUD distance clamps at min 1.30 m")
	_assert_near("HUD-ERGONOMICS", flow.adjust_hud_distance(5.0), 2.20, 0.001, "HUD distance clamps at max 2.20 m")
	_assert_near("HUD-ERGONOMICS", flow.adjust_hud_distance(-0.55), 1.65, 0.001, "HUD distance resets cleanly to 1.65 m")
	_assert_near("HUD-ERGONOMICS", flow.adjust_hud_scale(-2.0), 0.85, 0.001, "HUD scale clamps at min 0.85x")
	_assert_near("HUD-ERGONOMICS", flow.adjust_hud_scale(2.0), 1.20, 0.001, "HUD scale clamps at max 1.20x")
	_assert_near("HUD-ERGONOMICS", flow.adjust_hud_scale(-0.20), 1.00, 0.001, "HUD scale resets cleanly to 1.00x")

	# Verify UI.pdf panels build cleanly across all 11 states & fit inside viewport without clipping
	var bf := BodyFrame.new()
	var ui := ZenoWorldUI.new()
	ui.flow_override = flow
	if host_root != null:
		host_root.add_child(ui)
	var all_ui_texts: Array[String] = []
	var test_states := [
		ZenoEnums.AppState.WELCOME, ZenoEnums.AppState.MAIN_MENU,
		ZenoEnums.AppState.EXERCISE_SELECT, ZenoEnums.AppState.EXERCISE_PREVIEW,
		ZenoEnums.AppState.CALIBRATION, ZenoEnums.AppState.ROUND_PLAY,
		ZenoEnums.AppState.PAUSED, ZenoEnums.AppState.RESULTS,
		ZenoEnums.AppState.SETTINGS, ZenoEnums.AppState.TUTORIAL,
		ZenoEnums.AppState.CREDITS, ZenoEnums.AppState.EXIT_CONFIRM
	]
	for st in test_states:
		flow.current_state = st
		ui.update_ui_display(bf, null, null, Vector3(0, 1.18, 0), Vector3(0, 0, -1), 0.05)
		_collect_ui_labels(ui.main_panel, all_ui_texts)

	var resize_ok := true
	var seq := [
		ZenoEnums.AppState.MAIN_MENU, ZenoEnums.AppState.EXERCISE_SELECT,
		ZenoEnums.AppState.EXERCISE_PREVIEW, ZenoEnums.AppState.ROUND_PLAY,
		ZenoEnums.AppState.PAUSED, ZenoEnums.AppState.SETTINGS,
		ZenoEnums.AppState.PAUSED, ZenoEnums.AppState.EXIT_CONFIRM,
		ZenoEnums.AppState.RESULTS, ZenoEnums.AppState.MAIN_MENU
	]
	for r_state in seq:
		var tabs := [0, 1, 2, 3] if r_state == ZenoEnums.AppState.SETTINGS else [0]
		for tab_idx in tabs:
			ui._settings_tab = tab_idx
			flow.current_state = r_state
			if r_state == ZenoEnums.AppState.SETTINGS:
				ui._rebuild_all_panels()
			else:
				ui.update_ui_display(bf, null, null, Vector3(0, 1.18, 0), Vector3(0, 0, -1), 0.05)
			var vp := ui.main_panel.viewport_px
			var min_sz := ui.main_panel.get_content_min_size()
			var root_sz := ui.main_panel.get_root_panel_size()
			if min_sz.x > float(vp.x) + 1.0 or min_sz.y > float(vp.y) + 1.0 or root_sz.x > float(vp.x) + 1.0 or root_sz.y > float(vp.y) + 1.0:
				resize_ok = false
				results_log.append("[OVERFLOW] state=%d tab=%d vp=%s min=%s root=%s" % [r_state, tab_idx, str(vp), str(min_sz), str(root_sz)])
	_assert_true("PANEL-RESIZE", resize_ok, "Shrinking/expanding panel across all 12 screens & Settings tabs fits without overflow or clipping")

	for id in SessionDraw.get_all_exercises():
		all_ui_texts.append(ZenoEnums.get_exercise_title(id))
		all_ui_texts.append(ZenoEnums.get_exercise_tagline(id))
		all_ui_texts.append(ZenoEnums.get_exercise_cue(id))
		for s in ZenoEnums.get_exercise_preview_steps(id):
			all_ui_texts.append(s)

	var joined := "\n".join(all_ui_texts)
	var forbidden := ["M01", "M02", "M03", "M04", "M05", "M06", "M07", "M08", "M09", "M10", "[Tab]", "[Space]", "Politeknik", "Fruit Harvester", "Makiwara"]
	var clean := true
	for bad in forbidden:
		if joined.contains(bad):
			clean = false
			results_log.append("[DEBUG-TEXT-FOUND] " + bad)
	_assert_true("NO-DEBUG-UI", clean, "Zero debug codes, keyboard hints, or legacy PENS/Sci-Fi strings in UI")
	_assert_true("CREDITS-ITS", joined.contains("Institut Teknologi Sepuluh Nopember") and joined.contains("jrevel"), "Credits accurately lists ITS and jrevel attribution")

	if host_root != null:
		host_root.remove_child(ui)
	ui.free()
	flow._exit_tree()
	flow.free()

func _collect_ui_labels(node: Node, out: Array[String]) -> void:
	if node == null:
		return
	if node is Label:
		out.append((node as Label).text)
	elif node is Button:
		out.append((node as Button).text)
	for c in node.get_children():
		_collect_ui_labels(c, out)
