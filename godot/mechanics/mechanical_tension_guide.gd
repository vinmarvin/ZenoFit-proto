class_name MechanicalTensionGuide
extends RefCounted

## 3D Mechanical Tension Line/Zone guide and proximity evaluator.
## Distinct from regular Target Hit / Box Hit props: renders a continuous glowing
## movement corridor, translucent tolerance markers, and an animated directional flow bead.
## All coordinates live in BodyFrame SpecSpace and adapt to the user's seated calibration.

const COL_GOOD := Color(0.18, 0.84, 1.0)
const COL_IDLE := Color(0.28, 0.72, 0.96)
const COL_WARN := Color(1.0, 0.36, 0.28)

const TEMPO_UP_S: float = 1.0
const TEMPO_HOLD_S: float = 0.6
const TEMPO_DOWN_S: float = 2.0
const TEMPO_CYCLE_S: float = TEMPO_UP_S + TEMPO_HOLD_S + TEMPO_DOWN_S

var _arena_root: Node3D = null
var _body_frame: BodyFrame = null
var _root: Node3D = null
var _path_mat: StandardMaterial3D = null
var _bead_mat: StandardMaterial3D = null
var _flow_bead: Node3D = null
var _smooth_curve: Array[Vector3] = []

var _is_circle: bool = false
var _circle_plane: String = "xy"
var _waypoints_spec: Array[Vector3] = []
var _circle_center_spec: Vector3 = Vector3.ZERO
var _circle_radius_m: float = 0.16
var _flow_phase: float = 0.0
var _tempo_clock_s: float = 0.0
var _pulse_time: float = 0.0

func setup_polyline(
	arena_root: Node3D,
	body_frame: BodyFrame,
	waypoints_spec: Array[Vector3],
	tolerance_m: float
) -> void:
	retire()
	_arena_root = arena_root
	_body_frame = body_frame
	_is_circle = false
	_waypoints_spec = waypoints_spec.duplicate()
	_flow_phase = 0.0
	_pulse_time = 0.0
	_create_materials()
	_build_root()

	if _waypoints_spec.size() < 2 or _body_frame == null:
		return

	# Subdivide waypoints into a smooth Catmull-Rom curve so the line is fluid, not rigid
	_smooth_curve = _subdivide_smooth_curve(_waypoints_spec, 24)

	# Build extra-thin, crisp glowing line
	for i in range(_smooth_curve.size() - 1):
		var a_world := _body_frame.to_godot_world(_smooth_curve[i])
		var b_world := _body_frame.to_godot_world(_smooth_curve[i + 1])
		_add_segment_mesh(a_world, b_world, 0.0025, _path_mat)

	# Small clean end-caps at start/end bounds
	for end_pt in [_waypoints_spec[0], _waypoints_spec[_waypoints_spec.size() - 1]]:
		var cap := SphereMesh.new()
		cap.radius = 0.007
		cap.height = 0.014
		cap.radial_segments = 10
		cap.rings = 6
		var cap_mi := _attach_mesh(cap, _path_mat)
		cap_mi.position = _body_frame.to_godot_world(end_pt)

	_create_flow_bead()
	_update_bead_position(0.0)

func setup_circle(
	arena_root: Node3D,
	body_frame: BodyFrame,
	center_spec: Vector3,
	radius_m: float,
	tolerance_m: float,
	plane: String = "xy"
) -> void:
	retire()
	_arena_root = arena_root
	_body_frame = body_frame
	_is_circle = true
	_circle_plane = plane
	_circle_center_spec = center_spec
	_circle_radius_m = maxf(0.08, radius_m)
	_flow_phase = 0.0
	_tempo_clock_s = 0.0
	_pulse_time = 0.0
	_create_materials()
	_build_root()

	if _body_frame == null:
		return

	var center_world := _body_frame.to_godot_world(_circle_center_spec)
	var yaw_rad := _body_frame.get_godot_yaw_rad()

	# Extra-thin, crisp glowing tension ring aligned cleanly to XY or YZ plane
	var core_torus := MechanicBase.make_thin_torus(_circle_radius_m, 0.003, 40, 10)
	var core_mi := _attach_mesh(core_torus, _path_mat)
	core_mi.position = center_world
	if _circle_plane == "yz":
		core_mi.basis = Basis(Vector3.UP, yaw_rad) * Basis(Vector3.FORWARD, deg_to_rad(90.0))
	else:
		core_mi.basis = Basis(Vector3.UP, yaw_rad) * Basis(Vector3.RIGHT, deg_to_rad(90.0))

	_create_flow_bead()
	_update_bead_position(0.0)

func evaluate_hand(hand_pos_spec: Vector3, tolerance_m: float) -> Dictionary:
	if _is_circle:
		return _evaluate_circle_hand(hand_pos_spec, tolerance_m)
	return _evaluate_polyline_hand(hand_pos_spec, tolerance_m)

func _evaluate_polyline_hand(hand_pos_spec: Vector3, tolerance_m: float) -> Dictionary:
	if _waypoints_spec.size() < 2:
		return {"in_zone": true, "distance_m": 0.0, "closest_spec": hand_pos_spec, "progress_t": 0.0, "tension_ratio": 1.0}

	var best_dist := INF
	var best_pt := _waypoints_spec[0]
	var best_seg_idx := 0
	var best_seg_t := 0.0
	var total_len := 0.0
	var seg_lengths: Array[float] = []

	for i in range(_waypoints_spec.size() - 1):
		var a := _waypoints_spec[i]
		var b := _waypoints_spec[i + 1]
		var seg_len := a.distance_to(b)
		seg_lengths.append(seg_len)
		total_len += seg_len

		var closest := Geometry3D.get_closest_point_to_segment(hand_pos_spec, a, b)
		var d := hand_pos_spec.distance_to(closest)
		if d < best_dist:
			best_dist = d
			best_pt = closest
			best_seg_idx = i
			best_seg_t = (a.distance_to(closest) / seg_len) if seg_len > 1e-5 else 0.0

	var accum_len := 0.0
	for i in range(best_seg_idx):
		accum_len += seg_lengths[i]
	accum_len += seg_lengths[best_seg_idx] * best_seg_t
	var progress_t := clampf(accum_len / maxf(1e-5, total_len), 0.0, 1.0)
	var in_zone := best_dist <= tolerance_m + 1e-5
	var ratio := clampf(1.0 - (best_dist / maxf(0.01, tolerance_m)), 0.0, 1.0)

	return {
		"in_zone": in_zone,
		"distance_m": best_dist,
		"closest_spec": best_pt,
		"progress_t": progress_t,
		"tension_ratio": ratio
	}

func _evaluate_circle_hand(hand_pos_spec: Vector3, tolerance_m: float) -> Dictionary:
	var rel := hand_pos_spec - _circle_center_spec
	var plane_vec := Vector2(rel.z, rel.y) if _circle_plane == "yz" else Vector2(rel.x, rel.y)
	var plane_err := absf(rel.x) if _circle_plane == "yz" else absf(rel.z)
	var radial := plane_vec.length()
	var radial_err := absf(radial - _circle_radius_m)
	var dist := sqrt(radial_err * radial_err + plane_err * plane_err)
	var ang := atan2(plane_vec.y, plane_vec.x)
	var progress_t := fposmod(ang, TAU) / TAU
	var in_zone := dist <= tolerance_m + 1e-5
	var ratio := clampf(1.0 - (dist / maxf(0.01, tolerance_m)), 0.0, 1.0)

	var dir_2d := plane_vec.normalized() if radial > 1e-4 else Vector2(1.0, 0.0)
	var closest := _circle_center_spec + (
		Vector3(0.0, dir_2d.y * _circle_radius_m, dir_2d.x * _circle_radius_m)
		if _circle_plane == "yz"
		else Vector3(dir_2d.x * _circle_radius_m, dir_2d.y * _circle_radius_m, 0.0)
	)

	return {
		"in_zone": in_zone,
		"distance_m": dist,
		"closest_spec": closest,
		"progress_t": progress_t,
		"tension_ratio": ratio
	}

func get_tempo_phase_label() -> String:
	if _tempo_clock_s < TEMPO_UP_S:
		return "Lift (1s)"
	elif _tempo_clock_s < TEMPO_UP_S + TEMPO_HOLD_S:
		return "Contract!"
	return "Lower slowly (2s)"

func update_visual_feedback(dt: float, in_zone: bool, reverse_flow: bool = false, is_active: bool = true, use_tempo_cycle: bool = false) -> void:
	_pulse_time += dt
	var is_contracting := false
	if use_tempo_cycle and not _is_circle:
		_tempo_clock_s = fposmod(_tempo_clock_s + dt, TEMPO_CYCLE_S)
		if _tempo_clock_s < TEMPO_UP_S:
			_flow_phase = _tempo_clock_s / TEMPO_UP_S
		elif _tempo_clock_s < TEMPO_UP_S + TEMPO_HOLD_S:
			_flow_phase = 1.0
			is_contracting = true
		else:
			var down_t := (_tempo_clock_s - TEMPO_UP_S - TEMPO_HOLD_S) / TEMPO_DOWN_S
			_flow_phase = 1.0 - clampf(down_t, 0.0, 1.0)
	else:
		var flow_speed := 0.72 if not _is_circle else 0.55
		var dir := -1.0 if reverse_flow else 1.0
		_flow_phase = fposmod(_flow_phase + dt * flow_speed * dir, 1.0)
	_update_bead_position(_flow_phase)

	if _flow_bead != null:
		var bead_scale := (1.28 + 0.12 * sin(_pulse_time * 10.0)) if is_contracting else 1.0
		_flow_bead.scale = Vector3.ONE * bead_scale

	if _path_mat != null and _bead_mat != null:
		var target_col := COL_GOOD if in_zone else COL_WARN
		if not is_active:
			target_col = COL_IDLE
		var warn_pulse := 0.50 + 0.22 * absf(sin(_pulse_time * 6.0))
		_path_mat.albedo_color = Color(target_col.r, target_col.g, target_col.b, 0.80)
		_path_mat.emission = target_col
		_path_mat.emission_energy_multiplier = 0.58 if in_zone else warn_pulse

		_bead_mat.albedo_color = Color(0.95, 0.99, 1.0, 0.95) if in_zone else Color(1.0, 0.78, 0.62, 0.95)
		_bead_mat.emission = target_col
		_bead_mat.emission_energy_multiplier = 0.72 if is_contracting else 0.55

func retire() -> void:
	if _root != null:
		if _root.is_inside_tree():
			_root.queue_free()
		else:
			if _root.get_parent() != null:
				_root.get_parent().remove_child(_root)
			_root.free()
		_root = null
	_flow_bead = null
	_smooth_curve.clear()

func _create_materials() -> void:
	_path_mat = StandardMaterial3D.new()
	_path_mat.albedo_color = Color(COL_IDLE.r, COL_IDLE.g, COL_IDLE.b, 0.85)
	_path_mat.roughness = 0.35
	_path_mat.emission_enabled = true
	_path_mat.emission = COL_IDLE
	_path_mat.emission_energy_multiplier = 0.45
	_path_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

	_bead_mat = StandardMaterial3D.new()
	_bead_mat.albedo_color = Color(0.95, 0.99, 1.0, 0.96)
	_bead_mat.roughness = 0.25
	_bead_mat.emission_enabled = true
	_bead_mat.emission = COL_GOOD
	_bead_mat.emission_energy_multiplier = 0.50
	_bead_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

func _subdivide_smooth_curve(pts: Array[Vector3], steps: int) -> Array[Vector3]:
	if pts.size() <= 2 or steps <= 1:
		return pts.duplicate()
	var out: Array[Vector3] = []
	for s in range(steps + 1):
		var u := (float(s) / float(steps)) * float(pts.size() - 1)
		var idx := mini(pts.size() - 2, int(floor(u)))
		var t := u - float(idx)
		var p0 := pts[maxi(0, idx - 1)]
		var p1 := pts[idx]
		var p2 := pts[idx + 1]
		var p3 := pts[mini(pts.size() - 1, idx + 2)]
		var t2 := t * t
		var t3 := t2 * t
		var pos := 0.5 * (
			(2.0 * p1)
			+ (-p0 + p2) * t
			+ (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t2
			+ (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t3
		)
		out.append(pos)
	return out

func _build_root() -> void:
	_root = Node3D.new()
	_root.name = "MechanicalTensionGuide"
	if _arena_root != null:
		_arena_root.add_child(_root)

func _attach_mesh(mesh: Mesh, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.material_override = mat
	if _root != null:
		_root.add_child(mi)
	return mi

func _add_segment_mesh(a_world: Vector3, b_world: Vector3, radius_m: float, mat: Material) -> void:
	var length := a_world.distance_to(b_world)
	if length < 0.002:
		return
	var cyl := CylinderMesh.new()
	cyl.top_radius = radius_m
	cyl.bottom_radius = radius_m
	cyl.height = length
	cyl.radial_segments = 10
	var mi := _attach_mesh(cyl, mat)
	mi.position = (a_world + b_world) * 0.5
	var dir := (b_world - a_world).normalized()
	if absf(dir.dot(Vector3.UP)) > 0.999:
		if dir.y < 0.0:
			mi.rotation_degrees = Vector3(180.0, 0.0, 0.0)
	else:
		var axis := Vector3.UP.cross(dir).normalized()
		var angle := acos(clampf(Vector3.UP.dot(dir), -1.0, 1.0))
		mi.basis = Basis(axis, angle)

func _create_flow_bead() -> void:
	var sphere := SphereMesh.new()
	sphere.radius = 0.011
	sphere.height = 0.022
	sphere.radial_segments = 14
	sphere.rings = 10
	_flow_bead = _attach_mesh(sphere, _bead_mat)

func _sample_pos_and_tangent(t: float) -> Dictionary:
	var tc := clampf(t, 0.0, 1.0)
	if _is_circle:
		var ang := tc * TAU
		if _circle_plane == "yz":
			return {
				"pos": _circle_center_spec + Vector3(0.0, sin(ang) * _circle_radius_m, cos(ang) * _circle_radius_m),
				"dir": Vector3(0.0, cos(ang), -sin(ang)).normalized()
			}
		return {
			"pos": _circle_center_spec + Vector3(cos(ang) * _circle_radius_m, sin(ang) * _circle_radius_m, 0.0),
			"dir": Vector3(-sin(ang), cos(ang), 0.0).normalized()
		}
	var pts := _smooth_curve if _smooth_curve.size() >= 2 else _waypoints_spec
	if pts.size() >= 2:
		var seg_count := pts.size() - 1
		var scaled := tc * float(seg_count)
		var idx := mini(seg_count - 1, int(floor(scaled)))
		var frac := scaled - float(idx)
		return {
			"pos": pts[idx].lerp(pts[idx + 1], frac),
			"dir": (pts[idx + 1] - pts[idx]).normalized()
		}
	return {"pos": Vector3.ZERO, "dir": Vector3.UP}

func _update_bead_position(t: float) -> void:
	if _flow_bead == null or _body_frame == null:
		return
	var sample := _sample_pos_and_tangent(t)
	_flow_bead.position = _body_frame.to_godot_world(sample["pos"])

