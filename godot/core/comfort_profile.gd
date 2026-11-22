class_name ComfortProfile
extends RefCounted

## Stores calibrated seated body geometry, per-hand reach, module limits, and obstacle exclusion zones
## (01-body-frame-and-calibration.md §4.2–4.7).

const MAX_REACH_FACTOR_K: float = 0.85
const DEFAULT_CHEST_OFFSET_BELOW_HEAD_M: float = 0.25
const DEFAULT_SHOULDER_WIDTH_M: float = 0.40
const DEFAULT_EXCLUSION_RADIUS_M: float = 0.12

var version: int = 1
var created_utc: String = "2026-11-15T00:00:00Z"
var shoulder_width_m: float = DEFAULT_SHOULDER_WIDTH_M

var left_enabled: bool = true
var left_reach_forward_m: float = 0.60
var left_arm_length_m: float = 0.60

var right_enabled: bool = true
var right_reach_forward_m: float = 0.60
var right_arm_length_m: float = 0.60

# Module calibrations (§4.7)
var twist_deg_l: float = 50.0
var twist_deg_r: float = 40.0
var neck_deg_l: float = 70.0
var neck_deg_r: float = 65.0
var lean_m_l: float = 0.30
var lean_m_r: float = 0.20

var twist_calibrated: bool = false
var neck_calibrated: bool = false
var lean_calibrated: bool = false

# Offsets in BodyFrame spec space (metres)
var chest_offset_from_head_m: Vector3 = Vector3(0.0, -0.25, 0.08)
var lap_point_from_chest_m: Vector3 = Vector3(0.0, -0.45, 0.20)
var left_shoulder_local_m: Vector3 = Vector3(-0.20, 0.12, 0.0)
var right_shoulder_local_m: Vector3 = Vector3(0.20, 0.12, 0.0)

# Obstacle points in BodyFrame spec space (Vector3)
var obstacles: Array[Vector3] = []

static func create_default() -> ComfortProfile:
	var p := ComfortProfile.new()
	p.update_shoulder_positions_from_width()
	return p

func update_shoulder_positions_from_width() -> void:
	var half_w := maxf(0.12, shoulder_width_m * 0.5)
	left_shoulder_local_m = Vector3(-half_w, 0.12, 0.0)
	right_shoulder_local_m = Vector3(half_w, 0.12, 0.0)

func is_hand_enabled(hand: int) -> bool:
	return left_enabled if hand == ZenoEnums.Hand.LEFT else right_enabled

func get_reach_forward_m(hand: int) -> float:
	return left_reach_forward_m if hand == ZenoEnums.Hand.LEFT else right_reach_forward_m

func get_arm_length_m(hand: int) -> float:
	return left_arm_length_m if hand == ZenoEnums.Hand.LEFT else right_arm_length_m

func get_shoulder_local(hand: int) -> Vector3:
	return left_shoulder_local_m if hand == ZenoEnums.Hand.LEFT else right_shoulder_local_m

## §4.3: R_target(hand) = k * R_f,hand, clamped to k <= 0.85
func get_target_forward_distance(hand: int, k: float) -> float:
	var clamped_k := clampf(k, 0.10, MAX_REACH_FACTOR_K)
	return clamped_k * get_reach_forward_m(hand)

## §6.6 Ki Palm Push: Two-hand plane uses min(R_f,L, R_f,R) so neither arm is over-reached (AT-21)
func get_two_hand_forward_distance(k: float) -> float:
	var clamped_k := clampf(k, 0.10, MAX_REACH_FACTOR_K)
	if left_enabled and right_enabled:
		return clamped_k * minf(left_reach_forward_m, right_reach_forward_m)
	elif left_enabled:
		return clamped_k * left_reach_forward_m
	else:
		return clamped_k * right_reach_forward_m

func get_effective_hand_mode(requested_mode: int) -> int:
	if not left_enabled and right_enabled:
		return ZenoEnums.HandMode.RIGHT_ONLY
	if not right_enabled and left_enabled:
		return ZenoEnums.HandMode.LEFT_ONLY
	return requested_mode

## §4.5: A target candidate position T is rejected if distance(T, O_i) < r_ex + target_radius
func is_violating_obstacle_zone(
	candidate_local_spec: Vector3,
	target_radius_m: float,
	exclusion_radius_m: float = DEFAULT_EXCLUSION_RADIUS_M
) -> bool:
	var min_dist := exclusion_radius_m + target_radius_m
	for obs in obstacles:
		if candidate_local_spec.distance_to(obs) < min_dist:
			return true
	return false

## §4.5 & AT-04: Widens angle/offset within comfort envelope if an obstacle blocks the candidate position.
func resolve_obstacle_free_position(
	candidate_local_spec: Vector3,
	target_radius_m: float,
	exclusion_radius_m: float = DEFAULT_EXCLUSION_RADIUS_M,
	max_attempts: int = 16
) -> Dictionary:
	if not is_violating_obstacle_zone(candidate_local_spec, target_radius_m, exclusion_radius_m):
		return {"valid": true, "position": candidate_local_spec}

	var base_r_xz := Vector2(candidate_local_spec.x, candidate_local_spec.z).length()
	var base_yaw := atan2(candidate_local_spec.x, maxf(0.05, candidate_local_spec.z))

	for i in range(1, max_attempts + 1):
		var sign_dir := 1.0 if (i % 2 == 1) else -1.0
		var step_idx := int(ceil(float(i) / 2.0))
		var delta_angle := deg_to_rad(8.0 * float(step_idx)) * sign_dir
		var test_yaw := base_yaw + delta_angle
		var test_pos := Vector3(
			base_r_xz * sin(test_yaw),
			candidate_local_spec.y + (0.04 * float(step_idx % 3)),
			base_r_xz * cos(test_yaw)
		)
		if not is_violating_obstacle_zone(test_pos, target_radius_m, exclusion_radius_m):
			return {"valid": true, "position": test_pos}

	return {"valid": false, "position": candidate_local_spec}

func to_dict() -> Dictionary:
	var obs_arr: Array = []
	for o in obstacles:
		obs_arr.append({"x": o.x, "y": o.y, "z": o.z})
	return {
		"version": version,
		"createdUtc": created_utc,
		"shoulderWidthM": shoulder_width_m,
		"leftHand": {
			"enabled": left_enabled,
			"reachForwardM": left_reach_forward_m,
			"armLengthM": left_arm_length_m
		},
		"rightHand": {
			"enabled": right_enabled,
			"reachForwardM": right_reach_forward_m,
			"armLengthM": right_arm_length_m
		},
		"modules": {
			"twistDegL": twist_deg_l,
			"twistDegR": twist_deg_r,
			"neckDegL": neck_deg_l,
			"neckDegR": neck_deg_r,
			"leanM_L": lean_m_l,
			"leanM_R": lean_m_r,
			"twistCalibrated": twist_calibrated,
			"neckCalibrated": neck_calibrated,
			"leanCalibrated": lean_calibrated
		},
		"chestOffsetFromHeadM": [chest_offset_from_head_m.x, chest_offset_from_head_m.y, chest_offset_from_head_m.z],
		"lapPointFromChestM": [lap_point_from_chest_m.x, lap_point_from_chest_m.y, lap_point_from_chest_m.z],
		"obstacles": obs_arr
	}

static func from_dict(d: Dictionary) -> ComfortProfile:
	var p := ComfortProfile.create_default()
	p.version = int(d.get("version", 1))
	p.created_utc = str(d.get("createdUtc", p.created_utc))
	p.shoulder_width_m = float(d.get("shoulderWidthM", DEFAULT_SHOULDER_WIDTH_M))
	p.update_shoulder_positions_from_width()

	if d.has("leftHand") and typeof(d["leftHand"]) == TYPE_DICTIONARY:
		var lh: Dictionary = d["leftHand"]
		p.left_enabled = bool(lh.get("enabled", true))
		p.left_reach_forward_m = float(lh.get("reachForwardM", 0.60))
		p.left_arm_length_m = float(lh.get("armLengthM", 0.60))

	if d.has("rightHand") and typeof(d["rightHand"]) == TYPE_DICTIONARY:
		var rh: Dictionary = d["rightHand"]
		p.right_enabled = bool(rh.get("enabled", true))
		p.right_reach_forward_m = float(rh.get("reachForwardM", 0.60))
		p.right_arm_length_m = float(rh.get("armLengthM", 0.60))

	if d.has("modules") and typeof(d["modules"]) == TYPE_DICTIONARY:
		var m: Dictionary = d["modules"]
		p.twist_deg_l = float(m.get("twistDegL", 50.0))
		p.twist_deg_r = float(m.get("twistDegR", 40.0))
		p.neck_deg_l = float(m.get("neckDegL", 70.0))
		p.neck_deg_r = float(m.get("neckDegR", 65.0))
		p.lean_m_l = float(m.get("leanM_L", 0.30))
		p.lean_m_r = float(m.get("leanM_R", 0.20))
		p.twist_calibrated = bool(m.get("twistCalibrated", false))
		p.neck_calibrated = bool(m.get("neckCalibrated", false))
		p.lean_calibrated = bool(m.get("leanCalibrated", false))

	if d.has("chestOffsetFromHeadM") and typeof(d["chestOffsetFromHeadM"]) == TYPE_ARRAY:
		var c: Array = d["chestOffsetFromHeadM"]
		if c.size() >= 3:
			p.chest_offset_from_head_m = Vector3(float(c[0]), float(c[1]), float(c[2]))

	if d.has("lapPointFromChestM") and typeof(d["lapPointFromChestM"]) == TYPE_ARRAY:
		var l: Array = d["lapPointFromChestM"]
		if l.size() >= 3:
			p.lap_point_from_chest_m = Vector3(float(l[0]), float(l[1]), float(l[2]))

	p.obstacles.clear()
	if d.has("obstacles") and typeof(d["obstacles"]) == TYPE_ARRAY:
		for item in d["obstacles"]:
			if typeof(item) == TYPE_DICTIONARY:
				p.obstacles.append(Vector3(float(item.get("x", 0.0)), float(item.get("y", 0.0)), float(item.get("z", 0.0))))

	return p
