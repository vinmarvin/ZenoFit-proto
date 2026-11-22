class_name ZenoWorldUI
extends Node3D

## Beat-Saber-style 3-Panel Curved Interactive 3D World UI anchored stationary in BodyFrame.
## - LeftPanel:  GAMEPLAY SETUP (Difficulty, Hand Mode, No-Trunk Safe Mode, Zeno HQ/Low-Poly, HUD Distance, Reset)
## - MainPanel:  MAIN MENU / ROUTINE PICKER / CALIBRATION / WARM_UP / PAUSED / RESULTS / CREDITS / Compact Round HUD
## - RightPanel: DOJO STATUS & Personal Best pedestal positioned cleanly underneath Zeno on the right
## Clickable directly with Desktop Mouse raycast AND VR Controller / Hand raycast (disabled during ROUND_PLAY).

signal request_confirm_calibration_step()
signal request_skip_calibration_step()
signal request_mark_obstacle()
signal request_auto_action()
signal request_poke_mascot()
signal request_toggle_mascot_quality()

const COL_CYAN := Color(0.18, 0.82, 0.76)
const COL_EMERALD := Color(0.16, 0.78, 0.48)
const COL_MAGENTA := Color(0.76, 0.30, 0.78)
const COL_AMBER := Color(0.92, 0.64, 0.18)
const COL_SLATE := Color(0.32, 0.42, 0.52)
const COL_RED := Color(0.78, 0.24, 0.26)

var flow_override: GameFlowController = null

var main_panel: DojoPanel3D
var left_panel: DojoPanel3D
var right_panel: DojoPanel3D
var _pointer_dot: MeshInstance3D

# Dynamic labels updated in-place every frame without rebuilding controls
var _live_header_lbl: Label = null
var _live_body_lbl: Label = null
var _live_sub_lbl: Label = null
var _last_built_state: int = -1
var _last_built_cal_step: int = -1
var _last_built_pause_reason: int = -1

# Minimal Desktop shortcut strip (hidden in VR)
var _canvas_layer: CanvasLayer
var _desktop_hint_lbl: Label
var _round_quick_bar: HBoxContainer

var _hud_initialized: bool = false
var _smoothed_pos: Vector3 = Vector3(0.0, 0.25, -1.35)
var _smoothed_yaw_rad: float = 0.0
var _hovered_panel: DojoPanel3D = null

var _picker_routine: int = ZenoEnums.RoutineId.FULL_UPPER_DOJO
var _picker_duration_min: int = 6
var _picker_warmup: bool = false
var _fallback_flow: GameFlowController = null

func _gf() -> GameFlowController:
	if flow_override != null:
		return flow_override
	if is_inside_tree() and get_tree().root.has_node("GameFlow"):
		return get_tree().root.get_node("GameFlow") as GameFlowController
	if _fallback_flow == null:
		_fallback_flow = GameFlowController.new()
	return _fallback_flow

func _plat() -> Node:
	if is_inside_tree() and get_tree().root.has_node("Platform"):
		return get_tree().root.get_node("Platform")
	return null

func _save() -> SaveServiceClass:
	if is_inside_tree() and get_tree().root.has_node("SaveService"):
		return get_tree().root.get_node("SaveService") as SaveServiceClass
	return _gf()._get_save_service()

func _eb() -> Node:
	if is_inside_tree() and get_tree().root.has_node("EventBus"):
		return get_tree().root.get_node("EventBus")
	return null

func _ready() -> void:
	var gf := _gf()
	_picker_routine = gf.selected_routine
	_picker_duration_min = int(gf.settings.get("preferred_duration_min", 6))
	_picker_warmup = bool(gf.settings.get("enable_warmup", false))
	_ensure_3d_panels()
	_build_minimal_desktop_strip()
	var eb := _eb()
	if eb != null:
		eb.state_changed.connect(_on_state_changed)
	_rebuild_all_panels()

func _exit_tree() -> void:
	if _fallback_flow != null:
		_fallback_flow._exit_tree()
		_fallback_flow.free()
		_fallback_flow = null

func _ensure_3d_panels() -> void:
	if main_panel != null:
		return

	main_panel = DojoPanel3D.new()
	main_panel.name = "MainPanel"
	main_panel.setup_panel(1.12, 0.80, Vector2i(780, 560), COL_CYAN)
	add_child(main_panel)

	left_panel = DojoPanel3D.new()
	left_panel.name = "LeftSetupPanel"
	left_panel.setup_panel(0.64, 0.76, Vector2i(460, 540), COL_MAGENTA)
	left_panel.position = Vector3(-0.92, 0.0, 0.18)
	left_panel.rotation_degrees = Vector3(0.0, 26.0, 0.0)
	add_child(left_panel)

	right_panel = DojoPanel3D.new()
	right_panel.name = "RightStatusPanel"
	right_panel.setup_panel(0.58, 0.28, Vector2i(420, 210), COL_AMBER)
	right_panel.position = Vector3(0.92, -0.36, 0.22)
	right_panel.rotation_degrees = Vector3(0.0, -28.0, 0.0)
	add_child(right_panel)

	_pointer_dot = MeshInstance3D.new()
	_pointer_dot.name = "UIPointerDot"
	_pointer_dot.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var dot_mesh := SphereMesh.new()
	dot_mesh.radius = 0.011
	dot_mesh.height = 0.022
	_pointer_dot.mesh = dot_mesh
	var dot_mat := StandardMaterial3D.new()
	dot_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	dot_mat.albedo_color = Color(0.35, 1.0, 0.90)
	_pointer_dot.material_override = dot_mat
	_pointer_dot.visible = false
	add_child(_pointer_dot)

func _build_minimal_desktop_strip() -> void:
	var plat := _plat()
	var is_xr := bool(plat.get("is_xr_active")) if plat != null else false
	_canvas_layer = CanvasLayer.new()
	_canvas_layer.visible = not is_xr
	add_child(_canvas_layer)

	# Sleek 1-line translucent shortcut strip at the very bottom (never clutters the 3D Dojo!)
	var bottom_panel := PanelContainer.new()
	bottom_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bottom_panel.offset_top = -34.0
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.04, 0.07, 0.10, 0.68)
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 4
	sb.content_margin_bottom = 4
	bottom_panel.add_theme_stylebox_override("panel", sb)
	_canvas_layer.add_child(bottom_panel)

	_desktop_hint_lbl = Label.new()
	_desktop_hint_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_desktop_hint_lbl.add_theme_font_size_override("font_size", 13)
	_desktop_hint_lbl.add_theme_color_override("font_color", Color(0.84, 0.94, 0.92))
	_desktop_hint_lbl.text = "Click 3D Panels Directly  |  RMB+Drag / Arrows: Look  |  Q/E+Mouse: Hands  |  Scroll: Reach  |  Tab: Auto-Hit  |  M: Poke Zeno  |  -/=: HUD Dist  |  Esc: Pause"
	bottom_panel.add_child(_desktop_hint_lbl)

	# Minimal top-right quick pills ONLY visible during active rounds on Desktop Simulator
	_round_quick_bar = HBoxContainer.new()
	_round_quick_bar.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_round_quick_bar.offset_left = -330.0
	_round_quick_bar.offset_right = -12.0
	_round_quick_bar.offset_top = 10.0
	_round_quick_bar.offset_bottom = 46.0
	_round_quick_bar.add_theme_constant_override("separation", 8)
	_round_quick_bar.visible = false
	_canvas_layer.add_child(_round_quick_bar)

	_round_quick_bar.add_child(DojoPanel3D.make_styled_button("Auto-Hit [Tab]", func(): request_auto_action.emit(), COL_EMERALD, 14, 34.0))
	_round_quick_bar.add_child(DojoPanel3D.make_styled_button("Next [N]", func(): _gf().round_timer_s = 0.01, COL_SLATE, 14, 34.0))
	_round_quick_bar.add_child(DojoPanel3D.make_styled_button("Pause [Esc]", func(): _gf().pause_session(ZenoEnums.PauseReason.MANUAL, "Manual Pause"), COL_AMBER, 14, 34.0))

func _on_state_changed(_prev: int, _next_state: int) -> void:
	_rebuild_all_panels()

func _play_click_sfx() -> void:
	var plat := _plat()
	if plat != null:
		plat.play_dojo_sfx("menu_click", 0)

func _mk_btn(text: String, cb: Callable, accent: Color = COL_CYAN, font_size: int = 19, min_h: float = 46.0, selected: bool = false) -> Button:
	return DojoPanel3D.make_styled_button(text, func():
		_play_click_sfx()
		cb.call()
	, accent, font_size, min_h, selected)

func _mk_label(text: String, font_size: int = 18, color: Color = Color(0.92, 0.96, 0.96), align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_CENTER) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.horizontal_alignment = align
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.add_theme_color_override("font_color", color)
	return lbl

## Public compatibility hook called by main.gd when settings/quality change.
func _rebuild_buttons_for_state(_state: int) -> void:
	_rebuild_all_panels()

func _rebuild_all_panels(cal_ctrl: CalibrationController = null) -> void:
	_ensure_3d_panels()
	var gf := _gf()
	var state := gf.current_state
	_last_built_state = state
	_last_built_pause_reason = gf.current_pause_reason
	if cal_ctrl != null:
		_last_built_cal_step = cal_ctrl.current_step

	var in_round := (
		state == ZenoEnums.AppState.ROUND_INTRO
		or state == ZenoEnums.AppState.ROUND_PLAY
		or state == ZenoEnums.AppState.ROUND_OUTRO
	)
	if _round_quick_bar != null:
		_round_quick_bar.visible = in_round

	left_panel.visible = (state == ZenoEnums.AppState.MAIN_MENU or state == ZenoEnums.AppState.ROUTINE_PICKER)
	right_panel.visible = (state == ZenoEnums.AppState.MAIN_MENU or state == ZenoEnums.AppState.ROUTINE_PICKER or state == ZenoEnums.AppState.RESULTS)
	main_panel.visible = true

	if in_round:
		main_panel.set_panel_dimensions(1.06, 0.30, Vector2i(760, 210))
	else:
		main_panel.set_panel_dimensions(1.12, 0.80, Vector2i(780, 560))

	if left_panel.visible:
		_build_left_setup_panel()
	if right_panel.visible:
		_build_right_status_panel()
	_build_main_panel(state, cal_ctrl)

func _build_left_setup_panel() -> void:
	left_panel.clear_content()
	var box := left_panel.get_content_box()
	var gf := _gf()
	var preset := gf.get_current_preset()
	var hand_idx := gf.profile.get_effective_hand_mode(int(gf.settings.get("hand_mode", 0)))
	var hand_names: Array[String] = ["Both Hands", "Left Only", "Right Only"]
	var hand_str: String = hand_names[clampi(hand_idx, 0, 2)]
	var no_trunk := bool(gf.settings.get("no_trunk_mode", false))
	var hq_mascot := bool(gf.settings.get("mascot_high_quality", true))
	var hud_dist := clampf(float(gf.settings.get("hud_distance_m", 1.35)), 0.90, 2.00)

	box.add_child(DojoPanel3D.make_banner_header("GAMEPLAY SETUP", COL_MAGENTA, 22))
	box.add_child(_mk_label("Customize your comfort & VR performance", 15, Color(0.76, 0.86, 0.88)))

	box.add_child(_mk_btn("Difficulty: %s (k=%.2f)" % [preset.preset_name, preset.reach_factor_k], func():
		_cycle_difficulty()
		_rebuild_all_panels()
	, COL_CYAN, 18, 46.0))

	box.add_child(_mk_btn("Hand Mode: %s" % hand_str, func():
		_cycle_hand_mode()
		_rebuild_all_panels()
	, COL_CYAN, 18, 46.0))

	box.add_child(_mk_btn("No-Trunk Safe Mode: %s" % ("ON (Level A)" if no_trunk else "OFF (All 10)"), func():
		_toggle_no_trunk()
		_rebuild_all_panels()
	, COL_AMBER if no_trunk else COL_SLATE, 18, 46.0, no_trunk))

	box.add_child(_mk_btn("Zeno Model: %s" % ("HQ Textured" if hq_mascot else "Low-Poly Fast"), func():
		request_toggle_mascot_quality.emit()
	, COL_EMERALD if hq_mascot else COL_SLATE, 18, 46.0, hq_mascot))

	var dist_row := HBoxContainer.new()
	dist_row.add_theme_constant_override("separation", 8)
	dist_row.add_child(_mk_btn("HUD -", func():
		gf.adjust_hud_distance(-0.15)
		_rebuild_all_panels()
	, COL_SLATE, 17, 42.0))
	var dist_lbl := _mk_label("Dist: %.2fm" % hud_dist, 17, Color(0.95, 0.98, 0.98))
	dist_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dist_row.add_child(dist_lbl)
	dist_row.add_child(_mk_btn("HUD +", func():
		gf.adjust_hud_distance(0.15)
		_rebuild_all_panels()
	, COL_SLATE, 17, 42.0))
	box.add_child(dist_row)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(spacer)

	box.add_child(_mk_btn("Reset Saved Data", func():
		_save().delete_all_saved_data()
		gf.has_valid_calibration = false
		gf.profile = ComfortProfile.create_default()
		gf.settings["chair_is_swivel"] = false
		_rebuild_all_panels()
	, COL_RED, 16, 40.0))

func _build_right_status_panel() -> void:
	right_panel.clear_content()
	var box := right_panel.get_content_box()
	var gf := _gf()
	var pb := _save().load_personal_best()
	var best_sc := int(pb.get("overall_best_score", 0))
	var best_rk := String(pb.get("overall_best_rank", "C"))

	box.add_child(DojoPanel3D.make_banner_header("DOJO STATUS", COL_AMBER, 19))
	box.add_child(_mk_label("Personal Best: %d pts   |   Rank: %s" % [best_sc, best_rk], 18, Color(1.0, 0.92, 0.68)))
	box.add_child(_mk_label("Calibration: %s" % ("READY (<=10s Check)" if gf.has_valid_calibration else "FIRST-TIME SETUP"), 15, Color(0.78, 0.92, 0.88)))
	box.add_child(_mk_btn("High-Five Zeno [M]", func(): request_poke_mascot.emit(), COL_EMERALD, 17, 40.0))

func _build_main_panel(state: int, cal_ctrl: CalibrationController) -> void:
	main_panel.clear_content()
	_live_header_lbl = null
	_live_body_lbl = null
	_live_sub_lbl = null
	var box := main_panel.get_content_box()
	var gf := _gf()

	match state:
		ZenoEnums.AppState.MAIN_MENU:
			box.add_child(DojoPanel3D.make_banner_header("ZENOFIT  —  ZEN DOJO ARCADE", COL_CYAN, 26))
			box.add_child(_mk_btn("PLAY  —  CHOOSE ROUTINE", func(): gf.open_routine_picker_from_menu(), COL_EMERALD, 24, 66.0, true))

			var nav_row := HBoxContainer.new()
			nav_row.add_theme_constant_override("separation", 10)
			nav_row.add_child(_mk_btn("RECALIBRATE", func(): gf.request_recalibrate(), COL_SLATE, 18, 44.0))
			nav_row.add_child(_mk_btn("CREDITS", func(): gf.open_credits(), COL_SLATE, 18, 44.0))
			nav_row.add_child(_mk_btn("QUIT", func(): gf.quit_application(), COL_RED, 18, 44.0))
			box.add_child(nav_row)

			box.add_child(_mk_label("QUICK PRACTICE — JUMP INTO ANY EXERCISE", 15, Color(0.68, 0.88, 0.86)))
			var grid := GridContainer.new()
			grid.columns = 2
			grid.add_theme_constant_override("h_separation", 8)
			grid.add_theme_constant_override("v_separation", 6)
			for m in SessionDraw.get_all_mechanics():
				var title := ZenoEnums.get_mechanic_title(m).split("(")[0].strip_edges()
				grid.add_child(_mk_btn(title, func(): gf.start_practice_mechanic(m), COL_SLATE, 16, 36.0))
			box.add_child(grid)

			box.add_child(_mk_label("Preventive seated active break  •  Not a medical device.", 14, Color(0.62, 0.72, 0.74)))

		ZenoEnums.AppState.ROUTINE_PICKER:
			var top_row := HBoxContainer.new()
			top_row.add_theme_constant_override("separation", 10)
			var back_b := _mk_btn("< BACK", func(): gf.return_to_main_menu(), COL_SLATE, 18, 44.0)
			back_b.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
			back_b.custom_minimum_size = Vector2(120.0, 44.0)
			top_row.add_child(back_b)
			var title_p := DojoPanel3D.make_banner_header("SELECT ROUTINE & DURATION", COL_CYAN, 22)
			title_p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			top_row.add_child(title_p)
			box.add_child(top_row)

			for r: int in [ZenoEnums.RoutineId.SHOULDER_NECK_REFRESH, ZenoEnums.RoutineId.POSTURE_MOBILITY_FLOW, ZenoEnums.RoutineId.FULL_UPPER_DOJO]:
				var is_sel: bool = (_picker_routine == r)
				var card_txt := "%s%s\n%s" % [
					"★ " if is_sel else "",
					ZenoEnums.get_routine_title(r),
					ZenoEnums.get_routine_description(r)
				]
				box.add_child(_mk_btn(card_txt, func():
					_picker_routine = r
					_rebuild_all_panels()
				, COL_EMERALD if is_sel else COL_SLATE, 16, 70.0, is_sel))

			var dur_row := HBoxContainer.new()
			dur_row.add_theme_constant_override("separation", 8)
			for mins in [3, 6, 10]:
				dur_row.add_child(_mk_btn("%d MIN" % mins, func(): _set_picker_duration(mins), COL_CYAN, 18, 46.0, _picker_duration_min == mins))
			dur_row.add_child(_mk_btn("Warm-Up: %s" % ("ON" if _picker_warmup else "OFF"), func():
				_picker_warmup = not _picker_warmup
				gf.settings["enable_warmup"] = _picker_warmup
				_save().save_settings(gf.settings)
				_rebuild_all_panels()
			, COL_AMBER if _picker_warmup else COL_SLATE, 17, 46.0, _picker_warmup))
			box.add_child(dur_row)

			box.add_child(_mk_btn("START SESSION (%d MIN)" % _picker_duration_min, func():
				gf.select_routine_and_start(_picker_routine, _picker_duration_min, _picker_warmup)
			, COL_EMERALD, 23, 62.0, true))

		ZenoEnums.AppState.CALIBRATION:
			box.add_child(DojoPanel3D.make_banner_header("SEATED COMFORT CALIBRATION", COL_CYAN, 24))
			_live_header_lbl = _mk_label(cal_ctrl.get_step_instruction() if cal_ctrl != null else "Sit comfortably upright.", 21, Color(0.96, 0.99, 0.98))
			_live_header_lbl.custom_minimum_size = Vector2(0.0, 120.0)
			box.add_child(_live_header_lbl)
			_live_sub_lbl = _mk_label("Only reach within comfort. Stop anytime if anything hurts.", 17, Color(0.75, 0.92, 0.88))
			box.add_child(_live_sub_lbl)

			var confirm_txt := "CONFIRM STEP [Space]"
			var skip_txt := "SKIP / DEFAULT [K]"
			if cal_ctrl != null and cal_ctrl.current_step == ZenoEnums.CalibrationStep.CHAIR_CHECK:
				confirm_txt = "STABLE CHAIR (Recommended)"
				skip_txt = "SWIVEL / ROLLING CHAIR (Lock Level B)"

			box.add_child(_mk_btn(confirm_txt, func(): request_confirm_calibration_step.emit(), COL_EMERALD, 22, 62.0, true))
			var sub_row := HBoxContainer.new()
			sub_row.add_theme_constant_override("separation", 10)
			sub_row.add_child(_mk_btn(skip_txt, func(): request_skip_calibration_step.emit(), COL_AMBER, 18, 48.0))
			sub_row.add_child(_mk_btn("MARK OBSTACLE [O]", func(): request_mark_obstacle.emit(), COL_SLATE, 18, 48.0))
			box.add_child(sub_row)
			box.add_child(_mk_btn("< BACK TO MAIN MENU", func(): gf.return_to_main_menu(), COL_SLATE, 17, 42.0))

		ZenoEnums.AppState.WARM_UP:
			box.add_child(DojoPanel3D.make_banner_header("GENTLE WARM-UP", COL_EMERALD, 24))
			_live_header_lbl = _mk_label("15.0 s", 44, Color(0.45, 1.0, 0.82))
			box.add_child(_live_header_lbl)
			_live_body_lbl = _mk_label("Roll your shoulders slowly in gentle circles and take two calm breaths.", 21, Color(0.95, 0.98, 0.98))
			box.add_child(_live_body_lbl)
			box.add_child(_mk_btn("SKIP WARM-UP & START [Space]", func(): gf.skip_warmup(), COL_EMERALD, 22, 60.0, true))
			box.add_child(_mk_btn("< BACK TO MAIN MENU", func(): gf.return_to_main_menu(), COL_SLATE, 18, 44.0))

		ZenoEnums.AppState.ROUND_INTRO, ZenoEnums.AppState.ROUND_PLAY, ZenoEnums.AppState.ROUND_OUTRO:
			_live_header_lbl = _mk_label("ROUND", 24, Color(0.42, 0.98, 0.88))
			box.add_child(_live_header_lbl)
			_live_body_lbl = _mk_label("SCORE: 0", 24, Color(1.0, 0.95, 0.72))
			box.add_child(_live_body_lbl)
			_live_sub_lbl = _mk_label("", 18, Color(0.84, 0.94, 0.96))
			box.add_child(_live_sub_lbl)

		ZenoEnums.AppState.PAUSED:
			box.add_child(DojoPanel3D.make_banner_header("PAUSED", COL_AMBER, 24))
			_live_header_lbl = _mk_label(gf.pause_message, 21, Color(0.98, 0.96, 0.90))
			_live_header_lbl.custom_minimum_size = Vector2(0.0, 100.0)
			box.add_child(_live_header_lbl)

			if gf.current_pause_reason == ZenoEnums.PauseReason.STABLE_CHAIR_CONFIRMATION:
				box.add_child(_mk_btn("CONFIRM STABLE CHAIR — CONTINUE", func(): gf.confirm_stable_chair(), COL_EMERALD, 21, 60.0, true))
				box.add_child(_mk_btn("DECLINE — SWAP TO LEVEL A EXERCISE", func(): gf.decline_stable_chair_and_substitute(), COL_AMBER, 19, 52.0))
			else:
				box.add_child(_mk_btn("RESUME (3s COUNTDOWN)", func(): gf.request_resume_with_countdown(), COL_EMERALD, 22, 60.0, true))
				box.add_child(_mk_btn("RECALIBRATE SEAT", func(): gf.request_recalibrate(), COL_CYAN, 18, 46.0))

			var row_p := HBoxContainer.new()
			row_p.add_theme_constant_override("separation", 10)
			row_p.add_child(_mk_btn("END -> RESULTS", func(): gf.finish_session_to_results(), COL_SLATE, 18, 46.0))
			row_p.add_child(_mk_btn("MAIN MENU", func(): gf.return_to_main_menu(), COL_RED, 18, 46.0))
			box.add_child(row_p)

		ZenoEnums.AppState.RESULTS:
			box.add_child(DojoPanel3D.make_banner_header("DOJO SESSION COMPLETE!", COL_EMERALD, 25))
			var pb_tag := "  ★ NEW PERSONAL BEST! ★" if gf.is_new_personal_best else ("  (Best: %d)" % gf.personal_best_score)
			box.add_child(_mk_label("DOJO RANK:  %s%s" % [gf.last_session_rank, pb_tag], 30, Color(1.0, 0.88, 0.32)))
			box.add_child(_mk_label("Total Score: %d   |   Accuracy: %.1f%%   (Hits: %d / Misses: %d)" % [
				gf.session_score, gf.round_tracker.get_accuracy_percent(), gf.round_tracker.hits, gf.round_tracker.misses
			], 20, Color(0.95, 0.99, 0.98)))
			var areas: PackedStringArray = []
			for g in gf.covered_groups:
				areas.append("[x] " + ZenoEnums.get_group_name(g))
			box.add_child(_mk_label("Duration: %.1f s  |  Max Tempo: %.0f BPM\nAreas covered: %s" % [
				gf.session_elapsed_s, gf.adaptive_tempo.max_bpm_reached, ", ".join(areas)
			], 17, Color(0.76, 0.92, 0.88)))

			box.add_child(_mk_btn("PLAY AGAIN", func(): gf.begin_session(), COL_EMERALD, 22, 60.0, true))
			var row_r := HBoxContainer.new()
			row_r.add_theme_constant_override("separation", 10)
			row_r.add_child(_mk_btn("CHOOSE ROUTINE", func(): gf.open_routine_picker_from_menu(), COL_CYAN, 18, 48.0))
			row_r.add_child(_mk_btn("MAIN MENU", func(): gf.return_to_main_menu(), COL_SLATE, 18, 48.0))
			box.add_child(row_r)
			box.add_child(_mk_label("Preventive active break • Not a medical device.", 14, Color(0.62, 0.72, 0.74)))

		ZenoEnums.AppState.CREDITS:
			box.add_child(DojoPanel3D.make_banner_header("CREDITS & ATTRIBUTION", COL_CYAN, 24))
			box.add_child(_mk_label("Zen Dojo Room Environment:\n\"Japanese Traditional Room\" by jrevel (CC BY 4.0 / Sketchfab)", 19, Color(0.96, 0.98, 0.96)))
			box.add_child(_mk_label("Zeno Mascot & Zenofit System:\nTeam Zenofit — Politeknik Elektronika Negeri Surabaya", 19, Color(0.84, 0.94, 0.90)))
			box.add_child(_mk_label("Preventive active-break software for seated desk workers.\nNot a medical device.", 16, Color(0.70, 0.80, 0.82)))
			box.add_child(_mk_btn("< BACK TO MAIN MENU", func(): gf.return_to_main_menu(), COL_EMERALD, 20, 56.0, true))

## Raycasts against all visible 3D panels and pushes hover/click directly into SubViewport.
## Returns true if the ray hit a visible 3D panel.
func process_pointer_ray(
	ray_origin: Vector3,
	ray_dir: Vector3,
	_button_pressed: bool,
	just_pressed: bool,
	just_released: bool
) -> bool:
	_ensure_3d_panels()
	var best_panel: DojoPanel3D = null
	var best_hit: Dictionary = {}
	var best_dist := 999.0

	for p: DojoPanel3D in [main_panel, left_panel, right_panel]:
		if p == null or not p.visible:
			continue
		var res: Dictionary = p.intersect_ray(ray_origin, ray_dir)
		if bool(res.get("hit", false)):
			var d := float(res.get("distance", 999.0))
			if d < best_dist:
				best_dist = d
				best_panel = p
				best_hit = res

	if _hovered_panel != null and _hovered_panel != best_panel:
		_hovered_panel.push_pointer_exit()
	_hovered_panel = best_panel

	if best_panel == null:
		if _pointer_dot != null:
			_pointer_dot.visible = false
		return false

	var vp_pos: Vector2 = best_hit["viewport_pos"]
	var world_pos: Vector3 = best_hit["world_pos"]
	if _pointer_dot != null:
		_pointer_dot.visible = true
		if is_inside_tree():
			_pointer_dot.global_position = world_pos - ray_dir.normalized() * 0.008
		else:
			_pointer_dot.position = world_pos

	if just_pressed:
		best_panel.push_pointer_button(vp_pos, true)
	elif just_released:
		best_panel.push_pointer_button(vp_pos, false)
	else:
		best_panel.push_pointer_motion(vp_pos)
	return true

func hide_pointer_dot() -> void:
	if _pointer_dot != null:
		_pointer_dot.visible = false
	if _hovered_panel != null:
		_hovered_panel.push_pointer_exit()
		_hovered_panel = null

func _set_picker_duration(mins: int) -> void:
	var gf := _gf()
	_picker_duration_min = mins
	gf.settings["preferred_duration_min"] = mins
	_save().save_settings(gf.settings)
	_rebuild_all_panels()

func _cycle_difficulty() -> void:
	var gf := _gf()
	var curr := int(gf.settings.get("difficulty", ZenoEnums.DifficultyTier.STANDARD))
	gf.settings["difficulty"] = (curr + 1) % 3
	_save().save_settings(gf.settings)

func _cycle_hand_mode() -> void:
	var gf := _gf()
	var curr := int(gf.settings.get("hand_mode", ZenoEnums.HandMode.BOTH_HANDS))
	gf.settings["hand_mode"] = (curr + 1) % 3
	_save().save_settings(gf.settings)

func _toggle_no_trunk() -> void:
	var gf := _gf()
	var curr := bool(gf.settings.get("no_trunk_mode", false))
	gf.settings["no_trunk_mode"] = not curr
	_save().save_settings(gf.settings)

func update_ui_display(
	body_frame: BodyFrame,
	calibration_ctrl: CalibrationController,
	active_mechanic: MechanicBase,
	_camera_world_pos: Vector3 = Vector3.ZERO,
	_camera_fwd_world: Vector3 = Vector3(0.0, 0.0, -1.0),
	dt: float = 0.016
) -> void:
	_ensure_3d_panels()
	var gf := _gf()
	var plat := _plat()
	var is_xr := bool(plat.get("is_xr_active")) if plat != null else false
	if _canvas_layer != null:
		_canvas_layer.visible = not is_xr

	# Rebuild UI cleanly if state, pause reason, or calibration step changed
	var cal_step := calibration_ctrl.current_step if calibration_ctrl != null else -1
	if _last_built_state != gf.current_state \
		or (gf.current_state == ZenoEnums.AppState.CALIBRATION and _last_built_cal_step != cal_step) \
		or (gf.current_state == ZenoEnums.AppState.PAUSED and _last_built_pause_reason != gf.current_pause_reason):
		_rebuild_all_panels(calibration_ctrl)

	var hud_dist := clampf(float(gf.settings.get("hud_distance_m", 1.35)), 0.90, 2.00)
	var in_active_round := (
		gf.current_state == ZenoEnums.AppState.ROUND_INTRO
		or gf.current_state == ZenoEnums.AppState.ROUND_PLAY
		or gf.current_state == ZenoEnums.AppState.ROUND_OUTRO
	)

	# Stationary World-Space Anchor inside BodyFrame (never follows camera head turns)
	var board_y_spec := 0.56 if in_active_round else 0.25
	var board_z_spec := hud_dist + (0.12 if in_active_round else 0.0)
	var target_pos := body_frame.to_godot_world(Vector3(0.0, board_y_spec, board_z_spec))
	var target_yaw_rad := body_frame.get_godot_yaw_rad()

	if not _hud_initialized:
		_smoothed_pos = target_pos
		_smoothed_yaw_rad = target_yaw_rad
		_hud_initialized = true
	else:
		var follow_speed := 10.0
		_smoothed_pos = _smoothed_pos.lerp(target_pos, clampf(dt * follow_speed, 0.0, 1.0))
		_smoothed_yaw_rad = lerp_angle(_smoothed_yaw_rad, target_yaw_rad, clampf(dt * follow_speed, 0.0, 1.0))

	if is_inside_tree():
		global_position = _smoothed_pos
	else:
		position = _smoothed_pos
	rotation = Vector3(deg_to_rad(8.0) if in_active_round else 0.0, _smoothed_yaw_rad, 0.0)

	# Update live text fields in-place for dynamic states
	match gf.current_state:
		ZenoEnums.AppState.CALIBRATION:
			if _live_header_lbl != null and calibration_ctrl != null:
				_live_header_lbl.text = calibration_ctrl.get_step_instruction()
			if _live_sub_lbl != null and calibration_ctrl != null:
				_live_sub_lbl.text = "Obstacles Marked: %d  •  Only reach comfortably; stop if anything hurts." % calibration_ctrl.working_profile.obstacles.size()

		ZenoEnums.AppState.WARM_UP:
			if _live_header_lbl != null:
				_live_header_lbl.text = "%.1f s" % maxf(0.0, gf.warmup_timer_s)

		ZenoEnums.AppState.ROUND_INTRO:
			var mech := gf.get_current_mechanic_id()
			var lvl := "Level B (Trunk/Neck)" if ZenoEnums.get_mechanic_safety_level(mech) == ZenoEnums.SafetyLevel.LEVEL_B else "Level A (Arms)"
			if _live_header_lbl != null:
				_live_header_lbl.text = "ROUND %d / %d  —  GET READY (%.1f s)  [%s]" % [gf.current_round_index + 1, gf.session_lineup.size(), gf.round_timer_s, lvl]
			if _live_body_lbl != null:
				_live_body_lbl.text = ZenoEnums.get_mechanic_title(mech)
			if _live_sub_lbl != null:
				_live_sub_lbl.text = ZenoEnums.get_mechanic_instruction(mech)

		ZenoEnums.AppState.ROUND_PLAY:
			var mech := gf.get_current_mechanic_id()
			var mult := ZenoScoring.compute_combo_multiplier(gf.round_tracker.streak)
			if _live_header_lbl != null:
				_live_header_lbl.text = "ROUND %d/%d  •  %s  •  TIME: %.1f s" % [
					gf.current_round_index + 1, gf.session_lineup.size(),
					ZenoEnums.get_mechanic_title(mech).split("(")[0].strip_edges(),
					gf.round_timer_s
				]
			if _live_body_lbl != null:
				_live_body_lbl.text = "SCORE: %d   |   STREAK: %d (x%.2f)   |   TEMPO: %.0f BPM" % [
					gf.round_tracker.combo_total_score, gf.round_tracker.streak, mult, gf.adaptive_tempo.current_bpm
				]
			if _live_sub_lbl != null:
				_live_sub_lbl.text = active_mechanic.status_hint if active_mechanic != null else ""

		ZenoEnums.AppState.ROUND_OUTRO:
			if _live_header_lbl != null:
				_live_header_lbl.text = "ROUND %d COMPLETE!" % (gf.current_round_index + 1)
			if _live_body_lbl != null:
				_live_body_lbl.text = "Score: %d   |   Accuracy: %.1f%%" % [gf.round_tracker.combo_total_score, gf.round_tracker.get_accuracy_percent()]
			if _live_sub_lbl != null:
				_live_sub_lbl.text = "Next round starting in %.1f s..." % gf.round_timer_s

		ZenoEnums.AppState.PAUSED:
			if _live_header_lbl != null:
				if gf.is_resume_counting_down:
					_live_header_lbl.text = "RESUMING IN %.1f s...\nSit comfortably upright." % gf.resume_countdown_remaining_s
				else:
					_live_header_lbl.text = gf.pause_message
