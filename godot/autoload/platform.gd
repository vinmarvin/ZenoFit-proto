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
var last_haptic_event: Dictionary = {}

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

func simulate_recenter() -> void:
	_on_openxr_pose_recentered()

func _on_openxr_pose_recentered() -> void:
	tracking_origin_recentered.emit()
