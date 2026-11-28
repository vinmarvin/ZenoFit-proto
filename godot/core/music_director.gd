class_name ZenoMusic
extends RefCounted

## Pure state -> background-music mapping used by Main to drive Platform.play_music().
## Tracks live in res://assets/audio/ and are imported with loop=true.
##   - "menu"             : MainMenu_BGM.ogg      (Welcome, Main Menu, Library, Preview, Tutorial, Credits)
##   - "workout_play"     : Workout_Play.ogg      (whole active session: Session Start -> Rounds -> Paused)
##   - "workout_complete" : Workout_Complete.ogg  (looped while the Results screen stays open)
## Overlay screens (Settings, Exit Confirm, Calibration) keep whichever track is already
## playing so opening Settings from Pause never interrupts the workout music.

const TRACK_NONE := ""
const TRACK_MENU := "menu"
const TRACK_WORKOUT_PLAY := "workout_play"
const TRACK_WORKOUT_COMPLETE := "workout_complete"

const TRACK_PATHS := {
	TRACK_MENU: "res://assets/audio/MainMenu_BGM.ogg",
	TRACK_WORKOUT_PLAY: "res://assets/audio/Workout_Play.ogg",
	TRACK_WORKOUT_COMPLETE: "res://assets/audio/Workout_Complete.ogg",
}

static func track_for_state(state: int, current_track: String = TRACK_NONE) -> String:
	match state:
		ZenoEnums.AppState.BOOT:
			return TRACK_NONE
		ZenoEnums.AppState.SESSION_START, \
		ZenoEnums.AppState.ROUND_INTRO, \
		ZenoEnums.AppState.ROUND_PLAY, \
		ZenoEnums.AppState.ROUND_OUTRO, \
		ZenoEnums.AppState.PAUSED:
			return TRACK_WORKOUT_PLAY
		ZenoEnums.AppState.RESULTS:
			return TRACK_WORKOUT_COMPLETE
		ZenoEnums.AppState.SETTINGS, \
		ZenoEnums.AppState.EXIT_CONFIRM, \
		ZenoEnums.AppState.CALIBRATION:
			return current_track if current_track != TRACK_NONE else TRACK_MENU
		_:
			return TRACK_MENU
