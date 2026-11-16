class_name ZenoEnums
extends RefCounted

enum AppState {
	BOOT,
	MAIN_MENU,
	CALIBRATION,
	SESSION_START,
	ROUND_INTRO,
	ROUND_PLAY,
	ROUND_OUTRO,
	PAUSED,
	RESULTS
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
	M01_ASTEROID_BRAWLER = 1,
	M02_FRUIT_HARVESTER = 2,
	M03_GLIDER_PILOT = 3,
	M04_TURRET_GUNNER = 4,
	M05_COSMIC_TUG_OF_WAR = 5,
	M06_FORCE_BLAST = 6,
	M07_SHIELD_CRANK = 7,
	M08_RECON_SCANNER = 8,
	M09_POTION_BREWER = 9,
	M10_LASER_EVADER = 10
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
	CHEST_POINT = 2,
	SHOULDERS = 3,
	LEFT_REACH = 4,
	RIGHT_REACH = 5,
	LAP_POINT = 6,
	OBSTACLES = 7,
	MODULE_TWIST = 8,
	MODULE_NECK = 9,
	MODULE_LEAN = 10,
	COMPLETE = 11
}

static func get_mechanic_title(m: int) -> String:
	match m:
		MechanicId.M01_ASTEROID_BRAWLER: return "M01: Asteroid Brawler (Seated Boxing)"
		MechanicId.M02_FRUIT_HARVESTER: return "M02: Fruit Harvester (Overhead Reach)"
		MechanicId.M03_GLIDER_PILOT: return "M03: Glider Pilot (Side Arm Raise)"
		MechanicId.M04_TURRET_GUNNER: return "M04: Turret Gunner (Trunk Twist)"
		MechanicId.M05_COSMIC_TUG_OF_WAR: return "M05: Cosmic Tug-of-War (Seated Row)"
		MechanicId.M06_FORCE_BLAST: return "M06: Force Blast (Forward Press)"
		MechanicId.M07_SHIELD_CRANK: return "M07: Shield Generator Crank (Arm Circles)"
		MechanicId.M08_RECON_SCANNER: return "M08: Recon Scanner (Neck Mobility)"
		MechanicId.M09_POTION_BREWER: return "M09: Potion Brewer (Curl & Wrist Pour)"
		MechanicId.M10_LASER_EVADER: return "M10: Laser Evader (Side Bend)"
		_: return "Unknown Mechanic"

static func get_mechanic_instruction(m: int) -> String:
	match m:
		MechanicId.M01_ASTEROID_BRAWLER: return "Punch approaching asteroids on the beat within your comfort reach."
		MechanicId.M02_FRUIT_HARVESTER: return "Reach diagonally forward-up to harvest glowing fruit before it falls past."
		MechanicId.M03_GLIDER_PILOT: return "Raise arms laterally to deploy wings; vary arm heights slightly to steer through rings."
		MechanicId.M04_TURRET_GUNNER: return "Hold hands near chest and rotate your upper body to lock onto side targets."
		MechanicId.M05_COSMIC_TUG_OF_WAR: return "Pull tethered space debris from forward reach back toward your waist."
		MechanicId.M06_FORCE_BLAST: return "Push the energy plane forward and hold for 2.0 s to charge a Force Blast."
		MechanicId.M07_SHIELD_CRANK: return "Move hands in smooth chest-height circles to charge the shield generator."
		MechanicId.M08_RECON_SCANNER: return "Turn your head slowly (<= 60 deg/s) to rest the reticle on horizon targets."
		MechanicId.M09_POTION_BREWER: return "Reach for ingredients, curl toward your shoulder, and roll wrist (>= 60 deg) to pour."
		MechanicId.M10_LASER_EVADER: return "Hold the overhead rail and lean your torso gently sideways into the safe gap."
		_: return ""

static func get_mechanic_group(m: int) -> int:
	match m:
		MechanicId.M02_FRUIT_HARVESTER, MechanicId.M03_GLIDER_PILOT, MechanicId.M07_SHIELD_CRANK, MechanicId.M08_RECON_SCANNER:
			return MechanicGroup.NECK_AND_SHOULDERS
		MechanicId.M04_TURRET_GUNNER, MechanicId.M05_COSMIC_TUG_OF_WAR, MechanicId.M10_LASER_EVADER:
			return MechanicGroup.BACK_TRUNK
		MechanicId.M01_ASTEROID_BRAWLER, MechanicId.M06_FORCE_BLAST, MechanicId.M09_POTION_BREWER:
			return MechanicGroup.CHEST_ARMS
		_:
			return MechanicGroup.CHEST_ARMS

static func get_mechanic_safety_level(m: int) -> int:
	match m:
		MechanicId.M04_TURRET_GUNNER, MechanicId.M08_RECON_SCANNER, MechanicId.M10_LASER_EVADER:
			return SafetyLevel.LEVEL_B
		_:
			return SafetyLevel.LEVEL_A

static func get_group_name(g: int) -> String:
	match g:
		MechanicGroup.NECK_AND_SHOULDERS: return "Neck & shoulders"
		MechanicGroup.BACK_TRUNK: return "Back / trunk"
		MechanicGroup.CHEST_ARMS: return "Chest & arms"
		_: return "General"
