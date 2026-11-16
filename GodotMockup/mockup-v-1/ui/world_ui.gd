class_name ZenoWorldUI
extends Node3D

## World-Space 3D VR Panel (1.15 m ahead, 15-feedback-and-ui.md §9.3) + Desktop Simulator Canvas UI.
## Never makes health/treatment claims ("Not a medical device", §8.8, Rule 12).

signal request_confirm_calibration_step()
signal request_skip_calibration_step()
signal request_mark_obstacle()
signal request_auto_action()
signal request_poke_mascot()

var _board_label: Label3D
var _sub_label: Label3D
var _canvas_layer: CanvasLayer
var _status_label_2d: Label
var _buttons_box: HBoxContainer
var _mechanic_buttons_box: HFlowContainer

func _ready() -> void:
	_build_3d_board()
	_build_desktop_overlay()
	if EventBus != null:
		EventBus.state_changed.connect(_on_state_changed)

func _build_3d_board() -> void:
	var backing := MeshInstance3D.new()
	var quad := BoxMesh.new()
	quad.size = Vector3(1.45, 0.78, 0.02)
	backing.mesh = quad
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.08, 0.12, 0.18, 0.92)
	mat.roughness = 0.8
	backing.material_override = mat
	add_child(backing)

	_board_label = Label3D.new()
	_board_label.position = Vector3(0.0, 0.12, 0.02)
	_board_label.pixel_size = 0.0020
	_board_label.font_size = 24
	_board_label.outline_size = 6
	_board_label.modulate = Color(0.95, 0.98, 1.0)
	add_child(_board_label)

	_sub_label = Label3D.new()
	_sub_label.position = Vector3(0.0, -0.22, 0.02)
	_sub_label.pixel_size = 0.0016
	_sub_label.font_size = 20
	_sub_label.modulate = Color(0.70, 0.88, 0.96)
	add_child(_sub_label)

func _build_desktop_overlay() -> void:
	_canvas_layer = CanvasLayer.new()
	add_child(_canvas_layer)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	panel.offset_top = -175.0
	_canvas_layer.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	panel.add_child(vbox)

	_status_label_2d = Label.new()
	_status_label_2d.text = "ZenoFit Seated VR (Godot 4.7) — Not a medical device. Stop if anything hurts."
	_status_label_2d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(_status_label_2d)

	_buttons_box = HBoxContainer.new()
	_buttons_box.add_theme_constant_override("separation", 8)
	vbox.add_child(_buttons_box)

	_mechanic_buttons_box = HFlowContainer.new()
	_mechanic_buttons_box.add_theme_constant_override("h_separation", 6)
	vbox.add_child(_mechanic_buttons_box)

	_rebuild_buttons_for_state(GameFlow.current_state)

func _on_state_changed(_prev: int, next_state: int) -> void:
	_rebuild_buttons_for_state(next_state)

func _clear_children(node: Node) -> void:
	for c in node.get_children():
		c.queue_free()

func _add_btn(parent: Node, text: String, callback: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.pressed.connect(callback)
	parent.add_child(b)
	return b

func _rebuild_buttons_for_state(state: int) -> void:
	if _buttons_box == null or _mechanic_buttons_box == null:
		return
	_clear_children(_buttons_box)
	_clear_children(_mechanic_buttons_box)

	match state:
		ZenoEnums.AppState.MAIN_MENU:
			_add_btn(_buttons_box, "Play Score Attack (5x30s) [Space]", func(): GameFlow.start_score_attack_from_menu())
			_add_btn(_buttons_box, "Recalibrate [C]", func(): GameFlow.request_recalibrate())
			_add_btn(_buttons_box, "Cycle Difficulty", _cycle_difficulty)
			_add_btn(_buttons_box, "Cycle Hand Mode", _cycle_hand_mode)
			_add_btn(_buttons_box, "Toggle No-Trunk Mode", _toggle_no_trunk)
			_add_btn(_buttons_box, "Poke Mascot [M]", func(): request_poke_mascot.emit())
			_add_btn(_buttons_box, "Reset Saved Data", func():
				SaveService.delete_all_saved_data()
				GameFlow.has_valid_calibration = false
				GameFlow.profile = ComfortProfile.create_default()
			)
			for m in SessionDraw.get_all_mechanics():
				var short_name := "Practice M%02d" % m
				_add_btn(_mechanic_buttons_box, short_name, func(): GameFlow.start_practice_mechanic(m))

		ZenoEnums.AppState.CALIBRATION:
			_add_btn(_buttons_box, "Confirm Step (Trigger / Space)", func(): request_confirm_calibration_step.emit())
			_add_btn(_buttons_box, "Skip / Default Step [K]", func(): request_skip_calibration_step.emit())
			_add_btn(_buttons_box, "Mark Obstacle [O]", func(): request_mark_obstacle.emit())
			_add_btn(_buttons_box, "Back to Menu [Esc]", func(): GameFlow.return_to_main_menu())

		ZenoEnums.AppState.ROUND_INTRO, ZenoEnums.AppState.ROUND_PLAY, ZenoEnums.AppState.ROUND_OUTRO:
			_add_btn(_buttons_box, "Auto-Perform Action [Tab]", func(): request_auto_action.emit())
			_add_btn(_buttons_box, "Pause [Esc]", func(): GameFlow.pause_session(ZenoEnums.PauseReason.MANUAL, "Manual Pause"))
			_add_btn(_buttons_box, "Skip to Next Round [N]", func(): GameFlow.round_timer_s = 0.01)
			_add_btn(_buttons_box, "Poke Mascot [M]", func(): request_poke_mascot.emit())
			_add_btn(_buttons_box, "Stop Session", func(): GameFlow.finish_session_to_results())

		ZenoEnums.AppState.PAUSED:
			if GameFlow.current_pause_reason == ZenoEnums.PauseReason.STABLE_CHAIR_CONFIRMATION:
				_add_btn(_buttons_box, "Confirm Stable Chair (Continue) [Space]", func(): GameFlow.confirm_stable_chair())
				_add_btn(_buttons_box, "Decline & Substitute Level A Mechanic [K]", func(): GameFlow.decline_stable_chair_and_substitute())
			else:
				_add_btn(_buttons_box, "Resume (3s Countdown) [Space]", func(): GameFlow.request_resume_with_countdown())
				_add_btn(_buttons_box, "Recalibrate", func(): GameFlow.request_recalibrate())
			_add_btn(_buttons_box, "Stop -> Results", func(): GameFlow.finish_session_to_results())
			_add_btn(_buttons_box, "Main Menu", func(): GameFlow.return_to_main_menu())

		ZenoEnums.AppState.RESULTS:
			_add_btn(_buttons_box, "Play Again [Space]", func(): GameFlow.begin_session())
			_add_btn(_buttons_box, "Main Menu [Esc]", func(): GameFlow.return_to_main_menu())
			_add_btn(_buttons_box, "Poke Mascot [M]", func(): request_poke_mascot.emit())

func _cycle_difficulty() -> void:
	var curr := int(GameFlow.settings.get("difficulty", ZenoEnums.DifficultyTier.STANDARD))
	GameFlow.settings["difficulty"] = (curr + 1) % 3
	SaveService.save_settings(GameFlow.settings)

func _cycle_hand_mode() -> void:
	var curr := int(GameFlow.settings.get("hand_mode", ZenoEnums.HandMode.BOTH_HANDS))
	GameFlow.settings["hand_mode"] = (curr + 1) % 3
	SaveService.save_settings(GameFlow.settings)

func _toggle_no_trunk() -> void:
	var curr := bool(GameFlow.settings.get("no_trunk_mode", false))
	GameFlow.settings["no_trunk_mode"] = not curr
	SaveService.save_settings(GameFlow.settings)

func update_ui_display(
	body_frame: BodyFrame,
	calibration_ctrl: CalibrationController,
	active_mechanic: MechanicBase
) -> void:
	# Position 3D board at 1.15 m in front of chest, slightly below eye level (§9.3)
	global_position = body_frame.to_godot_world(Vector3(0.0, 0.08, 1.15))
	rotation.y = body_frame.get_godot_yaw_rad()

	var preset := GameFlow.get_current_preset()
	var no_trunk_str := "ON (Level A Only)" if bool(GameFlow.settings.get("no_trunk_mode", false)) else "OFF (All 10 Mechanics)"
	var hand_mode_idx := GameFlow.profile.get_effective_hand_mode(int(GameFlow.settings.get("hand_mode", 0)))
	var hand_names: Array[String] = ["Both Hands", "Left Only", "Right Only"]
	var hand_str: String = hand_names[clampi(hand_mode_idx, 0, 2)]

	match GameFlow.current_state:
		ZenoEnums.AppState.MAIN_MENU:
			var history := SaveService.load_recent_sessions(3)
			var hist_line := "Recent Sessions: %d saved" % history.size()
			if history.size() > 0 and typeof(history[0]) == TYPE_DICTIONARY:
				hist_line += " (Last Score: %s)" % str(history[0].get("score", 0))
			_board_label.text = "ZENOFIT — SEATED VR SCORE ATTACK\nDifficulty: %s (k=%.2f) | Hands: %s\nNo-Trunk Mode: %s | Calibrated: %s" % [
				preset.preset_name, preset.reach_factor_k, hand_str, no_trunk_str,
				"YES" if GameFlow.has_valid_calibration else "NO (Will Calibrate)"
			]
			_sub_label.text = "%s\nNotice: Not a medical device. Stop if anything hurts." % hist_line

		ZenoEnums.AppState.CALIBRATION:
			_board_label.text = "SEATED COMFORT CALIBRATION\n%s" % calibration_ctrl.get_step_instruction()
			_sub_label.text = "Stop if it hurts. Only reach as far as is comfortable.\nObstacles marked: %d" % calibration_ctrl.working_profile.obstacles.size()

		ZenoEnums.AppState.ROUND_INTRO:
			var mech := GameFlow.get_current_mechanic_id()
			var lvl := "Level B (Trunk/Neck)" if ZenoEnums.get_mechanic_safety_level(mech) == ZenoEnums.SafetyLevel.LEVEL_B else "Level A (Arms Only)"
			_board_label.text = "ROUND %d / %d — GET READY (%.1f s)\n%s\n[%s | Group: %s]" % [
				GameFlow.current_round_index + 1, GameFlow.session_lineup.size(),
				GameFlow.round_timer_s, ZenoEnums.get_mechanic_title(mech),
				lvl, ZenoEnums.get_group_name(ZenoEnums.get_mechanic_group(mech))
			]
			_sub_label.text = ZenoEnums.get_mechanic_instruction(mech)

		ZenoEnums.AppState.ROUND_PLAY:
			var mech := GameFlow.get_current_mechanic_id()
			var mult := ZenoScoring.compute_combo_multiplier(GameFlow.round_tracker.streak)
			_board_label.text = "ROUND %d/%d: %s | Time: %.1f s\nScore: %d | Streak: %d (x%.2f) | Tempo: %.0f BPM" % [
				GameFlow.current_round_index + 1, GameFlow.session_lineup.size(),
				ZenoEnums.get_mechanic_title(mech).split("(")[0].strip_edges(),
				GameFlow.round_timer_s,
				GameFlow.round_tracker.combo_total_score,
				GameFlow.round_tracker.streak,
				mult,
				GameFlow.adaptive_tempo.current_bpm
			]
			_sub_label.text = active_mechanic.status_hint if active_mechanic != null else ""

		ZenoEnums.AppState.ROUND_OUTRO:
			_board_label.text = "ROUND %d COMPLETE!\nTotal Score: %d | Accuracy: %.1f%%" % [
				GameFlow.current_round_index + 1,
				GameFlow.round_tracker.combo_total_score,
				GameFlow.round_tracker.get_accuracy_percent()
			]
			_sub_label.text = "Next round starting in %.1f s..." % GameFlow.round_timer_s

		ZenoEnums.AppState.PAUSED:
			if GameFlow.is_resume_counting_down:
				_board_label.text = "RESUMING IN %.1f s...\nSit comfortably in position." % GameFlow.resume_countdown_remaining_s
			else:
				_board_label.text = "PAUSED\n%s" % GameFlow.pause_message
			_sub_label.text = "Passthrough: %s | Press Space to Resume or Esc for Menu" % ("ON" if Platform.passthrough_enabled else "Fallback Calm Scene")

		ZenoEnums.AppState.RESULTS:
			var areas: PackedStringArray = []
			for g in GameFlow.covered_groups:
				areas.append("[x] " + ZenoEnums.get_group_name(g))
			_board_label.text = "WELL DONE! SESSION RESULTS\nTotal Score: %d | Accuracy: %.1f%% (Hits: %d / Misses: %d)\nDuration: %.1f s | Max Tempo: %.0f BPM" % [
				GameFlow.session_score,
				GameFlow.round_tracker.get_accuracy_percent(),
				GameFlow.round_tracker.hits,
				GameFlow.round_tracker.misses,
				GameFlow.session_elapsed_s,
				GameFlow.adaptive_tempo.max_bpm_reached
			]
			_sub_label.text = "Body areas covered: %s\nSuggested next break in 60 min. (Not a medical device.)" % ", ".join(areas)

	if _status_label_2d != null:
		_status_label_2d.text = "[%s] %s  |  Shortcuts: Space=Confirm/Play, Tab=Auto-Hit, Q/E+Mouse=Move L/R Hand, L=Lap Pause, R=Recenter, M=Poke Mascot, Esc=Pause" % [
			Platform.get_device_name(),
			_board_label.text.replace("\n", " — ")
		]
