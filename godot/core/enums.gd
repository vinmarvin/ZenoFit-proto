class_name ZenoEnums
extends RefCounted

enum AppState {
	BOOT,
	MAIN_MENU,
	ROUTINE_PICKER,
	CALIBRATION,
	WARM_UP,
	SESSION_START,
	ROUND_INTRO,
	ROUND_PLAY,
	ROUND_OUTRO,
	PAUSED,
	RESULTS,
	CREDITS
}

enum RoutineId {
	SHOULDER_NECK_REFRESH = 1,
	POSTURE_MOBILITY_FLOW = 2,
	FULL_UPPER_DOJO = 3
}

enum DifficultyTier {
	GENTLE,
	STANDARD,
	ACTIVE
}

enum HandMode {
	BOTH_HANDS,
	LEFT_ONLY,
	RIGHT_ONLY
}

enum Hand {
	LEFT,
	RIGHT
}

enum TargetHand {
	LEFT,
	RIGHT,
	EITHER,
	BOTH
}

enum MechanicId {
	M01_MAKIWARA_STRIKES = 1,
	M02_SAKURA_CATCH = 2,
	M03_CRANE_WINGS = 3,
	M04_BOKKEN_GUARD = 4,
	M05_TEMPLE_BELL_PULL = 5,
	M06_KI_PALM_PUSH = 6,
	M07_ZEN_WATER_WHEEL = 7,
	M08_ZEN_HORIZON_WATCH = 8,
	M09_TEA_CEREMONY_POUR = 9,
	M10_BAMBOO_SWAY = 10
}

enum MechanicGroup {
	NECK_AND_SHOULDERS,
	BACK_TRUNK,
	CHEST_ARMS
}

enum SafetyLevel {
	LEVEL_A,
	LEVEL_B
}

enum PauseReason {
	NONE,
	MANUAL,
	AUTO_PAUSE_LAP,
	REST_REMINDER,
	LEAN_WARNING,
	RECENTER_REQUIRED,
	STABLE_CHAIR_CONFIRMATION
}

enum CalibrationStep {
	SEAT_ANCHOR = 1,
	CHAIR_CHECK = 2,
	CHEST_POINT = 3,
	SHOULDERS = 4,
	LEFT_REACH = 5,
	RIGHT_REACH = 6,
	LAP_POINT = 7,
	OBSTACLES = 8,
	MODULE_TWIST = 9,
	MODULE_NECK = 10,
	MODULE_LEAN = 11,
	COMPLETE = 12
}

static func get_mechanic_title(m: int) -> String:
	match m:
		MechanicId.M01_MAKIWARA_STRIKES: return "M01: Makiwara Strikes (Seated Boxing)"
		MechanicId.M02_SAKURA_CATCH: return "M02: Sakura Catch (Overhead Reach)"
		MechanicId.M03_CRANE_WINGS: return "M03: Crane Wings (Side Arm Raise)"
		MechanicId.M04_BOKKEN_GUARD: return "M04: Bokken Guard (Trunk Twist)"
		MechanicId.M05_TEMPLE_BELL_PULL: return "M05: Temple Bell Pull (Seated Row)"
		MechanicId.M06_KI_PALM_PUSH: return "M06: Ki Palm Push (Forward Press)"
		MechanicId.M07_ZEN_WATER_WHEEL: return "M07: Zen Water Wheel (Arm Circles)"
		MechanicId.M08_ZEN_HORIZON_WATCH: return "M08: Zen Horizon Watch (Neck Mobility)"
		MechanicId.M09_TEA_CEREMONY_POUR: return "M09: Tea Ceremony Pour (Curl & Wrist Pour)"
		MechanicId.M10_BAMBOO_SWAY: return "M10: Bamboo Sway (Side Bend)"
		_: return "Unknown Exercise"

static func get_mechanic_instruction(m: int) -> String:
	match m:
		MechanicId.M01_MAKIWARA_STRIKES: return "Extend your punch smoothly to strike approaching makiwara pads on the beat within your comfort reach."
		MechanicId.M02_SAKURA_CATCH: return "Reach diagonally forward-up to catch falling sakura petals before they drift past."
		MechanicId.M03_CRANE_WINGS: return "Extend both arms wide above shoulder height; tilt gently to guide your crane through rings."
		MechanicId.M04_BOKKEN_GUARD: return "Keep both hands near chest guard and rotate your upper torso to face side dojo targets."
		MechanicId.M05_TEMPLE_BELL_PULL: return "Pull the temple bell rope smoothly with active hands from forward reach back toward your waist."
		MechanicId.M06_KI_PALM_PUSH: return "Retract to chest, push the Ki plane forward to target depth, and hold steady for 2.0 s."
		MechanicId.M07_ZEN_WATER_WHEEL: return "Rotate both hands in smooth wide chest-height circles to turn the bamboo water wheel."
		MechanicId.M08_ZEN_HORIZON_WATCH: return "Turn your head slowly (<= 60 deg/s) across the Zen garden horizon to focus on lanterns."
		MechanicId.M09_TEA_CEREMONY_POUR: return "Reach for matcha ladles, curl cleanly toward your shoulder, and rotate wrist (>= 60 deg) to pour."
		MechanicId.M10_BAMBOO_SWAY: return "Hold both hands up on the overhead bamboo bar and sway your torso gently into the safe gap."
		_: return ""

static func get_mechanic_group(m: int) -> int:
	match m:
		MechanicId.M02_SAKURA_CATCH, MechanicId.M03_CRANE_WINGS, MechanicId.M07_ZEN_WATER_WHEEL, MechanicId.M08_ZEN_HORIZON_WATCH:
			return MechanicGroup.NECK_AND_SHOULDERS
		MechanicId.M04_BOKKEN_GUARD, MechanicId.M05_TEMPLE_BELL_PULL, MechanicId.M10_BAMBOO_SWAY:
			return MechanicGroup.BACK_TRUNK
		MechanicId.M01_MAKIWARA_STRIKES, MechanicId.M06_KI_PALM_PUSH, MechanicId.M09_TEA_CEREMONY_POUR:
			return MechanicGroup.CHEST_ARMS
		_:
			return MechanicGroup.CHEST_ARMS

static func get_mechanic_safety_level(m: int) -> int:
	match m:
		MechanicId.M04_BOKKEN_GUARD, MechanicId.M08_ZEN_HORIZON_WATCH, MechanicId.M10_BAMBOO_SWAY:
			return SafetyLevel.LEVEL_B
		_:
			return SafetyLevel.LEVEL_A

static func get_group_name(g: int) -> String:
	match g:
		MechanicGroup.NECK_AND_SHOULDERS: return "Neck & shoulders"
		MechanicGroup.BACK_TRUNK: return "Back / trunk"
		MechanicGroup.CHEST_ARMS: return "Chest & arms"
		_: return "General"

static func get_routine_title(r: int) -> String:
	match r:
		RoutineId.SHOULDER_NECK_REFRESH: return "Shoulder & Neck Refresh"
		RoutineId.POSTURE_MOBILITY_FLOW: return "Posture & Mobility Flow"
		RoutineId.FULL_UPPER_DOJO: return "Full Upper-Body Dojo"
		_: return "Dojo Session"

static func get_routine_description(r: int) -> String:
	match r:
		RoutineId.SHOULDER_NECK_REFRESH:
			return "Seated overhead reach, crane arm-raise, water-wheel circles, and slow garden gaze movement. Preventive active break; not a medical device."
		RoutineId.POSTURE_MOBILITY_FLOW:
			return "Seated bell pulls, forward Ki presses, boxing alignment, and gentle torso rotation for upright posture movement."
		RoutineId.FULL_UPPER_DOJO:
			return "Balanced multi-group upper-body session covering Neck & Shoulders, Back/Trunk, and Chest & Arms."
		_:
			return ""
