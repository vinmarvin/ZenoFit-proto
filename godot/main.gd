extends XROrigin3D

## Main XR & Desktop Simulator Coordinator for ZenoFit v0.4 (Zen Dojo Arcade, Godot 4.7).
## Owns:
## - OpenXR initialization (Seated / Local reference space, Hybrid Hand Tracking + Controller fallback)
## - Zen Dojo Environment (res://assets/Environment.glb) with 28 loose kitbash pieces stripped at runtime
## - Mobile VR Render Budget (zero real-time shadows on static environment/props, CULL_DISABLED on shoji)
## - CalibrationController, SafetyMonitors (Auto-Pause w/ FoV drop fallback, Lean Warning, Rest Reminder)
## - Active Exercise (M01..M10), FloatingMascotCoach (Opsi 1 Welcome Wave), ZenoWorldUI, and procedural Dojo VFX/SFX

@onready var xr_camera: XRCamera3D = $XRCamera3D
@onready var left_controller: XRController3D = $LeftController
@onready var right_controller: XRController3D = $RightController

var arena_root: Node3D
var dojo_env_root: Node3D
var floor_platform: MeshInstance3D
var left_tip_visual: MeshInstance3D
var right_tip_visual: MeshInstance3D
var left_menu_ray: MeshInstance3D
var right_menu_ray: MeshInstance3D
var mascot_coach: FloatingMascotCoach
var world_ui: ZenoWorldUI

var calibration_ctrl: CalibrationController
var auto_pause_monitor: SafetyMonitors.AutoPauseMonitor
var lean_monitor: SafetyMonitors.LeanMonitor
var rest_monitor: SafetyMonitors.RestReminderMonitor
var active_mechanic: MechanicBase = null

# Hand and head tracking state in SpecSpace / BodyFrame
var _prev_left_local_spec: Vector3 = Vector3(-0.20, -0.10, 0.35)
var _curr_left_local_spec: Vector3 = Vector3(-0.20, -0.10, 0.35)
var _prev_right_local_spec: Vector3 = Vector3(0.20, -0.10, 0.35)
var _curr_right_local_spec: Vector3 = Vector3(0.20, -0.10, 0.35)
var _left_world_pos: Vector3 = Vector3(-0.22, 0.95, -0.38)
var _right_world_pos: Vector3 = Vector3(0.22, 0.95, -0.38)
var _left_tracked: bool = true
var _right_tracked: bool = true
var _left_roll_deg: float = 0.0
var _right_roll_deg: float = 0.0
var _left_grasping: bool = false
var _right_grasping: bool = false
var _prev_left_pinch: bool = false
var _prev_right_pinch: bool = false
var _left_speeds: Array[float] = [0.0, 0.0, 0.0]
var _right_speeds: Array[float] = [0.0, 0.0, 0.0]
var _prev_head_yaw_deg: float = 0.0
var _sim_left_depth_m: float = 0.45
var _sim_right_depth_m: float = 0.45
var _sim_wrist_roll_deg: float = 0.0
var _sim_cam_yaw_deg: float = 0.0
var _sim_cam_pitch_deg: float = 0.0
var _sim_cam_offset_local: Vector3 = Vector3.ZERO
var _has_initial_xr_pose: bool = false

func _ready() -> void:
	Platform.initialize_platform()
	Platform.tracking_origin_recentered.connect(_on_tracking_origin_recentered)
	Platform.audio_volume = float(GameFlow.settings.get("audio_volume", 0.8))

	_setup_environment_and_nodes()
	_setup_controllers_and_tips()

	calibration_ctrl = CalibrationController.new(GameFlow.profile)
	auto_pause_monitor = SafetyMonitors.AutoPauseMonitor.new(0.15, 2.0)
	lean_monitor = SafetyMonitors.LeanMonitor.new(0.20, 0.50)
	rest_monitor = SafetyMonitors.RestReminderMonitor.new(float(GameFlow.settings.get("rest_reminder_minutes", 8.0)))

	EventBus.state_changed.connect(_on_flow_state_changed)
	EventBus.round_started.connect(_on_round_started)
	EventBus.mascot_poked.connect(_on_mascot_poked)
	EventBus.target_hit.connect(_on_target_hit_feedback)
	EventBus.target_missed.connect(_on_target_missed_feedback)

	_rebuild_body_frame_from_camera()
	GameFlow.complete_boot()

func _setup_environment_and_nodes() -> void:
	# Calm Zen lighting (Mobile VR render budget: 1 DirectionalLight3D, ZERO real-time shadows)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.16, 0.17, 0.15)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.86, 0.84, 0.78)
	env.ambient_light_energy = 0.78
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	add_child(world_env)

	var dir_light := DirectionalLight3D.new()
	dir_light.rotation_degrees = Vector3(-48.0, -32.0, 0.0)
	dir_light.light_color = Color(1.0, 0.96, 0.88)
	dir_light.light_energy = 0.82
	dir_light.shadow_enabled = false
	add_child(dir_light)

	# Fallback seated floor disc (hidden if Zen Dojo Environment.glb loads)
	floor_platform = MeshInstance3D.new()
	floor_platform.name = "StaticSeatedReferencePlatform"
	var cyl := CylinderMesh.new()
	cyl.top_radius = 1.5
	cyl.bottom_radius = 1.5
	cyl.height = 0.03
	floor_platform.mesh = cyl
	floor_platform.position = Vector3(0.0, -0.95, 0.0)
	floor_platform.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var floor_mat := StandardMaterial3D.new()
	floor_mat.albedo_color = Color(0.18, 0.21, 0.16)
	floor_mat.roughness = 0.9
	floor_platform.material_override = floor_mat
	add_child(floor_platform)

	# Load Zen Dojo Room (Environment.glb) cleanly with stray kitbash pieces stripped
	dojo_env_root = DojoEnvironmentLoader.load_and_clean_dojo_environment()
	if dojo_env_root != null:
		add_child(dojo_env_root)
		floor_platform.visible = false

	if not Platform.is_xr_active:
		xr_camera.position = Vector3(0.0, 1.20, 0.0)
		left_controller.position = Vector3(-0.22, 0.95, -0.38)
		right_controller.position = Vector3(0.22, 0.95, -0.38)

	arena_root = Node3D.new()
	arena_root.name = "SessionArena"
	add_child(arena_root)

	mascot_coach = FloatingMascotCoach.new()
	mascot_coach.name = "FloatingMascotCoach"
	add_child(mascot_coach)

	world_ui = ZenoWorldUI.new()
	world_ui.name = "WorldUI"
	world_ui.request_confirm_calibration_step.connect(_confirm_calibration_step)
	world_ui.request_skip_calibration_step.connect(_skip_calibration_step)
	world_ui.request_mark_obstacle.connect(_mark_calibration_obstacle)
	world_ui.request_auto_action.connect(_trigger_auto_action)
	world_ui.request_poke_mascot.connect(func(): mascot_coach.trigger_poke_reaction(ZenoEnums.Hand.RIGHT))
	world_ui.request_toggle_mascot_quality.connect(_toggle_mascot_quality)
	add_child(world_ui)

func _toggle_mascot_quality() -> void:
	var next_hq := not bool(GameFlow.settings.get("mascot_high_quality", true))
	GameFlow.settings["mascot_high_quality"] = next_hq
	SaveService.save_settings(GameFlow.settings)
	mascot_coach.set_quality_mode(next_hq)
	world_ui._rebuild_buttons_for_state(GameFlow.current_state)

func _setup_controllers_and_tips() -> void:
	left_tip_visual = _create_hand_tip(Color(0.20, 0.65, 1.0), "LeftHandTip")
	right_tip_visual = _create_hand_tip(Color(1.0, 0.58, 0.20), "RightHandTip")
	add_child(left_tip_visual)
	add_child(right_tip_visual)

	left_menu_ray = _create_menu_ray(left_controller, Color(0.35, 0.85, 1.0, 0.35))
	right_menu_ray = _create_menu_ray(right_controller, Color(1.0, 0.75, 0.35, 0.35))

	left_controller.button_pressed.connect(_on_xr_button_pressed.bind(ZenoEnums.Hand.LEFT))
	right_controller.button_pressed.connect(_on_xr_button_pressed.bind(ZenoEnums.Hand.RIGHT))

func _create_hand_tip(col: Color, tip_name: String) -> MeshInstance3D:
	var mesh_inst := MeshInstance3D.new()
	mesh_inst.name = tip_name
	mesh_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var sphere_mesh := SphereMesh.new()
	sphere_mesh.radius = ZenoGeometry.DEFAULT_HAND_TIP_RADIUS_M
	sphere_mesh.height = ZenoGeometry.DEFAULT_HAND_TIP_RADIUS_M * 2.0
	sphere_mesh.radial_segments = 12
	sphere_mesh.rings = 8
	mesh_inst.mesh = sphere_mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = col
	mat.emission_enabled = true
	mat.emission = col * 0.45
	mesh_inst.material_override = mat
	return mesh_inst

func _create_menu_ray(ctrl: XRController3D, col: Color) -> MeshInstance3D:
	var ray := MeshInstance3D.new()
	ray.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.004
	cyl.bottom_radius = 0.004
	cyl.height = 1.2
	ray.mesh = cyl
	ray.rotation_degrees = Vector3(90.0, 0.0, 0.0)
	ray.position = Vector3(0.0, 0.0, -0.6)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = col
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ray.material_override = mat
	ctrl.add_child(ray)
	return ray

## Raycast pointer beams are strictly forbidden during ROUND_PLAY (v0.4 §1 anti-raycast).
func is_ui_raycast_enabled() -> bool:
	return GameFlow.current_state != ZenoEnums.AppState.ROUND_PLAY

func _rebuild_body_frame_from_camera() -> void:
	GameFlow.body_frame = BodyFrame.rebuild_from_godot_head(
		xr_camera.global_position,
		xr_camera.global_transform.basis,
		GameFlow.profile.chest_offset_from_head_m
	)
	if Platform.is_xr_active:
		var fwd_y := (-xr_camera.global_transform.basis.z).y
		GameFlow.body_frame.origin_spec.y = xr_camera.global_position.y + fwd_y * 0.55 - 0.10
	GameFlow.seat_anchor_local_spec = GameFlow.body_frame.from_godot_world(xr_camera.global_position)
	calibration_ctrl.current_body_frame = GameFlow.body_frame
	calibration_ctrl.seat_anchor_local_spec = GameFlow.seat_anchor_local_spec
	_sync_dojo_floor_transform()

func _sync_dojo_floor_transform() -> void:
	var floor_world := GameFlow.body_frame.to_godot_world(Vector3(0.0, -0.68, 0.0))
	if dojo_env_root != null:
		dojo_env_root.global_position = floor_world
	if floor_platform != null:
		floor_platform.global_position = floor_world

func _process(delta: float) -> void:
	_handle_desktop_simulator_input(delta)
	_sync_xr_camera_body_frame()
	_update_tracked_poses(delta)

	var allow_ray := is_ui_raycast_enabled()
	if left_menu_ray != null:
		left_menu_ray.visible = allow_ray and Platform.is_xr_active and _left_tracked
	if right_menu_ray != null:
		right_menu_ray.visible = allow_ray and Platform.is_xr_active and _right_tracked

	if left_tip_visual != null:
		left_tip_visual.visible = _left_tracked or not Platform.is_xr_active
		left_tip_visual.global_position = _left_world_pos
	if right_tip_visual != null:
		right_tip_visual.visible = _right_tracked or not Platform.is_xr_active
		right_tip_visual.global_position = _right_world_pos

	_sync_dojo_floor_transform()
	GameFlow.advance_round_timer(delta)

	if GameFlow.current_state == ZenoEnums.AppState.ROUND_PLAY:
		_evaluate_safety_monitors(delta)
		if active_mechanic != null and GameFlow.current_state == ZenoEnums.AppState.ROUND_PLAY:
			active_mechanic.left_grasping = _left_grasping
			active_mechanic.right_grasping = _right_grasping

			var head_local := GameFlow.body_frame.from_godot_world(xr_camera.global_position)
			var head_fwd_spec := GameFlow.body_frame.rotate_world_to_local_spec(
				SpecSpace.to_spec(-xr_camera.global_transform.basis.z)
			)
			var head_yaw_deg := rad_to_deg(atan2(head_fwd_spec.x, maxf(0.01, head_fwd_spec.z)))
			var head_speed_deg_s := absf(head_yaw_deg - _prev_head_yaw_deg) / maxf(0.001, delta)
			_prev_head_yaw_deg = head_yaw_deg

			active_mechanic.update_mechanic(
				delta,
				head_local,
				head_fwd_spec,
				head_speed_deg_s,
				_prev_left_local_spec,
				_curr_left_local_spec,
				_get_smoothed_speed(_left_speeds),
				_prev_right_local_spec,
				_curr_right_local_spec,
				_get_smoothed_speed(_right_speeds),
				_left_roll_deg,
				_right_roll_deg
			)

	mascot_coach.update_coach(
		delta,
		GameFlow.body_frame,
		_left_world_pos,
		_right_world_pos
	)
	world_ui.update_ui_display(
		GameFlow.body_frame,
		calibration_ctrl,
		active_mechanic,
		xr_camera.global_position,
		-xr_camera.global_transform.basis.z,
		delta
	)

	# 3D Beat-Saber Panel Hover Pointer (Desktop Mouse or VR Controller; strictly OFF in ROUND_PLAY)
	if is_ui_raycast_enabled():
		if Platform.is_xr_active:
			var ctrl := right_controller if _right_tracked else left_controller
			if ctrl != null:
				world_ui.process_pointer_ray(ctrl.global_position, -ctrl.global_transform.basis.z, false, false, false)
		elif not Input.is_key_pressed(KEY_Q) and not Input.is_key_pressed(KEY_E):
			var mp := get_viewport().get_mouse_position()
			var r_orig := xr_camera.project_ray_origin(mp)
			var r_dir := xr_camera.project_ray_normal(mp)
			world_ui.process_pointer_ray(r_orig, r_dir, Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT), false, false)
	else:
		world_ui.hide_pointer_dot()

func _sync_xr_camera_body_frame() -> void:
	if not Platform.is_xr_active:
		return
	if not _has_initial_xr_pose and xr_camera.global_position.length_squared() > 0.0001:
		_has_initial_xr_pose = true
		_rebuild_body_frame_from_camera()
		return
	if GameFlow.current_state == ZenoEnums.AppState.CALIBRATION and calibration_ctrl.current_step == ZenoEnums.CalibrationStep.SEAT_ANCHOR:
		_rebuild_body_frame_from_camera()
	else:
		var fwd_y := (-xr_camera.global_transform.basis.z).y
		var expected_chest_y := xr_camera.global_position.y + fwd_y * 0.55 - 0.10
		if absf(expected_chest_y - GameFlow.body_frame.origin_spec.y) > 0.04:
			GameFlow.body_frame.origin_spec.y = lerpf(GameFlow.body_frame.origin_spec.y, expected_chest_y, 0.18)

func _update_tracked_poses(dt: float) -> void:
	var pose_l := Platform.sample_hybrid_hand_pose(ZenoEnums.Hand.LEFT, left_controller)
	var pose_r := Platform.sample_hybrid_hand_pose(ZenoEnums.Hand.RIGHT, right_controller)

	_left_tracked = bool(pose_l.get("tracked", true))
	_right_tracked = bool(pose_r.get("tracked", true))
	_left_world_pos = pose_l.get("origin_world", left_controller.global_position)
	_right_world_pos = pose_r.get("origin_world", right_controller.global_position)
	_left_roll_deg = float(pose_l.get("roll_deg", 0.0)) if Platform.is_xr_active else _sim_wrist_roll_deg
	_right_roll_deg = float(pose_r.get("roll_deg", 0.0)) if Platform.is_xr_active else _sim_wrist_roll_deg
	_left_grasping = bool(pose_l.get("grasp", false)) or not Platform.is_xr_active
	_right_grasping = bool(pose_r.get("grasp", false)) or not Platform.is_xr_active

	var pinch_l := bool(pose_l.get("pinch", false))
	var pinch_r := bool(pose_r.get("pinch", false))
	if String(pose_l.get("source", "")) == "hand_tracking" and pinch_l and not _prev_left_pinch:
		_on_xr_button_pressed("trigger_click", ZenoEnums.Hand.LEFT)
	if String(pose_r.get("source", "")) == "hand_tracking" and pinch_r and not _prev_right_pinch:
		_on_xr_button_pressed("trigger_click", ZenoEnums.Hand.RIGHT)
	_prev_left_pinch = pinch_l
	_prev_right_pinch = pinch_r

	_prev_left_local_spec = _curr_left_local_spec
	_prev_right_local_spec = _curr_right_local_spec
	_curr_left_local_spec = GameFlow.body_frame.from_godot_world(_left_world_pos)
	_curr_right_local_spec = GameFlow.body_frame.from_godot_world(_right_world_pos)

	var v_l := _curr_left_local_spec.distance_to(_prev_left_local_spec) / maxf(0.001, dt)
	var v_r := _curr_right_local_spec.distance_to(_prev_right_local_spec) / maxf(0.001, dt)
	_left_speeds.pop_front()
	_left_speeds.append(v_l)
	_right_speeds.pop_front()
	_right_speeds.append(v_r)

func _get_smoothed_speed(arr: Array[float]) -> float:
	var sum := 0.0
	for v in arr:
		sum += v
	return sum / float(maxi(1, arr.size()))

func _evaluate_safety_monitors(dt: float) -> void:
	# 1. Auto-pause when both hands rest in lap for >= 2.0 s (with FoV tracking-loss fallback, AT-09)
	if auto_pause_monitor.evaluate(
		_curr_left_local_spec, _curr_right_local_spec,
		GameFlow.profile.lap_point_from_chest_m, dt,
		_left_tracked, _right_tracked, -0.15
	):
		auto_pause_monitor.reset()
		GameFlow.pause_session(
			ZenoEnums.PauseReason.AUTO_PAUSE_LAP,
			"Auto-Paused: Hands rested in lap for 2.0 s. Take a breather!"
		)
		return

	# 2. Lateral lean warning (§8.4 for Level A, §6.10 override for M10, AT-10)
	var mech := GameFlow.get_current_mechanic_id()
	var head_local := GameFlow.body_frame.from_godot_world(xr_camera.global_position)
	if ZenoEnums.get_mechanic_safety_level(mech) == ZenoEnums.SafetyLevel.LEVEL_A:
		if lean_monitor.evaluate(head_local.x, GameFlow.seat_anchor_local_spec.x, dt):
			lean_monitor.reset()
			GameFlow.pause_session(
				ZenoEnums.PauseReason.LEAN_WARNING,
				"Safety Pause: Please sit back in a stable, centered position."
			)
			return
	elif mech == ZenoEnums.MechanicId.M10_BAMBOO_SWAY:
		var max_lean := maxf(GameFlow.profile.lean_m_l, GameFlow.profile.lean_m_r)
		var override_thresh := SafetyMonitors.LeanMonitor.get_m10_override_threshold(max_lean)
		if lean_monitor.evaluate(head_local.x, GameFlow.seat_anchor_local_spec.x, dt, override_thresh):
			lean_monitor.reset()
			GameFlow.pause_session(
				ZenoEnums.PauseReason.LEAN_WARNING,
				"Safety Pause: Lean exceeded safe threshold (%.2f m). Sit back comfortably." % override_thresh
			)
			return

	# 3. Rest reminder every 8 minutes (§8.3)
	if rest_monitor.evaluate(dt):
		GameFlow.pause_session(
			ZenoEnums.PauseReason.REST_REMINDER,
			"Rest Reminder: Relax your shoulders and neck from the headset weight."
		)

func _on_mascot_poked(_hand: int) -> void:
	# Opsi 1 Main Menu Flow: tapping/poking Zeno on MAIN_MENU opens Routine Picker!
	if GameFlow.current_state == ZenoEnums.AppState.MAIN_MENU:
		Platform.play_dojo_sfx("gong", 0)
		GameFlow.open_routine_picker_from_menu()

func _on_target_hit_feedback(hand: int, points: int, streak: int, is_solid: bool) -> void:
	var mech := GameFlow.get_current_mechanic_id()
	var sfx := "chime"
	if mech == ZenoEnums.MechanicId.M01_MAKIWARA_STRIKES or mech == ZenoEnums.MechanicId.M04_BOKKEN_GUARD or mech == ZenoEnums.MechanicId.M05_TEMPLE_BELL_PULL or mech == ZenoEnums.MechanicId.M06_KI_PALM_PUSH:
		sfx = "wood_strike" if not is_solid else "gong"
	Platform.play_dojo_sfx(sfx, streak)
	_spawn_hit_burst_vfx(_left_world_pos if hand == ZenoEnums.Hand.LEFT else _right_world_pos, points, streak, is_solid)

func _on_target_missed_feedback() -> void:
	Platform.play_dojo_sfx("miss", 0)

func _spawn_hit_burst_vfx(world_pos: Vector3, points: int, streak: int, is_solid: bool) -> void:
	if arena_root == null or not is_inside_tree():
		return
	var popup := Label3D.new()
	popup.text = "+%d%s" % [points, " (x%d)" % streak if streak >= 2 else ""]
	popup.font_size = 30 if is_solid else 24
	popup.pixel_size = 0.0024
	popup.modulate = Color(1.0, 0.90, 0.30) if is_solid else Color(0.55, 1.0, 0.78)
	popup.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	popup.global_position = world_pos + Vector3(0.0, 0.10, 0.0)
	arena_root.add_child(popup)

	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(popup, "global_position:y", world_pos.y + 0.34, 0.55)
	tw.tween_property(popup, "modulate:a", 0.0, 0.55)
	tw.chain().tween_callback(popup.queue_free)

func _on_flow_state_changed(_prev: int, next_state: int) -> void:
	if next_state == ZenoEnums.AppState.CALIBRATION:
		calibration_ctrl.working_profile = GameFlow.profile
		if GameFlow.has_valid_calibration:
			calibration_ctrl.start_returning_user_quick_check()
		else:
			calibration_ctrl.start_full_calibration()
	elif next_state == ZenoEnums.AppState.MAIN_MENU or next_state == ZenoEnums.AppState.RESULTS or next_state == ZenoEnums.AppState.ROUTINE_PICKER:
		if active_mechanic != null:
			active_mechanic.clear_arena()
			active_mechanic = null
	if next_state == ZenoEnums.AppState.RESULTS or next_state == ZenoEnums.AppState.SESSION_START:
		Platform.play_dojo_sfx("gong", 0)

func _on_round_started(_round_idx: int, mechanic_id: int) -> void:
	if Platform.is_xr_active and _round_idx == 0:
		_rebuild_body_frame_from_camera()
	auto_pause_monitor.reset()
	lean_monitor.reset()
	active_mechanic = _instantiate_mechanic(mechanic_id)
	active_mechanic.setup(
		mechanic_id,
		GameFlow.profile,
		GameFlow.body_frame,
		GameFlow.get_current_preset(),
		int(GameFlow.settings.get("hand_mode", ZenoEnums.HandMode.BOTH_HANDS)),
		arena_root
	)
	Platform.play_dojo_sfx("chime", 0)

func _instantiate_mechanic(mechanic_id: int) -> MechanicBase:
	match mechanic_id:
		ZenoEnums.MechanicId.M01_MAKIWARA_STRIKES: return M01MakiwaraStrikes.new()
		ZenoEnums.MechanicId.M02_SAKURA_CATCH: return M02SakuraCatch.new()
		ZenoEnums.MechanicId.M03_CRANE_WINGS: return M03CraneWings.new()
		ZenoEnums.MechanicId.M04_BOKKEN_GUARD: return M04BokkenGuard.new()
		ZenoEnums.MechanicId.M05_TEMPLE_BELL_PULL: return M05TempleBellPull.new()
		ZenoEnums.MechanicId.M06_KI_PALM_PUSH: return M06KiPalmPush.new()
		ZenoEnums.MechanicId.M07_ZEN_WATER_WHEEL: return M07ZenWaterWheel.new()
		ZenoEnums.MechanicId.M08_ZEN_HORIZON_WATCH: return M08ZenHorizonWatch.new()
		ZenoEnums.MechanicId.M09_TEA_CEREMONY_POUR: return M09TeaCeremonyPour.new()
		ZenoEnums.MechanicId.M10_BAMBOO_SWAY: return M10BambooSway.new()
		_: return M01MakiwaraStrikes.new()

func _on_xr_button_pressed(action_name: String, _hand: int) -> void:
	if action_name == "menu_button":
		if GameFlow.current_state == ZenoEnums.AppState.PAUSED:
			GameFlow.request_resume_with_countdown()
		elif GameFlow.current_state == ZenoEnums.AppState.CREDITS or GameFlow.current_state == ZenoEnums.AppState.ROUTINE_PICKER or GameFlow.current_state == ZenoEnums.AppState.WARM_UP:
			GameFlow.return_to_main_menu()
		else:
			GameFlow.pause_session(ZenoEnums.PauseReason.MANUAL, "Menu button pressed.")
	elif action_name == "trigger_click" or action_name == "ax_button":
		if action_name == "trigger_click" and is_ui_raycast_enabled() and Platform.is_xr_active:
			var ctrl := left_controller if _hand == ZenoEnums.Hand.LEFT else right_controller
			if ctrl != null:
				var o := ctrl.global_position
				var d := -ctrl.global_transform.basis.z
				if world_ui.process_pointer_ray(o, d, true, true, false):
					world_ui.process_pointer_ray(o, d, false, false, true)
					return
		if GameFlow.current_state == ZenoEnums.AppState.CALIBRATION:
			_confirm_calibration_step()
		elif GameFlow.current_state == ZenoEnums.AppState.MAIN_MENU:
			GameFlow.open_routine_picker_from_menu()
		elif GameFlow.current_state == ZenoEnums.AppState.ROUTINE_PICKER:
			GameFlow.select_routine_and_start(world_ui._picker_routine, world_ui._picker_duration_min, world_ui._picker_warmup)
		elif GameFlow.current_state == ZenoEnums.AppState.WARM_UP:
			GameFlow.skip_warmup()
		elif GameFlow.current_state == ZenoEnums.AppState.PAUSED:
			GameFlow.request_resume_with_countdown()
		elif GameFlow.current_state == ZenoEnums.AppState.RESULTS:
			GameFlow.begin_session()
	elif action_name == "by_button":
		if GameFlow.current_state == ZenoEnums.AppState.CALIBRATION:
			_skip_calibration_step()
		elif GameFlow.current_state == ZenoEnums.AppState.PAUSED and GameFlow.current_pause_reason == ZenoEnums.PauseReason.STABLE_CHAIR_CONFIRMATION:
			GameFlow.decline_stable_chair_and_substitute()
		elif GameFlow.current_state == ZenoEnums.AppState.MAIN_MENU or GameFlow.current_state == ZenoEnums.AppState.PAUSED:
			_rebuild_body_frame_from_camera()
			GameFlow.request_recalibrate()
		elif GameFlow.current_state == ZenoEnums.AppState.RESULTS or GameFlow.current_state == ZenoEnums.AppState.ROUTINE_PICKER or GameFlow.current_state == ZenoEnums.AppState.CREDITS:
			GameFlow.return_to_main_menu()

func _on_tracking_origin_recentered() -> void:
	_rebuild_body_frame_from_camera()
	if GameFlow.current_state == ZenoEnums.AppState.ROUND_INTRO \
		or GameFlow.current_state == ZenoEnums.AppState.ROUND_PLAY \
		or GameFlow.current_state == ZenoEnums.AppState.ROUND_OUTRO:
		GameFlow.pause_session(
			ZenoEnums.PauseReason.RECENTER_REQUIRED,
			"Headset Recentered: Sit comfortably and confirm your seated position to resume."
		)

func _confirm_calibration_step() -> void:
	var head_spec := SpecSpace.to_spec(xr_camera.global_position)
	var head_fwd_spec := SpecSpace.to_spec(-xr_camera.global_transform.basis.z)
	var left_spec := SpecSpace.to_spec(_left_world_pos)
	var right_spec := SpecSpace.to_spec(_right_world_pos)

	if not Platform.is_xr_active:
		match calibration_ctrl.current_step:
			ZenoEnums.CalibrationStep.CHEST_POINT:
				right_spec = head_spec + Vector3(0.0, -ComfortProfile.DEFAULT_CHEST_OFFSET_BELOW_HEAD_M, 0.08)
			ZenoEnums.CalibrationStep.SHOULDERS:
				left_spec = calibration_ctrl.current_body_frame.to_world_spec(Vector3(-0.20, 0.12, 0.0))
				right_spec = calibration_ctrl.current_body_frame.to_world_spec(Vector3(0.20, 0.12, 0.0))
			ZenoEnums.CalibrationStep.LEFT_REACH:
				left_spec = calibration_ctrl.current_body_frame.to_world_spec(Vector3(-0.20, 0.0, 0.60))
			ZenoEnums.CalibrationStep.RIGHT_REACH:
				right_spec = calibration_ctrl.current_body_frame.to_world_spec(Vector3(0.20, 0.0, 0.60))
			ZenoEnums.CalibrationStep.LAP_POINT:
				left_spec = calibration_ctrl.current_body_frame.to_world_spec(Vector3(-0.10, -0.45, 0.20))
				right_spec = calibration_ctrl.current_body_frame.to_world_spec(Vector3(0.10, -0.45, 0.20))

	var done := calibration_ctrl.confirm_current_step(head_spec, head_fwd_spec, left_spec, right_spec)
	if done:
		GameFlow.on_calibration_finished(
			calibration_ctrl.working_profile,
			calibration_ctrl.current_body_frame,
			calibration_ctrl.seat_anchor_local_spec,
			calibration_ctrl.is_swivel_chair
		)

func _skip_calibration_step() -> void:
	var done := calibration_ctrl.skip_current_step()
	if done:
		GameFlow.on_calibration_finished(
			calibration_ctrl.working_profile,
			calibration_ctrl.current_body_frame,
			calibration_ctrl.seat_anchor_local_spec,
			calibration_ctrl.is_swivel_chair
		)

func _mark_calibration_obstacle() -> void:
	var right_spec := SpecSpace.to_spec(_right_world_pos)
	calibration_ctrl.mark_obstacle_point(right_spec)

func _trigger_auto_action() -> void:
	if active_mechanic != null and GameFlow.current_state == ZenoEnums.AppState.ROUND_PLAY:
		active_mechanic.simulate_auto_action()

func _handle_desktop_simulator_input(dt: float) -> void:
	if Platform.is_xr_active:
		return

	# Smooth head rotation with arrow keys
	if Input.is_key_pressed(KEY_LEFT):
		_sim_cam_yaw_deg = clampf(_sim_cam_yaw_deg + 85.0 * dt, -85.0, 85.0)
	if Input.is_key_pressed(KEY_RIGHT):
		_sim_cam_yaw_deg = clampf(_sim_cam_yaw_deg - 85.0 * dt, -85.0, 85.0)
	if Input.is_key_pressed(KEY_UP):
		_sim_cam_pitch_deg = clampf(_sim_cam_pitch_deg + 70.0 * dt, -50.0, 50.0)
	if Input.is_key_pressed(KEY_DOWN):
		_sim_cam_pitch_deg = clampf(_sim_cam_pitch_deg - 70.0 * dt, -50.0, 50.0)

	# Move head closer / further (-Z forward in Godot) & lateral lean (Z/X)
	if Input.is_key_pressed(KEY_W):
		_sim_cam_offset_local.z = clampf(_sim_cam_offset_local.z - 0.65 * dt, -0.55, 0.45)
	if Input.is_key_pressed(KEY_S):
		_sim_cam_offset_local.z = clampf(_sim_cam_offset_local.z + 0.65 * dt, -0.55, 0.45)
	if Input.is_key_pressed(KEY_Z):
		_sim_cam_offset_local.x = clampf(_sim_cam_offset_local.x - 0.45 * dt, -0.32, 0.32)
	if Input.is_key_pressed(KEY_X):
		_sim_cam_offset_local.x = clampf(_sim_cam_offset_local.x + 0.45 * dt, -0.32, 0.32)

	# Wrist roll simulation ([ / ]) for M09 Tea Ceremony Pour
	if Input.is_key_pressed(KEY_BRACKETLEFT):
		_sim_wrist_roll_deg = clampf(_sim_wrist_roll_deg - 90.0 * dt, 0.0, 95.0)
	if Input.is_key_pressed(KEY_BRACKETRIGHT):
		_sim_wrist_roll_deg = clampf(_sim_wrist_roll_deg + 90.0 * dt, 0.0, 95.0)

	xr_camera.position = Vector3(_sim_cam_offset_local.x, 1.20, _sim_cam_offset_local.z)
	xr_camera.rotation_degrees = Vector3(_sim_cam_pitch_deg, _sim_cam_yaw_deg, 0.0)

	var mouse_pos := get_viewport().get_mouse_position()
	if Input.is_key_pressed(KEY_Q):
		var world_p := xr_camera.project_position(mouse_pos, _sim_left_depth_m)
		left_controller.global_position = world_p
	if Input.is_key_pressed(KEY_E):
		var world_p := xr_camera.project_position(mouse_pos, _sim_right_depth_m)
		right_controller.global_position = world_p

func _unhandled_input(event: InputEvent) -> void:
	if not Platform.is_xr_active and event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		var motion := event as InputEventMouseMotion
		_sim_cam_yaw_deg = clampf(_sim_cam_yaw_deg - motion.relative.x * 0.25, -85.0, 85.0)
		_sim_cam_pitch_deg = clampf(_sim_cam_pitch_deg - motion.relative.y * 0.25, -50.0, 50.0)

	if not Platform.is_xr_active and is_ui_raycast_enabled() and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if not Input.is_key_pressed(KEY_Q) and not Input.is_key_pressed(KEY_E):
			var mb := event as InputEventMouseButton
			var r_orig := xr_camera.project_ray_origin(mb.position)
			var r_dir := xr_camera.project_ray_normal(mb.position)
			world_ui.process_pointer_ray(r_orig, r_dir, mb.pressed, mb.pressed, not mb.pressed)

	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_sim_left_depth_m = clampf(_sim_left_depth_m + 0.04, 0.15, 0.85)
			_sim_right_depth_m = clampf(_sim_right_depth_m + 0.04, 0.15, 0.85)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_sim_left_depth_m = clampf(_sim_left_depth_m - 0.04, 0.15, 0.85)
			_sim_right_depth_m = clampf(_sim_right_depth_m - 0.04, 0.15, 0.85)

	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_MINUS:
				GameFlow.adjust_hud_distance(-0.15)
				world_ui._rebuild_all_panels(calibration_ctrl)
			KEY_EQUAL:
				GameFlow.adjust_hud_distance(0.15)
				world_ui._rebuild_all_panels(calibration_ctrl)
			KEY_H:
				_sim_cam_yaw_deg = 0.0
				_sim_cam_pitch_deg = 0.0
				_sim_cam_offset_local = Vector3.ZERO
				_sim_wrist_roll_deg = 0.0
				xr_camera.position = Vector3(0.0, 1.20, 0.0)
				xr_camera.rotation_degrees = Vector3.ZERO
			KEY_SPACE:
				if GameFlow.current_state == ZenoEnums.AppState.MAIN_MENU:
					GameFlow.open_routine_picker_from_menu()
				elif GameFlow.current_state == ZenoEnums.AppState.ROUTINE_PICKER:
					GameFlow.select_routine_and_start(world_ui._picker_routine, world_ui._picker_duration_min, world_ui._picker_warmup)
				elif GameFlow.current_state == ZenoEnums.AppState.WARM_UP:
					GameFlow.skip_warmup()
				elif GameFlow.current_state == ZenoEnums.AppState.CALIBRATION:
					_confirm_calibration_step()
				elif GameFlow.current_state == ZenoEnums.AppState.PAUSED:
					GameFlow.request_resume_with_countdown()
				elif GameFlow.current_state == ZenoEnums.AppState.RESULTS:
					GameFlow.begin_session()
			KEY_TAB:
				_trigger_auto_action()
			KEY_K:
				if GameFlow.current_state == ZenoEnums.AppState.CALIBRATION:
					_skip_calibration_step()
				elif GameFlow.current_state == ZenoEnums.AppState.PAUSED and GameFlow.current_pause_reason == ZenoEnums.PauseReason.STABLE_CHAIR_CONFIRMATION:
					GameFlow.decline_stable_chair_and_substitute()
			KEY_O:
				if GameFlow.current_state == ZenoEnums.AppState.CALIBRATION:
					_mark_calibration_obstacle()
			KEY_C:
				if GameFlow.current_state == ZenoEnums.AppState.MAIN_MENU:
					GameFlow.request_recalibrate()
			KEY_L:
				var lap_godot := GameFlow.body_frame.to_godot_world(GameFlow.profile.lap_point_from_chest_m)
				left_controller.global_position = lap_godot
				right_controller.global_position = lap_godot
			KEY_R:
				Platform.simulate_recenter()
			KEY_M:
				mascot_coach.trigger_poke_reaction(ZenoEnums.Hand.RIGHT)
			KEY_N:
				if GameFlow.current_state == ZenoEnums.AppState.ROUND_INTRO or GameFlow.current_state == ZenoEnums.AppState.ROUND_PLAY:
					GameFlow.round_timer_s = 0.01
			KEY_ESCAPE:
				if GameFlow.current_state == ZenoEnums.AppState.ROUND_INTRO or GameFlow.current_state == ZenoEnums.AppState.ROUND_PLAY or GameFlow.current_state == ZenoEnums.AppState.ROUND_OUTRO:
					GameFlow.pause_session(ZenoEnums.PauseReason.MANUAL, "Manual Pause (Esc)")
				elif GameFlow.current_state == ZenoEnums.AppState.PAUSED or GameFlow.current_state == ZenoEnums.AppState.RESULTS or GameFlow.current_state == ZenoEnums.AppState.CALIBRATION or GameFlow.current_state == ZenoEnums.AppState.ROUTINE_PICKER or GameFlow.current_state == ZenoEnums.AppState.CREDITS or GameFlow.current_state == ZenoEnums.AppState.WARM_UP:
					GameFlow.return_to_main_menu()
