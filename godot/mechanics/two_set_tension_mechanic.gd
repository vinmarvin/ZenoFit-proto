class_name TwoSetTensionMechanic
extends MechanicBase

## Shared base for two-set upper-body exercises with Mechanical Tension Line/Zone.
## Handles Set 1 -> calm transition -> Set 2 -> completion, plus hand-mode filtering
## and tension quality scoring so no two-set logic is duplicated across exercises.

const REPS_PER_SET: int = 12
const SET_TRANSITION_SECONDS: float = 1.6
const TENSION_BASE_TOLERANCE_M: float = 0.12

var current_set: int = 1
var reps_in_set: int = 0
var _in_set_transition: bool = false
var _transition_timer_s: float = 0.0
var _completed: bool = false

var _left_tension_guide: MechanicalTensionGuide = null
var _right_tension_guide: MechanicalTensionGuide = null

var _tension_frames_total: int = 0
var _tension_frames_in_zone: int = 0
var _last_left_in_zone: bool = true
var _last_right_in_zone: bool = true

func has_two_set_completion() -> bool:
	return true

func is_exercise_completed() -> bool:
	return _completed

func get_set_display_text() -> String:
	if _completed:
		return "Set 2 / 2  •  Complete!"
	if _in_set_transition:
		return "Set 1 Complete  •  Next: Set 2 (%s)" % _get_set_direction_label(2)
	return "Set %d / 2  •  %s (%d/%d)" % [current_set, _get_set_direction_label(current_set), reps_in_set, REPS_PER_SET]

func _get_set_direction_label(_set_num: int) -> String:
	return "Active Movement"

func _on_set_changed(_new_set: int) -> void:
	pass

func _reset_two_set_state() -> void:
	current_set = 1
	reps_in_set = 0
	_in_set_transition = false
	_transition_timer_s = 0.0
	_completed = false
	_tension_frames_total = 0
	_tension_frames_in_zone = 0
	_last_left_in_zone = true
	_last_right_in_zone = true

func _get_tension_tolerance_m() -> float:
	return get_effective_hit_radius(TENSION_BASE_TOLERANCE_M)

func _uses_left_hand() -> bool:
	return hand_mode != ZenoEnums.HandMode.RIGHT_ONLY and profile.left_enabled

func _uses_right_hand() -> bool:
	return hand_mode != ZenoEnums.HandMode.LEFT_ONLY and profile.right_enabled

func _step_transition(dt: float) -> bool:
	if not _in_set_transition:
		return false
	_transition_timer_s -= dt
	if _transition_timer_s <= 0.0:
		_in_set_transition = false
		current_set = 2
		reps_in_set = 0
		_reset_tension_accumulator()
		_on_set_changed(2)
		_play_haptic("play_haptic_light_touch", ZenoEnums.Hand.LEFT)
		_play_haptic("play_haptic_light_touch", ZenoEnums.Hand.RIGHT)
	return true

func _reset_tension_accumulator() -> void:
	_tension_frames_total = 0
	_tension_frames_in_zone = 0

func _record_tension_sample(in_zone: bool) -> void:
	_tension_frames_total += 1
	if in_zone:
		_tension_frames_in_zone += 1

func _get_tension_quality_ratio() -> float:
	if _tension_frames_total <= 0:
		return 1.0
	return float(_tension_frames_in_zone) / float(_tension_frames_total)

func _complete_rep(hand: int, elapsed_s: float, rep_label: String) -> void:
	var quality := _get_tension_quality_ratio()
	var high_tension := quality >= 0.65
	var bonus := 35 if high_tension else 0
	var res := _record_hit_and_notify(hand, elapsed_s, 3.0, high_tension, bonus)
	_play_haptic("play_haptic_solid_strike" if high_tension else "play_haptic_light_touch", ZenoEnums.Hand.LEFT)
	_play_haptic("play_haptic_solid_strike" if high_tension else "play_haptic_light_touch", ZenoEnums.Hand.RIGHT)
	_reset_tension_accumulator()

	reps_in_set += 1
	if reps_in_set >= REPS_PER_SET:
		if current_set == 1:
			_in_set_transition = true
			_transition_timer_s = SET_TRANSITION_SECONDS
			spawn_celebration_vfx(false)
			status_hint = "Set 1 Complete! Get ready for Set 2: %s" % _get_set_direction_label(2)
		else:
			_completed = true
			spawn_celebration_vfx(true)
			status_hint = "Both sets complete! Great form! +%d" % int(res["combo_points"])
	else:
		var form_tag := "Great Tension!" if high_tension else "Stay on the tension line"
		status_hint = "%s (%d/%d) • %s +%d" % [rep_label, reps_in_set, REPS_PER_SET, form_tag, int(res["combo_points"])]

func clear_arena() -> void:
	if _left_tension_guide != null:
		_left_tension_guide.retire()
		_left_tension_guide = null
	if _right_tension_guide != null:
		_right_tension_guide.retire()
		_right_tension_guide = null
	super.clear_arena()

