class_name GameFlowController
extends Node

## Central state machine owning all transitions (00-gameplay-overview.md §2 GP-FLOW-01, GP-FLOW-02):
## Boot -> MainMenu -> [Calibration if needed] -> SessionStart ->
##   (RoundIntro 4s -> RoundPlay 30s -> RoundOutro 2s) x 5 rounds -> Results
## Any Round state <-> Paused (Manual, Auto-Pause Lap, Rest Reminder, Lean Warning, Recenter, Stable Chair).

const ROUND_INTRO_SECONDS: float = 4.0
const ROUND_PLAY_SECONDS: float = 30.0
const ROUND_OUTRO_SECONDS: float = 2.0
const RESUME_COUNTDOWN_SECONDS: float = 3.0

var current_state: int = ZenoEnums.AppState.BOOT
var state_before_pause: int = ZenoEnums.AppState.ROUND_PLAY
var current_pause_reason: int = ZenoEnums.PauseReason.NONE
var pause_message: String = ""

var has_valid_calibration: bool = false
var profile: ComfortProfile = ComfortProfile.create_default()
var body_frame: BodyFrame = BodyFrame.new()
var seat_anchor_local_spec: Vector3 = Vector3(0.0, 0.25, -0.08)
var settings: Dictionary = {
	"difficulty": ZenoEnums.DifficultyTier.STANDARD,
	"hand_mode": ZenoEnums.HandMode.BOTH_HANDS,
	"no_trunk_mode": false,
	"quick_session_one_round": false,
	"haptics_enabled": true,
	"haptic_intensity": 1.0,
	"audio_volume": 0.8,
	"rest_reminder_minutes": 8.0
}

# Session & Score Attack state
var is_practice_mode: bool = false
var practice_mechanic_id: int = ZenoEnums.MechanicId.M01_ASTEROID_BRAWLER
var session_lineup: Array[int] = []
var previous_session_lineup: Array[int] = []
var current_round_index: int = 0 # 0..4
var round_timer_s: float = 0.0
var session_elapsed_s: float = 0.0
var stable_chair_confirmed_this_session: bool = false

# Resume countdown (GP-FLOW-02)
var is_resume_counting_down: bool = false
var resume_countdown_remaining_s: float = 0.0

# Scoring & results
var session_score: int = 0
var round_scores: Array[int] = []
var covered_groups: Array[int] = []
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

func _exit_tree() -> void:
	if _fallback_save_svc != null:
		_fallback_save_svc.free()
		_fallback_save_svc = null

func complete_boot() -> void:
	_transition_to(ZenoEnums.AppState.MAIN_MENU)

func get_current_preset() -> DifficultyPreset:
	var tier := int(settings.get("difficulty", ZenoEnums.DifficultyTier.STANDARD))
	return DifficultyPreset.create_for_tier(tier)

func get_current_mechanic_id() -> int:
	if is_practice_mode:
		return practice_mechanic_id
	if current_round_index >= 0 and current_round_index < session_lineup.size():
		return session_lineup[current_round_index]
	return ZenoEnums.MechanicId.M01_ASTEROID_BRAWLER

func start_score_attack_from_menu() -> void:
	is_practice_mode = false
	if not has_valid_calibration:
		_transition_to(ZenoEnums.AppState.CALIBRATION)
	else:
		begin_session()

func start_practice_mechanic(mechanic_id: int) -> void:
	is_practice_mode = true
	practice_mechanic_id = mechanic_id
	if not has_valid_calibration:
		_transition_to(ZenoEnums.AppState.CALIBRATION)
	else:
		begin_session()

func request_recalibrate() -> void:
	_transition_to(ZenoEnums.AppState.CALIBRATION)

func on_calibration_finished(new_profile: ComfortProfile, new_body_frame: BodyFrame, new_seat_anchor: Vector3) -> void:
	profile = new_profile
	body_frame = new_body_frame
	seat_anchor_local_spec = new_seat_anchor
	has_valid_calibration = true
	settings["hand_mode"] = profile.get_effective_hand_mode(int(settings.get("hand_mode", ZenoEnums.HandMode.BOTH_HANDS)))
	var svc := _get_save_service()
	svc.save_calibration_profile(profile)
	svc.save_settings(settings)
	begin_session()

func begin_session() -> void:
	_transition_to(ZenoEnums.AppState.SESSION_START)
	var preset := get_current_preset()
	adaptive_tempo = AdaptiveTempo.new(preset.start_tempo_bpm, preset.max_tempo_bpm)
	round_tracker.reset()
	session_score = 0
	round_scores.clear()
	covered_groups.clear()
	session_elapsed_s = 0.0
	current_round_index = 0
	stable_chair_confirmed_this_session = false

	if is_practice_mode:
		session_lineup = [practice_mechanic_id]
	else:
		var no_trunk := bool(settings.get("no_trunk_mode", false))
		var full_draw := SessionDraw.draw_five_mechanics(no_trunk, previous_session_lineup)
		if bool(settings.get("quick_session_one_round", false)):
			session_lineup = [full_draw[0]]
		else:
			session_lineup = full_draw
		previous_session_lineup = session_lineup.duplicate()

	_enter_round_intro(0)

func _enter_round_intro(round_idx: int) -> void:
	current_round_index = round_idx
	round_timer_s = ROUND_INTRO_SECONDS
	var mech := get_current_mechanic_id()
	var grp := ZenoEnums.get_mechanic_group(mech)
	if not covered_groups.has(grp):
		covered_groups.append(grp)
	_transition_to(ZenoEnums.AppState.ROUND_INTRO)
	var eb := _get_event_bus()
	if eb != null:
		eb.mascot_demo_requested.emit(mech)

	# §8.8 & AT-28: Before the first Level B round of a session, require stable-chair confirmation
	if ZenoEnums.get_mechanic_safety_level(mech) == ZenoEnums.SafetyLevel.LEVEL_B and not stable_chair_confirmed_this_session:
		pause_session(
			ZenoEnums.PauseReason.STABLE_CHAIR_CONFIRMATION,
			"Level B Mechanic: Sit on a stable chair (no wheels, or locked). Keep both feet on the floor. Stop if you feel pain or dizzy."
		)

func confirm_stable_chair() -> void:
	stable_chair_confirmed_this_session = true
	if current_state == ZenoEnums.AppState.PAUSED and current_pause_reason == ZenoEnums.PauseReason.STABLE_CHAIR_CONFIRMATION:
		current_pause_reason = ZenoEnums.PauseReason.NONE
		_transition_to(state_before_pause)

## AT-28: Given the user declines the stable-chair confirmation, the Level B round is skipped and a Level A mechanic is substituted.
func decline_stable_chair_and_substitute() -> int:
	var new_mech := SessionDraw.substitute_level_a_mechanic(session_lineup, current_round_index)
	if is_practice_mode:
		practice_mechanic_id = new_mech
	if current_state == ZenoEnums.AppState.PAUSED and current_pause_reason == ZenoEnums.PauseReason.STABLE_CHAIR_CONFIRMATION:
		current_pause_reason = ZenoEnums.PauseReason.NONE
		_transition_to(ZenoEnums.AppState.ROUND_INTRO)
	var eb := _get_event_bus()
	if eb != null:
		eb.mascot_demo_requested.emit(new_mech)
	return new_mech

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
			round_timer_s = ROUND_PLAY_SECONDS
			_transition_to(ZenoEnums.AppState.ROUND_PLAY)
			if eb != null:
				eb.round_started.emit(current_round_index, get_current_mechanic_id())

	elif current_state == ZenoEnums.AppState.ROUND_PLAY:
		session_elapsed_s += dt
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

func _finish_current_round() -> void:
	var prev_sum := 0
	for s in round_scores:
		prev_sum += s
	var this_round_pts := maxi(0, round_tracker.combo_total_score - prev_sum)
	round_scores.append(this_round_pts)
	session_score = round_tracker.combo_total_score
	var eb := _get_event_bus()
	if eb != null:
		eb.round_ended.emit(current_round_index, get_current_mechanic_id(), this_round_pts)
	round_timer_s = ROUND_OUTRO_SECONDS
	_transition_to(ZenoEnums.AppState.ROUND_OUTRO)

## AT-14: Pausing during any round transitions to PAUSED immediately (within 1 frame) and freezes beat clock/timers.
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
	if current_pause_reason == ZenoEnums.PauseReason.STABLE_CHAIR_CONFIRMATION:
		confirm_stable_chair()
		return
	is_resume_counting_down = true
	resume_countdown_remaining_s = RESUME_COUNTDOWN_SECONDS

func finish_session_to_results() -> void:
	is_resume_counting_down = false
	var plat := _get_platform()
	if plat != null:
		plat.set_passthrough(false)
	session_score = round_tracker.combo_total_score
	var record := {
		"dateUtc": Time.get_datetime_string_from_system(true) + "Z",
		"mode": "Practice" if is_practice_mode else "ScoreAttack",
		"mechanicsCount": session_lineup.size(),
		"difficulty": get_current_preset().preset_name,
		"handMode": int(settings.get("hand_mode", ZenoEnums.HandMode.BOTH_HANDS)),
		"durationSeconds": snappedf(session_elapsed_s, 0.1),
		"hits": round_tracker.hits,
		"misses": round_tracker.misses,
		"accuracyPercent": snappedf(round_tracker.get_accuracy_percent(), 0.1),
		"score": session_score,
		"maxTempoReachedBpm": adaptive_tempo.max_bpm_reached
	}
	_get_save_service().append_session_record(record, 10)
	_transition_to(ZenoEnums.AppState.RESULTS)

func return_to_main_menu() -> void:
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
