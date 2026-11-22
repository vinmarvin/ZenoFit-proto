class_name SessionDraw
extends RefCounted

## Balanced randomized 5-mechanic draw for Score Attack (00-gameplay-overview.md §5.2, 14-safety.md §8.8, AT-26, AT-28).
## Rules:
## 1. At least one mechanic from each of the 3 groups (Neck & shoulders, Back/trunk, Chest/arms).
## 2. Remaining two are random from unused mechanics.
## 3. Mechanics seen in the previous session get lower weight (x0.5).
## 4. Level B mechanics (M04, M08, M10) are excluded if no_trunk_mode is true.
## 5. No consecutive Level B rounds in the 5-round schedule (§8.8).
## 6. If the user declines stable-chair confirmation on a Level B round, substitute an unused Level A mechanic (AT-28).

static func get_all_mechanics() -> Array[int]:
	return [
		ZenoEnums.MechanicId.M01_MAKIWARA_STRIKES,
		ZenoEnums.MechanicId.M02_SAKURA_CATCH,
		ZenoEnums.MechanicId.M03_CRANE_WINGS,
		ZenoEnums.MechanicId.M04_BOKKEN_GUARD,
		ZenoEnums.MechanicId.M05_TEMPLE_BELL_PULL,
		ZenoEnums.MechanicId.M06_KI_PALM_PUSH,
		ZenoEnums.MechanicId.M07_ZEN_WATER_WHEEL,
		ZenoEnums.MechanicId.M08_ZEN_HORIZON_WATCH,
		ZenoEnums.MechanicId.M09_TEA_CEREMONY_POUR,
		ZenoEnums.MechanicId.M10_BAMBOO_SWAY
	]

## Draws upper-body routines aligned to v0.4 Routine Picker options while obeying
## no_trunk_mode and non-consecutive Level B constraints.
static func draw_for_routine(
	routine_id: int,
	no_trunk_mode: bool = false,
	previous_session_mechanics: Array[int] = [],
	rng: RandomNumberGenerator = null,
	round_count: int = -1
) -> Array[int]:
	if rng == null:
		rng = RandomNumberGenerator.new()
		rng.randomize()

	if routine_id == ZenoEnums.RoutineId.FULL_UPPER_DOJO:
		var base := draw_five_mechanics(no_trunk_mode, previous_session_mechanics, rng)
		var target_n := round_count if round_count > 0 else 5
		if target_n <= 5:
			return base.slice(0, target_n)
		# Extend deterministically without consecutive Level B for 10-min extended sessions
		var extra_pool: Array[int] = []
		for m in get_all_mechanics():
			if no_trunk_mode and ZenoEnums.get_mechanic_safety_level(m) == ZenoEnums.SafetyLevel.LEVEL_B:
				continue
			if not base.has(m):
				extra_pool.append(m)
		_shuffle_array(extra_pool, rng)
		for m in extra_pool:
			if base.size() >= target_n:
				break
			var prev_b := ZenoEnums.get_mechanic_safety_level(base[base.size() - 1]) == ZenoEnums.SafetyLevel.LEVEL_B
			if prev_b and ZenoEnums.get_mechanic_safety_level(m) == ZenoEnums.SafetyLevel.LEVEL_B:
				continue
			base.append(m)
		while base.size() < target_n:
			base.append(base[base.size() % 5] if ZenoEnums.get_mechanic_safety_level(base[base.size() % 5]) == ZenoEnums.SafetyLevel.LEVEL_A else ZenoEnums.MechanicId.M01_MAKIWARA_STRIKES)
		return base

	var preferred: Array[int] = []
	var default_rounds := 3
	if routine_id == ZenoEnums.RoutineId.SHOULDER_NECK_REFRESH:
		preferred = [
			ZenoEnums.MechanicId.M02_SAKURA_CATCH,
			ZenoEnums.MechanicId.M03_CRANE_WINGS,
			ZenoEnums.MechanicId.M07_ZEN_WATER_WHEEL,
			ZenoEnums.MechanicId.M08_ZEN_HORIZON_WATCH
		]
		default_rounds = 3
	else:
		# POSTURE_MOBILITY_FLOW
		preferred = [
			ZenoEnums.MechanicId.M05_TEMPLE_BELL_PULL,
			ZenoEnums.MechanicId.M06_KI_PALM_PUSH,
			ZenoEnums.MechanicId.M04_BOKKEN_GUARD,
			ZenoEnums.MechanicId.M10_BAMBOO_SWAY,
			ZenoEnums.MechanicId.M01_MAKIWARA_STRIKES
		]
		default_rounds = 4

	var filtered: Array[int] = []
	for m in preferred:
		if no_trunk_mode and ZenoEnums.get_mechanic_safety_level(m) == ZenoEnums.SafetyLevel.LEVEL_B:
			continue
		filtered.append(m)

	var fallback_order := [
		ZenoEnums.MechanicId.M01_MAKIWARA_STRIKES,
		ZenoEnums.MechanicId.M02_SAKURA_CATCH,
		ZenoEnums.MechanicId.M03_CRANE_WINGS,
		ZenoEnums.MechanicId.M05_TEMPLE_BELL_PULL,
		ZenoEnums.MechanicId.M06_KI_PALM_PUSH,
		ZenoEnums.MechanicId.M07_ZEN_WATER_WHEEL,
		ZenoEnums.MechanicId.M09_TEA_CEREMONY_POUR
	]
	var target_rounds := round_count if round_count > 0 else default_rounds
	for m in fallback_order:
		if filtered.size() >= target_rounds:
			break
		if not filtered.has(m):
			filtered.append(m)

	var chosen := filtered.slice(0, min(target_rounds, filtered.size()))
	while chosen.size() < target_rounds:
		chosen.append(fallback_order[chosen.size() % fallback_order.size()])
	return _arrange_without_consecutive_level_b(chosen, rng)

static func draw_five_mechanics(
	no_trunk_mode: bool = false,
	previous_session_mechanics: Array[int] = [],
	rng: RandomNumberGenerator = null
) -> Array[int]:
	if rng == null:
		rng = RandomNumberGenerator.new()
		rng.randomize()

	var candidates: Array[int] = []
	for m in get_all_mechanics():
		if no_trunk_mode and ZenoEnums.get_mechanic_safety_level(m) == ZenoEnums.SafetyLevel.LEVEL_B:
			continue
		candidates.append(m)

	var groups := [
		ZenoEnums.MechanicGroup.NECK_AND_SHOULDERS,
		ZenoEnums.MechanicGroup.BACK_TRUNK,
		ZenoEnums.MechanicGroup.CHEST_ARMS
	]

	var selected: Array[int] = []

	# Step 1: Pick 1 from each group
	for g in groups:
		var group_pool: Array[int] = []
		for m in candidates:
			if ZenoEnums.get_mechanic_group(m) == g and not selected.has(m):
				group_pool.append(m)
		if group_pool.size() > 0:
			var pick := _weighted_pick(group_pool, previous_session_mechanics, rng)
			selected.append(pick)

	# Step 2: Pick remaining up to 5 from unused candidates (preventing >3 Level B so non-consecutive ordering is always possible)
	while selected.size() < 5:
		var remaining: Array[int] = []
		var current_level_b_count := _count_level_b(selected)
		for m in candidates:
			if selected.has(m):
				continue
			if current_level_b_count >= 2 and ZenoEnums.get_mechanic_safety_level(m) == ZenoEnums.SafetyLevel.LEVEL_B:
				continue
			remaining.append(m)
		if remaining.is_empty():
			for m in candidates:
				if not selected.has(m):
					remaining.append(m)
		if remaining.is_empty():
			break
		var pick := _weighted_pick(remaining, previous_session_mechanics, rng)
		selected.append(pick)

	return _arrange_without_consecutive_level_b(selected, rng)

## AT-28: If user declines stable-chair confirmation, substitute an unused Level A mechanic.
static func substitute_level_a_mechanic(current_lineup: Array[int], replace_index: int) -> int:
	var all_mechs := get_all_mechanics()
	# Prefer a Level A mechanic in the same body-area group first
	var old_mech := current_lineup[replace_index] if replace_index >= 0 and replace_index < current_lineup.size() else ZenoEnums.MechanicId.M04_BOKKEN_GUARD
	var target_group := ZenoEnums.get_mechanic_group(old_mech)

	for m in all_mechs:
		if ZenoEnums.get_mechanic_safety_level(m) == ZenoEnums.SafetyLevel.LEVEL_A \
			and ZenoEnums.get_mechanic_group(m) == target_group \
			and not current_lineup.has(m):
			if replace_index >= 0 and replace_index < current_lineup.size():
				current_lineup[replace_index] = m
			return m

	for m in all_mechs:
		if ZenoEnums.get_mechanic_safety_level(m) == ZenoEnums.SafetyLevel.LEVEL_A and not current_lineup.has(m):
			if replace_index >= 0 and replace_index < current_lineup.size():
				current_lineup[replace_index] = m
			return m

	return ZenoEnums.MechanicId.M05_TEMPLE_BELL_PULL

static func _weighted_pick(pool: Array[int], prev_seen: Array[int], rng: RandomNumberGenerator) -> int:
	var weights: Array[float] = []
	var total_w: float = 0.0
	for m in pool:
		var w := 0.5 if prev_seen.has(m) else 1.0
		weights.append(w)
		total_w += w
	var roll := rng.randf() * total_w
	var accum := 0.0
	for i in range(pool.size()):
		accum += weights[i]
		if roll <= accum:
			return pool[i]
	return pool[pool.size() - 1]

static func _count_level_b(list: Array[int]) -> int:
	var c := 0
	for m in list:
		if ZenoEnums.get_mechanic_safety_level(m) == ZenoEnums.SafetyLevel.LEVEL_B:
			c += 1
	return c

static func _arrange_without_consecutive_level_b(lineup: Array[int], rng: RandomNumberGenerator) -> Array[int]:
	var level_b: Array[int] = []
	var level_a: Array[int] = []
	for m in lineup:
		if ZenoEnums.get_mechanic_safety_level(m) == ZenoEnums.SafetyLevel.LEVEL_B:
			level_b.append(m)
		else:
			level_a.append(m)

	# Shuffle both pools
	_shuffle_array(level_a, rng)
	_shuffle_array(level_b, rng)

	if level_b.size() <= 1:
		var combined: Array[int] = []
		combined.append_array(level_a)
		combined.append_array(level_b)
		_shuffle_array(combined, rng)
		return combined

	# Interleave Level B with Level A so two Level B mechanics are never adjacent
	var result: Array[int] = []
	var b_idx := 0
	var a_idx := 0
	for slot in range(lineup.size()):
		var prev_is_b := result.size() > 0 and ZenoEnums.get_mechanic_safety_level(result[result.size() - 1]) == ZenoEnums.SafetyLevel.LEVEL_B
		var remaining_slots := lineup.size() - slot
		var remaining_b := level_b.size() - b_idx
		if not prev_is_b and remaining_b > 0 and (remaining_b * 2 - 1 >= remaining_slots or a_idx >= level_a.size()):
			result.append(level_b[b_idx])
			b_idx += 1
		elif a_idx < level_a.size():
			result.append(level_a[a_idx])
			a_idx += 1
		elif b_idx < level_b.size():
			result.append(level_b[b_idx])
			b_idx += 1
	return result

static func _shuffle_array(arr: Array[int], rng: RandomNumberGenerator) -> void:
	for i in range(arr.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp := arr[i]
		arr[i] = arr[j]
		arr[j] = tmp
