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

func has_two_set_completion() -> bool:
	return false

func is_exercise_completed() -> bool:
	return false

func get_set_display_text() -> String:
	return ""

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

static var _aura_shader: Shader = null
static var _radial_glow_shader: Shader = null
static var _line_flow_shader: Shader = null

static func _get_aura_shader() -> Shader:
	if _aura_shader == null:
		_aura_shader = Shader.new()
		_aura_shader.code = """shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled;

uniform vec4 aura_color : source_color = vec4(0.24, 0.92, 0.68, 1.0);
uniform float intensity = 1.0;
uniform float fresnel_power = 1.8;
uniform float pulse_speed = 2.6;
uniform float rim_invert = 0.0;

void fragment() {
	float ndotv = clamp(abs(dot(normalize(NORMAL), normalize(VIEW))), 0.0, 1.0);
	float edge = mix(pow(1.0 - ndotv, fresnel_power), pow(ndotv, fresnel_power), rim_invert);
	float wave = 0.88 + 0.12 * sin(TIME * pulse_speed + VERTEX.y * 12.0);
	ALBEDO = aura_color.rgb * intensity * wave;
	ALPHA = clamp(aura_color.a * edge * wave, 0.0, 1.0);
}
"""
	return _aura_shader

static func _get_radial_glow_shader() -> Shader:
	if _radial_glow_shader == null:
		_radial_glow_shader = Shader.new()
		_radial_glow_shader.code = """shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled;

uniform vec4 inner_color : source_color = vec4(1.0, 0.90, 0.52, 0.72);
uniform vec4 outer_color : source_color = vec4(0.76, 0.36, 1.0, 0.45);
uniform float intensity = 0.95;

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float r = length(p);
	float ang = atan(p.y, p.x);
	float core = exp(-r * r * 6.5);
	float halo = smoothstep(1.0, 0.18, r) * (0.45 + 0.12 * sin(ang * 6.0 - TIME * 2.4));
	float ring1 = exp(-pow((r - 0.56) * 18.0, 2.0)) * 0.55;
	float ring2 = exp(-pow((r - 0.82) * 16.0, 2.0)) * 0.40;
	vec3 col = mix(outer_color.rgb, inner_color.rgb, clamp(core + ring1 * 0.8, 0.0, 1.0));
	float a = clamp(core * inner_color.a + halo * outer_color.a * 0.42 + ring1 * 0.55 + ring2 * 0.42, 0.0, 1.0);
	ALBEDO = col * intensity;
	ALPHA = a * smoothstep(1.0, 0.88, r);
}
"""
	return _radial_glow_shader

static func _get_line_flow_shader() -> Shader:
	if _line_flow_shader == null:
		_line_flow_shader = Shader.new()
		_line_flow_shader.code = """shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled;

uniform vec4 line_color : source_color = vec4(0.18, 0.84, 1.0, 0.82);
uniform vec4 core_color : source_color = vec4(0.85, 0.98, 1.0, 0.95);
uniform float intensity = 0.95;
uniform float flow_speed = 3.2;

void fragment() {
	float ndotv = clamp(abs(dot(normalize(NORMAL), normalize(VIEW))), 0.0, 1.0);
	float pulse = 0.72 + 0.28 * sin(UV.y * 14.0 - TIME * flow_speed);
	float shimmer = pow(ndotv, 1.2);
	vec3 col = mix(line_color.rgb, core_color.rgb, pow(ndotv, 2.8) * 0.65);
	ALBEDO = col * intensity * pulse;
	ALPHA = clamp(line_color.a * shimmer * pulse, 0.0, 1.0);
}
"""
	return _line_flow_shader

static func create_radial_glow_material(
	inner_col: Color = Color(1.0, 0.90, 0.52, 0.72),
	outer_col: Color = Color(0.76, 0.36, 1.0, 0.45),
	intensity: float = 0.95
) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = _get_radial_glow_shader()
	mat.set_shader_parameter("inner_color", inner_col)
	mat.set_shader_parameter("outer_color", outer_col)
	mat.set_shader_parameter("intensity", intensity)
	return mat

static func create_line_flow_material(
	line_col: Color = Color(0.18, 0.84, 1.0, 0.82),
	intensity: float = 0.95,
	flow_speed: float = 3.2
) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = _get_line_flow_shader()
	mat.set_shader_parameter("line_color", line_col)
	mat.set_shader_parameter("core_color", Color(0.88, 0.98, 1.0, 0.95))
	mat.set_shader_parameter("intensity", intensity)
	mat.set_shader_parameter("flow_speed", flow_speed)
	return mat

static func create_aura_material(
	color: Color,
	alpha: float = 0.45,
	intensity: float = 1.15,
	fresnel_power: float = 1.8,
	pulse_speed: float = 2.6,
	rim_invert: float = 0.0
) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = _get_aura_shader()
	mat.set_shader_parameter("aura_color", Color(color.r, color.g, color.b, alpha))
	mat.set_shader_parameter("intensity", intensity)
	mat.set_shader_parameter("fresnel_power", fresnel_power)
	mat.set_shader_parameter("pulse_speed", pulse_speed)
	mat.set_shader_parameter("rim_invert", rim_invert)
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

static var _soft_fade_shader: Shader = null

static func _get_soft_fade_shader() -> Shader:
	if _soft_fade_shader == null:
		_soft_fade_shader = Shader.new()
		_soft_fade_shader.code = """shader_type spatial;
render_mode unshaded, depth_draw_never, cull_back;

uniform vec4 fade_color : source_color = vec4(1.0, 0.78, 0.32, 0.35);
uniform float pulse_speed = 2.4;

void fragment() {
	float ndotv = clamp(abs(dot(normalize(NORMAL), normalize(VIEW))), 0.0, 1.0);
	float soft_edge = pow(ndotv, 2.2);
	float breath = 0.88 + 0.12 * sin(TIME * pulse_speed);
	ALBEDO = fade_color.rgb;
	ALPHA = clamp(fade_color.a * soft_edge * breath, 0.0, 1.0);
}
"""
	return _soft_fade_shader

static func create_soft_fade_material(color: Color, alpha: float = 0.32, pulse_speed: float = 2.4) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = _get_soft_fade_shader()
	mat.set_shader_parameter("fade_color", Color(color.r, color.g, color.b, alpha))
	mat.set_shader_parameter("pulse_speed", pulse_speed)
	return mat

static func make_thin_torus(ring_radius_m: float, tube_radius_m: float, rings: int = 32, ring_segments: int = 10) -> TorusMesh:
	var torus := TorusMesh.new()
	torus.outer_radius = ring_radius_m + tube_radius_m
	torus.inner_radius = maxf(0.002, ring_radius_m - tube_radius_m)
	torus.rings = rings
	torus.ring_segments = ring_segments
	return torus

func create_glow_orb(radius_m: float, color: Color, alpha: float = 0.90) -> Node3D:
	var root := Node3D.new()

	# Clean, saturated core orb with subtle glow
	var sphere := SphereMesh.new()
	sphere.radius = radius_m * 0.48
	sphere.height = radius_m * 0.96
	sphere.radial_segments = 16
	sphere.rings = 10
	_attach_mesh(sphere, _make_clean_material(color, 0.52, alpha), root)

	# Soft edge-fading hit area halo (normal alpha blend, zero additive glare)
	var fade_sphere := SphereMesh.new()
	fade_sphere.radius = radius_m * 0.88
	fade_sphere.height = radius_m * 1.76
	fade_sphere.radial_segments = 18
	fade_sphere.rings = 12
	_attach_mesh(fade_sphere, create_soft_fade_material(color.lightened(0.15), 0.34, 2.4), root)

	# Single true-thin accent ring
	var torus := make_thin_torus(radius_m * 0.86, 0.003, 28, 8)
	var r_mi := _attach_mesh(torus, _make_clean_material(color.lightened(0.20), 0.48, 0.65), root)
	r_mi.rotation_degrees = Vector3(90.0, 0.0, 0.0)

	if arena_root != null:
		arena_root.add_child(root)
	return root

func create_glow_ring(outer_radius_m: float, inner_radius_m: float, color: Color, alpha: float = 0.78) -> Node3D:
	var root := Node3D.new()
	var tube_r := clampf(inner_radius_m * 0.45, 0.003, 0.008)
	var torus := make_thin_torus(outer_radius_m * 0.86, tube_r, 28, 10)
	var mi := _attach_mesh(torus, _make_clean_material(color, 0.45, alpha), root)
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

func create_target_box(size_m: Vector3, color: Color, alpha: float = 0.88) -> Node3D:
	var root := Node3D.new()
	var base_r := maxf(size_m.x, size_m.y) * 0.56

	var box := BoxMesh.new()
	box.size = size_m * 0.64
	_attach_mesh(box, _make_clean_material(color, 0.50, alpha), root)

	# Soft edge-fading hit area halo around box
	var fade_sphere := SphereMesh.new()
	fade_sphere.radius = base_r * 1.15
	fade_sphere.height = base_r * 2.30
	fade_sphere.radial_segments = 16
	fade_sphere.rings = 10
	_attach_mesh(fade_sphere, create_soft_fade_material(color.lightened(0.15), 0.28, 2.4), root)

	var halo := make_thin_torus(base_r * 0.96, 0.003, 28, 8)
	var halo_mi := _attach_mesh(halo, _make_clean_material(color.lightened(0.20), 0.45, 0.62), root)
	halo_mi.rotation_degrees = Vector3(90.0, 0.0, 0.0)

	if arena_root != null:
		arena_root.add_child(root)
	return root

## Crisp dual-ring shockwave + spinning crystal shards on target hit (non-glaring, zero shadows).
func spawn_hit_vfx(pos_spec: Vector3, accent_color: Color = Color(0.32, 0.85, 0.72)) -> void:
	if arena_root == null or body_frame == null or not arena_root.is_inside_tree():
		return
	var vfx_root := Node3D.new()
	arena_root.add_child(vfx_root)
	vfx_root.global_position = body_frame.to_godot_world(pos_spec)
	vfx_root.rotation.y = body_frame.get_godot_yaw_rad()

	var secondary_col := Color(0.68, 0.42, 0.96)

	# 1. Quick crisp core pop
	var core_mesh := SphereMesh.new()
	core_mesh.radius = 0.026
	core_mesh.height = 0.052
	core_mesh.radial_segments = 10
	core_mesh.rings = 6
	var core_mat := _make_clean_material(accent_color.lightened(0.35), 0.65, 0.75)
	var core_mi := _attach_mesh(core_mesh, core_mat, vfx_root)

	# 2. Dual shockwave ripple rings (outer accent + inner violet)
	var ring1 := make_thin_torus(0.045, 0.003, 28, 8)
	var mat1 := _make_clean_material(accent_color, 0.58, 0.80)
	var ring1_mi := _attach_mesh(ring1, mat1, vfx_root)
	ring1_mi.rotation_degrees = Vector3(90.0, 0.0, 0.0)

	var ring2 := make_thin_torus(0.036, 0.0025, 24, 8)
	var mat2 := _make_clean_material(secondary_col, 0.52, 0.70)
	var ring2_mi := _attach_mesh(ring2, mat2, vfx_root)
	ring2_mi.rotation_degrees = Vector3(68.0, 24.0, 0.0)

	# 3. 10 spinning diamond crystal shards bursting outward
	var shard_mesh := BoxMesh.new()
	shard_mesh.size = Vector3(0.006, 0.016, 0.006)
	var shard_mat_a := _make_clean_material(accent_color.lightened(0.25), 0.60, 0.85)
	var shard_mat_b := _make_clean_material(secondary_col.lightened(0.20), 0.55, 0.80)

	var tw := vfx_root.create_tween()
	tw.set_parallel(true)
	tw.tween_property(core_mi, "scale", Vector3.ONE * 0.05, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(core_mat, "albedo_color:a", 0.0, 0.16)

	tw.tween_property(ring1_mi, "scale", Vector3.ONE * 2.35, 0.32).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(mat1, "albedo_color:a", 0.0, 0.32)

	tw.tween_property(ring2_mi, "scale", Vector3.ONE * 2.05, 0.36).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(ring2_mi, "rotation_degrees:z", 95.0, 0.36)
	tw.tween_property(mat2, "albedo_color:a", 0.0, 0.36)

	tw.tween_property(shard_mat_a, "albedo_color:a", 0.0, 0.38)
	tw.tween_property(shard_mat_b, "albedo_color:a", 0.0, 0.38)

	for i in range(10):
		var ang := float(i) * (TAU / 10.0)
		var elev := 0.35 if (i % 2 == 0) else -0.25
		var dir := Vector3(cos(ang), sin(ang), elev).normalized()
		var s_mi := _attach_mesh(shard_mesh, shard_mat_a if (i % 2 == 0) else shard_mat_b, vfx_root)
		s_mi.rotation_degrees = Vector3(float(i) * 36.0, float(i) * 24.0, 45.0)
		var dist := 0.13 + (0.04 if (i % 3 == 0) else 0.0)
		tw.tween_property(s_mi, "position", dir * dist, 0.38).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tw.tween_property(s_mi, "rotation_degrees:y", s_mi.rotation_degrees.y + 180.0, 0.38)
		tw.tween_property(s_mi, "scale", Vector3.ONE * 0.08, 0.38)

	tw.chain().tween_callback(vfx_root.queue_free)

## Inward lock-on pulse ring when hand primes a start zone.
func spawn_prime_vfx(pos_spec: Vector3, accent_color: Color = Color(0.95, 0.84, 0.42)) -> void:
	if arena_root == null or body_frame == null or not arena_root.is_inside_tree():
		return
	var vfx_root := Node3D.new()
	arena_root.add_child(vfx_root)
	vfx_root.global_position = body_frame.to_godot_world(pos_spec)
	vfx_root.rotation.y = body_frame.get_godot_yaw_rad()

	var ring := make_thin_torus(0.065, 0.003, 24, 8)
	var mat := _make_clean_material(accent_color, 0.50, 0.75)
	var ring_mi := _attach_mesh(ring, mat, vfx_root)
	ring_mi.rotation_degrees = Vector3(90.0, 0.0, 0.0)
	ring_mi.scale = Vector3.ONE * 1.55

	var tw := vfx_root.create_tween()
	tw.set_parallel(true)
	tw.tween_property(ring_mi, "scale", Vector3.ONE * 0.45, 0.22).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(mat, "albedo_color:a", 0.0, 0.22)
	tw.chain().tween_callback(vfx_root.queue_free)

## Japanese dojo golden & sakura energy celebration burst for Set Complete / Exercise Complete.
func spawn_celebration_vfx(is_final_complete: bool = false) -> void:
	if arena_root == null or body_frame == null or not arena_root.is_inside_tree():
		return
	var vfx_root := Node3D.new()
	arena_root.add_child(vfx_root)
	vfx_root.global_position = body_frame.to_godot_world(Vector3(0.0, 0.08, 0.55))
	vfx_root.rotation.y = body_frame.get_godot_yaw_rad()

	var gold_col := Color(0.98, 0.82, 0.32)
	var sakura_col := Color(0.96, 0.58, 0.72)
	var mint_col := Color(0.32, 0.88, 0.74)

	# Expanding celebration halo ring
	var halo := make_thin_torus(0.14, 0.004, 32, 8)
	var halo_mat := _make_clean_material(gold_col if is_final_complete else mint_col, 0.55, 0.78)
	var halo_mi := _attach_mesh(halo, halo_mat, vfx_root)
	halo_mi.rotation_degrees = Vector3(90.0, 0.0, 0.0)

	var petal_mesh := BoxMesh.new()
	petal_mesh.size = Vector3(0.014, 0.004, 0.022)
	var mat_gold := _make_clean_material(gold_col, 0.55, 0.90)
	var mat_sakura := _make_clean_material(sakura_col, 0.48, 0.88)
	var mat_mint := _make_clean_material(mint_col, 0.50, 0.88)

	var count := 18 if is_final_complete else 12
	var dur := 0.95 if is_final_complete else 0.72

	var tw := vfx_root.create_tween()
	tw.set_parallel(true)
	tw.tween_property(halo_mi, "scale", Vector3.ONE * (3.2 if is_final_complete else 2.4), dur * 0.65).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(halo_mat, "albedo_color:a", 0.0, dur * 0.65)
	tw.tween_property(mat_gold, "albedo_color:a", 0.0, dur)
	tw.tween_property(mat_sakura, "albedo_color:a", 0.0, dur)
	tw.tween_property(mat_mint, "albedo_color:a", 0.0, dur)

	for i in range(count):
		var ang := float(i) * (TAU / float(count))
		var mat_pick := mat_gold if (i % 3 == 0) else (mat_sakura if (i % 3 == 1) else mat_mint)
		var p_mi := _attach_mesh(petal_mesh, mat_pick, vfx_root)
		p_mi.rotation_degrees = Vector3(float(i) * 28.0, float(i) * 42.0, 20.0)
		var spread := (0.36 if is_final_complete else 0.26) + (0.08 if (i % 2 == 0) else 0.0)
		var rise := 0.22 + 0.14 * sin(float(i) * 1.3)
		var target_pos := Vector3(cos(ang) * spread, rise, sin(ang) * 0.14)
		tw.tween_property(p_mi, "position", target_pos, dur).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tw.tween_property(p_mi, "rotation_degrees", p_mi.rotation_degrees + Vector3(210.0, 260.0, 140.0), dur)
		tw.tween_property(p_mi, "scale", Vector3.ONE * 0.2, dur)

	tw.chain().tween_callback(vfx_root.queue_free)
