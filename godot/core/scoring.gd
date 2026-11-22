class_name ZenoScoring
extends RefCounted

## Scoring, timeliness, combo multiplier, and round score tracking (13-scoring-and-score-attack.md §7, AT-07, AT-08, AT-27).

const BASE_HIT_POINTS: int = 100
const MAX_TIMELINESS_BONUS: int = 50
const SOLID_BOXING_HIT_BONUS: int = 25
const DEFAULT_COMBO_CAP: int = 20

static func compute_lifetime_seconds(lifetime_beats: int, bpm: float) -> float:
	return float(maxi(1, lifetime_beats)) * (60.0 / maxf(1.0, bpm))

static func compute_timeliness(t_hit_s: float, lifetime_s: float) -> float:
	if lifetime_s <= 0.0:
		return 0.0
	return clampf(1.0 - (t_hit_s / lifetime_s), 0.0, 1.0)

## §7.1: points_hit = 100 + floor(50 * timeliness) (+25 for solid boxing hit)
static func compute_base_hit_points(t_hit_s: float, lifetime_s: float, is_solid_boxing_hit: bool = false, extra_bonus: int = 0) -> int:
	var timeliness := compute_timeliness(t_hit_s, lifetime_s)
	var speed_bonus := int(floor(float(MAX_TIMELINESS_BONUS) * timeliness + 1e-6))
	var pts := BASE_HIT_POINTS + speed_bonus + extra_bonus
	if is_solid_boxing_hit:
		pts += SOLID_BOXING_HIT_BONUS
	return pts

## §7.5: multiplier = 1 + min(streak_before, 20) / 20
static func compute_combo_multiplier(streak_before: int, combo_cap: int = DEFAULT_COMBO_CAP) -> float:
	var capped := mini(maxi(0, streak_before), maxi(1, combo_cap))
	return 1.0 + float(capped) / float(maxi(1, combo_cap))

## §7.5: hit points = floor(base_points * multiplier)
static func compute_combo_hit_points(base_points: int, streak_before: int, combo_cap: int = DEFAULT_COMBO_CAP) -> int:
	var mult := compute_combo_multiplier(streak_before, combo_cap)
	return int(floor(float(base_points) * mult + 1e-6))

class RoundScoreTracker extends RefCounted:
	var hits: int = 0
	var misses: int = 0
	var streak: int = 0
	var max_streak: int = 0
	var base_total_score: int = 0
	var combo_total_score: int = 0

	func reset() -> void:
		hits = 0
		misses = 0
		streak = 0
		max_streak = 0
		base_total_score = 0
		combo_total_score = 0

	func record_hit(t_hit_s: float, lifetime_s: float, is_solid_boxing_hit: bool = false, extra_bonus: int = 0) -> Dictionary:
		var base_pts := ZenoScoring.compute_base_hit_points(t_hit_s, lifetime_s, is_solid_boxing_hit, extra_bonus)
		var combo_pts := ZenoScoring.compute_combo_hit_points(base_pts, streak)
		var mult := ZenoScoring.compute_combo_multiplier(streak)
		hits += 1
		streak += 1
		if streak > max_streak:
			max_streak = streak
		base_total_score += base_pts
		combo_total_score += combo_pts
		return {
			"base_points": base_pts,
			"combo_points": combo_pts,
			"multiplier": mult,
			"streak": streak
		}

	func record_direct_points(base_pts: int, counts_as_hit: bool = true) -> Dictionary:
		var combo_pts := ZenoScoring.compute_combo_hit_points(base_pts, streak)
		var mult := ZenoScoring.compute_combo_multiplier(streak)
		if counts_as_hit:
			hits += 1
			streak += 1
			if streak > max_streak:
				max_streak = streak
		base_total_score += base_pts
		combo_total_score += combo_pts
		return {
			"base_points": base_pts,
			"combo_points": combo_pts,
			"multiplier": mult,
			"streak": streak
		}

	func record_miss() -> void:
		misses += 1
		streak = 0

	func get_total_targets() -> int:
		return hits + misses

	func get_accuracy_percent() -> float:
		var total := get_total_targets()
		if total <= 0:
			return 0.0
		return 100.0 * float(hits) / float(total)

## Computes Dojo Mastery Rank from session accuracy percentage (no belt system).
static func compute_dojo_rank(accuracy_percent: float) -> String:
	if accuracy_percent >= 90.0:
		return "Zen Master"
	elif accuracy_percent >= 75.0:
		return "S"
	elif accuracy_percent >= 55.0:
		return "A"
	elif accuracy_percent >= 35.0:
		return "B"
	return "C"
