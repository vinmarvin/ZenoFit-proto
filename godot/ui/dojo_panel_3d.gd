class_name DojoPanel3D
extends Node3D

## Reusable interactive 3D VR UI Panel (Beat-Saber-style dark glass panel rendered via SubViewport + QuadMesh).
## Supports zero-lag pure-math ray-quad intersection so both Desktop Mouse and VR Controller/Hand rays
## can hover and click real Godot Control buttons floating in 3D Zen Dojo space.

var panel_width_m: float = 1.10
var panel_height_m: float = 0.78
var viewport_px: Vector2i = Vector2i(760, 540)

var sub_viewport: SubViewport
var mesh_instance: MeshInstance3D
var _quad_mesh: QuadMesh
var _material: StandardMaterial3D
var _root_panel: PanelContainer
var _content_vbox: VBoxContainer
var _last_vp_pos: Vector2 = Vector2.ZERO
var _is_hovered: bool = false

func setup_panel(
	p_width_m: float,
	p_height_m: float,
	p_px_size: Vector2i,
	accent_color: Color = Color(0.22, 0.85, 0.72)
) -> VBoxContainer:
	panel_width_m = p_width_m
	panel_height_m = p_height_m
	viewport_px = p_px_size

	if sub_viewport == null:
		sub_viewport = SubViewport.new()
		sub_viewport.name = "UISubViewport"
		sub_viewport.transparent_bg = true
		sub_viewport.handle_input_locally = true
		sub_viewport.gui_embed_subwindows = true
		sub_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		add_child(sub_viewport)

		_root_panel = PanelContainer.new()
		_root_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
		_root_panel.add_theme_stylebox_override("panel", make_glass_panel_style(accent_color))
		sub_viewport.add_child(_root_panel)

		var margin := MarginContainer.new()
		margin.add_theme_constant_override("margin_left", 22)
		margin.add_theme_constant_override("margin_right", 22)
		margin.add_theme_constant_override("margin_top", 18)
		margin.add_theme_constant_override("margin_bottom", 18)
		_root_panel.add_child(margin)

		_content_vbox = VBoxContainer.new()
		_content_vbox.add_theme_constant_override("separation", 10)
		margin.add_child(_content_vbox)

	sub_viewport.size = viewport_px
	_root_panel.size = Vector2(viewport_px)
	_root_panel.custom_minimum_size = Vector2(viewport_px)

	if mesh_instance == null:
		mesh_instance = MeshInstance3D.new()
		mesh_instance.name = "PanelQuad"
		mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_quad_mesh = QuadMesh.new()
		mesh_instance.mesh = _quad_mesh

		_material = StandardMaterial3D.new()
		_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_material.cull_mode = BaseMaterial3D.CULL_DISABLED
		_material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
		_material.albedo_texture = sub_viewport.get_texture()
		mesh_instance.material_override = _material
		add_child(mesh_instance)

	_quad_mesh.size = Vector2(panel_width_m, panel_height_m)
	return _content_vbox

func set_panel_dimensions(p_width_m: float, p_height_m: float, p_px_size: Vector2i) -> void:
	panel_width_m = p_width_m
	panel_height_m = p_height_m
	viewport_px = p_px_size
	if _quad_mesh != null:
		_quad_mesh.size = Vector2(panel_width_m, panel_height_m)
	if sub_viewport != null:
		sub_viewport.size = viewport_px
	if _root_panel != null:
		_root_panel.size = Vector2(viewport_px)
		_root_panel.custom_minimum_size = Vector2(viewport_px)

func clear_content() -> void:
	if _content_vbox == null:
		return
	for c in _content_vbox.get_children():
		_content_vbox.remove_child(c)
		c.queue_free()

func get_content_box() -> VBoxContainer:
	return _content_vbox

## Pure mathematical ray-quad intersection against local Z=0 plane.
## Returns {hit: bool, distance: float, world_pos: Vector3, viewport_pos: Vector2}.
func intersect_ray(ray_origin: Vector3, ray_dir: Vector3) -> Dictionary:
	if not visible:
		return {"hit": false}
	var xform := global_transform if is_inside_tree() else transform
	var inv := xform.affine_inverse()
	var local_o := inv * ray_origin
	var local_d := (inv.basis * ray_dir).normalized()
	if absf(local_d.z) < 1e-5:
		return {"hit": false}
	var t := -local_o.z / local_d.z
	if t <= 0.05 or t > 6.0:
		return {"hit": false}
	var hit_local := local_o + local_d * t
	if absf(hit_local.x) > panel_width_m * 0.5 or absf(hit_local.y) > panel_height_m * 0.5:
		return {"hit": false}

	var u := clampf((hit_local.x / maxf(0.01, panel_width_m)) + 0.5, 0.0, 1.0)
	var v := clampf(0.5 - (hit_local.y / maxf(0.01, panel_height_m)), 0.0, 1.0)
	var vp_pos := Vector2(u * float(viewport_px.x), v * float(viewport_px.y))
	return {
		"hit": true,
		"distance": t,
		"world_pos": xform * hit_local,
		"viewport_pos": vp_pos
	}

func push_pointer_motion(vp_pos: Vector2) -> void:
	if sub_viewport == null:
		return
	var ev := InputEventMouseMotion.new()
	ev.position = vp_pos
	ev.global_position = vp_pos
	ev.relative = vp_pos - _last_vp_pos
	_last_vp_pos = vp_pos
	_is_hovered = true
	sub_viewport.push_input(ev)

func push_pointer_exit() -> void:
	if sub_viewport == null or not _is_hovered:
		return
	_is_hovered = false
	var ev := InputEventMouseMotion.new()
	ev.position = Vector2(-10.0, -10.0)
	ev.global_position = Vector2(-10.0, -10.0)
	sub_viewport.push_input(ev)

func push_pointer_button(vp_pos: Vector2, pressed: bool) -> void:
	if sub_viewport == null:
		return
	push_pointer_motion(vp_pos)
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.pressed = pressed
	ev.position = vp_pos
	ev.global_position = vp_pos
	ev.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
	sub_viewport.push_input(ev)

# ==============================================================================
# Beat-Saber / Zen-Dojo UI Theme Builders
# ==============================================================================

static func make_glass_panel_style(accent: Color = Color(0.22, 0.85, 0.72)) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.09, 0.13, 0.90)
	sb.border_color = Color(accent.r, accent.g, accent.b, 0.78)
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(18)
	return sb

static func make_banner_header(title: String, accent: Color, font_size: int = 24) -> PanelContainer:
	var p := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(accent.r, accent.g, accent.b, 0.92)
	sb.set_corner_radius_all(10)
	sb.content_margin_left = 14
	sb.content_margin_right = 14
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	p.add_theme_stylebox_override("panel", sb)

	var lbl := Label.new()
	lbl.text = title
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.add_theme_color_override("font_color", Color(0.04, 0.08, 0.10))
	p.add_child(lbl)
	return p

static func make_styled_button(
	text: String,
	callback: Callable,
	accent: Color = Color(0.18, 0.62, 0.56),
	font_size: int = 20,
	min_height: float = 48.0,
	is_selected: bool = false
) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0.0, min_height)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.add_theme_font_size_override("font_size", font_size)
	b.add_theme_color_override("font_color", Color(0.96, 0.99, 0.98))
	b.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0))

	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(accent.r, accent.g, accent.b, 0.88 if is_selected else 0.42)
	normal.border_color = Color(accent.r, accent.g, accent.b, 1.0 if is_selected else 0.72)
	normal.set_border_width_all(3 if is_selected else 2)
	normal.set_corner_radius_all(10)
	normal.content_margin_left = 12
	normal.content_margin_right = 12
	normal.content_margin_top = 8
	normal.content_margin_bottom = 8

	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color(minf(1.0, accent.r + 0.15), minf(1.0, accent.g + 0.15), minf(1.0, accent.b + 0.15), 0.92)
	hover.border_color = Color(1.0, 1.0, 1.0, 0.95)
	hover.set_border_width_all(3)

	var pressed_sb := normal.duplicate() as StyleBoxFlat
	pressed_sb.bg_color = Color(accent.r * 0.75, accent.g * 0.75, accent.b * 0.75, 0.96)

	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", pressed_sb)
	b.add_theme_stylebox_override("focus", hover)
	b.pressed.connect(callback)
	return b
