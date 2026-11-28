extends Node

## Platform abstraction autoload isolating OpenXR device features, Session Input Lock,
## haptics, passthrough, recenter signaling, procedural spatial audio SFX, and the
## looped background music (Main Menu / Workout Play / Workout Complete, see ZenoMusic).

signal tracking_origin_recentered()

var xr_interface: XRInterface = null
var is_xr_active: bool = false
var passthrough_enabled: bool = false
var haptics_enabled: bool = true
var haptic_intensity: float = 1.0
var audio_volume: float = 0.8:
	set(value):
		audio_volume = clampf(value, 0.0, 1.0)
		_refresh_music_volume()
var last_haptic_event: Dictionary = {}
var last_audio_event: Dictionary = {}
var last_music_event: Dictionary = {}
var current_music_track: String = ""

## Background music sits under the SFX mix (relative gain applied on top of audio_volume).
const MUSIC_GAIN := 0.55
const MUSIC_FADE_S := 0.8
const MUSIC_SILENT_DB := -80.0
## Fades run between this floor and the target (a linear dB ramp from -80 would sound silent for half the fade).
const MUSIC_FADE_FLOOR_DB := -40.0
const MUSIC_SHUTDOWN_DRAIN_MS := 60

var _sfx_players: Dictionary = {}
var _sfx_bank: Dictionary = {}
var _music_players: Dictionary = {}
var _music_tweens: Dictionary = {}

func _ready() -> void:
	_init_procedural_audio()
	_init_music_players()

func initialize_platform() -> bool:
	xr_interface = XRServer.find_interface("OpenXR")
	if xr_interface and xr_interface.is_initialized():
		is_xr_active = true
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		get_viewport().use_xr = true
		if xr_interface.has_signal("pose_recentered") and not xr_interface.is_connected("pose_recentered", _on_openxr_pose_recentered):
			xr_interface.connect("pose_recentered", _on_openxr_pose_recentered)
		print("[Platform] OpenXR initialized (Reference Space = Local / Seated).")
	else:
		is_xr_active = false
		print("[Platform] OpenXR headset not detected — running in Desktop Simulator mode.")
	return is_xr_active

func get_device_name() -> String:
	return "Standalone VR (OpenXR)" if is_xr_active else "Desktop Simulator"

func supports_passthrough() -> bool:
	if not is_xr_active or xr_interface == null:
		return false
	var modes := xr_interface.get_supported_environment_blend_modes()
	return modes.has(XRInterface.XR_ENV_BLEND_MODE_ALPHA_BLEND)

func set_passthrough(enabled: bool) -> void:
	passthrough_enabled = enabled
	if is_xr_active and xr_interface != null and supports_passthrough():
		if enabled:
			get_viewport().transparent_bg = true
			xr_interface.environment_blend_mode = XRInterface.XR_ENV_BLEND_MODE_ALPHA_BLEND
		else:
			get_viewport().transparent_bg = false
			xr_interface.environment_blend_mode = XRInterface.XR_ENV_BLEND_MODE_OPAQUE

func play_haptic(hand: int, amplitude_01: float, duration_s: float) -> void:
	if not haptics_enabled:
		return
	var scaled_amp := clampf(amplitude_01 * haptic_intensity, 0.0, 1.0)
	last_haptic_event = {
		"hand": hand,
		"amplitude": scaled_amp,
		"duration_s": duration_s
	}
	var ctrl_name := "LeftController" if hand == ZenoEnums.Hand.LEFT else "RightController"
	var root := get_tree().root if get_tree() != null else null
	if root != null:
		var ctrl := root.find_child(ctrl_name, true, false) as XRController3D
		if ctrl != null and is_xr_active:
			ctrl.trigger_haptic_pulse("haptic", 0.0, scaled_amp, duration_s, 0.0)

func play_haptic_light_touch(hand: int) -> void:
	play_haptic(hand, 0.25, 0.030)

func play_haptic_solid_strike(hand: int) -> void:
	play_haptic(hand, 0.72, 0.080)

func play_haptic_light_strike(hand: int) -> void:
	play_haptic(hand, 0.28, 0.035)

func get_hand_tracker(hand: int) -> XRHandTracker:
	var tracker_name := &"/user/hand_tracker/left" if hand == ZenoEnums.Hand.LEFT else &"/user/hand_tracker/right"
	var tracker := XRServer.get_tracker(tracker_name)
	if tracker is XRHandTracker:
		var ht := tracker as XRHandTracker
		if ht.has_tracking_data:
			return ht
	return null

func is_controller_connected(ctrl: XRController3D = null) -> bool:
	if not is_xr_active:
		return true
	return ctrl != null and ctrl.get_has_tracking_data()

func is_hand_tracking_available(hand: int) -> bool:
	return get_hand_tracker(hand) != null

## Session Input Lock: strictly reads ONLY the chosen input source (never switches mid-session).
func sample_input_pose(
	hand: int,
	ctrl: XRController3D,
	locked_input_mode: int = ZenoEnums.InputMode.CONTROLLER
) -> Dictionary:
	if locked_input_mode == ZenoEnums.InputMode.HAND_TRACKING:
		var ht := get_hand_tracker(hand)
		if ht != null:
			var palm := ht.get_hand_joint_transform(XRHandTracker.HAND_JOINT_PALM)
			var thumb := ht.get_hand_joint_transform(XRHandTracker.HAND_JOINT_THUMB_TIP)
			var idx := ht.get_hand_joint_transform(XRHandTracker.HAND_JOINT_INDEX_FINGER_TIP)
			var mid := ht.get_hand_joint_transform(XRHandTracker.HAND_JOINT_MIDDLE_FINGER_TIP)
			var pinch_dist := thumb.origin.distance_to(idx.origin)
			var grasp_dist := palm.origin.distance_to(mid.origin)
			var parent_3d := ctrl.get_parent() as Node3D if ctrl != null else null
			var world_xform: Transform3D = (parent_3d.global_transform * palm) if (parent_3d != null and parent_3d.is_inside_tree()) else palm
			var roll_deg := rad_to_deg(palm.basis.get_euler().z)
			return {
				"tracked": true,
				"origin_world": world_xform.origin,
				"roll_deg": roll_deg,
				"pinch": pinch_dist <= 0.035,
				"grasp": grasp_dist <= 0.070,
				"source": "hand_tracking"
			}
		if not is_xr_active and ctrl != null:
			return {
				"tracked": true,
				"origin_world": ctrl.global_position if ctrl.is_inside_tree() else ctrl.position,
				"roll_deg": ctrl.rotation_degrees.z,
				"pinch": false,
				"grasp": true,
				"source": "hand_tracking_sim"
			}
		var world_pos := ctrl.global_position if ctrl.is_inside_tree() else ctrl.position
		return {
			"tracked": false,
			"origin_world": world_pos,
			"roll_deg": 0.0,
			"pinch": false,
			"grasp": false,
			"source": "hand_tracking"
		}

	# Controller Mode (default): read strictly from XRController3D
	if ctrl != null:
		var has_data := ctrl.get_has_tracking_data() if is_xr_active else true
		var trig := ctrl.get_float("trigger") if (is_xr_active and has_data) else 0.0
		var grip := ctrl.get_float("grip") if (is_xr_active and has_data) else 0.0
		var world_pos := ctrl.global_position if ctrl.is_inside_tree() else ctrl.position
		return {
			"tracked": has_data,
			"origin_world": world_pos,
			"roll_deg": ctrl.rotation_degrees.z,
			"pinch": trig > 0.60,
			"grasp": grip > 0.50 or trig > 0.60 or not is_xr_active,
			"source": "controller"
		}
	return {"tracked": not is_xr_active, "origin_world": Vector3.ZERO, "roll_deg": 0.0, "pinch": false, "grasp": false, "source": "controller"}

func get_ui_pointer_ray(hand: int, ctrl: XRController3D, input_mode: int) -> Dictionary:
	if input_mode == ZenoEnums.InputMode.HAND_TRACKING:
		var ht := get_hand_tracker(hand)
		if ht != null:
			var palm := ht.get_hand_joint_transform(XRHandTracker.HAND_JOINT_PALM)
			var parent_3d := ctrl.get_parent() as Node3D if ctrl != null else null
			var world_xform: Transform3D = (parent_3d.global_transform * palm) if (parent_3d != null and parent_3d.is_inside_tree()) else palm
			return {
				"valid": true,
				"origin": world_xform.origin,
				"dir": (-world_xform.basis.z).normalized()
			}
	if ctrl != null and (ctrl.get_has_tracking_data() or not is_xr_active):
		var c_orig := ctrl.global_position if ctrl.is_inside_tree() else ctrl.position
		var c_dir := (-ctrl.global_transform.basis.z).normalized() if ctrl.is_inside_tree() else (-ctrl.transform.basis.z).normalized()
		return {
			"valid": true,
			"origin": c_orig,
			"dir": c_dir
		}
	return {"valid": false, "origin": Vector3.ZERO, "dir": Vector3(0.0, 0.0, -1.0)}

func _init_procedural_audio() -> void:
	_sfx_bank["wood_crack"] = _synth_wood_crack(0.22)
	_sfx_bank["chime"] = _synth_wav(0.32, 523.25, 523.25, 8.0, 0.0, true)
	_sfx_bank["gong"] = _synth_wav(0.45, 130.81, 128.0, 4.5, 0.15, true)
	_sfx_bank["menu_click"] = _synth_wav(0.05, 880.0, 620.0, 35.0, 0.0)
	_sfx_bank["miss"] = _synth_wav(0.12, 220.0, 150.0, 18.0, 0.0)

	for sfx_key in _sfx_bank.keys():
		var player := AudioStreamPlayer.new()
		player.stream = _sfx_bank[sfx_key]
		player.max_polyphony = 4
		add_child(player)
		_sfx_players[sfx_key] = player

func _synth_wood_crack(duration_s: float) -> AudioStreamWAV:
	var mix_rate := 22050
	var sample_count := int(duration_s * float(mix_rate))
	var data := PackedByteArray()
	data.resize(sample_count * 2)
	var phase_low := 0.0
	var phase_hi := 0.0
	var rng := RandomNumberGenerator.new()
	rng.seed = 4201
	for i in range(sample_count):
		var t := float(i) / float(mix_rate)
		var env_snap := exp(-48.0 * t)
		var env_body := exp(-18.0 * t)
		var env_splinter := exp(-24.0 * maxf(0.0, t - 0.045)) if t >= 0.045 else 0.0
		phase_low += TAU * lerpf(240.0, 95.0, clampf(t / 0.12, 0.0, 1.0)) / float(mix_rate)
		phase_hi += TAU * 1180.0 / float(mix_rate)
		var noise := rng.randf_range(-1.0, 1.0)
		var sig := 0.45 * sin(phase_low) * env_body + 0.35 * noise * env_snap + 0.25 * sin(phase_hi) * env_splinter + 0.20 * noise * env_splinter
		var pcm := int(clampf(sig * 0.55, -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, pcm)
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = mix_rate
	wav.stereo = false
	wav.data = data
	return wav

func _synth_wav(duration_s: float, f_start: float, f_end: float, decay_rate: float, noise_mix: float, harmonic: bool = false) -> AudioStreamWAV:
	var mix_rate := 22050
	var sample_count := int(duration_s * float(mix_rate))
	var data := PackedByteArray()
	data.resize(sample_count * 2)
	var phase := 0.0
	var phase2 := 0.0
	var rng := RandomNumberGenerator.new()
	rng.seed = int(f_start * 100.0)
	for i in range(sample_count):
		var t := float(i) / float(mix_rate)
		var u := clampf(t / maxf(0.001, duration_s), 0.0, 1.0)
		var freq := lerpf(f_start, f_end, u)
		phase += TAU * freq / float(mix_rate)
		phase2 += TAU * (freq * 1.5) / float(mix_rate)
		var env := exp(-decay_rate * t)
		var sample := sin(phase)
		if harmonic:
			sample = 0.65 * sin(phase) + 0.35 * sin(phase2)
		if noise_mix > 0.0:
			sample = (1.0 - noise_mix) * sample + noise_mix * rng.randf_range(-1.0, 1.0) * exp(-25.0 * t)
		var pcm := int(clampf(sample * env * 0.45, -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, pcm)
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = mix_rate
	wav.stereo = false
	wav.data = data
	return wav

func play_sfx(sfx_type: String, streak: int = 0) -> void:
	last_audio_event = {"type": sfx_type, "streak": streak}
	if audio_volume <= 0.01:
		return
	if not _sfx_players.has(sfx_type):
		return
	var player := _sfx_players[sfx_type] as AudioStreamPlayer
	if player == null:
		return
	var capped_streak := mini(maxi(0, streak), 12)
	player.pitch_scale = 1.0 + float(capped_streak) * 0.025
	player.volume_db = linear_to_db(clampf(audio_volume, 0.05, 1.0))
	if is_inside_tree():
		player.play()

# ==============================================================================
# Background Music (looped OGG tracks from res://assets/audio/, see ZenoMusic)
# ==============================================================================

func _init_music_players() -> void:
	for track_key in ZenoMusic.TRACK_PATHS.keys():
		var path := String(ZenoMusic.TRACK_PATHS[track_key])
		if not ResourceLoader.exists(path):
			push_warning("[Platform] Music track missing: %s" % path)
			continue
		var stream := load(path) as AudioStream
		if stream == null:
			continue
		if stream is AudioStreamOggVorbis:
			(stream as AudioStreamOggVorbis).loop = true
		var player := AudioStreamPlayer.new()
		player.name = "Music_%s" % track_key
		player.stream = stream
		player.volume_db = MUSIC_SILENT_DB
		player.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(player)
		_music_players[track_key] = player

func has_music_track(track: String) -> bool:
	return _music_players.has(track)

func is_music_track_looping(track: String) -> bool:
	if not _music_players.has(track):
		return false
	var stream := (_music_players[track] as AudioStreamPlayer).stream
	return stream is AudioStreamOggVorbis and (stream as AudioStreamOggVorbis).loop

func _music_target_db() -> float:
	if audio_volume <= 0.01:
		return MUSIC_SILENT_DB
	return linear_to_db(clampf(audio_volume * MUSIC_GAIN, 0.0001, 1.0))

## Cross-fades to `track` ("" = silence). Re-requesting the active track is a no-op,
## so the workout music keeps flowing across rounds, pause, and settings overlays.
func play_music(track: String) -> void:
	if track == current_music_track:
		return
	var prev := current_music_track
	current_music_track = track
	last_music_event = {"track": track, "previous": prev}
	if _music_players.has(prev):
		_fade_music_player(prev, MUSIC_FADE_FLOOR_DB, true)
	if _music_players.has(track):
		var player := _music_players[track] as AudioStreamPlayer
		_kill_music_tween(track)
		player.volume_db = MUSIC_FADE_FLOOR_DB
		if player.is_inside_tree():
			player.play(0.0)
		_fade_music_player(track, _music_target_db(), false)

func stop_music() -> void:
	play_music("")

func _fade_music_player(track: String, target_db: float, stop_after: bool) -> void:
	var player := _music_players[track] as AudioStreamPlayer
	_kill_music_tween(track)
	if not is_inside_tree() or not player.is_inside_tree():
		player.volume_db = target_db
		if stop_after:
			player.stop()
		return
	var tw := create_tween()
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_property(player, "volume_db", target_db, MUSIC_FADE_S)
	if stop_after:
		tw.tween_callback(player.stop)
	_music_tweens[track] = tw

func _kill_music_tween(track: String) -> void:
	if _music_tweens.has(track):
		var tw := _music_tweens[track] as Tween
		if tw != null and tw.is_valid():
			tw.kill()
		_music_tweens.erase(track)

func _refresh_music_volume() -> void:
	if not _music_players.has(current_music_track):
		return
	_kill_music_tween(current_music_track)
	(_music_players[current_music_track] as AudioStreamPlayer).volume_db = _music_target_db()

## Release active OGG playbacks before shutdown so AudioServer leaves no leaked streams.
func _exit_tree() -> void:
	var had_music := current_music_track != ""
	for track_key in _music_players.keys():
		_kill_music_tween(track_key)
		var player := _music_players[track_key] as AudioStreamPlayer
		player.stop()
		player.stream = null
	current_music_track = ""
	# AudioServer frees stopped playbacks on its mix thread; give it one mix period
	# before engine shutdown tears the server down, otherwise the OGG playback leaks.
	if had_music:
		OS.delay_msec(MUSIC_SHUTDOWN_DRAIN_MS)

func simulate_recenter() -> void:
	_on_openxr_pose_recentered()

func _on_openxr_pose_recentered() -> void:
	tracking_origin_recentered.emit()
