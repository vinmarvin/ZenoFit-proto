extends XROrigin3D

## Main XR & Desktop Simulator Coordinator for ZenoFit v1.0.
## Guarantees:
## - Rock-solid stationary BodyFrame (never shifts vertically/laterally on head pitch or yaw)
## - Strict Session Input Lock (Controller vs Hand Tracking never mid-switches)
## - Zero UI raycast during ROUND_PLAY
## - Integrated Japanese Minimalist Room + KarateBoard.glb + Zeno_WithTexture.glb

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
var _input_lost_timer_s: float = 0.0
var _hand_trail_timer_s: float = 0.0

# Desktop simulator state
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
	Platform.haptics_enabled = bool(GameFlow.settings.get("haptics_enabled", true))

	_setup_environment_and_nodes()
	_setup_controllers_and_tips()

	calibration_ctrl = CalibrationController.new(GameFlow.profile)
	auto_pause_monitor = SafetyMonitors.AutoPauseMonitor.new(0.15, 2.0)
	lean_monitor = SafetyMonitors.LeanMonitor.new(0.22, 0.50)
	rest_monitor = SafetyMonitors.RestReminderMonitor.new(float(GameFlow.settings.get("rest_reminder_minutes", 8.0)))

	EventBus.state_changed.connect(_on_flow_state_changed)
	EventBus.round_started.connect(_on_round_started)
	EventBus.mascot_poked.connect(_on_mascot_poked)
	EventBus.target_hit.connect(_on_target_hit_feedback)
	EventBus.target_missed.connect(_on_target_missed_feedback)

	_rebuild_body_frame_from_camera()
	GameFlow.complete_boot()

func _setup_environment_and_nodes() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.14, 0.16, 0.14)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.88, 0.86, 0.80)
	env.ambient_light_energy = 0.82
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	add_child(world_env)

	var dir_light := DirectionalLight3D.new()
	dir_light.rotation_degrees = Vector3(-48.0, -32.0, 0.0)
	dir_light.light_color = Color(1.0, 0.96, 0.88)
	dir_light.light_energy = 0.82
	dir_light.shadow_enabled = false
	add_child(dir_light)

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
	floor_mat.albedo_color = Color(0.16, 0.20, 0.16)
	floor_mat.roughness = 0.9
	floor_platform.material_override = floor_mat
	add_child(floor_platform)

	dojo_env_root = DojoEnvironmentLoader.load_and_clean_dojo_environment()
	if dojo_env_root != null:
		add_child(dojo_env_root)
		floor_platform.visible = false

	if not Platform.is_xr_active:
		xr_camera.fov = 50.0
		xr_camera.position = Vector3(0.0, 1.18, 0.0)
		left_controller.position = Vector3(-0.25, 0.88, -0.48)
		right_controller.position = Vector3(0.25, 0.88, -0.48)

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
	world_ui.request_recenter_view.connect(_recenter_seated_view)
	world_ui.request_auto_action.connect(_trigger_auto_action)
	add_child(world_ui)

func _setup_controllers_and_tips() -> void:
	left_tip_visual = _create_hand_tip(Color(0.32, 0.85, 0.72), "LeftHandTip")
	right_tip_visual = _create_hand_tip(Color(0.95, 0.68, 0.28), "RightHandTip")
	add_child(left_tip_visual)
	add_child(right_tip_visual)

	left_menu_ray = _create_menu_ray(left_controller, Color(0.45, 0.88, 0.78, 0.35))
	right_menu_ray = _create_menu_ray(right_controller, Color(0.95, 0.78, 0.42, 0.35))

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
	cyl.top_radius = 0.003
	cyl.bottom_radius = 0.003
	cyl.height = 1.4
	ray.mesh = cyl
	ray.rotation_degrees = Vector3(90.0, 0.0, 0.0)
	ray.position = Vector3(0.0, 0.0, -0.7)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = col
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ray.material_override = mat
	ctrl.add_child(ray)
	return ray

## Raycast pointers are strictly OFF during ROUND_PLAY.
func is_ui_raycast_enabled() -> bool:
	return GameFlow.current_state != ZenoEnums.AppState.ROUND_PLAY

func _rebuild_body_frame_from_camera() -> void:
	var head_spec := SpecSpace.to_spec(xr_camera.global_position)
	GameFlow.seated_height_m = clampf(head_spec.y, 0.70, 1.80) if head_spec.y > 0.2 else 1.18
	GameFlow.body_frame = BodyFrame.rebuild_from_godot_head(
		xr_camera.global_position,
		xr_camera.global_transform.basis,
		GameFlow.profile.chest_offset_from_head_m
	)
	GameFlow.seat_anchor_local_spec = GameFlow.body_frame.from_godot_world(xr_camera.global_position)
	calibration_ctrl.current_body_frame = GameFlow.body_frame
	calibration_ctrl.seat_anchor_local_spec = GameFlow.seat_anchor_local_spec
	calibration_ctrl.seated_height_m = GameFlow.seated_height_m
	_sync_dojo_floor_transform()

func _recenter_seated_view() -> void:
	_rebuild_body_frame_from_camera()
	Platform.play_sfx("menu_click", 0)

func _sync_dojo_floor_transform() -> void:
	var floor_world := GameFlow.body_frame.to_godot_world(Vector3(0.0, -0.68, 0.0))
	if dojo_env_root != null:
		dojo_env_root.global_position = floor_world
	if floor_platform != null:
		floor_platform.global_position = floor_world

func _get_effective_input_mode() -> int:
	var in_round := (
		GameFlow.current_state == ZenoEnums.AppState.ROUND_INTRO
		or GameFlow.current_state == ZenoEnums.AppState.ROUND_PLAY
		or GameFlow.current_state == ZenoEnums.AppState.ROUND_OUTRO
	)
	return GameFlow.active_input_mode if in_round else int(GameFlow.settings.get("input_mode", ZenoEnums.InputMode.CONTROLLER))

func _process(delta: float) -> void:
	_handle_desktop_simulator_input(delta)
	_sync_xr_camera_body_frame()
	var mode := _get_effective_input_mode()
	_update_tracked_poses(delta, mode)

	var allow_ray := is_ui_raycast_enabled()
	var show_ctrl_ray := allow_ray and Platform.is_xr_active and mode == ZenoEnums.InputMode.CONTROLLER
	if left_menu_ray != null:
		left_menu_ray.visible = show_ctrl_ray and _left_tracked
	if right_menu_ray != null:
		right_menu_ray.visible = show_ctrl_ray and _right_tracked

	var active_hand_view := (
		GameFlow.current_state == ZenoEnums.AppState.CALIBRATION
		or GameFlow.current_state == ZenoEnums.AppState.ROUND_INTRO
		or GameFlow.current_state == ZenoEnums.AppState.ROUND_PLAY
		or GameFlow.current_state == ZenoEnums.AppState.ROUND_OUTRO
	)
	if left_tip_visual != null:
		left_tip_visual.visible = (_left_tracked and Platform.is_xr_active) or (not Platform.is_xr_active and (active_hand_view or Input.is_key_pressed(KEY_Q)))
		left_tip_visual.global_position = _left_world_pos
	if right_tip_visual != null:
		right_tip_visual.visible = (_right_tracked and Platform.is_xr_active) or (not Platform.is_xr_active and (active_hand_view or Input.is_key_pressed(KEY_E)))
		right_tip_visual.global_position = _right_world_pos

	_sync_dojo_floor_transform()
	GameFlow.advance_round_timer(delta)

	var in_round_state := (
		GameFlow.current_state == ZenoEnums.AppState.ROUND_INTRO
		or GameFlow.current_state == ZenoEnums.AppState.ROUND_PLAY
		or GameFlow.current_state == ZenoEnums.AppState.ROUND_OUTRO
	)
	if arena_root != null:
		arena_root.visible = in_round_state

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
			if active_mechanic.has_two_set_completion() and active_mechanic.is_exercise_completed():
				GameFlow.complete_active_round()
			_update_hand_motion_trails(delta)

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

	if is_ui_raycast_enabled():
		if Platform.is_xr_active:
			var ui_ray := Platform.get_ui_pointer_ray(
				ZenoEnums.Hand.RIGHT if _right_tracked else ZenoEnums.Hand.LEFT,
				right_controller if _right_tracked else left_controller,
				mode
			)
			if bool(ui_ray["valid"]):
				world_ui.process_pointer_ray(ui_ray["origin"], ui_ray["dir"], false, false, false)
			else:
				world_ui.hide_pointer_dot()
		elif not Input.is_key_pressed(KEY_Q) and not Input.is_key_pressed(KEY_E):
			var mp := get_viewport().get_mouse_position()
			var r_orig := xr_camera.project_ray_origin(mp)
			var r_dir := xr_camera.project_ray_normal(mp)
			world_ui.process_pointer_ray(r_orig, r_dir, Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT), false, false)
	else:
		world_ui.hide_pointer_dot()

## Anchors BodyFrame ONLY once on initial valid XR pose or during Calibration Step 1 (SEAT_ANCHOR).
## Zero per-frame chest/floor shifting when head pitches or turns!
func _sync_xr_camera_body_frame() -> void:
	if not Platform.is_xr_active:
		return
	if not _has_initial_xr_pose and xr_camera.global_position.length_squared() > 0.0001:
		_has_initial_xr_pose = true
		_rebuild_body_frame_from_camera()
		return
	if GameFlow.current_state == ZenoEnums.AppState.CALIBRATION and calibration_ctrl.current_step == ZenoEnums.CalibrationStep.SEAT_ANCHOR:
		_rebuild_body_frame_from_camera()

func _update_tracked_poses(dt: float, input_mode: int) -> void:
	var pose_l := Platform.sample_input_pose(ZenoEnums.Hand.LEFT, left_controller, input_mode)
	var pose_r := Platform.sample_input_pose(ZenoEnums.Hand.RIGHT, right_controller, input_mode)

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
	if input_mode == ZenoEnums.InputMode.HAND_TRACKING and Platform.is_xr_active:
		if pinch_l and not _prev_left_pinch:
			_on_xr_button_pressed("trigger_click", ZenoEnums.Hand.LEFT)
		if pinch_r and not _prev_right_pinch:
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
	if auto_pause_monitor.evaluate(
		_curr_left_local_spec, _curr_right_local_spec,
		GameFlow.profile.lap_point_from_chest_m, dt,
		_left_tracked, _right_tracked, -0.15
	):
		auto_pause_monitor.reset()
		GameFlow.pause_session(
			ZenoEnums.PauseReason.AUTO_PAUSE_LAP,
			"Hands rested in lap for 2 seconds. Take a breather!"
		)
		return

	if Platform.is_xr_active:
		var h_mode := int(GameFlow.settings.get("hand_mode", ZenoEnums.HandMode.BOTH_HANDS))
		var need_l := (h_mode != ZenoEnums.HandMode.RIGHT_ONLY) and GameFlow.profile.left_enabled
		var need_r := (h_mode != ZenoEnums.HandMode.LEFT_ONLY) and GameFlow.profile.right_enabled
		var input_lost := (need_l and not _left_tracked) or (need_r and not _right_tracked)
		if input_lost:
			_input_lost_timer_s += dt
			if _input_lost_timer_s >= 2.5:
				_input_lost_timer_s = 0.0
				GameFlow.pause_session(
					ZenoEnums.PauseReason.INPUT_LOST,
					"%s tracking was lost. Reconnect or switch input mode." % ZenoEnums.get_input_mode_name(GameFlow.active_input_mode)
				)
				return
		else:
			_input_lost_timer_s = 0.0

	var head_local := GameFlow.body_frame.from_godot_world(xr_camera.global_position)
	if lean_monitor.evaluate(head_local.x, GameFlow.seat_anchor_local_spec.x, dt):
		lean_monitor.reset()
		GameFlow.pause_session(
			ZenoEnums.PauseReason.LEAN_WARNING,
			"Please return to a centered, upright seated posture."
		)
		return

	if rest_monitor.evaluate(dt):
		GameFlow.pause_session(
			ZenoEnums.PauseReason.REST_REMINDER,
			"Time for a quick breather — relax your shoulders and neck."
		)

func _on_mascot_poked(_hand: int) -> void:
	if GameFlow.current_state == ZenoEnums.AppState.WELCOME:
		Platform.play_sfx("gong", 0)
		GameFlow.continue_to_main_menu()

func _on_target_hit_feedback(_hand: int, _points: int, streak: int, _is_solid: bool) -> void:
	var ex := GameFlow.get_current_exercise_id()
	var sfx := "wood_crack" if (
		ex == ZenoEnums.ExerciseId.BOARD_SMASH
		or ex == ZenoEnums.ExerciseId.WIDE_SPLIT
		or ex == ZenoEnums.ExerciseId.TORSO_TWIST
	) else "chime"
	Platform.play_sfx(sfx, streak)
	_spawn_hit_burst_vfx(_left_world_pos if _hand == ZenoEnums.Hand.LEFT else _right_world_pos, _points, streak, _is_solid)

func _on_target_missed_feedback() -> void:
	Platform.play_sfx("miss", 0)

func _update_hand_motion_trails(dt: float) -> void:
	if arena_root == null or not is_inside_tree():
		return
	_hand_trail_timer_s += dt
	if _hand_trail_timer_s < 0.045:
		return
	_hand_trail_timer_s = 0.0
	if _left_tracked and _get_smoothed_speed(_left_speeds) >= 0.35:
		_spawn_hand_trail_dot(_left_world_pos, Color(0.32, 0.88, 0.78))
	if _right_tracked and _get_smoothed_speed(_right_speeds) >= 0.35:
		_spawn_hand_trail_dot(_right_world_pos, Color(0.96, 0.72, 0.32))

func _spawn_hand_trail_dot(world_pos: Vector3, col: Color) -> void:
	var mi := MeshInstance3D.new()
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var sphere := SphereMesh.new()
	sphere.radius = 0.012
	sphere.height = 0.024
	sphere.radial_segments = 8
	sphere.rings = 6
	mi.mesh = sphere
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(col.r, col.g, col.b, 0.48)
	mat.emission_enabled = true
	mat.emission = col
	mat.emission_energy_multiplier = 0.45
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mi.material_override = mat
	arena_root.add_child(mi)
	mi.global_position = world_pos

	var tw := mi.create_tween()
	tw.set_parallel(true)
	tw.tween_property(mi, "scale", Vector3.ONE * 0.12, 0.24).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(mat, "albedo_color:a", 0.0, 0.24)
	tw.chain().tween_callback(mi.queue_free)

func _spawn_hit_burst_vfx(world_pos: Vector3, points: int, streak: int, is_solid: bool) -> void:
	if arena_root == null or not is_inside_tree():
		return
	var local_spec := GameFlow.body_frame.from_godot_world(world_pos)
	var safe_spec := Vector3(
		clampf(local_spec.x, -0.38, 0.38),
		clampf(local_spec.y + 0.08, -0.02, 0.24),
		clampf(local_spec.z, 1.05, 1.45)
	)
	var spawn_world := GameFlow.body_frame.to_godot_world(safe_spec)

	var popup := Label3D.new()
	popup.text = "+%d%s" % [points, " x%d" % streak if streak >= 2 else ""]
	popup.font_size = 24 if is_solid else 20
	popup.outline_size = 5
	popup.pixel_size = 0.0010
	popup.modulate = Color(0.95, 0.86, 0.42) if is_solid else Color(0.76, 0.94, 0.80)
	popup.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	arena_root.add_child(popup)
	popup.global_position = spawn_world

	var tw := popup.create_tween()
	tw.set_parallel(true)
	tw.tween_property(popup, "global_position:y", spawn_world.y + 0.16, 0.42)
	tw.tween_property(popup, "modulate:a", 0.0, 0.42)
	tw.chain().tween_callback(popup.queue_free)

func _on_flow_state_changed(_prev: int, next_state: int) -> void:
	if arena_root != null:
		arena_root.visible = (
			next_state == ZenoEnums.AppState.ROUND_INTRO
			or next_state == ZenoEnums.AppState.ROUND_PLAY
			or next_state == ZenoEnums.AppState.ROUND_OUTRO
		)
	if next_state == ZenoEnums.AppState.CALIBRATION:
		calibration_ctrl.working_profile = GameFlow.profile
		calibration_ctrl.start_calibration()
	elif next_state == ZenoEnums.AppState.MAIN_MENU \
		or next_state == ZenoEnums.AppState.RESULTS \
		or next_state == ZenoEnums.AppState.EXERCISE_SELECT \
		or next_state == ZenoEnums.AppState.EXERCISE_PREVIEW:
		if active_mechanic != null:
			active_mechanic.clear_arena()
			active_mechanic = null
	if next_state == ZenoEnums.AppState.RESULTS or next_state == ZenoEnums.AppState.SESSION_START:
		Platform.play_sfx("gong", 0)

func _on_round_started(_round_idx: int, exercise_id: int) -> void:
	auto_pause_monitor.reset()
	lean_monitor.reset()
	_input_lost_timer_s = 0.0
	active_mechanic = _instantiate_exercise(exercise_id)
	active_mechanic.setup(
		exercise_id,
		GameFlow.profile,
		GameFlow.body_frame,
		GameFlow.get_current_preset(),
		int(GameFlow.settings.get("hand_mode", ZenoEnums.HandMode.BOTH_HANDS)),
		arena_root
	)
	GameFlow.require_explicit_round_completion = active_mechanic.has_two_set_completion()
	Platform.play_sfx("chime", 0)

func _instantiate_exercise(exercise_id: int) -> MechanicBase:
	match exercise_id:
		ZenoEnums.ExerciseId.BOARD_SMASH: return BoardSmashMechanic.new()
		ZenoEnums.ExerciseId.WIDE_SPLIT: return WideSplitMechanic.new()
		ZenoEnums.ExerciseId.SKY_REACH: return SkyReachMechanic.new()
		ZenoEnums.ExerciseId.ORBIT_FLOW: return OrbitFlowMechanic.new()
		ZenoEnums.ExerciseId.WRIST_TWIST: return WristTwistMechanic.new()
		ZenoEnums.ExerciseId.TORSO_TWIST: return TorsoTwistMechanic.new()
		ZenoEnums.ExerciseId.HORIZON_GAZE: return HorizonGazeMechanic.new()
		ZenoEnums.ExerciseId.SHOULDER_PRESS: return ShoulderPressMechanic.new()
		ZenoEnums.ExerciseId.BICEP_CURL: return BicepCurlMechanic.new()
		ZenoEnums.ExerciseId.ARM_CIRCLES: return ArmCirclesMechanic.new()
		ZenoEnums.ExerciseId.LATERAL_RAISE: return LateralRaiseMechanic.new()
		_: return BoardSmashMechanic.new()

func _on_xr_button_pressed(action_name: String, hand: int) -> void:
	var mode := _get_effective_input_mode()
	if action_name == "menu_button":
		if GameFlow.current_state == ZenoEnums.AppState.PAUSED:
			GameFlow.request_resume_with_countdown()
		elif GameFlow.current_state == ZenoEnums.AppState.ROUND_INTRO or GameFlow.current_state == ZenoEnums.AppState.ROUND_PLAY or GameFlow.current_state == ZenoEnums.AppState.ROUND_OUTRO:
			GameFlow.pause_session(ZenoEnums.PauseReason.MANUAL, "Session paused")
		elif GameFlow.current_state != ZenoEnums.AppState.WELCOME and GameFlow.current_state != ZenoEnums.AppState.MAIN_MENU:
			GameFlow.return_to_main_menu()
	elif action_name == "trigger_click" or action_name == "ax_button":
		if is_ui_raycast_enabled() and Platform.is_xr_active:
			var ray := Platform.get_ui_pointer_ray(hand, left_controller if hand == ZenoEnums.Hand.LEFT else right_controller, mode)
			if bool(ray["valid"]) and world_ui.process_pointer_ray(ray["origin"], ray["dir"], true, true, false):
				world_ui.process_pointer_ray(ray["origin"], ray["dir"], false, false, true)
				return
		if GameFlow.current_state == ZenoEnums.AppState.CALIBRATION:
			_confirm_calibration_step()
		elif GameFlow.current_state == ZenoEnums.AppState.PAUSED:
			GameFlow.request_resume_with_countdown()
	elif action_name == "by_button":
		if GameFlow.current_state == ZenoEnums.AppState.CALIBRATION:
			_skip_calibration_step()
		elif GameFlow.current_state != ZenoEnums.AppState.ROUND_PLAY and GameFlow.current_state != ZenoEnums.AppState.WELCOME:
			GameFlow.return_to_main_menu()

func _on_tracking_origin_recentered() -> void:
	_rebuild_body_frame_from_camera()
	if GameFlow.current_state == ZenoEnums.AppState.ROUND_INTRO \
		or GameFlow.current_state == ZenoEnums.AppState.ROUND_PLAY \
		or GameFlow.current_state == ZenoEnums.AppState.ROUND_OUTRO:
		GameFlow.pause_session(
			ZenoEnums.PauseReason.RECENTER_REQUIRED,
			"View recentered. Confirm your seated posture to continue."
		)

func _confirm_calibration_step() -> void:
	var head_spec := SpecSpace.to_spec(xr_camera.global_position)
	var head_fwd_spec := SpecSpace.to_spec(-xr_camera.global_transform.basis.z)
	var left_spec := SpecSpace.to_spec(_left_world_pos)
	var right_spec := SpecSpace.to_spec(_right_world_pos)

	if not Platform.is_xr_active and calibration_ctrl.current_step == ZenoEnums.CalibrationStep.COMFORT_REACH:
		left_spec = calibration_ctrl.current_body_frame.to_world_spec(Vector3(-0.20, 0.0, 0.60))
		right_spec = calibration_ctrl.current_body_frame.to_world_spec(Vector3(0.20, 0.0, 0.60))
	elif not Platform.is_xr_active and calibration_ctrl.current_step == ZenoEnums.CalibrationStep.LAP_ZONE:
		left_spec = calibration_ctrl.current_body_frame.to_world_spec(Vector3(-0.10, -0.45, 0.20))
		right_spec = calibration_ctrl.current_body_frame.to_world_spec(Vector3(0.10, -0.45, 0.20))

	var done := calibration_ctrl.confirm_current_step(head_spec, head_fwd_spec, left_spec, right_spec)
	if done:
		GameFlow.on_calibration_finished(
			calibration_ctrl.working_profile,
			calibration_ctrl.current_body_frame,
			calibration_ctrl.seat_anchor_local_spec,
			calibration_ctrl.seated_height_m
		)

func _skip_calibration_step() -> void:
	var done := calibration_ctrl.skip_current_step()
	if done:
		GameFlow.on_calibration_finished(
			calibration_ctrl.working_profile,
			calibration_ctrl.current_body_frame,
			calibration_ctrl.seat_anchor_local_spec,
			calibration_ctrl.seated_height_m
		)

func _trigger_auto_action() -> void:
	if active_mechanic != null and GameFlow.current_state == ZenoEnums.AppState.ROUND_PLAY:
		active_mechanic.simulate_auto_action()

func _handle_desktop_simulator_input(dt: float) -> void:
	if Platform.is_xr_active:
		return

	if Input.is_key_pressed(KEY_LEFT):
		_sim_cam_yaw_deg = clampf(_sim_cam_yaw_deg + 85.0 * dt, -85.0, 85.0)
	if Input.is_key_pressed(KEY_RIGHT):
		_sim_cam_yaw_deg = clampf(_sim_cam_yaw_deg - 85.0 * dt, -85.0, 85.0)
	if Input.is_key_pressed(KEY_UP):
		_sim_cam_pitch_deg = clampf(_sim_cam_pitch_deg + 70.0 * dt, -50.0, 50.0)
	if Input.is_key_pressed(KEY_DOWN):
		_sim_cam_pitch_deg = clampf(_sim_cam_pitch_deg - 70.0 * dt, -50.0, 50.0)

	if Input.is_key_pressed(KEY_W):
		_sim_cam_offset_local.z = clampf(_sim_cam_offset_local.z - 0.65 * dt, -0.55, 0.45)
	if Input.is_key_pressed(KEY_S):
		_sim_cam_offset_local.z = clampf(_sim_cam_offset_local.z + 0.65 * dt, -0.55, 0.45)
	if Input.is_key_pressed(KEY_Z):
		_sim_cam_offset_local.x = clampf(_sim_cam_offset_local.x - 0.45 * dt, -0.32, 0.32)
	if Input.is_key_pressed(KEY_X):
		_sim_cam_offset_local.x = clampf(_sim_cam_offset_local.x + 0.45 * dt, -0.32, 0.32)

	if Input.is_key_pressed(KEY_BRACKETLEFT):
		_sim_wrist_roll_deg = clampf(_sim_wrist_roll_deg - 95.0 * dt, -95.0, 95.0)
	if Input.is_key_pressed(KEY_BRACKETRIGHT):
		_sim_wrist_roll_deg = clampf(_sim_wrist_roll_deg + 95.0 * dt, -95.0, 95.0)

	xr_camera.position = Vector3(_sim_cam_offset_local.x, 1.18, _sim_cam_offset_local.z)
	xr_camera.rotation_degrees = Vector3(_sim_cam_pitch_deg, _sim_cam_yaw_deg, 0.0)

	var mouse_pos := get_viewport().get_mouse_position()
	if Input.is_key_pressed(KEY_Q):
		left_controller.global_position = xr_camera.project_position(mouse_pos, _sim_left_depth_m)
	if Input.is_key_pressed(KEY_E):
		right_controller.global_position = xr_camera.project_position(mouse_pos, _sim_right_depth_m)

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
			KEY_H:
				_sim_cam_yaw_deg = 0.0
				_sim_cam_pitch_deg = 0.0
				_sim_cam_offset_local = Vector3.ZERO
				_sim_wrist_roll_deg = 0.0
				xr_camera.position = Vector3(0.0, 1.18, 0.0)
				xr_camera.rotation_degrees = Vector3.ZERO
			KEY_TAB:
				_trigger_auto_action()
			KEY_N:
				if GameFlow.current_state == ZenoEnums.AppState.ROUND_INTRO or GameFlow.current_state == ZenoEnums.AppState.ROUND_PLAY:
					GameFlow.round_timer_s = 0.01
			KEY_R:
				Platform.simulate_recenter()
			KEY_ESCAPE:
				if GameFlow.current_state == ZenoEnums.AppState.ROUND_INTRO or GameFlow.current_state == ZenoEnums.AppState.ROUND_PLAY or GameFlow.current_state == ZenoEnums.AppState.ROUND_OUTRO:
					GameFlow.pause_session(ZenoEnums.PauseReason.MANUAL, "Session paused")
				elif GameFlow.current_state != ZenoEnums.AppState.WELCOME and GameFlow.current_state != ZenoEnums.AppState.MAIN_MENU:
					GameFlow.return_to_main_menu()
