class_name AdaptiveTempo
extends RefCounted

## Adaptive tempo evaluation for rhythm mechanics (02-targets-and-hit-detection.md §6.B, AT-05, AT-06).
## interval_s = 60 / BPM
## window = last 8 targets
## if accuracy >= 0.85 -> BPM += 5 (never above preset max)
## if accuracy < 0.60  -> BPM -= 5 (never below 40)
## otherwise           -> hold

const DEFAULT_WINDOW_SIZE: int = 8
const RAISE_THRESHOLD: float = 0.85
const LOWER_THRESHOLD: float = 0.60
const TEMPO_STEP_BPM: float = 5.0
const MIN_TEMPO_BPM: float = 40.0

var current_bpm: float = 60.0
var max_bpm: float = 80.0
var min_bpm: float = MIN_TEMPO_BPM
var max_bpm_reached: float = 60.0
var window_size: int = DEFAULT_WINDOW_SIZE
var _window_outcomes: Array[bool] = []

func _init(p_start_bpm: float = 60.0, p_max_bpm: float = 80.0, p_window_size: int = DEFAULT_WINDOW_SIZE) -> void:
	window_size = maxi(1, p_window_size)
	max_bpm = maxf(MIN_TEMPO_BPM, p_max_bpm)
	current_bpm = clampf(p_start_bpm, MIN_TEMPO_BPM, max_bpm)
	max_bpm_reached = current_bpm

static func get_beat_interval_seconds(bpm: float) -> float:
	return 60.0 / maxf(1.0, bpm)

func get_current_interval_seconds() -> float:
	return get_beat_interval_seconds(current_bpm)

func evaluate_window(hits: int, targets_in_window: int) -> float:
	if targets_in_window <= 0:
		return current_bpm
	var accuracy := float(hits) / float(targets_in_window)
	if accuracy >= RAISE_THRESHOLD - 1e-6:
		current_bpm = minf(max_bpm, current_bpm + TEMPO_STEP_BPM)
	elif accuracy < LOWER_THRESHOLD - 1e-6:
		current_bpm = maxf(min_bpm, current_bpm - TEMPO_STEP_BPM)
	if current_bpm > max_bpm_reached:
		max_bpm_reached = current_bpm
	return current_bpm

func record_target_outcome(is_hit: bool) -> float:
	_window_outcomes.append(is_hit)
	if _window_outcomes.size() >= window_size:
		var hits := 0
		for outcome in _window_outcomes:
			if outcome:
				hits += 1
		var count := _window_outcomes.size()
		_window_outcomes.clear()
		return evaluate_window(hits, count)
	return current_bpm
