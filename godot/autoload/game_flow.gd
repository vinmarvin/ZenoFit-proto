class_name GameFlowController
extends Node

## Central state machine matching the ZenoFit v1.0 UI.pdf 11-screen flow:
## BOOT -> WELCOME -> MAIN_MENU -> (EXERCISE_SELECT -> EXERCISE_PREVIEW | Quick Break)
##   -> ROUND_INTRO (3s) -> ROUND_PLAY (45s single / 30s x 5 Quick Break) -> ROUND_OUTRO (2s) -> RESULTS.

const ROUND_INTRO_SECONDS: float = 3.0
const SINGLE_EXERCISE_SECONDS: float = 45.0
const QUICK_BREAK_ROUND_SECONDS: float = 30.0
const ROUND_OUTRO_SECONDS: float = 2.0
const RESUME_COUNTDOWN_SECONDS: float = 3.0

var current_state: int = ZenoEnums.AppState.BOOT
var state_before_pause: int = ZenoEnums.AppState.ROUND_PLAY
var return_state_from_settings: int = ZenoEnums.AppState.MAIN_MENU
var current_pause_reason: int = ZenoEnums.PauseReason.NONE
var pause_message: String = ""

var has_valid_calibration: bool = false
var profile: ComfortProfile = ComfortProfile.create_default()
var body_frame: BodyFrame = BodyFrame.new()
var seat_anchor_local_spec: Vector3 = Vector3(0.0, 0.25, -0.08)
var seated_height_m: float = 1.18
var settings: Dictionary = {
	"difficulty": ZenoEnums.DifficultyTier.STANDARD,
	"hand_mode": ZenoEnums.HandMode.BOTH_HANDS,
	"input_mode": ZenoEnums.InputMode.CONTROLLER,
	"haptics_enabled": true,
	"haptic_intensity": 1.0,
	"audio_volume": 0.8,
	"rest_reminder_minutes": 8.0,
	"hud_distance_m": 1.65,
	"hud_scale": 1.0
}

# Active session & UI flow state
var selected_exercise_id: int = ZenoEnums.ExerciseId.BOARD_SMASH
var is_quick_break_mode: bool = false
var active_input_mode: int = ZenoEnums.InputMode.CONTROLLER
var filter_category: int = ZenoEnums.ExerciseCategory.ALL
var tutorial_step: int = 0
var session_lineup: Array[int] = []
var previous_session_lineup: Array[int] = []
var current_round_index: int = 0
var round_timer_s: float = 0.0
var session_elapsed_s: float = 0.0
var calibration_return_state: int = ZenoEnums.AppState.MAIN_MENU
var require_explicit_round_completion: bool = false

# Resume countdown
var is_resume_counting_down: bool = false
var resume_countdown_remaining_s: float = 0.0

# Scoring & Personal Best
var session_score: int = 0
var last_session_rank: String = "C"
var is_new_personal_best: bool = false
var personal_best_score: int = 0
var round_scores: Array[int] = []
var covered_areas: Array[String] = []
var round_tracker: ZenoScoring.RoundScoreTracker = ZenoScoring.RoundScoreTracker.new()
var adaptive_tempo: AdaptiveTempo = AdaptiveTempo.new(60.0, 80.0)

var _fallback_save_svc: SaveServiceClass = null

func _get_save_service() -> SaveServiceClass:
	if is_inside_tree() and get_tree().root.has_node("SaveService"):
		return get_tree().root.get_node("SaveService") as SaveServiceClass
	if _fallback_save_svc == null:
		_fallback_save_svc = SaveServiceClass.new()
	return _fallback_save_svc

func _get_event_bus() -> Node:
	if is_inside_tree() and get_tree().root.has_node("EventBus"):
		return get_tree().root.get_node("EventBus")
	return null

func _get_platform() -> Node:
	if is_inside_tree() and get_tree().root.has_node("Platform"):
		return get_tree().root.get_node("Platform")
	return null

func _ready() -> void:
	var svc := _get_save_service()
	settings = svc.load_settings()
	var loaded_data := svc.try_load_calibration_profile()
	has_valid_calibration = bool(loaded_data.get("loaded", false))
	profile = loaded_data.get("profile", ComfortProfile.create_default())
	active_input_mode = int(settings.get("input_mode", ZenoEnums.InputMode.CONTROLLER))

func _exit_tree() -> void:
	if _fallback_save_svc != null:
		_fallback_save_svc.free()
		_fallback_save_svc = null

func complete_boot() -> void:
	_transition_to(ZenoEnums.AppState.WELCOME)

func get_current_preset() -> DifficultyPreset:
	var tier := int(settings.get("difficulty", ZenoEnums.DifficultyTier.STANDARD))
	return DifficultyPreset.create_for_tier(tier)

func get_current_exercise_id() -> int:
	if current_round_index >= 0 and current_round_index < session_lineup.size():
		return session_lineup[current_round_index]
	return selected_exercise_id

func adjust_hud_distance(delta_m: float) -> float:
	var curr := float(settings.get("hud_distance_m", 1.65))
	var updated := clampf(curr + delta_m, 1.30, 2.20)
	settings["hud_distance_m"] = updated
	_get_save_service().save_settings(settings)
	return updated

func adjust_hud_scale(delta_scale: float) -> float:
	var curr := float(settings.get("hud_scale", 1.0))
	var updated := clampf(curr + delta_scale, 0.85, 1.20)
	settings["hud_scale"] = updated
	_get_save_service().save_settings(settings)
	return updated

func set_input_mode(mode: int) -> void:
	var clamped := clampi(mode, ZenoEnums.InputMode.CONTROLLER, ZenoEnums.InputMode.HAND_TRACKING)
	settings["input_mode"] = clamped
	if current_state != ZenoEnums.AppState.ROUND_PLAY:
		active_input_mode = clamped
	_get_save_service().save_settings(settings)

# ==============================================================================
# UI Navigation Actions
# ==============================================================================

func continue_to_main_menu() -> void:
	_transition_to(ZenoEnums.AppState.MAIN_MENU)

func open_exercise_select(category: int = ZenoEnums.ExerciseCategory.ALL) -> void:
	filter_category = category
	_transition_to(ZenoEnums.AppState.EXERCISE_SELECT)

func open_exercise_preview(exercise_id: int) -> void:
	selected_exercise_id = exercise_id
	is_quick_break_mode = false
	var eb := _get_event_bus()
	if eb != null:
		eb.mascot_demo_requested.emit(exercise_id)
	_transition_to(ZenoEnums.AppState.EXERCISE_PREVIEW)

func open_settings(from_state: int = -1) -> void:
	return_state_from_settings = from_state if from_state >= 0 else current_state
	_transition_to(ZenoEnums.AppState.SETTINGS)

func close_settings() -> void:
	if return_state_from_settings == ZenoEnums.AppState.PAUSED:
		_transition_to(ZenoEnums.AppState.PAUSED)
	elif return_state_from_settings == ZenoEnums.AppState.WELCOME:
		_transition_to(ZenoEnums.AppState.WELCOME)
	else:
		_transition_to(ZenoEnums.AppState.MAIN_MENU)

func open_tutorial() -> void:
	tutorial_step = 0
	_transition_to(ZenoEnums.AppState.TUTORIAL)

func open_credits() -> void:
	_transition_to(ZenoEnums.AppState.CREDITS)

func request_exit_confirm() -> void:
	_transition_to(ZenoEnums.AppState.EXIT_CONFIRM)

func confirm_quit_application() -> void:
	if is_inside_tree():
		get_tree().quit()

func open_calibration(from_state: int = -1) -> void:
	calibration_return_state = from_state if from_state >= 0 else current_state
	_transition_to(ZenoEnums.AppState.CALIBRATION)

func on_calibration_finished(
	new_profile: ComfortProfile,
	new_body_frame: BodyFrame,
	new_seat_anchor: Vector3,
	new_seated_height_m: float = 1.18
) -> void:
	profile = new_profile
	body_frame = new_body_frame
	seat_anchor_local_spec = new_seat_anchor
	seated_height_m = new_seated_height_m
	has_valid_calibration = true
	settings["hand_mode"] = profile.get_effective_hand_mode(int(settings.get("hand_mode", ZenoEnums.HandMode.BOTH_HANDS)))
	var svc := _get_save_service()
	svc.save_calibration_profile(profile)
	svc.save_settings(settings)
	if calibration_return_state == ZenoEnums.AppState.WELCOME:
		_transition_to(ZenoEnums.AppState.WELCOME)
	elif calibration_return_state == ZenoEnums.AppState.SETTINGS:
		_transition_to(ZenoEnums.AppState.SETTINGS)
	else:
		_transition_to(ZenoEnums.AppState.MAIN_MENU)

# ==============================================================================
# Session & Round Lifecycle
# ==============================================================================

func start_single_exercise(exercise_id: int) -> void:
	selected_exercise_id = exercise_id
	is_quick_break_mode = false
	begin_session()

func start_quick_break() -> void:
	is_quick_break_mode = true
	begin_session()

func begin_session() -> void:
	_transition_to(ZenoEnums.AppState.SESSION_START)
	# Lock input mode for the entire session so tracking never jumps mid-exercise
	active_input_mode = int(settings.get("input_mode", ZenoEnums.InputMode.CONTROLLER))
	var preset := get_current_preset()
	adaptive_tempo = AdaptiveTempo.new(preset.start_tempo_bpm, preset.max_tempo_bpm)
	round_tracker.reset()
	session_score = 0
	last_session_rank = "C"
	is_new_personal_best = false
	round_scores.clear()
	covered_areas.clear()
	session_elapsed_s = 0.0
	current_round_index = 0

	if is_quick_break_mode:
		session_lineup = SessionDraw.draw_quick_break_mix(previous_session_lineup)
		previous_session_lineup = session_lineup.duplicate()
	else:
		session_lineup = [selected_exercise_id]

	_enter_round_intro(0)

func _enter_round_intro(round_idx: int) -> void:
	require_explicit_round_completion = false
	current_round_index = round_idx
	round_timer_s = ROUND_INTRO_SECONDS
	var ex := get_current_exercise_id()
	var area := ZenoEnums.get_exercise_area(ex)
	if not covered_areas.has(area):
		covered_areas.append(area)
	_transition_to(ZenoEnums.AppState.ROUND_INTRO)
	var eb := _get_event_bus()
	if eb != null:
		eb.mascot_demo_requested.emit(ex)

func get_active_round_play_seconds() -> float:
	return QUICK_BREAK_ROUND_SECONDS if is_quick_break_mode else SINGLE_EXERCISE_SECONDS

func advance_round_timer(dt: float) -> void:
	var eb := _get_event_bus()
	var plat := _get_platform()
	if current_state == ZenoEnums.AppState.PAUSED:
		if is_resume_counting_down:
			resume_countdown_remaining_s -= dt
			if eb != null:
				eb.resume_countdown_tick.emit(maxf(0.0, resume_countdown_remaining_s))
			if resume_countdown_remaining_s <= 0.0:
				is_resume_counting_down = false
				current_pause_reason = ZenoEnums.PauseReason.NONE
				if plat != null:
					plat.set_passthrough(false)
				_transition_to(state_before_pause)
		return

	if current_state == ZenoEnums.AppState.ROUND_INTRO:
		round_timer_s -= dt
		if round_timer_s <= 0.0:
			round_timer_s = get_active_round_play_seconds()
			_transition_to(ZenoEnums.AppState.ROUND_PLAY)
			if eb != null:
				eb.round_started.emit(current_round_index, get_current_exercise_id())

	elif current_state == ZenoEnums.AppState.ROUND_PLAY:
		session_elapsed_s += dt
		if require_explicit_round_completion:
			round_timer_s = maxf(0.0, round_timer_s - dt)
		else:
			round_timer_s -= dt
			if round_timer_s <= 0.0:
				_finish_current_round()

	elif current_state == ZenoEnums.AppState.ROUND_OUTRO:
		round_timer_s -= dt
		if round_timer_s <= 0.0:
			if current_round_index + 1 < session_lineup.size():
				_enter_round_intro(current_round_index + 1)
			else:
				finish_session_to_results()

func complete_active_round() -> void:
	if current_state == ZenoEnums.AppState.ROUND_PLAY:
		_finish_current_round()

func _finish_current_round() -> void:
	require_explicit_round_completion = false
	var prev_sum := 0
	for s in round_scores:
		prev_sum += s
	var this_round_pts := maxi(0, round_tracker.combo_total_score - prev_sum)
	round_scores.append(this_round_pts)
	session_score = round_tracker.combo_total_score
	var eb := _get_event_bus()
	if eb != null:
		eb.round_ended.emit(current_round_index, get_current_exercise_id(), this_round_pts)
	round_timer_s = ROUND_OUTRO_SECONDS
	_transition_to(ZenoEnums.AppState.ROUND_OUTRO)

func pause_session(reason: int, message: String = "Session Paused") -> bool:
	if current_state != ZenoEnums.AppState.ROUND_INTRO \
		and current_state != ZenoEnums.AppState.ROUND_PLAY \
		and current_state != ZenoEnums.AppState.ROUND_OUTRO:
		return false
	state_before_pause = current_state
	current_pause_reason = reason
	pause_message = message
	is_resume_counting_down = false
	var plat := _get_platform()
	if reason == ZenoEnums.PauseReason.AUTO_PAUSE_LAP and plat != null:
		plat.set_passthrough(true)
	_transition_to(ZenoEnums.AppState.PAUSED)
	var eb := _get_event_bus()
	if eb != null:
		eb.session_paused.emit(reason, message)
	return true

func request_resume_with_countdown() -> void:
	if current_state != ZenoEnums.AppState.PAUSED:
		return
	is_resume_counting_down = true
	resume_countdown_remaining_s = RESUME_COUNTDOWN_SECONDS

func switch_input_mode_and_resume() -> void:
	var next_mode := ZenoEnums.InputMode.HAND_TRACKING if active_input_mode == ZenoEnums.InputMode.CONTROLLER else ZenoEnums.InputMode.CONTROLLER
	settings["input_mode"] = next_mode
	active_input_mode = next_mode
	_get_save_service().save_settings(settings)
	request_resume_with_countdown()

func finish_session_to_results() -> void:
	is_resume_counting_down = false
	var plat := _get_platform()
	if plat != null:
		plat.set_passthrough(false)
	session_score = round_tracker.combo_total_score
	var acc := round_tracker.get_accuracy_percent()
	last_session_rank = ZenoScoring.compute_rank(acc)
	var svc := _get_save_service()
	var key := "quick_break" if is_quick_break_mode else ("ex_%d" % selected_exercise_id)
	var pb_res := svc.update_personal_best(key, session_score, acc, last_session_rank)
	is_new_personal_best = bool(pb_res.get("is_new_best", false))
	personal_best_score = int(pb_res.get("new_best", session_score))
	var record := {
		"dateUtc": Time.get_datetime_string_from_system(true) + "Z",
		"mode": "Quick Break" if is_quick_break_mode else ZenoEnums.get_exercise_title(selected_exercise_id),
		"inputMode": ZenoEnums.get_input_mode_name(active_input_mode),
		"difficulty": get_current_preset().preset_name,
		"durationSeconds": snappedf(session_elapsed_s, 0.1),
		"hits": round_tracker.hits,
		"misses": round_tracker.misses,
		"accuracyPercent": snappedf(acc, 0.1),
		"score": session_score,
		"rank": last_session_rank,
		"isNewPersonalBest": is_new_personal_best
	}
	svc.append_session_record(record, 30)
	_transition_to(ZenoEnums.AppState.RESULTS)

func return_to_main_menu() -> void:
	require_explicit_round_completion = false
	is_resume_counting_down = false
	var plat := _get_platform()
	if plat != null:
		plat.set_passthrough(false)
	_transition_to(ZenoEnums.AppState.MAIN_MENU)

func _transition_to(next_state: int) -> void:
	var prev := current_state
	current_state = next_state
	var eb := _get_event_bus()
	if eb != null:
		eb.state_changed.emit(prev, next_state)
