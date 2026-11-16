class_name SaveServiceClass
extends Node

## Local JSON persistence for calibration profile, session history, and settings
## (01-body-frame-and-calibration.md §4.6, 13-scoring-and-score-attack.md §7.4, AT-15).
## Uses user:// by default, with automatic fallback to /tmp/zenofit_userdata/ in headless CI/sandbox environments.

var base_dir: String = "user://"

func _init(p_base_dir: String = "user://") -> void:
	base_dir = p_base_dir
	if not base_dir.ends_with("/"):
		base_dir += "/"

func _resolve_writable_dir() -> String:
	var probe_path := base_dir + ".write_probe"
	var f := FileAccess.open(probe_path, FileAccess.WRITE)
	if f != null:
		f.close()
		DirAccess.remove_absolute(ProjectSettings.globalize_path(probe_path))
		return base_dir
	var fallback := "/tmp/zenofit_userdata/"
	DirAccess.make_dir_recursive_absolute(fallback)
	base_dir = fallback
	return base_dir

func get_calibration_path() -> String:
	return _resolve_writable_dir() + "calibration_profile.json"

func get_sessions_path() -> String:
	return _resolve_writable_dir() + "sessions.json"

func get_settings_path() -> String:
	return _resolve_writable_dir() + "settings.json"

func save_calibration_profile(profile: ComfortProfile) -> bool:
	var path := get_calibration_path()
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(JSON.stringify(profile.to_dict(), "\t"))
	f.close()
	return true

func try_load_calibration_profile() -> Dictionary:
	var path := get_calibration_path()
	if not FileAccess.file_exists(path):
		return {"loaded": false, "profile": ComfortProfile.create_default()}
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {"loaded": false, "profile": ComfortProfile.create_default()}
	var parsed = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(parsed) == TYPE_DICTIONARY:
		return {"loaded": true, "profile": ComfortProfile.from_dict(parsed)}
	return {"loaded": false, "profile": ComfortProfile.create_default()}

func append_session_record(record: Dictionary, max_history: int = 10) -> bool:
	var sessions := load_recent_sessions(max_history * 2)
	sessions.push_front(record)
	while sessions.size() > max_history:
		sessions.pop_back()
	var path := get_sessions_path()
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(JSON.stringify(sessions, "\t"))
	f.close()
	return true

func load_recent_sessions(limit: int = 10) -> Array:
	var path := get_sessions_path()
	if not FileAccess.file_exists(path):
		return []
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return []
	var parsed = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(parsed) == TYPE_ARRAY:
		var arr: Array = parsed
		if arr.size() > limit:
			return arr.slice(0, limit)
		return arr
	return []

func save_settings(settings_dict: Dictionary) -> bool:
	var path := get_settings_path()
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(JSON.stringify(settings_dict, "\t"))
	f.close()
	return true

func load_settings() -> Dictionary:
	var defaults := {
		"difficulty": ZenoEnums.DifficultyTier.STANDARD,
		"hand_mode": ZenoEnums.HandMode.BOTH_HANDS,
		"no_trunk_mode": false,
		"quick_session_one_round": false,
		"haptics_enabled": true,
		"haptic_intensity": 1.0,
		"audio_volume": 0.8,
		"rest_reminder_minutes": 8.0
	}
	var path := get_settings_path()
	if not FileAccess.file_exists(path):
		return defaults
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return defaults
	var parsed = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(parsed) == TYPE_DICTIONARY:
		for k in parsed.keys():
			defaults[k] = parsed[k]
	return defaults

func delete_all_saved_data() -> void:
	var paths: Array[String] = [get_calibration_path(), get_sessions_path(), get_settings_path()]
	for p: String in paths:
		if FileAccess.file_exists(p):
			var abs_p: String = ProjectSettings.globalize_path(p) if (p.begins_with("user://") or p.begins_with("res://")) else p
			DirAccess.remove_absolute(abs_p)
