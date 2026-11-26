class_name ZenoEnums
extends RefCounted

enum AppState {
	BOOT,
	WELCOME,
	MAIN_MENU,
	EXERCISE_SELECT,
	EXERCISE_PREVIEW,
	CALIBRATION,
	SESSION_START,
	ROUND_INTRO,
	ROUND_PLAY,
	ROUND_OUTRO,
	PAUSED,
	RESULTS,
	SETTINGS,
	TUTORIAL,
	CREDITS,
	EXIT_CONFIRM
}

enum ExerciseId {
	BOARD_SMASH = 1,
	WIDE_SPLIT = 2,
	SKY_REACH = 3,
	ORBIT_FLOW = 4,
	WRIST_TWIST = 5,
	TORSO_TWIST = 6,
	HORIZON_GAZE = 7,
	SHOULDER_PRESS = 8,
	BICEP_CURL = 9,
	ARM_CIRCLES = 10,
	LATERAL_RAISE = 11
}

enum ExerciseCategory {
	ALL = 0,
	ACTIVE = 1,
	MOBILITY = 2,
	POSTURE = 3
}

enum InputMode {
	CONTROLLER = 0,
	HAND_TRACKING = 1
}

enum DifficultyTier {
	GENTLE = 0,
	STANDARD = 1,
	ACTIVE = 2
}

enum HandMode {
	BOTH_HANDS = 0,
	LEFT_ONLY = 1,
	RIGHT_ONLY = 2
}

enum Hand {
	LEFT = 0,
	RIGHT = 1
}

enum TargetHand {
	LEFT = 0,
	RIGHT = 1,
	EITHER = 2,
	BOTH = 3
}

enum SafetyLevel {
	LEVEL_A = 0,
	LEVEL_B = 1
}

enum PauseReason {
	NONE = 0,
	MANUAL = 1,
	AUTO_PAUSE_LAP = 2,
	REST_REMINDER = 3,
	LEAN_WARNING = 4,
	RECENTER_REQUIRED = 5,
	INPUT_LOST = 6
}

enum CalibrationStep {
	SEAT_ANCHOR = 1,
	COMFORT_REACH = 2,
	LAP_ZONE = 3,
	COMPLETE = 4
}

static func get_exercise_title(id: int) -> String:
	match id:
		ExerciseId.BOARD_SMASH: return "Board Smash"
		ExerciseId.WIDE_SPLIT: return "Wide Split"
		ExerciseId.SKY_REACH: return "Sky Reach"
		ExerciseId.ORBIT_FLOW: return "Orbit Flow"
		ExerciseId.WRIST_TWIST: return "Wrist Twist"
		ExerciseId.TORSO_TWIST: return "Torso Twist"
		ExerciseId.HORIZON_GAZE: return "Horizon Gaze"
		ExerciseId.SHOULDER_PRESS: return "Shoulder Press"
		ExerciseId.BICEP_CURL: return "Bicep Curl"
		ExerciseId.ARM_CIRCLES: return "Arm Circles"
		ExerciseId.LATERAL_RAISE: return "Lateral Raise"
		_: return "Seated Flow"

static func get_exercise_tagline(id: int) -> String:
	match id:
		ExerciseId.BOARD_SMASH: return "Smash wooden boards on rhythm"
		ExerciseId.WIDE_SPLIT: return "Open chest and upper back"
		ExerciseId.SKY_REACH: return "Lift shoulders and open posture"
		ExerciseId.ORBIT_FLOW: return "Smooth shoulder circle flow"
		ExerciseId.WRIST_TWIST: return "Gentle wrist rotation anti-RSI"
		ExerciseId.TORSO_TWIST: return "Rotate upper torso left and right"
		ExerciseId.HORIZON_GAZE: return "Slow neck turns across horizon"
		ExerciseId.SHOULDER_PRESS: return "Press both hands overhead and lower with control"
		ExerciseId.BICEP_CURL: return "Curl both arms toward shoulders and extend smoothly"
		ExerciseId.ARM_CIRCLES: return "Circle both arms clockwise then counterclockwise"
		ExerciseId.LATERAL_RAISE: return "Raise both arms to shoulder height and lower"
		_: return "Comfortable seated movement"

static func get_exercise_area(id: int) -> String:
	match id:
		ExerciseId.BOARD_SMASH: return "Arms & Chest"
		ExerciseId.WIDE_SPLIT: return "Upper Back & Chest"
		ExerciseId.SKY_REACH: return "Shoulders"
		ExerciseId.ORBIT_FLOW: return "Shoulders & Mobility"
		ExerciseId.WRIST_TWIST: return "Wrists & Forearms"
		ExerciseId.TORSO_TWIST: return "Core & Spine"
		ExerciseId.HORIZON_GAZE: return "Neck"
		ExerciseId.SHOULDER_PRESS: return "Shoulders & Triceps"
		ExerciseId.BICEP_CURL: return "Biceps"
		ExerciseId.ARM_CIRCLES: return "Shoulders"
		ExerciseId.LATERAL_RAISE: return "Lateral Deltoid"
		_: return "Upper Body"

static func get_exercise_cue(id: int) -> String:
	match id:
		ExerciseId.BOARD_SMASH: return "Strike incoming boards smoothly"
		ExerciseId.WIDE_SPLIT: return "Bring hands to chest, then split wide"
		ExerciseId.SKY_REACH: return "Reach diagonally upward with control"
		ExerciseId.ORBIT_FLOW: return "Trace steady circles along both rings"
		ExerciseId.WRIST_TWIST: return "Keep forearms steady and rotate wrists"
		ExerciseId.TORSO_TWIST: return "Hold hands near chest and turn your torso"
		ExerciseId.HORIZON_GAZE: return "Turn your head slowly to each lantern"
		ExerciseId.SHOULDER_PRESS: return "Follow the vertical tension line up and down"
		ExerciseId.BICEP_CURL: return "Curl along the tension arc with steady elbows"
		ExerciseId.ARM_CIRCLES: return "Trace the circular tension ring in each set direction"
		ExerciseId.LATERAL_RAISE: return "Lift and lower both arms along the lateral tension arc"
		_: return "Move comfortably within your reach"

static func get_exercise_preview_steps(id: int) -> Array[String]:
	match id:
		ExerciseId.BOARD_SMASH:
			return [
				"Sit tall with relaxed shoulders and hands ready",
				"Punch forward or at an angle to break incoming boards",
				"Keep strokes crisp without over-leaning forward"
			]
		ExerciseId.WIDE_SPLIT:
			return [
				"Bring both hands together in front of your chest",
				"Open both arms wide together to break both side boards",
				"Return calmly to center to ready the next pair"
			]
		ExerciseId.SKY_REACH:
			return [
				"Keep your neck relaxed and eyes angled comfortably",
				"Reach diagonally forward and up to touch each lantern",
				"Lower your arm slightly between reaches"
			]
		ExerciseId.ORBIT_FLOW:
			return [
				"Hold both hands at comfortable chest height",
				"Trace smooth, wide circles along the glowing rings",
				"Switch direction calmly when the ring cue flips"
			]
		ExerciseId.WRIST_TWIST:
			return [
				"Rest your forearms comfortably inside the dial rings",
				"Rotate your wrists gently to match the target angle",
				"Hold briefly at the target until the dial chimes"
			]
		ExerciseId.TORSO_TWIST:
			return [
				"Sit steadily with both feet grounded on the floor",
				"Keep hands close to your chest and turn your upper torso",
				"Hold your aim on the side board to shatter it"
			]
		ExerciseId.HORIZON_GAZE:
			return [
				"Keep your shoulders relaxed and spine upright",
				"Turn your head slowly toward each glowing lantern",
				"Pause steadily for one second before turning back"
			]
		ExerciseId.SHOULDER_PRESS:
			return [
				"Set 1: Lift both hands upward along the vertical tension line",
				"Set 2: Lower both hands back to shoulder height with control",
				"Stay inside the glowing tension corridor to hit every target"
			]
		ExerciseId.BICEP_CURL:
			return [
				"Set 1: Bend both elbows to curl hands up toward your shoulders",
				"Set 2: Extend both elbows smoothly back to the start position",
				"Keep your hands following the curved tension arc"
			]
		ExerciseId.ARM_CIRCLES:
			return [
				"Set 1: Circle both arms clockwise along the glowing ring",
				"Set 2: Circle both arms counterclockwise with steady form",
				"Stay on the circular tension path to hit each checkpoint"
			]
		ExerciseId.LATERAL_RAISE:
			return [
				"Set 1: Raise both arms out to the sides up to shoulder height",
				"Set 2: Lower both arms smoothly back down along the arc",
				"Follow the lateral tension path for balanced form"
			]
		_:
			return [
				"Sit comfortably upright in your chair",
				"Follow Zeno's movement preview at your own pace",
				"Stop anytime if you feel discomfort"
			]

static func get_exercise_dumbbell_note(id: int) -> String:
	match id:
		ExerciseId.SHOULDER_PRESS, ExerciseId.BICEP_CURL, ExerciseId.ARM_CIRCLES:
			return "Ingin mendapatkan latihan yang lebih optimal? Kamu bisa menggunakan sepasang dumbbell untuk menambahkan resistensi selama latihan. Tidak punya dumbbell? Tidak masalah! Kamu tetap bisa melakukan exercise ini hanya dengan menggunakan tangan."
		_:
			return ""

static func get_exercise_category(id: int) -> int:
	match id:
		ExerciseId.BOARD_SMASH, ExerciseId.WIDE_SPLIT, ExerciseId.SHOULDER_PRESS, ExerciseId.BICEP_CURL, ExerciseId.LATERAL_RAISE:
			return ExerciseCategory.ACTIVE
		ExerciseId.SKY_REACH, ExerciseId.ORBIT_FLOW, ExerciseId.WRIST_TWIST, ExerciseId.ARM_CIRCLES:
			return ExerciseCategory.MOBILITY
		ExerciseId.TORSO_TWIST, ExerciseId.HORIZON_GAZE:
			return ExerciseCategory.POSTURE
		_:
			return ExerciseCategory.ACTIVE

static func get_exercise_safety_level(id: int) -> int:
	match id:
		ExerciseId.TORSO_TWIST, ExerciseId.HORIZON_GAZE:
			return SafetyLevel.LEVEL_B
		_:
			return SafetyLevel.LEVEL_A

static func get_category_name(cat: int) -> String:
	match cat:
		ExerciseCategory.ALL: return "All Exercises"
		ExerciseCategory.ACTIVE: return "Active"
		ExerciseCategory.MOBILITY: return "Mobility"
		ExerciseCategory.POSTURE: return "Posture"
		_: return "All Exercises"

static func get_input_mode_name(mode: int) -> String:
	match mode:
		InputMode.CONTROLLER: return "Controllers"
		InputMode.HAND_TRACKING: return "Hand Tracking"
		_: return "Controllers"
