class_name DojoPanel3D
extends Node3D

## Spatial Product System 3D Glass Panel (UI.pdf Dark-Sage Glassmorphism via SubViewport + QuadMesh).
## Supports ray-quad pointer intersection for both Desktop Mouse and XR Controller/Hand rays.

const COL_BG_GLASS := Color(0.08, 0.12, 0.10, 0.86)
const COL_BORDER := Color(0.30, 0.44, 0.37, 0.72)
const COL_CARD_BG := Color(0.11, 0.16, 0.13, 0.84)
const COL_CARD_BORDER := Color(0.28, 0.42, 0.35, 0.56)
const COL_PRIMARY := Color(0.76, 0.87, 0.75, 0.96)
const COL_PRIMARY_TEXT := Color(0.07, 0.12, 0.09)
const COL_SELECTED := Color(0.20, 0.48, 0.43, 0.92)
const COL_DESTRUCTIVE := Color(0.38, 0.17, 0.19, 0.88)
const COL_DESTRUCTIVE_BORDER := Color(0.74, 0.36, 0.38, 0.78)
const COL_TEXT_MAIN := Color(0.94, 0.97, 0.95)
const COL_TEXT_MUTED := Color(0.68, 0.77, 0.72)
const COL_ACCENT_TEAL := Color(0.45, 0.82, 0.74)

var panel_width_m: float = 1.28
var panel_height_m: float = 0.74
var viewport_px: Vector2i = Vector2i(1280, 740)

var sub_viewport: SubViewport
var mesh_instance: MeshInstance3D
var _quad_mesh: QuadMesh
var _material: StandardMaterial3D
var _root_panel: PanelContainer
var _content_vbox: VBoxContainer
var _last_vp_pos: Vector2 = Vector2.ZERO
var _is_hovered: bool = false
var _border_col: Color = COL_BORDER

func _rebuild_root_container() -> void:
	if sub_viewport == null:
		return
	if _root_panel != null:
		if _root_panel.get_parent() != null:
			_root_panel.get_parent().remove_child(_root_panel)
		_root_panel.queue_free()
		_root_panel = null
		_content_vbox = null

	_root_panel = PanelContainer.new()
	_root_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_root_panel.custom_minimum_size = Vector2.ZERO
	_root_panel.clip_contents = true
	_root_panel.add_theme_stylebox_override("panel", make_glass_panel_style(_border_col))
	sub_viewport.add_child(_root_panel)

	var pad_x := 20 if viewport_px.y <= 140 else (24 if viewport_px.y <= 240 else 28)
	var pad_y := 8 if viewport_px.y <= 140 else (14 if viewport_px.y <= 240 else 22)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", pad_x)
	margin.add_theme_constant_override("margin_right", pad_x)
	margin.add_theme_constant_override("margin_top", pad_y)
	margin.add_theme_constant_override("margin_bottom", pad_y)
	_root_panel.add_child(margin)

	_content_vbox = VBoxContainer.new()
	_content_vbox.add_theme_constant_override("separation", 8 if viewport_px.y <= 240 else 12)
	margin.add_child(_content_vbox)

	_root_panel.position = Vector2.ZERO
	_root_panel.size = Vector2(viewport_px)

func setup_panel(
	p_width_m: float,
	p_height_m: float,
	p_px_size: Vector2i,
	border_col: Color = COL_BORDER
) -> VBoxContainer:
	panel_width_m = p_width_m
	panel_height_m = p_height_m
	viewport_px = p_px_size
	_border_col = border_col

	if sub_viewport == null:
		sub_viewport = SubViewport.new()
		sub_viewport.name = "UISubViewport"
		sub_viewport.transparent_bg = true
		sub_viewport.handle_input_locally = true
		sub_viewport.gui_embed_subwindows = true
		sub_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		add_child(sub_viewport)

	sub_viewport.size = viewport_px
	_rebuild_root_container()

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
	_rebuild_root_container()

func get_root_panel_size() -> Vector2:
	return _root_panel.size if _root_panel != null else Vector2.ZERO

func get_content_min_size() -> Vector2:
	return _root_panel.get_combined_minimum_size() if _root_panel != null else Vector2.ZERO

func clear_content() -> void:
	if _content_vbox == null:
		return
	for c in _content_vbox.get_children():
		_content_vbox.remove_child(c)
		c.queue_free()

func get_content_box() -> VBoxContainer:
	return _content_vbox

func intersect_ray(ray_origin: Vector3, ray_dir: Vector3) -> Dictionary:
	if not visible:
		return {"hit": false}
	var xform := global_transform if is_inside_tree() else transform
	var inv := xform.affine_inverse()
	var local_o := inv * ray_origin
	var local_d := inv.basis * ray_dir.normalized()
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
# UI.pdf Dark-Sage Glassmorphism Design System Builders
# ==============================================================================

static func make_glass_panel_style(border_col: Color = COL_BORDER) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = COL_BG_GLASS
	sb.border_color = border_col
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(24)
	return sb

static func make_card_panel(bg: Color = COL_CARD_BG, border: Color = COL_CARD_BORDER, pad_x: int = 18, pad_y: int = 14) -> PanelContainer:
	var p := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(16)
	sb.content_margin_left = pad_x
	sb.content_margin_right = pad_x
	sb.content_margin_top = pad_y
	sb.content_margin_bottom = pad_y
	p.add_theme_stylebox_override("panel", sb)
	return p

static func make_label(text: String, font_size: int = 18, color: Color = COL_TEXT_MAIN, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.horizontal_alignment = align
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.add_theme_color_override("font_color", color)
	return lbl

static func make_section_eyebrow(text: String, color: Color = COL_ACCENT_TEAL) -> Label:
	var lbl := make_label(text.to_upper(), 13, color, HORIZONTAL_ALIGNMENT_LEFT)
	return lbl

static func make_pill_badge(text: String, bg: Color = Color(0.14, 0.22, 0.18, 0.90), text_col: Color = COL_ACCENT_TEAL) -> PanelContainer:
	var p := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = Color(text_col.r, text_col.g, text_col.b, 0.40)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(99)
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 4
	sb.content_margin_bottom = 4
	p.add_theme_stylebox_override("panel", sb)
	var lbl := make_label(text, 14, text_col, HORIZONTAL_ALIGNMENT_CENTER)
	lbl.autowrap_mode = TextServer.AUTOWRAP_OFF
	p.add_child(lbl)
	return p

static func make_metric_tile(eyebrow: String, value_text: String, sub_text: String = "") -> PanelContainer:
	var card := make_card_panel(COL_CARD_BG, COL_CARD_BORDER, 16, 12)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 4)
	card.add_child(vb)
	var ey := make_section_eyebrow(eyebrow, COL_TEXT_MUTED)
	ey.autowrap_mode = TextServer.AUTOWRAP_OFF
	vb.add_child(ey)
	var val_lbl := make_label(value_text, 28, COL_TEXT_MAIN, HORIZONTAL_ALIGNMENT_LEFT)
	val_lbl.autowrap_mode = TextServer.AUTOWRAP_OFF
	vb.add_child(val_lbl)
	if not sub_text.is_empty():
		vb.add_child(make_label(sub_text, 14, COL_ACCENT_TEAL, HORIZONTAL_ALIGNMENT_LEFT))
	return card

static func make_progress_bar(ratio: float, bar_color: Color = COL_PRIMARY, height_px: float = 8.0) -> ProgressBar:
	var pb := ProgressBar.new()
	pb.min_value = 0.0
	pb.max_value = 100.0
	pb.value = clampf(ratio * 100.0, 0.0, 100.0)
	pb.show_percentage = false
	pb.custom_minimum_size = Vector2(0.0, height_px)
	pb.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var bg_sb := StyleBoxFlat.new()
	bg_sb.bg_color = Color(0.16, 0.22, 0.19, 0.85)
	bg_sb.set_corner_radius_all(6)
	var fill_sb := StyleBoxFlat.new()
	fill_sb.bg_color = bar_color
	fill_sb.set_corner_radius_all(6)
	pb.add_theme_stylebox_override("background", bg_sb)
	pb.add_theme_stylebox_override("fill", fill_sb)
	return pb

static func _build_button(
	text: String,
	callback: Callable,
	bg_norm: Color,
	bg_hover: Color,
	border_col: Color,
	text_col: Color,
	font_size: int,
	min_height: float
) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0.0, min_height)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.add_theme_font_size_override("font_size", font_size)
	b.add_theme_color_override("font_color", text_col)
	b.add_theme_color_override("font_hover_color", text_col)
	b.add_theme_color_override("font_pressed_color", text_col)

	var normal := StyleBoxFlat.new()
	normal.bg_color = bg_norm
	normal.border_color = border_col
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(14)
	normal.content_margin_left = 16
	normal.content_margin_right = 16
	normal.content_margin_top = 10
	normal.content_margin_bottom = 10

	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = bg_hover
	hover.border_color = Color(0.85, 0.94, 0.86, 0.90)
	hover.set_border_width_all(2)

	var pressed_sb := normal.duplicate() as StyleBoxFlat
	pressed_sb.bg_color = bg_norm.darkened(0.15)

	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", pressed_sb)
	b.add_theme_stylebox_override("focus", hover)
	b.pressed.connect(callback)
	return b

static func make_primary_button(text: String, callback: Callable, font_size: int = 20, min_height: float = 52.0) -> Button:
	return _build_button(text, callback, COL_PRIMARY, Color(0.85, 0.94, 0.84, 1.0), Color(0.86, 0.95, 0.85, 1.0), COL_PRIMARY_TEXT, font_size, min_height)

static func make_secondary_button(text: String, callback: Callable, selected: bool = false, font_size: int = 18, min_height: float = 46.0) -> Button:
	var bg := COL_SELECTED if selected else COL_CARD_BG
	var hover := Color(0.24, 0.54, 0.49, 0.92) if selected else Color(0.17, 0.25, 0.21, 0.90)
	var border := Color(0.45, 0.82, 0.74, 0.90) if selected else COL_CARD_BORDER
	return _build_button(text, callback, bg, hover, border, COL_TEXT_MAIN, font_size, min_height)

static func make_destructive_button(text: String, callback: Callable, font_size: int = 18, min_height: float = 46.0) -> Button:
	return _build_button(text, callback, COL_DESTRUCTIVE, Color(0.50, 0.21, 0.23, 0.94), COL_DESTRUCTIVE_BORDER, COL_TEXT_MAIN, font_size, min_height)
