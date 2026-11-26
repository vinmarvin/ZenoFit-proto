class_name ZenoWorldUI
extends Node3D

## Spatial 3D Glass UI synchronized with UI.pdf (11 screens) in ZenoFit v1.0.
## Strictly stationary inside BodyFrame (never follows camera head pitch/yaw) with user-configurable
## HUD distance (1.30–2.20 m, default 1.65 m) and HUD scale (0.85–1.20x, default 1.0x).
## Zero debug exercise codes (M01..M10) or keyboard shortcuts shown inside VR panels.

signal request_confirm_calibration_step()
signal request_skip_calibration_step()
signal request_recenter_view()
signal request_auto_action()

var flow_override: GameFlowController = null

var main_panel: DojoPanel3D
var bottom_cue_panel: DojoPanel3D
var _pointer_dot: MeshInstance3D

# Live in-place labels for dynamic states
var _live_title_lbl: Label = null
var _live_sub_lbl: Label = null
var _live_score_lbl: Label = null
var _live_timer_lbl: Label = null
var _live_progress: ProgressBar = null
var _live_bottom_cue_lbl: Label = null
var _last_built_state: int = -1
var _last_built_cal_step: int = -1
var _last_built_pause_reason: int = -1

# Desktop-only helper bar (strictly hidden in VR)
var _canvas_layer: CanvasLayer
var _round_quick_bar: HBoxContainer

var _hud_initialized: bool = false
var _smoothed_pos: Vector3 = Vector3(0.0, 0.20, -1.65)
var _smoothed_yaw_rad: float = 0.0
var _hovered_panel: DojoPanel3D = null
var _settings_tab: int = 0 # 0=Comfort, 1=Input, 2=Audio, 3=Display
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
	_ensure_3d_panels()
	_build_desktop_only_strip()
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
	main_panel.setup_panel(1.38, 0.80, Vector2i(1180, 684))
	add_child(main_panel)

	bottom_cue_panel = DojoPanel3D.new()
	bottom_cue_panel.name = "BottomCuePanel"
	bottom_cue_panel.setup_panel(0.90, 0.095, Vector2i(820, 86))
	bottom_cue_panel.position = Vector3(0.0, -0.45, 0.0)
	bottom_cue_panel.visible = false
	add_child(bottom_cue_panel)

	_pointer_dot = MeshInstance3D.new()
	_pointer_dot.name = "UIPointerDot"
	_pointer_dot.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var dot_mesh := SphereMesh.new()
	dot_mesh.radius = 0.010
	dot_mesh.height = 0.020
	_pointer_dot.mesh = dot_mesh
	var dot_mat := StandardMaterial3D.new()
	dot_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	dot_mat.albedo_color = Color(0.76, 0.94, 0.80)
	_pointer_dot.material_override = dot_mat
	_pointer_dot.visible = false
	add_child(_pointer_dot)

func _build_desktop_only_strip() -> void:
	var plat := _plat()
	var is_xr := bool(plat.get("is_xr_active")) if plat != null else false
	_canvas_layer = CanvasLayer.new()
	_canvas_layer.visible = not is_xr
	add_child(_canvas_layer)

	var bottom_panel := PanelContainer.new()
	bottom_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bottom_panel.offset_top = -32.0
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.05, 0.08, 0.06, 0.70)
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 4
	sb.content_margin_bottom = 4
	bottom_panel.add_theme_stylebox_override("panel", sb)
	_canvas_layer.add_child(bottom_panel)

	var hint_lbl := DojoPanel3D.make_label(
		"Desktop Simulator  |  Click Panels Directly  |  RMB+Drag / Arrows: Look  |  Q/E+Mouse: Hands  |  Scroll: Depth  |  [/]: Wrist Roll  |  Tab: Auto-Hit  |  Esc: Pause",
		12, DojoPanel3D.COL_TEXT_MUTED, HORIZONTAL_ALIGNMENT_CENTER
	)
	bottom_panel.add_child(hint_lbl)

	_round_quick_bar = HBoxContainer.new()
	_round_quick_bar.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_round_quick_bar.offset_left = -310.0
	_round_quick_bar.offset_right = -12.0
	_round_quick_bar.offset_top = 10.0
	_round_quick_bar.offset_bottom = 44.0
	_round_quick_bar.add_theme_constant_override("separation", 8)
	_round_quick_bar.visible = false
	_canvas_layer.add_child(_round_quick_bar)

	_round_quick_bar.add_child(DojoPanel3D.make_primary_button("Auto-Hit", func(): request_auto_action.emit(), 13, 32.0))
	_round_quick_bar.add_child(DojoPanel3D.make_secondary_button("Next", func(): _gf().round_timer_s = 0.01, false, 13, 32.0))
	_round_quick_bar.add_child(DojoPanel3D.make_secondary_button("Pause", func(): _gf().pause_session(ZenoEnums.PauseReason.MANUAL, "Session paused"), false, 13, 32.0))

func _on_state_changed(_prev: int, _next_state: int) -> void:
	_rebuild_all_panels()

func _play_click_sfx() -> void:
	var plat := _plat()
	if plat != null:
		plat.play_sfx("menu_click", 0)

func _btn_primary(text: String, cb: Callable, font_size: int = 19, min_h: float = 50.0) -> Button:
	return DojoPanel3D.make_primary_button(text, func():
		_play_click_sfx()
		cb.call()
	, font_size, min_h)

func _btn_secondary(text: String, cb: Callable, selected: bool = false, font_size: int = 17, min_h: float = 44.0) -> Button:
	return DojoPanel3D.make_secondary_button(text, func():
		_play_click_sfx()
		cb.call()
	, selected, font_size, min_h)

func _btn_destructive(text: String, cb: Callable, font_size: int = 17, min_h: float = 44.0) -> Button:
	return DojoPanel3D.make_destructive_button(text, func():
		_play_click_sfx()
		cb.call()
	, font_size, min_h)

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

	main_panel.visible = true
	bottom_cue_panel.visible = in_round

	if in_round:
		main_panel.set_panel_dimensions(1.14, 0.16, Vector2i(1020, 144))
		main_panel.position = Vector3(0.0, 0.45, 0.0)
		bottom_cue_panel.position = Vector3(0.0, -0.45, 0.0)
		_build_bottom_cue_bar()
	elif state == ZenoEnums.AppState.PAUSED:
		main_panel.set_panel_dimensions(0.96, 0.72, Vector2i(920, 690))
		main_panel.position = Vector3(-0.08, 0.0, 0.0)
	elif state == ZenoEnums.AppState.EXIT_CONFIRM:
		main_panel.set_panel_dimensions(0.84, 0.56, Vector2i(760, 506))
		main_panel.position = Vector3(-0.06, 0.0, 0.0)
	elif state == ZenoEnums.AppState.EXERCISE_PREVIEW:
		main_panel.set_panel_dimensions(1.38, 0.80, Vector2i(1180, 684))
		main_panel.position = Vector3.ZERO
	else:
		main_panel.set_panel_dimensions(1.38, 0.80, Vector2i(1180, 684))
		main_panel.position = Vector3(-0.20, 0.0, 0.0)

	_build_main_panel(state, cal_ctrl)

func _build_bottom_cue_bar() -> void:
	bottom_cue_panel.clear_content()
	var box := bottom_cue_panel.get_content_box()
	_live_bottom_cue_lbl = DojoPanel3D.make_label(
		"Stay within your comfortable seated range", 18, DojoPanel3D.COL_TEXT_MAIN, HORIZONTAL_ALIGNMENT_CENTER
	)
	_live_bottom_cue_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_live_bottom_cue_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	box.add_child(_live_bottom_cue_lbl)

func _build_header_bar(eyebrow: String, title: String, subtitle: String, show_back: bool, back_cb: Callable) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	if show_back:
		var back_btn := _btn_secondary("<  Back", back_cb, false, 17, 44.0)
		back_btn.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		back_btn.custom_minimum_size = Vector2(120.0, 44.0)
		row.add_child(back_btn)
	var title_col := VBoxContainer.new()
	title_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_col.add_theme_constant_override("separation", 2)
	title_col.add_child(DojoPanel3D.make_section_eyebrow(eyebrow))
	title_col.add_child(DojoPanel3D.make_label(title, 30, DojoPanel3D.COL_TEXT_MAIN))
	if not subtitle.is_empty():
		title_col.add_child(DojoPanel3D.make_label(subtitle, 16, DojoPanel3D.COL_TEXT_MUTED))
	row.add_child(title_col)
	return row

func _build_main_panel(state: int, cal_ctrl: CalibrationController) -> void:
	main_panel.clear_content()
	_live_title_lbl = null
	_live_sub_lbl = null
	_live_score_lbl = null
	_live_timer_lbl = null
	_live_progress = null
	var box := main_panel.get_content_box()
	var gf := _gf()
	var input_mode := int(gf.settings.get("input_mode", ZenoEnums.InputMode.CONTROLLER))

	match state:
		ZenoEnums.AppState.WELCOME:
			var cols := HBoxContainer.new()
			cols.size_flags_vertical = Control.SIZE_EXPAND_FILL
			cols.add_theme_constant_override("separation", 24)
			box.add_child(cols)

			# Left hero welcome card (Page 01)
			var left_card := DojoPanel3D.make_card_panel(Color(0.10, 0.15, 0.12, 0.72), DojoPanel3D.COL_CARD_BORDER, 28, 28)
			left_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			var lvb := VBoxContainer.new()
			lvb.add_theme_constant_override("separation", 12)
			left_card.add_child(lvb)
			lvb.add_child(DojoPanel3D.make_pill_badge("SEATED ACTIVE BREAK  •  OPENXR"))
			lvb.add_child(DojoPanel3D.make_label("ZENOFIT", 20, DojoPanel3D.COL_TEXT_MUTED))
			lvb.add_child(DojoPanel3D.make_label("Move freely.\nFeel centered.", 42, DojoPanel3D.COL_TEXT_MAIN))
			lvb.add_child(DojoPanel3D.make_label("Comfortable seated movement and mindful active breaks, designed around your workspace.", 18, DojoPanel3D.COL_TEXT_MUTED))
			var sp := Control.new()
			sp.size_flags_vertical = Control.SIZE_EXPAND_FILL
			lvb.add_child(sp)
			lvb.add_child(DojoPanel3D.make_label("Preventive wellness game • Not a medical device.", 14, DojoPanel3D.COL_TEXT_MUTED))
			cols.add_child(left_card)

			# Right seated setup column
			var right_col := VBoxContainer.new()
			right_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			right_col.add_theme_constant_override("separation", 12)
			right_col.add_child(DojoPanel3D.make_section_eyebrow("SEATED SETUP"))
			right_col.add_child(DojoPanel3D.make_label("Seated Comfort Check", 28, DojoPanel3D.COL_TEXT_MAIN))
			right_col.add_child(DojoPanel3D.make_metric_tile("SEATED HEIGHT", "%.2f m" % gf.seated_height_m, "Ready & centered"))

			var mode_txt := "Input Mode: %s (Locked Per Session)" % ZenoEnums.get_input_mode_name(input_mode)
			right_col.add_child(_btn_secondary(mode_txt + "   •   Switch", func():
				var next_m := ZenoEnums.InputMode.HAND_TRACKING if input_mode == ZenoEnums.InputMode.CONTROLLER else ZenoEnums.InputMode.CONTROLLER
				gf.set_input_mode(next_m)
				_rebuild_all_panels()
			, false, 16, 48.0))

			var setup_row := HBoxContainer.new()
			setup_row.add_theme_constant_override("separation", 10)
			setup_row.add_child(_btn_secondary("Calibrate Reach", func(): gf.open_calibration(ZenoEnums.AppState.WELCOME), false, 16, 48.0))
			setup_row.add_child(_btn_secondary("Recenter View", func(): request_recenter_view.emit(), false, 16, 48.0))
			right_col.add_child(setup_row)

			var rsp := Control.new()
			rsp.size_flags_vertical = Control.SIZE_EXPAND_FILL
			right_col.add_child(rsp)
			right_col.add_child(_btn_primary("Continue to Dojo  >", func(): gf.continue_to_main_menu(), 22, 60.0))
			cols.add_child(right_col)

		ZenoEnums.AppState.MAIN_MENU:
			var cols := HBoxContainer.new()
			cols.size_flags_vertical = Control.SIZE_EXPAND_FILL
			cols.add_theme_constant_override("separation", 24)
			box.add_child(cols)

			# Left greeting & weekly flow column (Page 02)
			var left_col := VBoxContainer.new()
			left_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			left_col.add_theme_constant_override("separation", 12)
			left_col.add_child(DojoPanel3D.make_pill_badge("DOJO READY  •  %s" % ZenoEnums.get_input_mode_name(input_mode).to_upper()))
			left_col.add_child(DojoPanel3D.make_label("Take a breather.", 40, DojoPanel3D.COL_TEXT_MAIN))
			left_col.add_child(DojoPanel3D.make_label("Find your balance. Move at your pace without leaving your chair.", 18, DojoPanel3D.COL_TEXT_MUTED))

			var stats := _save().get_weekly_stats()
			var flow_tile := DojoPanel3D.make_metric_tile(
				"RECENT FLOW",
				"%d sessions" % int(stats["sessions_count"]),
				"Best Score: %d  •  Rank %s" % [int(stats["best_score"]), String(stats["best_rank"])]
			)
			left_col.add_child(flow_tile)

			var sp_l := Control.new()
			sp_l.size_flags_vertical = Control.SIZE_EXPAND_FILL
			left_col.add_child(sp_l)

			var util_row := HBoxContainer.new()
			util_row.add_theme_constant_override("separation", 10)
			util_row.add_child(_btn_secondary("Credits", func(): gf.open_credits(), false, 15, 40.0))
			util_row.add_child(_btn_secondary("Recenter", func(): request_recenter_view.emit(), false, 15, 40.0))
			left_col.add_child(util_row)
			cols.add_child(left_col)

			# Right action cards (Page 02)
			var right_col := VBoxContainer.new()
			right_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			right_col.add_theme_constant_override("separation", 12)

			var hero_btn := _btn_primary("Start Quick Break  •  3 Min Mix\nBalanced 5-round upper-body flow", func(): gf.start_quick_break(), 21, 96.0)
			right_col.add_child(hero_btn)

			var grid := GridContainer.new()
			grid.columns = 2
			grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
			grid.add_theme_constant_override("h_separation", 12)
			grid.add_theme_constant_override("v_separation", 12)
			var lib_btn := _btn_secondary("Exercise Library\n%d seated movements" % SessionDraw.get_all_exercises().size(), func(): gf.open_exercise_select(ZenoEnums.ExerciseCategory.ALL), false, 18, 92.0)
			var tut_btn := _btn_secondary("Tutorial\nLearn the controls", func(): gf.open_tutorial(), false, 18, 92.0)
			var set_btn := _btn_secondary("Settings\nComfort & display", func(): gf.open_settings(ZenoEnums.AppState.MAIN_MENU), false, 18, 92.0)
			var ext_btn := _btn_destructive("Exit Experience\nLeave session", func(): gf.request_exit_confirm(), 18, 92.0)
			for b in [lib_btn, tut_btn, set_btn, ext_btn]:
				b.size_flags_vertical = Control.SIZE_EXPAND_FILL
				grid.add_child(b)
			right_col.add_child(grid)
			cols.add_child(right_col)

		ZenoEnums.AppState.EXERCISE_SELECT:
			box.add_child(_build_header_bar("EXERCISE LIBRARY", "Choose your movement", "All exercises are designed for comfortable seated motion.", true, func(): gf.return_to_main_menu()))

			var tabs := HBoxContainer.new()
			tabs.add_theme_constant_override("separation", 10)
			for cat in [ZenoEnums.ExerciseCategory.ALL, ZenoEnums.ExerciseCategory.ACTIVE, ZenoEnums.ExerciseCategory.MOBILITY, ZenoEnums.ExerciseCategory.POSTURE]:
				var is_sel: bool = (gf.filter_category == cat)
				tabs.add_child(_btn_secondary(ZenoEnums.get_category_name(cat), func():
					gf.filter_category = cat
					_rebuild_all_panels()
				, is_sel, 16, 40.0))
			box.add_child(tabs)

			var list := SessionDraw.get_exercises_by_category(gf.filter_category)
			var is_compact := list.size() > 8
			var grid := GridContainer.new()
			grid.columns = 4 if list.size() >= 4 else maxi(1, list.size())
			grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
			grid.add_theme_constant_override("h_separation", 10 if is_compact else 12)
			grid.add_theme_constant_override("v_separation", 8 if is_compact else 12)
			for ex_id in list:
				var card := DojoPanel3D.make_card_panel(DojoPanel3D.COL_CARD_BG, DojoPanel3D.COL_CARD_BORDER, 12 if is_compact else 14, 8 if is_compact else 12)
				card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				card.size_flags_vertical = Control.SIZE_EXPAND_FILL
				var cvb := VBoxContainer.new()
				cvb.add_theme_constant_override("separation", 3 if is_compact else 6)
				card.add_child(cvb)
				cvb.add_child(DojoPanel3D.make_pill_badge(ZenoEnums.get_exercise_area(ex_id)))
				cvb.add_child(DojoPanel3D.make_label(ZenoEnums.get_exercise_title(ex_id), 18 if is_compact else 21, DojoPanel3D.COL_TEXT_MAIN))
				var tag_lbl := DojoPanel3D.make_label(ZenoEnums.get_exercise_tagline(ex_id), 12 if is_compact else 14, DojoPanel3D.COL_TEXT_MUTED)
				tag_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
				cvb.add_child(tag_lbl)
				cvb.add_child(_btn_primary("Preview", func(): gf.open_exercise_preview(ex_id), 14 if is_compact else 16, 32.0 if is_compact else 40.0))
				grid.add_child(card)
			box.add_child(grid)

		ZenoEnums.AppState.EXERCISE_PREVIEW:
			var ex := gf.selected_exercise_id
			box.add_child(_build_header_bar("EXERCISE PREVIEW", ZenoEnums.get_exercise_title(ex), "%s  •  %s" % [ZenoEnums.get_exercise_area(ex), gf.get_current_preset().preset_name], true, func(): gf.open_exercise_select(gf.filter_category)))

			var cols := HBoxContainer.new()
			cols.size_flags_vertical = Control.SIZE_EXPAND_FILL
			cols.add_theme_constant_override("separation", 24)
			box.add_child(cols)

			# Left space intentionally frames the live 3D Zeno mascot demonstration
			var zeno_frame := DojoPanel3D.make_card_panel(Color(0.08, 0.12, 0.10, 0.42), DojoPanel3D.COL_CARD_BORDER, 16, 16)
			zeno_frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			var zvb := VBoxContainer.new()
			zeno_frame.add_child(zvb)
			zvb.add_child(DojoPanel3D.make_section_eyebrow("MOVEMENT PREVIEW  •  LIVE COACH"))
			var zsp := Control.new()
			zsp.size_flags_vertical = Control.SIZE_EXPAND_FILL
			zvb.add_child(zsp)
			zvb.add_child(DojoPanel3D.make_pill_badge("Move only within your comfortable range"))
			cols.add_child(zeno_frame)

			# Right instructions & start controls
			var right_col := VBoxContainer.new()
			right_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			right_col.add_theme_constant_override("separation", 10)
			right_col.add_child(DojoPanel3D.make_section_eyebrow("HOW TO MOVE"))
			var steps := ZenoEnums.get_exercise_preview_steps(ex)
			for i in range(steps.size()):
				var step_card := DojoPanel3D.make_card_panel(DojoPanel3D.COL_CARD_BG, DojoPanel3D.COL_CARD_BORDER, 14, 10)
				step_card.add_child(DojoPanel3D.make_label("0%d   %s" % [i + 1, steps[i]], 16, DojoPanel3D.COL_TEXT_MAIN))
				right_col.add_child(step_card)

			var meta_row := HBoxContainer.new()
			meta_row.add_theme_constant_override("separation", 10)
			meta_row.add_child(DojoPanel3D.make_metric_tile("DURATION", "45 sec", ZenoEnums.get_input_mode_name(input_mode)))
			meta_row.add_child(DojoPanel3D.make_metric_tile("COMFORT", gf.get_current_preset().preset_name, "Reach %.0f%%" % (gf.get_current_preset().reach_factor_k * 100.0)))
			right_col.add_child(meta_row)

			var dumbbell_note := ZenoEnums.get_exercise_dumbbell_note(ex)
			if not dumbbell_note.is_empty():
				var note_card := DojoPanel3D.make_card_panel(Color(0.14, 0.22, 0.18, 0.85), DojoPanel3D.COL_ACCENT_TEAL, 12, 10)
				note_card.add_child(DojoPanel3D.make_label(dumbbell_note, 13, DojoPanel3D.COL_TEXT_MAIN))
				right_col.add_child(note_card)

			var sp_r := Control.new()
			sp_r.size_flags_vertical = Control.SIZE_EXPAND_FILL
			right_col.add_child(sp_r)
			right_col.add_child(_btn_primary("Start Exercise  >", func(): gf.start_single_exercise(ex), 21, 56.0))
			cols.add_child(right_col)

		ZenoEnums.AppState.CALIBRATION:
			var step_idx := cal_ctrl.get_step_index() if cal_ctrl != null else 1
			var step_title := cal_ctrl.get_step_title() if cal_ctrl != null else "Seated Posture"
			var step_inst := cal_ctrl.get_step_instruction() if cal_ctrl != null else "Sit comfortably upright."
			box.add_child(_build_header_bar("COMFORT CALIBRATION  •  STEP %d OF 3" % step_idx, step_title, "Reach only where comfortable. Stop anytime if anything feels strained.", true, func(): gf.return_to_main_menu()))
			box.add_child(DojoPanel3D.make_progress_bar(float(step_idx) / 3.0))

			var card := DojoPanel3D.make_card_panel(DojoPanel3D.COL_CARD_BG, DojoPanel3D.COL_CARD_BORDER, 24, 24)
			card.size_flags_vertical = Control.SIZE_EXPAND_FILL
			_live_title_lbl = DojoPanel3D.make_label(step_inst, 24, DojoPanel3D.COL_TEXT_MAIN, HORIZONTAL_ALIGNMENT_CENTER)
			_live_title_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
			_live_title_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			card.add_child(_live_title_lbl)
			box.add_child(card)

			var act_row := HBoxContainer.new()
			act_row.add_theme_constant_override("separation", 12)
			act_row.add_child(_btn_secondary("Skip Step", func(): request_skip_calibration_step.emit(), false, 18, 54.0))
			act_row.add_child(_btn_primary("Confirm Step", func(): request_confirm_calibration_step.emit(), 20, 54.0))
			box.add_child(act_row)

		ZenoEnums.AppState.ROUND_INTRO, ZenoEnums.AppState.ROUND_PLAY, ZenoEnums.AppState.ROUND_OUTRO:
			var ex := gf.get_current_exercise_id()
			var top_row := HBoxContainer.new()
			top_row.add_theme_constant_override("separation", 16)
			box.add_child(top_row)

			var info_col := VBoxContainer.new()
			info_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			info_col.add_theme_constant_override("separation", 2)
			_live_title_lbl = DojoPanel3D.make_label(ZenoEnums.get_exercise_title(ex), 26, DojoPanel3D.COL_TEXT_MAIN)
			_live_title_lbl.autowrap_mode = TextServer.AUTOWRAP_OFF
			_live_sub_lbl = DojoPanel3D.make_label(ZenoEnums.get_exercise_area(ex), 15, DojoPanel3D.COL_ACCENT_TEAL)
			_live_sub_lbl.autowrap_mode = TextServer.AUTOWRAP_OFF
			info_col.add_child(_live_title_lbl)
			info_col.add_child(_live_sub_lbl)
			top_row.add_child(info_col)

			_live_score_lbl = DojoPanel3D.make_label("SCORE  0", 24, DojoPanel3D.COL_TEXT_MAIN, HORIZONTAL_ALIGNMENT_CENTER)
			_live_score_lbl.autowrap_mode = TextServer.AUTOWRAP_OFF
			_live_score_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			_live_score_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			_live_score_lbl.custom_minimum_size = Vector2(240.0, 0.0)
			top_row.add_child(_live_score_lbl)

			_live_timer_lbl = DojoPanel3D.make_label("00:30", 28, DojoPanel3D.COL_PRIMARY, HORIZONTAL_ALIGNMENT_RIGHT)
			_live_timer_lbl.autowrap_mode = TextServer.AUTOWRAP_OFF
			_live_timer_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			_live_timer_lbl.size_flags_horizontal = Control.SIZE_SHRINK_END
			_live_timer_lbl.custom_minimum_size = Vector2(115.0, 0.0)
			top_row.add_child(_live_timer_lbl)

			var pause_btn := _btn_secondary("Pause", func(): gf.pause_session(ZenoEnums.PauseReason.MANUAL, "Session paused"), false, 16, 44.0)
			pause_btn.size_flags_horizontal = Control.SIZE_SHRINK_END
			pause_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			pause_btn.custom_minimum_size = Vector2(110.0, 44.0)
			top_row.add_child(pause_btn)

			_live_progress = DojoPanel3D.make_progress_bar(0.0, DojoPanel3D.COL_PRIMARY, 10.0)
			box.add_child(_live_progress)

		ZenoEnums.AppState.PAUSED:
			var badge_center := CenterContainer.new()
			badge_center.add_child(DojoPanel3D.make_pill_badge("SESSION PAUSED"))
			box.add_child(badge_center)

			_live_title_lbl = DojoPanel3D.make_label("Take your time.", 36, DojoPanel3D.COL_TEXT_MAIN, HORIZONTAL_ALIGNMENT_CENTER)
			box.add_child(_live_title_lbl)

			var sub_msg := gf.pause_message if (not gf.pause_message.is_empty() and gf.pause_message != "Session paused") else "Your progress is saved. Resume when you're ready."
			_live_sub_lbl = DojoPanel3D.make_label(sub_msg, 17, DojoPanel3D.COL_TEXT_MUTED, HORIZONTAL_ALIGNMENT_CENTER)
			box.add_child(_live_sub_lbl)

			var ex := gf.get_current_exercise_id()
			var round_sub := ("Round %d of %d" % [gf.current_round_index + 1, maxi(1, gf.session_lineup.size())]) if gf.is_quick_break_mode else ZenoEnums.get_exercise_area(ex)
			var metrics := HBoxContainer.new()
			metrics.add_theme_constant_override("separation", 12)
			metrics.add_child(DojoPanel3D.make_metric_tile("EXERCISE", ZenoEnums.get_exercise_title(ex), round_sub))
			metrics.add_child(DojoPanel3D.make_metric_tile("TIME LEFT", _format_mm_ss(gf.round_timer_s), ZenoEnums.get_input_mode_name(gf.active_input_mode)))
			metrics.add_child(DojoPanel3D.make_metric_tile(
				"CURRENT SCORE",
				"%d" % gf.round_tracker.combo_total_score,
				"%d hits  •  %dx streak" % [gf.round_tracker.hits, gf.round_tracker.streak]
			))
			box.add_child(metrics)

			if gf.current_pause_reason == ZenoEnums.PauseReason.INPUT_LOST:
				box.add_child(_btn_primary("Switch Input Mode & Resume", func(): gf.switch_input_mode_and_resume(), 21, 60.0))
			else:
				box.add_child(_btn_primary("Resume Workout", func(): gf.request_resume_with_countdown(), 21, 60.0))

			var grid := GridContainer.new()
			grid.columns = 2
			grid.add_theme_constant_override("h_separation", 12)
			grid.add_theme_constant_override("v_separation", 12)
			grid.add_child(_btn_secondary("Restart Exercise", func(): gf.begin_session(), false, 18, 50.0))
			grid.add_child(_btn_secondary("Settings", func(): gf.open_settings(ZenoEnums.AppState.PAUSED), false, 18, 50.0))
			grid.add_child(_btn_secondary("Recenter View", func(): request_recenter_view.emit(), false, 18, 50.0))
			grid.add_child(_btn_secondary("Main Menu", func(): gf.return_to_main_menu(), false, 18, 50.0))
			box.add_child(grid)

			var psp := Control.new()
			psp.size_flags_vertical = Control.SIZE_EXPAND_FILL
			box.add_child(psp)
			box.add_child(_btn_destructive("Exit Experience", func(): gf.request_exit_confirm(), 18, 48.0))

		ZenoEnums.AppState.RESULTS:
			box.add_child(DojoPanel3D.make_section_eyebrow("SESSION COMPLETE"))
			var pb_tag := "  •  New Personal Best!" if gf.is_new_personal_best else ""
			box.add_child(DojoPanel3D.make_label("Nice work.%s" % pb_tag, 38, DojoPanel3D.COL_TEXT_MAIN))
			box.add_child(DojoPanel3D.make_label(
				"You completed %s." % ("your Quick Break mix" if gf.is_quick_break_mode else ZenoEnums.get_exercise_title(gf.selected_exercise_id)),
				18, DojoPanel3D.COL_TEXT_MUTED
			))

			var metrics := HBoxContainer.new()
			metrics.add_theme_constant_override("separation", 14)
			metrics.add_child(DojoPanel3D.make_metric_tile("SCORE", "%d" % gf.session_score, "Best: %d" % gf.personal_best_score))
			metrics.add_child(DojoPanel3D.make_metric_tile("SESSION TIME", _format_mm_ss(gf.session_elapsed_s), "%s Mode" % ZenoEnums.get_input_mode_name(gf.active_input_mode)))
			metrics.add_child(DojoPanel3D.make_metric_tile("ACCURACY & RANK", "%.0f%%  (%s)" % [gf.round_tracker.get_accuracy_percent(), gf.last_session_rank], "%d hits  •  %d max streak" % [gf.round_tracker.hits, gf.round_tracker.max_streak]))
			box.add_child(metrics)

			var areas_str := ", ".join(gf.covered_areas) if not gf.covered_areas.is_empty() else "Upper Body"
			box.add_child(DojoPanel3D.make_card_panel(DojoPanel3D.COL_CARD_BG, DojoPanel3D.COL_CARD_BORDER, 16, 12))
			box.get_child(box.get_child_count() - 1).add_child(DojoPanel3D.make_label("Areas moved: %s" % areas_str, 17, DojoPanel3D.COL_ACCENT_TEAL))

			var sp := Control.new()
			sp.size_flags_vertical = Control.SIZE_EXPAND_FILL
			box.add_child(sp)

			var btn_row := HBoxContainer.new()
			btn_row.add_theme_constant_override("separation", 12)
			btn_row.add_child(_btn_secondary("Repeat", func(): gf.begin_session(), false, 18, 52.0))
			btn_row.add_child(_btn_secondary("Choose Another", func(): gf.open_exercise_select(gf.filter_category), false, 18, 52.0))
			btn_row.add_child(_btn_primary("Main Menu", func(): gf.return_to_main_menu(), 18, 52.0))
			box.add_child(btn_row)

		ZenoEnums.AppState.SETTINGS:
			box.add_child(_build_header_bar("CUSTOMIZE", "Settings & Comfort", "Tune ZenoFit to your chair, input preference, and display.", true, func(): gf.close_settings()))
			var cols := HBoxContainer.new()
			cols.size_flags_vertical = Control.SIZE_EXPAND_FILL
			cols.add_theme_constant_override("separation", 18)
			box.add_child(cols)

			# Left sidebar tabs (Page 08)
			var sidebar := VBoxContainer.new()
			sidebar.custom_minimum_size = Vector2(220.0, 0.0)
			sidebar.add_theme_constant_override("separation", 10)
			var tab_names := ["Comfort", "Input & Haptics", "Audio", "Display & HUD"]
			for i in range(tab_names.size()):
				sidebar.add_child(_btn_secondary(tab_names[i], func():
					_settings_tab = i
					_rebuild_all_panels()
				, _settings_tab == i, 17, 48.0))
			cols.add_child(sidebar)

			# Right category detail card
			var detail := DojoPanel3D.make_card_panel(DojoPanel3D.COL_CARD_BG, DojoPanel3D.COL_CARD_BORDER, 22, 18)
			detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			var dvb := VBoxContainer.new()
			dvb.add_theme_constant_override("separation", 12)
			detail.add_child(dvb)
			_populate_settings_tab(dvb)
			cols.add_child(detail)

		ZenoEnums.AppState.TUTORIAL:
			box.add_child(_build_header_bar("LEARN", "Learn the Controls", "Step %d of 3" % (gf.tutorial_step + 1), true, func(): gf.return_to_main_menu()))
			var tut_titles := ["Point & Select", "Move Within Comfort", "Pause Anytime"]
			var tut_bodies := [
				"Aim your controller ray (or hand pinch) at any panel button and press trigger to confirm. During active workouts, rays turn off automatically so every hit requires real movement.",
				"Targets always stay inside your calibrated reach envelope (<= 85%). Keep your shoulders relaxed and break boards or trace rings smoothly at your own pace.",
				"Drop both hands comfortably to your lap for 2 seconds to trigger Auto-Pause with room passthrough, or press the menu button anytime."
			]
			var card := DojoPanel3D.make_card_panel(DojoPanel3D.COL_CARD_BG, DojoPanel3D.COL_CARD_BORDER, 26, 24)
			card.size_flags_vertical = Control.SIZE_EXPAND_FILL
			var cvb := VBoxContainer.new()
			cvb.add_theme_constant_override("separation", 12)
			card.add_child(cvb)
			cvb.add_child(DojoPanel3D.make_pill_badge("0%d  •  GUIDE" % (gf.tutorial_step + 1)))
			cvb.add_child(DojoPanel3D.make_label(tut_titles[gf.tutorial_step], 30, DojoPanel3D.COL_TEXT_MAIN))
			cvb.add_child(DojoPanel3D.make_label(tut_bodies[gf.tutorial_step], 19, DojoPanel3D.COL_TEXT_MUTED))
			box.add_child(card)

			var nav_row := HBoxContainer.new()
			nav_row.add_theme_constant_override("separation", 12)
			nav_row.add_child(_btn_secondary("Previous", func():
				gf.tutorial_step = maxi(0, gf.tutorial_step - 1)
				_rebuild_all_panels()
			, false, 18, 50.0))
			if gf.tutorial_step < 2:
				nav_row.add_child(_btn_primary("Next  >", func():
					gf.tutorial_step = mini(2, gf.tutorial_step + 1)
					_rebuild_all_panels()
				, 18, 50.0))
			else:
				nav_row.add_child(_btn_primary("Done", func(): gf.return_to_main_menu(), 18, 50.0))
			box.add_child(nav_row)

		ZenoEnums.AppState.CREDITS:
			box.add_child(_build_header_bar("ATTRIBUTION", "Credits & Safety", "ZenoFit Seated Active-Break XR Application", true, func(): gf.return_to_main_menu()))
			var c1 := DojoPanel3D.make_card_panel(DojoPanel3D.COL_CARD_BG, DojoPanel3D.COL_CARD_BORDER, 20, 16)
			var c1_vb := VBoxContainer.new()
			c1_vb.add_theme_constant_override("separation", 8)
			c1.add_child(c1_vb)
			c1_vb.add_child(DojoPanel3D.make_label("Team ZenoFit — Group 4 (Lebah Ganteng)\nInstitut Teknologi Sepuluh Nopember (ITS)", 20, DojoPanel3D.COL_TEXT_MAIN))
			c1_vb.add_child(DojoPanel3D.make_label("Room Environment: \"Japanese Traditional Room\" by jrevel (CC BY 4.0 / Sketchfab)", 16, DojoPanel3D.COL_TEXT_MUTED))
			c1_vb.add_child(DojoPanel3D.make_label("3D Assets: Zeno Mascot & Karate Board (Claude Sonnet 5.5)", 16, DojoPanel3D.COL_TEXT_MUTED))
			c1_vb.add_child(DojoPanel3D.make_label("Disclaimer: Preventive seated active-break game for desk workers. Not a medical device.", 15, DojoPanel3D.COL_ACCENT_TEAL))
			c1.size_flags_vertical = Control.SIZE_EXPAND_FILL
			box.add_child(c1)

		ZenoEnums.AppState.EXIT_CONFIRM:
			var exit_badge := CenterContainer.new()
			exit_badge.add_child(DojoPanel3D.make_pill_badge("EXIT ZENOFIT"))
			box.add_child(exit_badge)
			box.add_child(DojoPanel3D.make_label("Leave your current session?", 34, DojoPanel3D.COL_TEXT_MAIN, HORIZONTAL_ALIGNMENT_CENTER))
			box.add_child(DojoPanel3D.make_label("Your saved comfort settings and completed session records remain safe.", 17, DojoPanel3D.COL_TEXT_MUTED, HORIZONTAL_ALIGNMENT_CENTER))
			var sp := Control.new()
			sp.size_flags_vertical = Control.SIZE_EXPAND_FILL
			box.add_child(sp)
			var row := HBoxContainer.new()
			row.add_theme_constant_override("separation", 14)
			row.add_child(_btn_secondary("Stay in Dojo", func(): gf.return_to_main_menu(), false, 19, 54.0))
			row.add_child(_btn_destructive("Exit Experience", func(): gf.confirm_quit_application(), 19, 54.0))
			box.add_child(row)

func _populate_settings_tab(dvb: VBoxContainer) -> void:
	var gf := _gf()
	match _settings_tab:
		0: # Comfort
			var preset := gf.get_current_preset()
			dvb.add_child(DojoPanel3D.make_label("Comfort & Reach", 24, DojoPanel3D.COL_TEXT_MAIN))
			dvb.add_child(_btn_secondary("Difficulty: %s (%.0f%% reach)" % [preset.preset_name, preset.reach_factor_k * 100.0], func():
				var curr := int(gf.settings.get("difficulty", ZenoEnums.DifficultyTier.STANDARD))
				gf.settings["difficulty"] = (curr + 1) % 3
				_save().save_settings(gf.settings)
				_rebuild_all_panels()
			, false, 17, 48.0))
			var h_idx := gf.profile.get_effective_hand_mode(int(gf.settings.get("hand_mode", 0)))
			var h_names := ["Both Hands", "Left Only", "Right Only"]
			dvb.add_child(_btn_secondary("Active Hands: %s" % h_names[clampi(h_idx, 0, 2)], func():
				var curr := int(gf.settings.get("hand_mode", ZenoEnums.HandMode.BOTH_HANDS))
				gf.settings["hand_mode"] = (curr + 1) % 3
				_save().save_settings(gf.settings)
				_rebuild_all_panels()
			, false, 17, 48.0))
			dvb.add_child(_btn_secondary("Recalibrate Seated Comfort", func(): gf.open_calibration(ZenoEnums.AppState.SETTINGS), false, 17, 48.0))
			var sp := Control.new()
			sp.size_flags_vertical = Control.SIZE_EXPAND_FILL
			dvb.add_child(sp)
			dvb.add_child(_btn_destructive("Reset Saved Data", func():
				_save().delete_all_saved_data()
				gf.has_valid_calibration = false
				gf.profile = ComfortProfile.create_default()
				_rebuild_all_panels()
			, 16, 44.0))

		1: # Input & Haptics
			var in_mode := int(gf.settings.get("input_mode", ZenoEnums.InputMode.CONTROLLER))
			var hap_on := bool(gf.settings.get("haptics_enabled", true))
			dvb.add_child(DojoPanel3D.make_label("Input & Haptics", 24, DojoPanel3D.COL_TEXT_MAIN))
			dvb.add_child(DojoPanel3D.make_label("Your chosen input mode locks during active sessions so tracking stays consistent.", 15, DojoPanel3D.COL_TEXT_MUTED))
			dvb.add_child(_btn_secondary("Input Source: %s" % ZenoEnums.get_input_mode_name(in_mode), func():
				var next_m := ZenoEnums.InputMode.HAND_TRACKING if in_mode == ZenoEnums.InputMode.CONTROLLER else ZenoEnums.InputMode.CONTROLLER
				gf.set_input_mode(next_m)
				_rebuild_all_panels()
			, true, 18, 52.0))
			dvb.add_child(_btn_secondary("Controller Haptics: %s" % ("ON" if hap_on else "OFF"), func():
				gf.settings["haptics_enabled"] = not hap_on
				if _plat() != null:
					_plat().haptics_enabled = not hap_on
				_save().save_settings(gf.settings)
				_rebuild_all_panels()
			, hap_on, 17, 48.0))

		2: # Audio
			var vol := clampf(float(gf.settings.get("audio_volume", 0.8)), 0.0, 1.0)
			dvb.add_child(DojoPanel3D.make_label("Audio", 24, DojoPanel3D.COL_TEXT_MAIN))
			dvb.add_child(DojoPanel3D.make_label("Master Sound Volume: %.0f%%" % (vol * 100.0), 19, DojoPanel3D.COL_TEXT_MAIN))
			dvb.add_child(DojoPanel3D.make_progress_bar(vol))
			var row := HBoxContainer.new()
			row.add_theme_constant_override("separation", 12)
			row.add_child(_btn_secondary("Volume -", func():
				gf.settings["audio_volume"] = clampf(vol - 0.15, 0.0, 1.0)
				if _plat() != null:
					_plat().audio_volume = float(gf.settings["audio_volume"])
				_save().save_settings(gf.settings)
				_rebuild_all_panels()
			, false, 17, 48.0))
			row.add_child(_btn_secondary("Volume +", func():
				gf.settings["audio_volume"] = clampf(vol + 0.15, 0.0, 1.0)
				if _plat() != null:
					_plat().audio_volume = float(gf.settings["audio_volume"])
				_save().save_settings(gf.settings)
				_rebuild_all_panels()
			, false, 17, 48.0))
			dvb.add_child(row)

		3: # Display & HUD
			var dist := clampf(float(gf.settings.get("hud_distance_m", 1.65)), 1.30, 2.20)
			var scl := clampf(float(gf.settings.get("hud_scale", 1.0)), 0.85, 1.20)
			dvb.add_child(DojoPanel3D.make_label("Display & HUD", 24, DojoPanel3D.COL_TEXT_MAIN))
			dvb.add_child(DojoPanel3D.make_label("Panel Distance: %.2f m  (Range 1.30–2.20 m)" % dist, 18, DojoPanel3D.COL_TEXT_MAIN))
			var d_row := HBoxContainer.new()
			d_row.add_theme_constant_override("separation", 10)
			d_row.add_child(_btn_secondary("Closer  -", func():
				gf.adjust_hud_distance(-0.15)
				_rebuild_all_panels()
			, false, 17, 46.0))
			d_row.add_child(_btn_secondary("Farther  +", func():
				gf.adjust_hud_distance(0.15)
				_rebuild_all_panels()
			, false, 17, 46.0))
			dvb.add_child(d_row)

			dvb.add_child(DojoPanel3D.make_label("Panel Scale: %.2fx  (Range 0.85–1.20x)" % scl, 18, DojoPanel3D.COL_TEXT_MAIN))
			var s_row := HBoxContainer.new()
			s_row.add_theme_constant_override("separation", 10)
			s_row.add_child(_btn_secondary("Smaller  -", func():
				gf.adjust_hud_scale(-0.05)
				_rebuild_all_panels()
			, false, 17, 46.0))
			s_row.add_child(_btn_secondary("Larger  +", func():
				gf.adjust_hud_scale(0.05)
				_rebuild_all_panels()
			, false, 17, 46.0))
			dvb.add_child(s_row)

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

	for p: DojoPanel3D in [main_panel]:
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
		if _pointer_dot.is_inside_tree():
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

	var cal_step := calibration_ctrl.current_step if calibration_ctrl != null else -1
	if _last_built_state != gf.current_state \
		or (gf.current_state == ZenoEnums.AppState.CALIBRATION and _last_built_cal_step != cal_step) \
		or (gf.current_state == ZenoEnums.AppState.PAUSED and _last_built_pause_reason != gf.current_pause_reason):
		_rebuild_all_panels(calibration_ctrl)

	var hud_dist := clampf(float(gf.settings.get("hud_distance_m", 1.65)), 1.30, 2.20)
	var hud_scl := clampf(float(gf.settings.get("hud_scale", 1.0)), 0.85, 1.20)
	var in_round := (
		gf.current_state == ZenoEnums.AppState.ROUND_INTRO
		or gf.current_state == ZenoEnums.AppState.ROUND_PLAY
		or gf.current_state == ZenoEnums.AppState.ROUND_OUTRO
	)

	# Anchored strictly in stationary BodyFrame (completely immune to camera head turns)
	var board_y_spec := 0.22 if not in_round else 0.16
	var board_z_spec := hud_dist + (0.14 if in_round else 0.0)
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
	rotation = Vector3(0.0, _smoothed_yaw_rad, 0.0)
	scale = Vector3.ONE * hud_scl

	match gf.current_state:
		ZenoEnums.AppState.CALIBRATION:
			if _live_title_lbl != null and calibration_ctrl != null:
				_live_title_lbl.text = calibration_ctrl.get_step_instruction()

		ZenoEnums.AppState.ROUND_INTRO:
			var ex := gf.get_current_exercise_id()
			if _live_title_lbl != null:
				_live_title_lbl.text = "%s  •  Get Ready" % ZenoEnums.get_exercise_title(ex)
			if _live_sub_lbl != null:
				_live_sub_lbl.text = "Round %d of %d" % [gf.current_round_index + 1, gf.session_lineup.size()] if gf.is_quick_break_mode else ZenoEnums.get_exercise_area(ex)
			if _live_timer_lbl != null:
				_live_timer_lbl.text = "%.0f s" % ceilf(maxf(0.0, gf.round_timer_s))
			if _live_progress != null:
				_live_progress.value = clampf((1.0 - gf.round_timer_s / GameFlowController.ROUND_INTRO_SECONDS) * 100.0, 0.0, 100.0)
			if _live_bottom_cue_lbl != null:
				_live_bottom_cue_lbl.text = ZenoEnums.get_exercise_cue(ex)

		ZenoEnums.AppState.ROUND_PLAY:
			var ex := gf.get_current_exercise_id()
			var total_play := gf.get_active_round_play_seconds()
			if _live_title_lbl != null:
				_live_title_lbl.text = ZenoEnums.get_exercise_title(ex)
			if _live_sub_lbl != null:
				var set_txt := ""
				if active_mechanic != null and active_mechanic.has_two_set_completion():
					set_txt = active_mechanic.get_set_display_text()
				if not set_txt.is_empty():
					_live_sub_lbl.text = ("Round %d of %d  •  %s" % [gf.current_round_index + 1, gf.session_lineup.size(), set_txt]) if gf.is_quick_break_mode else set_txt
				else:
					_live_sub_lbl.text = "Round %d of %d  •  %s" % [gf.current_round_index + 1, gf.session_lineup.size(), ZenoEnums.get_exercise_area(ex)] if gf.is_quick_break_mode else ZenoEnums.get_exercise_area(ex)
			if _live_score_lbl != null:
				var streak_str := "  (x%d)" % gf.round_tracker.streak if gf.round_tracker.streak >= 2 else ""
				_live_score_lbl.text = "SCORE  %d%s" % [gf.round_tracker.combo_total_score, streak_str]
			if _live_timer_lbl != null:
				_live_timer_lbl.text = _format_mm_ss(gf.round_timer_s)
			if _live_progress != null:
				_live_progress.value = clampf((1.0 - gf.round_timer_s / maxf(1.0, total_play)) * 100.0, 0.0, 100.0)
			if _live_bottom_cue_lbl != null:
				_live_bottom_cue_lbl.text = active_mechanic.status_hint if (active_mechanic != null and not active_mechanic.status_hint.is_empty()) else ZenoEnums.get_exercise_cue(ex)

		ZenoEnums.AppState.ROUND_OUTRO:
			if _live_title_lbl != null:
				_live_title_lbl.text = "Round Complete"
			if _live_score_lbl != null:
				_live_score_lbl.text = "SCORE  %d" % gf.round_tracker.combo_total_score
			if _live_timer_lbl != null:
				_live_timer_lbl.text = "Done"
			if _live_progress != null:
				_live_progress.value = 100.0
			if _live_bottom_cue_lbl != null:
				_live_bottom_cue_lbl.text = "Take a calm breath"

		ZenoEnums.AppState.PAUSED:
			if _live_title_lbl != null:
				if gf.is_resume_counting_down:
					_live_title_lbl.text = "Resuming in %.0f..." % ceilf(maxf(0.1, gf.resume_countdown_remaining_s))
				else:
					_live_title_lbl.text = "Take your time."

static func _format_mm_ss(seconds_val: float) -> String:
	var s := maxi(0, int(ceil(seconds_val)))
	return "%02d:%02d" % [int(s / 60), s % 60]
