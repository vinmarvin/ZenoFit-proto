class_name MechanicBase
extends RefCounted

## Base class for all 7 curated ZenoFit v1.0 exercises.
## Keeps targets clean (no debug Label3D text), disables real-time shadows for mobile VR,
## provides shared scoring/audio/haptic/event helpers safe for both live XR and headless tests,
## and isolates all spatial kinematics inside SpecSpace / BodyFrame.

var exercise_id: int = ZenoEnums.ExerciseId.BOARD_SMASH
var profile: ComfortProfile
var body_frame: BodyFrame
var preset: DifficultyPreset
var hand_mode: int = ZenoEnums.HandMode.BOTH_HANDS
var arena_root: Node3D
var status_hint: String = ""

var left_grasping: bool = true
var right_grasping: bool = true

var _fallback_tracker: ZenoScoring.RoundScoreTracker = null
var _fallback_tempo: AdaptiveTempo = null

func setup(
	p_exercise_id: int,
	p_profile: ComfortProfile,
	p_body_frame: BodyFrame,
	p_preset: DifficultyPreset,
	p_hand_mode: int,
	p_arena_root: Node3D
) -> void:
	exercise_id = p_exercise_id
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
		if arena_root.is_inside_tree():
			child.queue_free()
		else:
			arena_root.remove_child(child)
			child.free()

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

func simulate_auto_action() -> void:
	pass

func _get_autoload(autoload_name: String) -> Node:
	if arena_root != null and arena_root.is_inside_tree():
		var root := arena_root.get_tree().root
		if root.has_node(autoload_name):
			return root.get_node(autoload_name)
	return null

func _gf() -> Node:
	return _get_autoload("GameFlow")

func _plat() -> Node:
	return _get_autoload("Platform")

func _eb() -> Node:
	return _get_autoload("EventBus")

func _tracker() -> ZenoScoring.RoundScoreTracker:
	var gf := _gf()
	if gf != null:
		return gf.round_tracker
	if _fallback_tracker == null:
		_fallback_tracker = ZenoScoring.RoundScoreTracker.new()
	return _fallback_tracker

func _tempo() -> AdaptiveTempo:
	var gf := _gf()
	if gf != null:
		return gf.adaptive_tempo
	if _fallback_tempo == null:
		var start_bpm := preset.start_tempo_bpm if preset != null else 60.0
		var max_bpm := preset.max_tempo_bpm if preset != null else 80.0
		_fallback_tempo = AdaptiveTempo.new(start_bpm, max_bpm)
	return _fallback_tempo

func _record_hit_and_notify(hand: int, elapsed_s: float, lifetime_s: float, is_solid: bool = false, extra_bonus: int = 0) -> Dictionary:
	var res := _tracker().record_hit(elapsed_s, lifetime_s, is_solid, extra_bonus)
	var eb := _eb()
	if eb != null:
		eb.target_hit.emit(hand, int(res["combo_points"]), int(res["streak"]), is_solid)
	return res

func _record_direct_hit_and_notify(hand: int, base_pts: int, is_solid: bool = false) -> Dictionary:
	var res := _tracker().record_direct_points(base_pts, true)
	var eb := _eb()
	if eb != null:
		eb.target_hit.emit(hand, int(res["combo_points"]), int(res["streak"]), is_solid)
	return res

func _record_miss_and_notify() -> void:
	_tracker().record_miss()
	var eb := _eb()
	if eb != null:
		eb.target_missed.emit()

func _play_haptic(method_name: String, hand: int) -> void:
	var plat := _plat()
	if plat != null and plat.has_method(method_name):
		plat.call(method_name, hand)

func _emit_safety_cue(msg: String) -> void:
	var eb := _eb()
	if eb != null:
		eb.safety_cue.emit(msg)

func _set_node_world_pos(node: Node3D, pos_spec: Vector3) -> void:
	if node == null or body_frame == null:
		return
	var wp := body_frame.to_godot_world(pos_spec)
	if node.is_inside_tree():
		node.global_position = wp
	else:
		node.position = wp

func _set_node_world_rot(node: Node3D, rot_rad: Vector3) -> void:
	if node == null:
		return
	node.rotation = rot_rad

func _retire_node(node: Node3D) -> void:
	if node == null:
		return
	if node.is_inside_tree():
		node.queue_free()
	else:
		if node.get_parent() != null:
			node.get_parent().remove_child(node)
		node.free()

func get_effective_hit_radius(base_radius_m: float) -> float:
	var gf := _gf()
	if gf != null and int(gf.get("active_input_mode")) == ZenoEnums.InputMode.HAND_TRACKING:
		return base_radius_m + 0.025
	return base_radius_m

func pick_hand_for_spawn(index: int) -> int:
	if hand_mode == ZenoEnums.HandMode.LEFT_ONLY or not profile.right_enabled:
		return ZenoEnums.Hand.LEFT
	if hand_mode == ZenoEnums.HandMode.RIGHT_ONLY or not profile.left_enabled:
		return ZenoEnums.Hand.RIGHT
	return ZenoEnums.Hand.LEFT if (index % 2 == 0) else ZenoEnums.Hand.RIGHT

func _make_clean_material(color: Color, emission_strength: float = 0.45, alpha: float = 1.0) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(color.r, color.g, color.b, alpha)
	mat.roughness = 0.35
	mat.metallic = 0.05
	if emission_strength > 0.0:
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = emission_strength
	if alpha < 0.99:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return mat

func _attach_mesh(mesh: Mesh, mat: Material, parent: Node3D = null) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.material_override = mat
	var target_parent := parent if parent != null else arena_root
	if target_parent != null:
		target_parent.add_child(mi)
	return mi

func create_glow_orb(radius_m: float, color: Color, alpha: float = 0.92) -> Node3D:
	var root := Node3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = radius_m
	sphere.height = radius_m * 2.0
	sphere.radial_segments = 16
	sphere.rings = 10
	_attach_mesh(sphere, _make_clean_material(color, 0.55, alpha), root)
	if arena_root != null:
		arena_root.add_child(root)
	return root

func create_glow_ring(outer_radius_m: float, inner_radius_m: float, color: Color, alpha: float = 0.90) -> Node3D:
	var root := Node3D.new()
	var torus := TorusMesh.new()
	torus.outer_radius = outer_radius_m
	torus.inner_radius = inner_radius_m
	torus.rings = 22
	torus.ring_segments = 10
	var mi := _attach_mesh(torus, _make_clean_material(color, 0.50, alpha), root)
	mi.rotation_degrees = Vector3(90.0, 0.0, 0.0)
	if arena_root != null:
		arena_root.add_child(root)
	return root

## Minimalist Japanese wood-frame lantern prop (~60 tris, zero shadows).
func create_lantern_prop(glow_color: Color, scale_mult: float = 1.0) -> Node3D:
	var root := Node3D.new()
	root.scale = Vector3.ONE * scale_mult

	var wood_mat := _make_clean_material(Color(0.32, 0.24, 0.16), 0.0, 1.0)
	var core_mat := _make_clean_material(glow_color, 0.90, 0.92)

	var core_box := BoxMesh.new()
	core_box.size = Vector3(0.11, 0.14, 0.11)
	_attach_mesh(core_box, core_mat, root)

	var cap_box := BoxMesh.new()
	cap_box.size = Vector3(0.14, 0.022, 0.14)
	var top_cap := _attach_mesh(cap_box, wood_mat, root)
	top_cap.position = Vector3(0.0, 0.08, 0.0)
	var bot_cap := _attach_mesh(cap_box, wood_mat, root)
	bot_cap.position = Vector3(0.0, -0.08, 0.0)

	if arena_root != null:
		arena_root.add_child(root)
	return root

## Clean dial ring with rotating needle + target marker for Wrist Twist.
func create_dial_prop(radius_m: float, ring_color: Color) -> Dictionary:
	var root := Node3D.new()
	var torus := TorusMesh.new()
	torus.outer_radius = radius_m
	torus.inner_radius = 0.012
	torus.rings = 24
	torus.ring_segments = 8
	var ring_mi := _attach_mesh(torus, _make_clean_material(ring_color, 0.42, 0.78), root)
	ring_mi.rotation_degrees = Vector3(90.0, 0.0, 0.0)

	var needle_pivot := Node3D.new()
	root.add_child(needle_pivot)
	var needle_box := BoxMesh.new()
	needle_box.size = Vector3(0.016, radius_m * 0.85, 0.014)
	var needle_mi := _attach_mesh(needle_box, _make_clean_material(Color(0.86, 0.96, 0.88), 0.75, 1.0), needle_pivot)
	needle_mi.position = Vector3(0.0, radius_m * 0.42, 0.0)

	var target_pivot := Node3D.new()
	root.add_child(target_pivot)
	var marker_sphere := SphereMesh.new()
	marker_sphere.radius = 0.022
	marker_sphere.height = 0.044
	var marker_mi := _attach_mesh(marker_sphere, _make_clean_material(Color(0.96, 0.82, 0.36), 0.85, 1.0), target_pivot)
	marker_mi.position = Vector3(0.0, radius_m, 0.0)

	if arena_root != null:
		arena_root.add_child(root)
	return {
		"root": root,
		"needle": needle_pivot,
		"target": target_pivot
	}

func create_aim_beam(color: Color) -> MeshInstance3D:
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.008
	cyl.bottom_radius = 0.008
	cyl.height = 1.0
	var mi := _attach_mesh(cyl, _make_clean_material(color, 0.65, 0.55), arena_root)
	return mi
