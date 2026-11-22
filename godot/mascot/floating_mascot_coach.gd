class_name FloatingMascotCoach
extends Node3D

## Interactive Floating Mascot & Exercise Coach supporting dual visual LODs:
## - High Quality (Textured): res://assets/Zeno_WithTexture.glb (66,480 tris, 12 PBR PNG textures, expressive eyes & hover rings)
## - Low Poly (Performance):   res://assets/Floating Mascots.glb (19,900 tris, lightweight flat materials for Quest 2 / low-spec)
##
## Procedurally animates Arm_L, Arm_R, Head/Neck, Leaf, and Expressions to demonstrate all 10 Zen Dojo exercises (M01–M10).

const MASCOT_HQ_GLB_PATH: String = "res://assets/Zeno_WithTexture.glb"
const MASCOT_LOW_POLY_GLB_PATH: String = "res://assets/Floating Mascots.glb"
const POKE_RADIUS_M: float = 0.24

# Positioned cleanly on the right side of the 3-panel Beat-Saber-style Dojo layout in BodyFrame
var base_spec_pos: Vector3 = Vector3(0.92, 0.04, 1.12)
var use_high_quality_model: bool = true
var loaded_model_path: String = ""
var active_demo_mechanic: int = ZenoEnums.MechanicId.M01_MAKIWARA_STRIKES
var poke_reaction_timer_s: float = 0.0
var cheer_reaction_timer_s: float = 0.0
var poke_count: int = 0
var is_main_menu_welcome: bool = true

var _visual_root: Node3D
var _left_shoulder_pivot: Node3D
var _right_shoulder_pivot: Node3D
var _neck_pivot: Node3D
var _leaf_node: Node3D
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

func _ready() -> void:
	if is_inside_tree() and get_tree().root.has_node("GameFlow"):
		var gf := get_tree().root.get_node("GameFlow")
		use_high_quality_model = bool(gf.settings.get("mascot_high_quality", true))
	_build_mascot_hierarchy()
	if is_inside_tree() and get_tree().root.has_node("EventBus"):
		var eb := get_tree().root.get_node("EventBus")
		eb.mascot_demo_requested.connect(_on_mascot_demo_requested)
		eb.target_hit.connect(_on_target_hit)
		eb.state_changed.connect(_on_state_changed)

func set_quality_mode(high_quality: bool) -> void:
	use_high_quality_model = high_quality
	_build_mascot_hierarchy()
	_animate_joints()

func _clear_hierarchy() -> void:
	_visual_root = null
	_left_shoulder_pivot = null
	_right_shoulder_pivot = null
	_neck_pivot = null
	_leaf_node = null
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

func _load_glb_scene(path: String) -> Node:
	if ResourceLoader.exists(path):
		var loaded := ResourceLoader.load(path)
		if loaded is PackedScene:
			return (loaded as PackedScene).instantiate()
	if FileAccess.file_exists(path):
		var bytes := FileAccess.get_file_as_bytes(path)
		if bytes.size() > 0:
			var gltf := GLTFDocument.new()
			var st := GLTFState.new()
			if gltf.append_from_buffer(bytes, "res://assets/", st) == OK:
				return gltf.generate_scene(st)
	return null

func _build_mascot_hierarchy() -> void:
	_clear_hierarchy()
	_visual_root = Node3D.new()
	_visual_root.name = "MascotVisualRoot"
	_visual_root.scale = Vector3.ONE * 0.18
	_visual_root.rotation = Vector3.ZERO
	add_child(_visual_root)

	var target_path := MASCOT_HQ_GLB_PATH if use_high_quality_model else MASCOT_LOW_POLY_GLB_PATH
	var instance := _load_glb_scene(target_path)
	if instance == null and target_path != MASCOT_LOW_POLY_GLB_PATH:
		target_path = MASCOT_LOW_POLY_GLB_PATH
		instance = _load_glb_scene(target_path)

	if instance != null:
		loaded_model_path = target_path
		_visual_root.add_child(instance)
		var is_rigged_hq := instance.find_child("Head", true, false) != null
		if is_rigged_hq:
			_bind_hq_rigged_pivots(instance)
		else:
			_setup_anatomical_pivots(instance)
			_apply_vibrant_materials(instance)
	else:
		loaded_model_path = ""

	_speech_label = Label3D.new()
	_speech_label.name = "CoachBubble"
	# Positioned safely above Zeno_WithTexture.glb head top (~0.48 m) with bottom alignment so multi-line text grows upward
	_speech_label.position = Vector3(0.0, 0.66, 0.0)
	_speech_label.pixel_size = 0.0018
	_speech_label.font_size = 20
	_speech_label.outline_size = 6
	_speech_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	_speech_label.modulate = Color(0.92, 0.99, 0.96)
	_speech_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_speech_label.text = "Halo! I'm Zeno!\nPoke me or click PLAY!"
	add_child(_speech_label)

func _bind_hq_rigged_pivots(glb_root: Node) -> void:
	# Stop any embedded GLB AnimationPlayer so procedural exercise demos drive joints cleanly
	var anim_player := glb_root.find_child("AnimationPlayer", true, false)
	if anim_player is AnimationPlayer:
		(anim_player as AnimationPlayer).stop()

	_left_shoulder_pivot = glb_root.find_child("Arm_L", true, false) as Node3D
	_right_shoulder_pivot = glb_root.find_child("Arm_R", true, false) as Node3D
	_neck_pivot = glb_root.find_child("Head", true, false) as Node3D
	_leaf_node = glb_root.find_child("Leaf", true, false) as Node3D

	_eye_l = glb_root.find_child("Eye_L", true, false) as Node3D
	_eye_r = glb_root.find_child("Eye_R", true, false) as Node3D
	_eye_happy_l = glb_root.find_child("EyeHappy_L", true, false) as Node3D
	_eye_happy_r = glb_root.find_child("EyeHappy_R", true, false) as Node3D
	_mouth_smile = glb_root.find_child("Mouth_Smile", true, false) as Node3D
	_mouth_open = glb_root.find_child("Mouth_Open", true, false) as Node3D
	_ring_1 = glb_root.find_child("Ring_1", true, false) as Node3D
	_ring_2 = glb_root.find_child("Ring_2", true, false) as Node3D
	_ring_3 = glb_root.find_child("Ring_3", true, false) as Node3D

	_optimize_hq_meshes(glb_root)

func _optimize_hq_meshes(node: Node) -> void:
	if node is MeshInstance3D:
		var mi := node as MeshInstance3D
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		if mi.mesh != null:
			for s_idx in range(mi.mesh.get_surface_count()):
				var mat := mi.get_surface_override_material(s_idx)
				if mat == null:
					mat = mi.mesh.surface_get_material(s_idx)
				if mat is BaseMaterial3D:
					var bm := (mat as BaseMaterial3D).duplicate() as BaseMaterial3D
					bm.cull_mode = BaseMaterial3D.CULL_DISABLED
					mi.set_surface_override_material(s_idx, bm)
	for c in node.get_children():
		_optimize_hq_meshes(c)

func _setup_anatomical_pivots(glb_root: Node) -> void:
	_left_shoulder_pivot = Node3D.new()
	_left_shoulder_pivot.name = "LeftShoulderPivot"
	_left_shoulder_pivot.position = Vector3(-0.42, 0.92, 0.0)
	glb_root.add_child(_left_shoulder_pivot)

	_right_shoulder_pivot = Node3D.new()
	_right_shoulder_pivot.name = "RightShoulderPivot"
	_right_shoulder_pivot.position = Vector3(0.42, 0.92, 0.0)
	glb_root.add_child(_right_shoulder_pivot)

	_neck_pivot = Node3D.new()
	_neck_pivot.name = "NeckPivot"
	_neck_pivot.position = Vector3(0.0, 1.25, 0.0)
	glb_root.add_child(_neck_pivot)

	var arm_l := glb_root.find_child("Arm_L", true, false) as Node3D
	if arm_l != null:
		arm_l.owner = null
		arm_l.reparent(_left_shoulder_pivot, false)
		arm_l.position = -_left_shoulder_pivot.position

	var arm_r := glb_root.find_child("Arm_R", true, false) as Node3D
	if arm_r != null:
		arm_r.owner = null
		arm_r.reparent(_right_shoulder_pivot, false)
		arm_r.position = -_right_shoulder_pivot.position

	for head_part_name in ["HeadShell", "Visor", "Ear_L", "Ear_R", "Eye_L", "Eye_R", "Mouth_Smile"]:
		var part := glb_root.find_child(head_part_name, true, false) as Node3D
		if part != null:
			part.owner = null
			part.reparent(_neck_pivot, false)
			part.position = -_neck_pivot.position

	_leaf_node = glb_root.find_child("Leaf", true, false) as Node3D

func _apply_vibrant_materials(glb_root: Node) -> void:
	var body_mat := _make_mat(Color(0.84, 0.94, 0.88), 0.35, 0.05)
	var head_mat := _make_mat(Color(0.94, 0.98, 0.95), 0.30, 0.05)
	var visor_mat := _make_mat(Color(0.05, 0.09, 0.14), 0.12, 0.25)
	var face_glow_mat := _make_mat(Color(0.35, 0.96, 1.0), 0.20, 0.0, Color(0.25, 0.90, 1.0), 1.4)
	var leaf_mat := _make_mat(Color(0.22, 0.78, 0.36), 0.40, 0.0, Color(0.08, 0.30, 0.12), 0.3)
	var emblem_mat := _make_mat(Color(0.45, 0.85, 0.62), 0.35, 0.1)

	_set_mesh_mat(glb_root, "Torso", body_mat)
	_set_mesh_mat(glb_root, "Neck", body_mat)
	_set_mesh_mat(glb_root, "Arm_L", body_mat)
	_set_mesh_mat(glb_root, "Arm_R", body_mat)
	_set_mesh_mat(glb_root, "HeadShell", head_mat)
	_set_mesh_mat(glb_root, "Ear_L", emblem_mat)
	_set_mesh_mat(glb_root, "Ear_R", emblem_mat)
	_set_mesh_mat(glb_root, "EmblemDisc", emblem_mat)
	_set_mesh_mat(glb_root, "Leaf", leaf_mat)
	_set_mesh_mat(glb_root, "Visor", visor_mat)
	_set_mesh_mat(glb_root, "Eye_L", face_glow_mat)
	_set_mesh_mat(glb_root, "Eye_R", face_glow_mat)
	_set_mesh_mat(glb_root, "Mouth_Smile", face_glow_mat)

func _make_mat(albedo: Color, rough: float, metal: float, emission: Color = Color.BLACK, energy: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = albedo
	m.roughness = rough
	m.metallic = metal
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	if energy > 0.0:
		m.emission_enabled = true
		m.emission = emission
		m.emission_energy_multiplier = energy
	return m

func _set_mesh_mat(root: Node, node_name: String, mat: Material) -> void:
	var n := root.find_child(node_name, true, false) as MeshInstance3D
	if n != null:
		n.material_override = mat
		n.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func update_coach(
	dt: float,
	body_frame: BodyFrame,
	left_hand_godot: Vector3,
	right_hand_godot: Vector3
) -> void:
	_anim_time += dt
	if _poke_cooldown_s > 0.0:
		_poke_cooldown_s = maxf(0.0, _poke_cooldown_s - dt)
	if poke_reaction_timer_s > 0.0:
		poke_reaction_timer_s = maxf(0.0, poke_reaction_timer_s - dt)
	if cheer_reaction_timer_s > 0.0:
		cheer_reaction_timer_s = maxf(0.0, cheer_reaction_timer_s - dt)

	var hover_y := sin(_anim_time * 2.2) * 0.035
	if poke_reaction_timer_s > 0.0 or cheer_reaction_timer_s > 0.0:
		hover_y += absf(sin(_anim_time * 14.0)) * 0.06
	var coach_spec := base_spec_pos
	if is_inside_tree() and get_tree().root.has_node("GameFlow"):
		var gf := get_tree().root.get_node("GameFlow")
		var hud_dist := clampf(float(gf.settings.get("hud_distance_m", 1.35)), 0.90, 2.00)
		coach_spec.z = minf(base_spec_pos.z, hud_dist - 0.22)
	var target_world := body_frame.to_godot_world(coach_spec + Vector3(0.0, hover_y, 0.0))
	if is_inside_tree():
		global_position = target_world
	else:
		position = target_world
	# Face inward toward the seated player from the right side
	rotation.y = body_frame.get_godot_yaw_rad() - deg_to_rad(28.0)

	var base_pos := global_position if is_inside_tree() else position
	var center := base_pos + Vector3(0.0, 0.22, 0.0)
	if _poke_cooldown_s <= 0.0:
		if left_hand_godot.distance_to(center) <= POKE_RADIUS_M:
			trigger_poke_reaction(ZenoEnums.Hand.LEFT)
		elif right_hand_godot.distance_to(center) <= POKE_RADIUS_M:
			trigger_poke_reaction(ZenoEnums.Hand.RIGHT)

	_animate_joints()

func trigger_poke_reaction(hand: int) -> void:
	_poke_cooldown_s = 0.8
	poke_reaction_timer_s = 1.6
	poke_count += 1
	if is_inside_tree() and get_tree().root.has_node("Platform"):
		get_tree().root.get_node("Platform").play_haptic_light_touch(hand)
	if is_inside_tree() and get_tree().root.has_node("EventBus"):
		get_tree().root.get_node("EventBus").mascot_poked.emit(hand)
	if _speech_label != null:
		if is_main_menu_welcome:
			_speech_label.text = "Yatta! Let's pick a Zen Dojo routine!"
		else:
			_speech_label.text = "Hi there! (#%d)\nDemoing: %s" % [
				poke_count,
				ZenoEnums.get_mechanic_title(active_demo_mechanic).split("(")[0].strip_edges()
			]

func set_demo_mechanic(mechanic_id: int) -> void:
	is_main_menu_welcome = false
	active_demo_mechanic = mechanic_id
	if _speech_label != null:
		_speech_label.text = "Coach Demo:\n%s" % ZenoEnums.get_mechanic_title(mechanic_id).split("(")[0].strip_edges()

func _on_state_changed(_prev: int, next_state: int) -> void:
	is_main_menu_welcome = (next_state == ZenoEnums.AppState.MAIN_MENU or next_state == ZenoEnums.AppState.ROUTINE_PICKER or next_state == ZenoEnums.AppState.CREDITS)
	if _speech_label == null:
		return
	if next_state == ZenoEnums.AppState.MAIN_MENU:
		_speech_label.text = "Halo! I'm Zeno!\nPoke/Tap me or press Play to start!"
	elif next_state == ZenoEnums.AppState.ROUTINE_PICKER:
		_speech_label.text = "Choose your Zen Dojo routine\nand comfortable session time!"
	elif next_state == ZenoEnums.AppState.WARM_UP:
		_speech_label.text = "Roll shoulders slowly & breathe in..."

func _on_mascot_demo_requested(mechanic_id: int) -> void:
	set_demo_mechanic(mechanic_id)

func _on_target_hit(_hand: int, points: int, streak: int, _is_solid: bool) -> void:
	if streak > 0 and streak % 5 == 0:
		cheer_reaction_timer_s = 0.85
	if _speech_label != null and poke_reaction_timer_s <= 0.0:
		if streak >= 5 and streak % 5 == 0:
			_speech_label.text = "SUGOI! Streak x%d! (+%d pts)" % [streak, points]
		else:
			_speech_label.text = "Nice! +%d pts (Streak x%d)" % [points, streak]

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

	var pulse := 0.85 + 0.15 * sin(t * 4.5)
	if _ring_1 != null:
		_ring_1.scale = Vector3.ONE * pulse
	if _ring_2 != null:
		_ring_2.scale = Vector3.ONE * (0.72 + 0.12 * sin(t * 4.5 + 1.0))
	if _ring_3 != null:
		_ring_3.scale = Vector3.ONE * (0.54 + 0.10 * sin(t * 4.5 + 2.0))

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
		_right_shoulder_pivot.rotation.z = deg_to_rad(135.0 + sin(t * 16.0) * 20.0)
		_left_shoulder_pivot.rotation.z = deg_to_rad(-135.0 - sin(t * 16.0) * 15.0) if cheer_reaction_timer_s > 0.0 else deg_to_rad(-35.0)
		_neck_pivot.rotation.z = deg_to_rad(sin(t * 10.0) * 12.0)
		return

	if is_main_menu_welcome:
		_right_shoulder_pivot.rotation.z = deg_to_rad(125.0 + sin(t * 5.0) * 18.0)
		_left_shoulder_pivot.rotation.z = deg_to_rad(-22.0)
		_neck_pivot.rotation.z = deg_to_rad(sin(t * 2.5) * 6.0)
		return

	match active_demo_mechanic:
		ZenoEnums.MechanicId.M01_MAKIWARA_STRIKES:
			_left_shoulder_pivot.rotation.x = deg_to_rad(-75.0 * maxf(0.0, sin(t * 4.0)))
			_right_shoulder_pivot.rotation.x = deg_to_rad(-75.0 * maxf(0.0, -sin(t * 4.0)))
		ZenoEnums.MechanicId.M02_SAKURA_CATCH:
			_left_shoulder_pivot.rotation.x = deg_to_rad(-125.0 * (0.5 + 0.5 * sin(t * 2.5)))
			_right_shoulder_pivot.rotation.x = deg_to_rad(-125.0 * (0.5 + 0.5 * cos(t * 2.5)))
		ZenoEnums.MechanicId.M03_CRANE_WINGS:
			_left_shoulder_pivot.rotation.z = deg_to_rad(-75.0 + sin(t * 2.0) * 12.0)
			_right_shoulder_pivot.rotation.z = deg_to_rad(75.0 + sin(t * 2.0) * 12.0)
		ZenoEnums.MechanicId.M04_BOKKEN_GUARD:
			_left_shoulder_pivot.rotation.x = deg_to_rad(-65.0)
			_right_shoulder_pivot.rotation.x = deg_to_rad(-65.0)
			_visual_root.rotation.y = deg_to_rad(sin(t * 2.0) * 38.0)
		ZenoEnums.MechanicId.M05_TEMPLE_BELL_PULL:
			var row_angle := deg_to_rad(-45.0 - 45.0 * sin(t * 2.8))
			_left_shoulder_pivot.rotation.x = row_angle
			_right_shoulder_pivot.rotation.x = row_angle
		ZenoEnums.MechanicId.M06_KI_PALM_PUSH:
			var press := clampf(sin(t * 1.8) * 1.4, 0.0, 1.0)
			_left_shoulder_pivot.rotation.x = deg_to_rad(-90.0 * press)
			_right_shoulder_pivot.rotation.x = deg_to_rad(-90.0 * press)
		ZenoEnums.MechanicId.M07_ZEN_WATER_WHEEL:
			_left_shoulder_pivot.rotation.x = deg_to_rad(-75.0 + sin(t * 4.5) * 25.0)
			_left_shoulder_pivot.rotation.z = deg_to_rad(-20.0 + cos(t * 4.5) * 25.0)
			_right_shoulder_pivot.rotation.x = deg_to_rad(-75.0 + sin(t * 4.5) * 25.0)
			_right_shoulder_pivot.rotation.z = deg_to_rad(20.0 - cos(t * 4.5) * 25.0)
		ZenoEnums.MechanicId.M08_ZEN_HORIZON_WATCH:
			_neck_pivot.rotation.y = deg_to_rad(sin(t * 1.4) * 48.0)
		ZenoEnums.MechanicId.M09_TEA_CEREMONY_POUR:
			_right_shoulder_pivot.rotation.x = deg_to_rad(-80.0 - 30.0 * sin(t * 2.5))
			_right_shoulder_pivot.rotation.y = deg_to_rad(30.0 * maxf(0.0, cos(t * 2.5)))
		ZenoEnums.MechanicId.M10_BAMBOO_SWAY:
			_left_shoulder_pivot.rotation.x = deg_to_rad(-130.0)
			_right_shoulder_pivot.rotation.x = deg_to_rad(-130.0)
			_visual_root.rotation.z = deg_to_rad(sin(t * 1.8) * 18.0)
