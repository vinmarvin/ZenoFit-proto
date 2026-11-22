extends Node

## Platform abstraction autoload (03-godot-build.md §5.1, §5.4, Rule 3).
## Isolates OpenXR device features (haptics, passthrough, recenter signal) from gameplay code,
## with full Desktop Simulator fallback when running without a headset.

signal tracking_origin_recentered()

var xr_interface: XRInterface = null
var is_xr_active: bool = false
var passthrough_enabled: bool = false
var haptics_enabled: bool = true
var haptic_intensity: float = 1.0
var audio_volume: float = 0.8
var last_haptic_event: Dictionary = {}
var last_audio_event: Dictionary = {}

var _sfx_players: Dictionary = {}
var _sfx_bank: Dictionary = {}

func _ready() -> void:
	_init_procedural_dojo_audio()

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
	return "Meta Quest (OpenXR)" if is_xr_active else "Desktop Simulator (Mouse + Keyboard)"

func supports_passthrough() -> bool:
	if not is_xr_active or xr_interface == null:
		return false
	var modes := xr_interface.get_supported_environment_blend_modes()
	return modes.has(XRInterface.XR_ENV_BLEND_MODE_ALPHA_BLEND)

## Switch OpenXR environment blend mode (alpha blend = passthrough) with calm fallback scene (§5.4, D-06).
func set_passthrough(enabled: bool) -> void:
	passthrough_enabled = enabled
	if is_xr_active and xr_interface != null and supports_passthrough():
		if enabled:
			get_viewport().transparent_bg = true
			xr_interface.environment_blend_mode = XRInterface.XR_ENV_BLEND_MODE_ALPHA_BLEND
		else:
			get_viewport().transparent_bg = false
			xr_interface.environment_blend_mode = XRInterface.XR_ENV_BLEND_MODE_OPAQUE

## Trigger controller haptic pulse via OpenXR action "haptic" (15-feedback-and-ui.md §9.1, 03-godot-build.md §5.4).
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

func play_haptic_forward_press(hand: int) -> void:
	play_haptic(hand, 0.40, 0.050)

func play_haptic_solid_boxing(hand: int) -> void:
	play_haptic(hand, 0.70, 0.080)

func play_haptic_light_boxing(hand: int) -> void:
	play_haptic(hand, 0.20, 0.030)

## Hybrid OpenXR Hand Tracking + Controller fallback queries (v0.4 §5).
func get_hand_tracker(hand: int) -> XRHandTracker:
	var tracker_name := &"/user/hand_tracker/left" if hand == ZenoEnums.Hand.LEFT else &"/user/hand_tracker/right"
	var tracker := XRServer.get_tracker(tracker_name)
	if tracker is XRHandTracker:
		var ht := tracker as XRHandTracker
		if ht.has_tracking_data:
			return ht
	return null

func is_hand_tracked(hand: int, ctrl: XRController3D = null) -> bool:
	if get_hand_tracker(hand) != null:
		return true
	if ctrl != null and ctrl.get_has_tracking_data():
		return true
	return not is_xr_active # Desktop simulator fallback keeps hands tracked

## Returns hand pose dictionary {tracked, origin_world, roll_deg, pinch, grasp, source} using XRHandTracker first, XRController3D fallback.
func sample_hybrid_hand_pose(hand: int, ctrl: XRController3D) -> Dictionary:
	var ht := get_hand_tracker(hand)
	if ht != null:
		var palm := ht.get_hand_joint_transform(XRHandTracker.HAND_JOINT_PALM)
		var thumb := ht.get_hand_joint_transform(XRHandTracker.HAND_JOINT_THUMB_TIP)
		var idx := ht.get_hand_joint_transform(XRHandTracker.HAND_JOINT_INDEX_FINGER_TIP)
		var mid := ht.get_hand_joint_transform(XRHandTracker.HAND_JOINT_MIDDLE_FINGER_TIP)
		var pinch_dist := thumb.origin.distance_to(idx.origin)
		var grasp_dist := palm.origin.distance_to(mid.origin)
		var parent_3d := ctrl.get_parent() as Node3D if ctrl != null else null
		var world_xform: Transform3D = (parent_3d.global_transform * palm) if parent_3d != null else palm
		var roll_deg := rad_to_deg(palm.basis.get_euler().z)
		return {
			"tracked": true,
			"origin_world": world_xform.origin,
			"roll_deg": roll_deg,
			"pinch": pinch_dist <= 0.035,
			"grasp": grasp_dist <= 0.070,
			"source": "hand_tracking"
		}
	if ctrl != null:
		var trig := ctrl.get_float("trigger") if ctrl.get_has_tracking_data() else 0.0
		var grip := ctrl.get_float("grip") if ctrl.get_has_tracking_data() else 0.0
		return {
			"tracked": ctrl.get_has_tracking_data() or not is_xr_active,
			"origin_world": ctrl.global_position,
			"roll_deg": ctrl.rotation_degrees.z,
			"pinch": trig > 0.60,
			"grasp": grip > 0.50 or trig > 0.60,
			"source": "controller"
		}
	return {"tracked": not is_xr_active, "origin_world": Vector3.ZERO, "roll_deg": 0.0, "pinch": false, "grasp": false, "source": "desktop"}

func _init_procedural_dojo_audio() -> void:
	if DisplayServer.get_name() == "headless":
		# Still build tiny waveforms lazily only if played, or keep ready with light memory
		pass
	_sfx_bank["wood_strike"] = _synth_wav(0.18, 165.0, 85.0, 14.0, 0.35)
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

func play_dojo_sfx(sfx_type: String, streak: int = 0) -> void:
	last_audio_event = {"type": sfx_type, "streak": streak}
	if audio_volume <= 0.01:
		return
	if not _sfx_players.has(sfx_type):
		return
	var player := _sfx_players[sfx_type] as AudioStreamPlayer
	if player == null:
		return
	var capped_streak := mini(maxi(0, streak), 10)
	player.pitch_scale = 1.0 + float(capped_streak) * 0.03
	player.volume_db = linear_to_db(clampf(audio_volume, 0.05, 1.0))
	if is_inside_tree():
		player.play()

func simulate_recenter() -> void:
	_on_openxr_pose_recentered()

func _on_openxr_pose_recentered() -> void:
	tracking_origin_recentered.emit()
