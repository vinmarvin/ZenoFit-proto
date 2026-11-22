class_name SafetyMonitors
extends RefCounted

## Safety monitors for Auto-Pause (Hands in Lap, §8.1, AT-09), Lateral Lean Warning (§8.4 & §6.10, AT-10),
## and Rest Reminder (§8.3).

class AutoPauseMonitor extends RefCounted:
	var lap_distance_threshold_m: float = 0.15
	var hold_duration_seconds: float = 2.0
	var accumulated_seconds: float = 0.0
	var _has_last_left: bool = false
	var _has_last_right: bool = false
	var _last_left_local: Vector3 = Vector3.ZERO
	var _last_right_local: Vector3 = Vector3.ZERO

	func _init(p_threshold_m: float = 0.15, p_hold_s: float = 2.0) -> void:
		lap_distance_threshold_m = p_threshold_m
		hold_duration_seconds = p_hold_s

	func reset() -> void:
		accumulated_seconds = 0.0

	func evaluate(
		left_hand_local: Vector3,
		right_hand_local: Vector3,
		lap_point_local: Vector3,
		dt: float,
		left_tracked: bool = true,
		right_tracked: bool = true,
		lower_zone_max_y: float = -0.15
	) -> bool:
		if left_tracked:
			_last_left_local = left_hand_local
			_has_last_left = true
		if right_tracked:
			_last_right_local = right_hand_local
			_has_last_right = true

		var left_in_lap := false
		if left_tracked:
			left_in_lap = left_hand_local.distance_to(lap_point_local) <= lap_distance_threshold_m + 1e-5
		elif _has_last_left and _last_left_local.y <= lower_zone_max_y:
			# Optical hand tracking dropped in the lower headset FoV after hand descended toward lap.
			left_in_lap = true

		var right_in_lap := false
		if right_tracked:
			right_in_lap = right_hand_local.distance_to(lap_point_local) <= lap_distance_threshold_m + 1e-5
		elif _has_last_right and _last_right_local.y <= lower_zone_max_y:
			right_in_lap = true

		if left_in_lap and right_in_lap:
			accumulated_seconds += maxf(0.0, dt)
			return accumulated_seconds >= hold_duration_seconds - 1e-5
		else:
			accumulated_seconds = 0.0
			return false

class LeanMonitor extends RefCounted:
	var lean_threshold_m: float = 0.20
	var hold_seconds: float = 0.50
	var accumulated_lean_seconds: float = 0.0

	func _init(p_threshold_m: float = 0.20, p_hold_s: float = 0.50) -> void:
		lean_threshold_m = p_threshold_m
		hold_seconds = p_hold_s

	func reset() -> void:
		accumulated_lean_seconds = 0.0

	## §8.4: Level A uses |Δx| > 0.20 m for >= 0.5 s.
	## §6.10: Bamboo Sway overrides threshold to min(Δx_max + 0.05, 0.30) m.
	static func get_m10_override_threshold(delta_x_max_m: float) -> float:
		return minf(absf(delta_x_max_m) + 0.05, 0.30)

	func evaluate(
		head_local_x: float,
		seat_anchor_local_x: float,
		dt: float,
		override_threshold_m: float = -1.0
	) -> bool:
		var threshold := override_threshold_m if override_threshold_m > 0.0 else lean_threshold_m
		var delta_x := absf(head_local_x - seat_anchor_local_x)
		if delta_x > threshold + 1e-5:
			accumulated_lean_seconds += maxf(0.0, dt)
			return accumulated_lean_seconds >= hold_seconds - 1e-5
		else:
			accumulated_lean_seconds = 0.0
			return false

class RestReminderMonitor extends RefCounted:
	var interval_seconds: float = 480.0 # 8 minutes default (range 7-10 min)
	var elapsed_play_seconds: float = 0.0

	func _init(p_interval_minutes: float = 8.0) -> void:
		set_interval_minutes(p_interval_minutes)

	func set_interval_minutes(minutes: float) -> void:
		var clamped_min := clampf(minutes, 7.0, 10.0)
		interval_seconds = clamped_min * 60.0

	func reset() -> void:
		elapsed_play_seconds = 0.0

	func evaluate(dt: float) -> bool:
		elapsed_play_seconds += maxf(0.0, dt)
		if elapsed_play_seconds >= interval_seconds - 1e-5:
			elapsed_play_seconds = 0.0
			return true
		return false
