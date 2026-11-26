class_name SessionDraw
extends RefCounted

## Curated 7-exercise registry, category filters, and Quick Break 5-round playlist generator.
## Guarantees coverage across Active, Mobility, and Posture with no consecutive Level B rounds.

static func get_all_exercises() -> Array[int]:
	return [
		ZenoEnums.ExerciseId.BOARD_SMASH,
		ZenoEnums.ExerciseId.WIDE_SPLIT,
		ZenoEnums.ExerciseId.SKY_REACH,
		ZenoEnums.ExerciseId.ORBIT_FLOW,
		ZenoEnums.ExerciseId.WRIST_TWIST,
		ZenoEnums.ExerciseId.TORSO_TWIST,
		ZenoEnums.ExerciseId.HORIZON_GAZE,
		ZenoEnums.ExerciseId.SHOULDER_PRESS,
		ZenoEnums.ExerciseId.BICEP_CURL,
		ZenoEnums.ExerciseId.ARM_CIRCLES,
		ZenoEnums.ExerciseId.LATERAL_RAISE
	]

static func get_exercises_by_category(category: int) -> Array[int]:
	if category == ZenoEnums.ExerciseCategory.ALL:
		return get_all_exercises()
	var out: Array[int] = []
	for id in get_all_exercises():
		if ZenoEnums.get_exercise_category(id) == category:
			out.append(id)
	return out

static func draw_quick_break_mix(
	previous_lineup: Array[int] = [],
	rng: RandomNumberGenerator = null
) -> Array[int]:
	if rng == null:
		rng = RandomNumberGenerator.new()
		rng.randomize()

	var categories := [
		ZenoEnums.ExerciseCategory.ACTIVE,
		ZenoEnums.ExerciseCategory.MOBILITY,
		ZenoEnums.ExerciseCategory.POSTURE
	]
	var selected: Array[int] = []

	# Step 1: Guarantee at least 1 exercise from each focus category
	for cat in categories:
		var pool := get_exercises_by_category(cat)
		if not pool.is_empty():
			selected.append(_weighted_pick(pool, previous_lineup, rng))

	# Step 2: Fill up to 5 distinct exercises without exceeding 2 Level B rounds
	while selected.size() < 5:
		var remaining: Array[int] = []
		var level_b_count := _count_level_b(selected)
		for id in get_all_exercises():
			if selected.has(id):
				continue
			if level_b_count >= 2 and ZenoEnums.get_exercise_safety_level(id) == ZenoEnums.SafetyLevel.LEVEL_B:
				continue
			remaining.append(id)
		if remaining.is_empty():
			break
		selected.append(_weighted_pick(remaining, previous_lineup, rng))

	return _arrange_without_consecutive_level_b(selected, rng)

static func _weighted_pick(pool: Array[int], prev_seen: Array[int], rng: RandomNumberGenerator) -> int:
	var weights: Array[float] = []
	var total_w := 0.0
	for id in pool:
		var w := 0.5 if prev_seen.has(id) else 1.0
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
	for id in list:
		if ZenoEnums.get_exercise_safety_level(id) == ZenoEnums.SafetyLevel.LEVEL_B:
			c += 1
	return c

static func _arrange_without_consecutive_level_b(lineup: Array[int], rng: RandomNumberGenerator) -> Array[int]:
	var level_b: Array[int] = []
	var level_a: Array[int] = []
	for id in lineup:
		if ZenoEnums.get_exercise_safety_level(id) == ZenoEnums.SafetyLevel.LEVEL_B:
			level_b.append(id)
		else:
			level_a.append(id)

	_shuffle_array(level_a, rng)
	_shuffle_array(level_b, rng)

	if level_b.size() <= 1:
		var combined: Array[int] = []
		combined.append_array(level_a)
		combined.append_array(level_b)
		_shuffle_array(combined, rng)
		return combined

	var result: Array[int] = []
	var b_idx := 0
	var a_idx := 0
	for slot in range(lineup.size()):
		var prev_is_b := result.size() > 0 and ZenoEnums.get_exercise_safety_level(result[result.size() - 1]) == ZenoEnums.SafetyLevel.LEVEL_B
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
