class_name MechanicBase
extends RefCounted

## Base class for all 10 ZenoFit Zen Dojo mechanics (M01–M10).
## Keeps each mechanic independent and renders 3D Zen Dojo targets in Godot space
## while performing all kinematics and gameplay math in SpecSpace / BodyFrame.

var mechanic_id: int = ZenoEnums.MechanicId.M01_MAKIWARA_STRIKES
var profile: ComfortProfile
var body_frame: BodyFrame
var preset: DifficultyPreset
var hand_mode: int = ZenoEnums.HandMode.BOTH_HANDS
var arena_root: Node3D
var status_hint: String = ""

## Hybrid OpenXR Hand/Controller signals updated by main.gd each frame (optional for headless tests).
var left_grasping: bool = true
var right_grasping: bool = true

func setup(
	p_mechanic_id: int,
	p_profile: ComfortProfile,
	p_body_frame: BodyFrame,
	p_preset: DifficultyPreset,
	p_hand_mode: int,
	p_arena_root: Node3D
) -> void:
	mechanic_id = p_mechanic_id
	profile = p_profile
	body_frame = p_body_frame
	preset = p_preset
	hand_mode = p_profile.get_effective_hand_mode(p_hand_mode)
	arena_root = p_arena_root
	clear_arena()
	_on_start()

func clear_arena() -> void:
	if arena_root == null:
		return
	for child in arena_root.get_children():
		child.queue_free()

func _on_start() -> void:
	pass

func update_mechanic(
	_dt: float,
	_head_local_spec: Vector3,
	_head_fwd_local_spec: Vector3,
	_head_speed_deg_s: float,
	_prev_left_local_spec: Vector3,
	_curr_left_local_spec: Vector3,
	_left_speed_mps: float,
	_prev_right_local_spec: Vector3,
	_curr_right_local_spec: Vector3,
	_right_speed_mps: float,
	_left_roll_deg: float,
	_right_roll_deg: float
) -> void:
	pass

## Called when pressing Tab in Desktop Simulator to test/verify the active mechanic cleanly.
func simulate_auto_action() -> void:
	pass

func pick_hand_for_spawn(index: int) -> int:
	if hand_mode == ZenoEnums.HandMode.LEFT_ONLY or not profile.right_enabled:
		return ZenoEnums.Hand.LEFT
	if hand_mode == ZenoEnums.HandMode.RIGHT_ONLY or not profile.left_enabled:
		return ZenoEnums.Hand.RIGHT
	return ZenoEnums.Hand.LEFT if (index % 2 == 0) else ZenoEnums.Hand.RIGHT

func _attach_mesh_with_label(mesh: Mesh, color: Color, label_offset_y: float, label_text: String = "", transparent: bool = false) -> Node3D:
	var root := Node3D.new()
	var mesh_inst := MeshInstance3D.new()
	mesh_inst.mesh = mesh
	# Mobile VR render budget: disable real-time shadow casting on dynamic gameplay shapes
	mesh_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color * 0.38
	mat.roughness = 0.35
	if transparent:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mesh_inst.material_override = mat
	root.add_child(mesh_inst)

	if not label_text.is_empty():
		var lbl := Label3D.new()
		lbl.text = label_text
		lbl.position = Vector3(0.0, label_offset_y, 0.0)
		lbl.pixel_size = 0.0022
		lbl.font_size = 24
		lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		root.add_child(lbl)

	if arena_root != null:
		arena_root.add_child(root)
	return root

func create_target_sphere(radius_m: float, color: Color, label_text: String = "") -> Node3D:
	var sphere := SphereMesh.new()
	sphere.radius = radius_m
	sphere.height = radius_m * 2.0
	sphere.radial_segments = 16
	sphere.rings = 10
	return _attach_mesh_with_label(sphere, color, radius_m + 0.06, label_text)

func create_dojo_box(size_m: Vector3, color: Color, label_text: String = "", transparent: bool = false) -> Node3D:
	var box := BoxMesh.new()
	box.size = size_m
	return _attach_mesh_with_label(box, color, size_m.y * 0.5 + 0.06, label_text, transparent)

func create_dojo_ring(outer_radius_m: float, inner_radius_m: float, color: Color, label_text: String = "") -> Node3D:
	var torus := TorusMesh.new()
	torus.outer_radius = outer_radius_m
	torus.inner_radius = inner_radius_m
	torus.rings = 18
	torus.ring_segments = 10
	var node := _attach_mesh_with_label(torus, color, outer_radius_m + 0.06, label_text)
	if node.get_child_count() > 0 and node.get_child(0) is MeshInstance3D:
		(node.get_child(0) as MeshInstance3D).rotation_degrees = Vector3(90.0, 0.0, 0.0)
	return node
