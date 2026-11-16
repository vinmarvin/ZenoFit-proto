extends XROrigin3D

## Main XR & Desktop Simulator Coordinator for ZenoFit (Godot 4.7).
## Owns:
## - OpenXR initialization (Seated / Local reference space, zero unintended locomotion)
## - Left & Right HandTip tracking (velocity smoothed over 3 frames + segment hit detection)
## - CalibrationController, SafetyMonitors (Auto-Pause Lap, Lean Warning, Rest Reminder)
## - Active Mechanic (M01..M10), FloatingMascotCoach, and ZenoWorldUI
## - Desktop Mouse + Keyboard Simulator when running without a VR headset

@onready var xr_camera: XRCamera3D = $XRCamera3D
@onready var left_controller: XRController3D = $LeftController
@onready var right_controller: XRController3D = $RightController

var arena_root: Node3D
var floor_platform: MeshInstance3D
var left_tip_visual: MeshInstance3D
var right_tip_visual: MeshInstance3D
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
var _left_speeds: Array[float] = [0.0, 0.0, 0.0]
var _right_speeds: Array[float] = [0.0, 0.0, 0.0]
var _prev_head_yaw_deg: float = 0.0
var _sim_left_depth_m: float = 0.45
var _sim_right_depth_m: float = 0.45
var _sim_wrist_roll_deg: float = 0.0
var _has_initial_xr_pose: bool = false

func _ready() -> void:
	Platform.initialize_platform()
	Platform.tracking_origin_recentered.connect(_on_tracking_origin_recentered)

	_setup_environment_and_nodes()
	_setup_controllers_and_tips()

	calibration_ctrl = CalibrationController.new(GameFlow.profile)
	auto_pause_monitor = SafetyMonitors.AutoPauseMonitor.new(0.15, 2.0)
	lean_monitor = SafetyMonitors.LeanMonitor.new(0.20, 0.50)
	rest_monitor = SafetyMonitors.RestReminderMonitor.new(float(GameFlow.settings.get("rest_reminder_minutes", 8.0)))

	EventBus.state_changed.connect(_on_flow_state_changed)
	EventBus.round_started.connect(_on_round_started)

	_rebuild_body_frame_from_camera()
	GameFlow.complete_boot()

func _setup_environment_and_nodes() -> void:
	# Calm directional light & environment (14-safety.md §8.6 GP-COMFORT-01)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.09, 0.13, 0.19)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.75, 0.82, 0.90)
	env.ambient_light_energy = 0.7
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	add_child(world_env)

	var dir_light := DirectionalLight3D.new()
	dir_light.rotation_degrees = Vector3(-45.0, -30.0, 0.0)
	dir_light.light_energy = 0.9
	add_child(dir_light)

	# Static seated reference floor platform (prevents cybersickness, GP-COMFORT-01)
	floor_platform = MeshInstance3D.new()
	floor_platform.name = "StaticSeatedReferencePlatform"
	var cyl := CylinderMesh.new()
	cyl.top_radius = 1.5
	cyl.bottom_radius = 1.5
	cyl.height = 0.03
	floor_platform.mesh = cyl
	floor_platform.position = Vector3(0.0, -0.95, 0.0)
	var floor_mat := StandardMaterial3D.new()
	floor_mat.albedo_color = Color(0.14, 0.19, 0.26)
	floor_mat.roughness = 0.9
	floor_platform.material_override = floor_mat
	add_child(floor_platform)

	# Default seated camera height in Desktop Simulator
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
	add_child(world_ui)

func _setup_controllers_and_tips() -> void:
	left_tip_visual = _create_hand_tip(left_controller, Color(0.20, 0.65, 1.0), "LeftHandTip")
	right_tip_visual = _create_hand_tip(right_controller, Color(1.0, 0.58, 0.20), "RightHandTip")
	left_controller.button_pressed.connect(_on_xr_button_pressed.bind(ZenoEnums.Hand.LEFT))
	right_controller.button_pressed.connect(_on_xr_button_pressed.bind(ZenoEnums.Hand.RIGHT))

func _create_hand_tip(ctrl: XRController3D, col: Color, tip_name: String) -> MeshInstance3D:
	var area := Area3D.new()
	area.name = tip_name
	var shape := CollisionShape3D.new()
	var sphere_shape := SphereShape3D.new()
	sphere_shape.radius = ZenoGeometry.DEFAULT_HAND_TIP_RADIUS_M
	shape.shape = sphere_shape
	area.add_child(shape)

	var mesh_inst := MeshInstance3D.new()
	var sphere_mesh := SphereMesh.new()
	sphere_mesh.radius = ZenoGeometry.DEFAULT_HAND_TIP_RADIUS_M
	sphere_mesh.height = ZenoGeometry.DEFAULT_HAND_TIP_RADIUS_M * 2.0
	mesh_inst.mesh = sphere_mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = col
	mat.emission_enabled = true
	mat.emission = col * 0.35
	mesh_inst.material_override = mat
	area.add_child(mesh_inst)
	ctrl.add_child(area)
	return mesh_inst

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

func _process(delta: float) -> void:
	_handle_desktop_simulator_input(delta)
	_sync_xr_camera_body_frame()
	_update_tracked_poses(delta)

	if Platform.is_xr_active:
		if left_tip_visual != null:
			left_tip_visual.visible = left_controller.get_has_tracking_data()
		if right_tip_visual != null:
			right_tip_visual.visible = right_controller.get_has_tracking_data()

	if floor_platform != null:
		floor_platform.global_position = GameFlow.body_frame.to_godot_world(Vector3(0.0, -0.68, 0.0))

	GameFlow.advance_round_timer(delta)

	if GameFlow.current_state == ZenoEnums.AppState.ROUND_PLAY:
		_evaluate_safety_monitors(delta)
		if active_mechanic != null and GameFlow.current_state == ZenoEnums.AppState.ROUND_PLAY:
			var head_local := GameFlow.body_frame.from_godot_world(xr_camera.global_position)
			var head_fwd_spec := GameFlow.body_frame.rotate_world_to_local_spec(
				SpecSpace.to_spec(-xr_camera.global_transform.basis.z)
			)
			var head_yaw_deg := rad_to_deg(atan2(head_fwd_spec.x, maxf(0.01, head_fwd_spec.z)))
			var head_speed_deg_s := absf(head_yaw_deg - _prev_head_yaw_deg) / maxf(0.001, delta)
			_prev_head_yaw_deg = head_yaw_deg

			var left_roll := rad_to_deg(left_controller.rotation.z) if Platform.is_xr_active else _sim_wrist_roll_deg
			var right_roll := rad_to_deg(right_controller.rotation.z) if Platform.is_xr_active else _sim_wrist_roll_deg

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
				left_roll,
				right_roll
			)

	mascot_coach.update_coach(
		delta,
		GameFlow.body_frame,
		left_controller.global_position,
		right_controller.global_position
	)
	world_ui.update_ui_display(
		GameFlow.body_frame,
		calibration_ctrl,
		active_mechanic,
		xr_camera.global_position,
		-xr_camera.global_transform.basis.z,
		delta
	)

func _sync_xr_camera_body_frame() -> void:
	if not Platform.is_xr_active:
		return
	if not _has_initial_xr_pose and xr_camera.global_position.length_squared() > 0.0001:
		_has_initial_xr_pose = true
		_rebuild_body_frame_from_camera()
		return
	# In Main Menu or Calibration Step 1 (Seat Anchor), keep BodyFrame aligned with player eye height & gaze
	if GameFlow.current_state == ZenoEnums.AppState.MAIN_MENU \
		or (GameFlow.current_state == ZenoEnums.AppState.CALIBRATION and calibration_ctrl.current_step == ZenoEnums.CalibrationStep.SEAT_ANCHOR):
		_rebuild_body_frame_from_camera()
	else:
		# Keep vertical chest height aligned with player eye-line
		var fwd_y := (-xr_camera.global_transform.basis.z).y
		var expected_chest_y := xr_camera.global_position.y + fwd_y * 0.55 - 0.10
		if absf(expected_chest_y - GameFlow.body_frame.origin_spec.y) > 0.04:
			GameFlow.body_frame.origin_spec.y = lerpf(GameFlow.body_frame.origin_spec.y, expected_chest_y, 0.18)

func _update_tracked_poses(dt: float) -> void:
	_prev_left_local_spec = _curr_left_local_spec
	_prev_right_local_spec = _curr_right_local_spec
	_curr_left_local_spec = GameFlow.body_frame.from_godot_world(left_controller.global_position)
	_curr_right_local_spec = GameFlow.body_frame.from_godot_world(right_controller.global_position)

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
	# 1. Auto-pause when both hands rest in lap for >= 2.0 s (§8.1, AT-09)
	if auto_pause_monitor.evaluate(_curr_left_local_spec, _curr_right_local_spec, GameFlow.profile.lap_point_from_chest_m, dt):
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
	elif mech == ZenoEnums.MechanicId.M10_LASER_EVADER:
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

func _on_flow_state_changed(_prev: int, next_state: int) -> void:
	if next_state == ZenoEnums.AppState.CALIBRATION:
		calibration_ctrl.working_profile = GameFlow.profile
		if GameFlow.has_valid_calibration:
			calibration_ctrl.start_returning_user_quick_check()
		else:
			calibration_ctrl.start_full_calibration()
	elif next_state == ZenoEnums.AppState.MAIN_MENU or next_state == ZenoEnums.AppState.RESULTS:
		if active_mechanic != null:
			active_mechanic.clear_arena()
			active_mechanic = null

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

func _instantiate_mechanic(mechanic_id: int) -> MechanicBase:
	match mechanic_id:
		ZenoEnums.MechanicId.M01_ASTEROID_BRAWLER: return M01AsteroidBrawler.new()
		ZenoEnums.MechanicId.M02_FRUIT_HARVESTER: return M02FruitHarvester.new()
		ZenoEnums.MechanicId.M03_GLIDER_PILOT: return M03GliderPilot.new()
		ZenoEnums.MechanicId.M04_TURRET_GUNNER: return M04TurretGunner.new()
		ZenoEnums.MechanicId.M05_COSMIC_TUG_OF_WAR: return M05CosmicTugOfWar.new()
		ZenoEnums.MechanicId.M06_FORCE_BLAST: return M06ForceBlast.new()
		ZenoEnums.MechanicId.M07_SHIELD_CRANK: return M07ShieldCrank.new()
		ZenoEnums.MechanicId.M08_RECON_SCANNER: return M08ReconScanner.new()
		ZenoEnums.MechanicId.M09_POTION_BREWER: return M09PotionBrewer.new()
		ZenoEnums.MechanicId.M10_LASER_EVADER: return M10LaserEvader.new()
		_: return M01AsteroidBrawler.new()

func _on_xr_button_pressed(action_name: String, _hand: int) -> void:
	if action_name == "menu_button":
		if GameFlow.current_state == ZenoEnums.AppState.PAUSED:
			GameFlow.request_resume_with_countdown()
		else:
			GameFlow.pause_session(ZenoEnums.PauseReason.MANUAL, "Menu button pressed.")
	elif action_name == "trigger_click" or action_name == "ax_button":
		if GameFlow.current_state == ZenoEnums.AppState.CALIBRATION:
			_confirm_calibration_step()
		elif GameFlow.current_state == ZenoEnums.AppState.MAIN_MENU:
			GameFlow.start_score_attack_from_menu()
		elif GameFlow.current_state == ZenoEnums.AppState.PAUSED:
			GameFlow.request_resume_with_countdown()
		elif GameFlow.current_state == ZenoEnums.AppState.RESULTS:
			GameFlow.begin_session()
	elif action_name == "by_button":
		if GameFlow.current_state == ZenoEnums.AppState.CALIBRATION:
			_skip_calibration_step()
		elif GameFlow.current_state == ZenoEnums.AppState.PAUSED and GameFlow.current_pause_reason == ZenoEnums.PauseReason.STABLE_CHAIR_CONFIRMATION:
			GameFlow.decline_stable_chair_and_substitute()
		elif GameFlow.current_state == ZenoEnums.AppState.MAIN_MENU or GameFlow.current_state == ZenoEnums.AppState.PAUSED or GameFlow.current_state == ZenoEnums.AppState.RESULTS:
			_rebuild_body_frame_from_camera()
			GameFlow.request_recalibrate()

func _on_tracking_origin_recentered() -> void:
	# GP-CAL-06 & AT-16: Pause game and ask for seat re-confirmation
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
	var left_spec := SpecSpace.to_spec(left_controller.global_position)
	var right_spec := SpecSpace.to_spec(right_controller.global_position)

	# In Desktop Simulator, supply realistic seated positions when confirming steps
	if not Platform.is_xr_active:
		match calibration_ctrl.current_step:
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
			calibration_ctrl.seat_anchor_local_spec
		)

func _skip_calibration_step() -> void:
	var done := calibration_ctrl.skip_current_step()
	if done:
		GameFlow.on_calibration_finished(
			calibration_ctrl.working_profile,
			calibration_ctrl.current_body_frame,
			calibration_ctrl.seat_anchor_local_spec
		)

func _mark_calibration_obstacle() -> void:
	var right_spec := SpecSpace.to_spec(right_controller.global_position)
	calibration_ctrl.mark_obstacle_point(right_spec)

func _trigger_auto_action() -> void:
	if active_mechanic != null and GameFlow.current_state == ZenoEnums.AppState.ROUND_PLAY:
		active_mechanic.simulate_auto_action()

func _handle_desktop_simulator_input(_dt: float) -> void:
	if Platform.is_xr_active:
		return
	var mouse_pos := get_viewport().get_mouse_position()
	if Input.is_key_pressed(KEY_Q):
		var world_p := xr_camera.project_position(mouse_pos, _sim_left_depth_m)
		left_controller.global_position = world_p
	if Input.is_key_pressed(KEY_E):
		var world_p := xr_camera.project_position(mouse_pos, _sim_right_depth_m)
		right_controller.global_position = world_p

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_sim_left_depth_m = clampf(_sim_left_depth_m + 0.04, 0.15, 0.85)
			_sim_right_depth_m = clampf(_sim_right_depth_m + 0.04, 0.15, 0.85)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_sim_left_depth_m = clampf(_sim_left_depth_m - 0.04, 0.15, 0.85)
			_sim_right_depth_m = clampf(_sim_right_depth_m - 0.04, 0.15, 0.85)

	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_SPACE:
				if GameFlow.current_state == ZenoEnums.AppState.MAIN_MENU:
					GameFlow.start_score_attack_from_menu()
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
				# Move both hands to LapPoint to test 2.0 s Auto-Pause (AT-09)
				var lap_godot := GameFlow.body_frame.to_godot_world(GameFlow.profile.lap_point_from_chest_m)
				left_controller.global_position = lap_godot
				right_controller.global_position = lap_godot
			KEY_R:
				# Simulate headset recenter event (AT-16)
				Platform.simulate_recenter()
			KEY_M:
				mascot_coach.trigger_poke_reaction(ZenoEnums.Hand.RIGHT)
			KEY_N:
				if GameFlow.current_state == ZenoEnums.AppState.ROUND_INTRO or GameFlow.current_state == ZenoEnums.AppState.ROUND_PLAY:
					GameFlow.round_timer_s = 0.01
			KEY_ESCAPE:
				if GameFlow.current_state == ZenoEnums.AppState.ROUND_INTRO or GameFlow.current_state == ZenoEnums.AppState.ROUND_PLAY or GameFlow.current_state == ZenoEnums.AppState.ROUND_OUTRO:
					GameFlow.pause_session(ZenoEnums.PauseReason.MANUAL, "Manual Pause (Esc)")
				elif GameFlow.current_state == ZenoEnums.AppState.PAUSED or GameFlow.current_state == ZenoEnums.AppState.RESULTS or GameFlow.current_state == ZenoEnums.AppState.CALIBRATION:
					GameFlow.return_to_main_menu()
