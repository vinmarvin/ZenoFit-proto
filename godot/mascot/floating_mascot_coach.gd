class_name FloatingMascotCoach
extends Node3D

## Textured Zeno Mascot Coach (res://assets/Zeno_WithTexture.glb ONLY).
## Uses FoV-safe anchoring (horizontal viewing angle strictly <= 24 deg inside VR lenses),
## demonstrates all 7 curated exercises in 3D, and keeps speech bubbles clean and temporary.

const MASCOT_GLB_PATH: String = "res://assets/Zeno_WithTexture.glb"
const POKE_RADIUS_M: float = 0.22
const MAX_FOV_HALF_ANGLE_DEG: float = 23.0

var base_spec_pos: Vector3 = Vector3(0.72, -0.06, 1.73)
var loaded_model_path: String = ""
var active_demo_exercise: int = ZenoEnums.ExerciseId.BOARD_SMASH
var poke_reaction_timer_s: float = 0.0
var cheer_reaction_timer_s: float = 0.0
var bubble_timer_s: float = 0.0
var poke_count: int = 0
var is_idle_menu: bool = true

var _visual_root: Node3D
var _left_shoulder_pivot: Node3D
var _right_shoulder_pivot: Node3D
var _neck_pivot: Node3D
var _speech_label: Label3D
var _eye_l: Node3D
var _eye_r: Node3D
var _eye_happy_l: Node3D
var _eye_happy_r: Node3D
var _mouth_smile: Node3D
var _mouth_open: Node3D
var _ring_1: Node3D
var _ring_2: Node3D
var _ring_3: Node3D
var _anim_time: float = 0.0
var _poke_cooldown_s: float = 0.0
var _anchor_initialized: bool = false
var _smoothed_spec_pos: Vector3 = Vector3(0.72, -0.06, 1.73)
var _smoothed_scale: float = 0.140
var _smoothed_facing_deg: float = -22.0

func _ready() -> void:
	_build_mascot_hierarchy()
	if is_inside_tree() and get_tree().root.has_node("EventBus"):
		var eb := get_tree().root.get_node("EventBus")
		eb.mascot_demo_requested.connect(_on_mascot_demo_requested)
		eb.target_hit.connect(_on_target_hit)
		eb.state_changed.connect(_on_state_changed)

func _clear_hierarchy() -> void:
	_visual_root = null
	_left_shoulder_pivot = null
	_right_shoulder_pivot = null
	_neck_pivot = null
	_speech_label = null
	_eye_l = null
	_eye_r = null
	_eye_happy_l = null
	_eye_happy_r = null
	_mouth_smile = null
	_mouth_open = null
	_ring_1 = null
	_ring_2 = null
	_ring_3 = null
	for child in get_children():
		remove_child(child)
		child.free()

func _build_mascot_hierarchy() -> void:
	_clear_hierarchy()
	_visual_root = Node3D.new()
	_visual_root.name = "MascotVisualRoot"
	_visual_root.scale = Vector3.ONE * 0.140
	_visual_root.rotation = Vector3.ZERO
	add_child(_visual_root)

	var instance := DojoEnvironmentLoader.load_glb_scene(MASCOT_GLB_PATH)
	if instance != null:
		loaded_model_path = MASCOT_GLB_PATH
		_visual_root.add_child(instance)
		_bind_rigged_pivots(instance)
	else:
		loaded_model_path = ""

	_speech_label = Label3D.new()
	_speech_label.name = "CoachBubble"
	_speech_label.position = Vector3(0.0, 0.56, 0.0)
	_speech_label.pixel_size = 0.0017
	_speech_label.font_size = 18
	_speech_label.outline_size = 5
	_speech_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	_speech_label.modulate = Color(0.92, 0.96, 0.94)
	_speech_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_speech_label.visible = false
	add_child(_speech_label)

func _bind_rigged_pivots(glb_root: Node) -> void:
	var anim_player := glb_root.find_child("AnimationPlayer", true, false)
	if anim_player is AnimationPlayer:
		(anim_player as AnimationPlayer).stop()

	_left_shoulder_pivot = glb_root.find_child("Arm_L", true, false) as Node3D
	_right_shoulder_pivot = glb_root.find_child("Arm_R", true, false) as Node3D
	_neck_pivot = glb_root.find_child("Head", true, false) as Node3D
	_eye_l = glb_root.find_child("Eye_L", true, false) as Node3D
	_eye_r = glb_root.find_child("Eye_R", true, false) as Node3D
	_eye_happy_l = glb_root.find_child("EyeHappy_L", true, false) as Node3D
	_eye_happy_r = glb_root.find_child("EyeHappy_R", true, false) as Node3D
	_mouth_smile = glb_root.find_child("Mouth_Smile", true, false) as Node3D
	_mouth_open = glb_root.find_child("Mouth_Open", true, false) as Node3D
	_ring_1 = glb_root.find_child("Ring_1", true, false) as Node3D
	_ring_2 = glb_root.find_child("Ring_2", true, false) as Node3D
	_ring_3 = glb_root.find_child("Ring_3", true, false) as Node3D

	# Hide ground shadow rings while floating cleanly beside panels
	for ground_name in ["Ground_Ring", "Ground_Ring_Inner"]:
		var gr := glb_root.find_child(ground_name, true, false) as Node3D
		if gr != null:
			gr.visible = false

	DojoEnvironmentLoader.optimize_meshes(glb_root, true)

## Computes FoV-safe anchor in BodyFrame SpecSpace so Zeno always sits inside <= 24 deg horizontal FoV.
static func compute_fov_safe_anchor(state: int, hud_dist_m: float) -> Dictionary:
	var z_menu := clampf(hud_dist_m + 0.08, 1.62, 2.24)
	var max_x := z_menu * tan(deg_to_rad(MAX_FOV_HALF_ANGLE_DEG))
	if state == ZenoEnums.AppState.EXERCISE_PREVIEW:
		var preview_z := clampf(hud_dist_m - 0.14, 1.40, 2.05)
		var px := -minf(0.34, preview_z * tan(deg_to_rad(18.0)))
		return {"pos": Vector3(px, -0.02, preview_z), "scale": 0.145, "facing_deg": 16.0}
	if state == ZenoEnums.AppState.ROUND_INTRO or state == ZenoEnums.AppState.ROUND_PLAY or state == ZenoEnums.AppState.ROUND_OUTRO:
		var play_z := maxf(1.65, hud_dist_m)
		var rx := minf(0.60, play_z * tan(deg_to_rad(20.0)))
		return {"pos": Vector3(rx, 0.02, play_z), "scale": 0.145, "facing_deg": -20.0}
	var mx := minf(0.72, max_x)
	return {"pos": Vector3(mx, -0.06, z_menu), "scale": 0.140, "facing_deg": -22.0}

func update_coach(
	dt: float,
	body_frame: BodyFrame,
	left_hand_godot: Vector3,
	right_hand_godot: Vector3
) -> void:
	_anim_time += dt
	_poke_cooldown_s = maxf(0.0, _poke_cooldown_s - dt)
	poke_reaction_timer_s = maxf(0.0, poke_reaction_timer_s - dt)
	cheer_reaction_timer_s = maxf(0.0, cheer_reaction_timer_s - dt)
	bubble_timer_s = maxf(0.0, bubble_timer_s - dt)
	if _speech_label != null and bubble_timer_s <= 0.0:
		_speech_label.visible = false

	var state := ZenoEnums.AppState.MAIN_MENU
	var hud_dist := 1.65
	if is_inside_tree() and get_tree().root.has_node("GameFlow"):
		var gf := get_tree().root.get_node("GameFlow")
		state = int(gf.get("current_state"))
		hud_dist = clampf(float(gf.settings.get("hud_distance_m", 1.65)), 1.30, 2.20)

	var anchor := compute_fov_safe_anchor(state, hud_dist)
	var target_spec: Vector3 = anchor["pos"]
	var target_scale := float(anchor["scale"])
	var target_facing := float(anchor["facing_deg"])

	if not _anchor_initialized:
		_smoothed_spec_pos = target_spec
		_smoothed_scale = target_scale
		_smoothed_facing_deg = target_facing
		_anchor_initialized = true
	else:
		var t := clampf(dt * 7.0, 0.0, 1.0)
		_smoothed_spec_pos = _smoothed_spec_pos.lerp(target_spec, t)
		_smoothed_scale = lerpf(_smoothed_scale, target_scale, t)
		_smoothed_facing_deg = lerpf(_smoothed_facing_deg, target_facing, t)

	var hover_y := sin(_anim_time * 2.1) * 0.025
	if poke_reaction_timer_s > 0.0 or cheer_reaction_timer_s > 0.0:
		hover_y += absf(sin(_anim_time * 13.0)) * 0.045

	var target_world := body_frame.to_godot_world(_smoothed_spec_pos + Vector3(0.0, hover_y, 0.0))
	if is_inside_tree():
		global_position = target_world
	else:
		position = target_world

	if _visual_root != null:
		_visual_root.scale = Vector3.ONE * _smoothed_scale
	rotation.y = body_frame.get_godot_yaw_rad() + deg_to_rad(_smoothed_facing_deg)

	var base_pos := global_position if is_inside_tree() else position
	var center := base_pos + Vector3(0.0, 0.20, 0.0)
	if _poke_cooldown_s <= 0.0 and state != ZenoEnums.AppState.ROUND_PLAY:
		if left_hand_godot.distance_to(center) <= POKE_RADIUS_M:
			trigger_poke_reaction(ZenoEnums.Hand.LEFT)
		elif right_hand_godot.distance_to(center) <= POKE_RADIUS_M:
			trigger_poke_reaction(ZenoEnums.Hand.RIGHT)

	_animate_joints()

func _show_brief_bubble(text: String, duration_s: float = 2.0) -> void:
	if _speech_label == null:
		return
	_speech_label.text = text
	_speech_label.visible = true
	bubble_timer_s = duration_s

func trigger_poke_reaction(hand: int) -> void:
	_poke_cooldown_s = 0.8
	poke_reaction_timer_s = 1.6
	poke_count += 1
	if is_inside_tree() and get_tree().root.has_node("Platform"):
		get_tree().root.get_node("Platform").play_haptic_light_touch(hand)
	if is_inside_tree() and get_tree().root.has_node("EventBus"):
		get_tree().root.get_node("EventBus").mascot_poked.emit(hand)
	_show_brief_bubble("High five!", 1.8)

func set_demo_exercise(exercise_id: int) -> void:
	is_idle_menu = false
	active_demo_exercise = exercise_id

func _on_state_changed(_prev: int, next_state: int) -> void:
	is_idle_menu = (
		next_state != ZenoEnums.AppState.EXERCISE_PREVIEW
		and next_state != ZenoEnums.AppState.ROUND_INTRO
		and next_state != ZenoEnums.AppState.ROUND_PLAY
		and next_state != ZenoEnums.AppState.ROUND_OUTRO
	)
	if next_state == ZenoEnums.AppState.WELCOME:
		_show_brief_bubble("Welcome! Ready to move?", 2.6)
	elif next_state == ZenoEnums.AppState.RESULTS:
		cheer_reaction_timer_s = 1.4
		_show_brief_bubble("Nice work!", 2.5)
	elif next_state == ZenoEnums.AppState.ROUND_PLAY:
		if _speech_label != null:
			_speech_label.visible = false

func _on_mascot_demo_requested(exercise_id: int) -> void:
	set_demo_exercise(exercise_id)

func _on_target_hit(_hand: int, _points: int, streak: int, _is_solid: bool) -> void:
	if streak > 0 and streak % 5 == 0:
		cheer_reaction_timer_s = 0.9
		_show_brief_bubble("Streak x%d!" % streak, 1.5)

func _animate_hq_expressions_and_rings(t: float, is_excited: bool) -> void:
	var happy_scale := Vector3.ONE if is_excited else Vector3.ONE * 0.001
	var normal_scale := Vector3.ONE * 0.001 if is_excited else Vector3.ONE
	if _eye_happy_l != null:
		_eye_happy_l.scale = happy_scale
	if _eye_happy_r != null:
		_eye_happy_r.scale = happy_scale
	if _eye_l != null:
		_eye_l.scale = normal_scale
	if _eye_r != null:
		_eye_r.scale = normal_scale
	if _mouth_open != null:
		_mouth_open.scale = Vector3.ONE if is_excited else Vector3.ONE * 0.001
	if _mouth_smile != null:
		_mouth_smile.scale = Vector3.ONE * 0.001 if is_excited else Vector3.ONE

	var pulse := 0.85 + 0.15 * sin(t * 4.2)
	if _ring_1 != null:
		_ring_1.scale = Vector3.ONE * pulse
	if _ring_2 != null:
		_ring_2.scale = Vector3.ONE * (0.72 + 0.12 * sin(t * 4.2 + 1.0))
	if _ring_3 != null:
		_ring_3.scale = Vector3.ONE * (0.54 + 0.10 * sin(t * 4.2 + 2.0))

func _animate_joints() -> void:
	if _left_shoulder_pivot == null or _right_shoulder_pivot == null or _neck_pivot == null or _visual_root == null:
		return

	var t := _anim_time
	var excited := (poke_reaction_timer_s > 0.0 or cheer_reaction_timer_s > 0.0)
	_animate_hq_expressions_and_rings(t, excited)

	_visual_root.rotation = Vector3.ZERO
	_left_shoulder_pivot.rotation = Vector3.ZERO
	_right_shoulder_pivot.rotation = Vector3.ZERO
	_neck_pivot.rotation = Vector3.ZERO

	if excited:
		_right_shoulder_pivot.rotation.z = deg_to_rad(132.0 + sin(t * 15.0) * 18.0)
		_left_shoulder_pivot.rotation.z = deg_to_rad(-132.0 - sin(t * 15.0) * 14.0) if cheer_reaction_timer_s > 0.0 else deg_to_rad(-28.0)
		_neck_pivot.rotation.z = deg_to_rad(sin(t * 9.0) * 10.0)
		return

	if is_idle_menu:
		_right_shoulder_pivot.rotation.z = deg_to_rad(25.0 + sin(t * 2.2) * 8.0)
		_left_shoulder_pivot.rotation.z = deg_to_rad(-25.0 - sin(t * 2.2) * 8.0)
		_neck_pivot.rotation.z = deg_to_rad(sin(t * 1.8) * 4.0)
		return

	match active_demo_exercise:
		ZenoEnums.ExerciseId.BOARD_SMASH:
			_left_shoulder_pivot.rotation.x = deg_to_rad(-75.0 * maxf(0.0, sin(t * 3.8)))
			_right_shoulder_pivot.rotation.x = deg_to_rad(-75.0 * maxf(0.0, -sin(t * 3.8)))
		ZenoEnums.ExerciseId.WIDE_SPLIT:
			var open_u := 0.5 + 0.5 * sin(t * 2.4)
			_left_shoulder_pivot.rotation.x = deg_to_rad(lerpf(-72.0, -25.0, open_u))
			_right_shoulder_pivot.rotation.x = deg_to_rad(lerpf(-72.0, -25.0, open_u))
			_left_shoulder_pivot.rotation.z = deg_to_rad(lerpf(12.0, -78.0, open_u))
			_right_shoulder_pivot.rotation.z = deg_to_rad(lerpf(-12.0, 78.0, open_u))
		ZenoEnums.ExerciseId.SKY_REACH:
			_left_shoulder_pivot.rotation.x = deg_to_rad(-122.0 * (0.5 + 0.5 * sin(t * 2.5)))
			_right_shoulder_pivot.rotation.x = deg_to_rad(-122.0 * (0.5 + 0.5 * cos(t * 2.5)))
		ZenoEnums.ExerciseId.ORBIT_FLOW:
			_left_shoulder_pivot.rotation.x = deg_to_rad(-75.0 + sin(t * 4.2) * 24.0)
			_left_shoulder_pivot.rotation.z = deg_to_rad(-18.0 + cos(t * 4.2) * 24.0)
			_right_shoulder_pivot.rotation.x = deg_to_rad(-75.0 + sin(t * 4.2) * 24.0)
			_right_shoulder_pivot.rotation.z = deg_to_rad(18.0 - cos(t * 4.2) * 24.0)
		ZenoEnums.ExerciseId.WRIST_TWIST:
			_left_shoulder_pivot.rotation.x = deg_to_rad(-65.0)
			_right_shoulder_pivot.rotation.x = deg_to_rad(-65.0)
			_left_shoulder_pivot.rotation.y = deg_to_rad(sin(t * 2.6) * 35.0)
			_right_shoulder_pivot.rotation.y = deg_to_rad(sin(t * 2.6) * 35.0)
		ZenoEnums.ExerciseId.TORSO_TWIST:
			_left_shoulder_pivot.rotation.x = deg_to_rad(-65.0)
			_right_shoulder_pivot.rotation.x = deg_to_rad(-65.0)
			_visual_root.rotation.y = deg_to_rad(sin(t * 1.9) * 36.0)
		ZenoEnums.ExerciseId.HORIZON_GAZE:
			_neck_pivot.rotation.y = deg_to_rad(sin(t * 1.3) * 44.0)
