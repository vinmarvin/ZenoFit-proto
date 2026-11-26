class_name KarateBoardProp
extends Node3D

## Interactive wooden karate breaking board (res://assets/KarateBoard.glb, 604 tris).
## Displays intact board with thin hand-cue accent edges; on strike impact, hides
## Board_Intact, reveals Board_Half_Left/Right + Splinter_1..6, and triggers the embedded Break animation.

const KARATE_BOARD_GLB_PATH: String = "res://assets/KarateBoard.glb"

var intact_node: Node3D = null
var half_left_node: Node3D = null
var half_right_node: Node3D = null
var splinter_nodes: Array[Node3D] = []
var anim_player: AnimationPlayer = null
var is_broken: bool = false

static func _load_raw_glb(path: String) -> Node:
	if FileAccess.file_exists(path):
		var bytes := FileAccess.get_file_as_bytes(path)
		if bytes.size() > 0:
			var gltf := GLTFDocument.new()
			var st := GLTFState.new()
			if gltf.append_from_buffer(bytes, "res://assets/", st) == OK:
				return gltf.generate_scene(st)
	return null

func setup_board(accent_color: Color = Color(0.32, 0.85, 0.72)) -> void:
	is_broken = false
	for child in get_children():
		remove_child(child)
		child.free()
	splinter_nodes.clear()

	var scene_root := DojoEnvironmentLoader.load_glb_scene(KARATE_BOARD_GLB_PATH)
	if scene_root == null:
		scene_root = _load_raw_glb(KARATE_BOARD_GLB_PATH)
	if scene_root == null:
		return

	add_child(scene_root)
	DojoEnvironmentLoader.optimize_meshes(scene_root, false)

	intact_node = scene_root.find_child("Board_Intact", true, false) as Node3D
	half_left_node = scene_root.find_child("Board_Half_Left", true, false) as Node3D
	half_right_node = scene_root.find_child("Board_Half_Right", true, false) as Node3D
	for i in range(1, 7):
		var sp := scene_root.find_child("Splinter_%d" % i, true, false) as Node3D
		if sp != null:
			splinter_nodes.append(sp)
	anim_player = scene_root.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if anim_player != null:
		anim_player.stop()

	_attach_hand_cue_rim(accent_color)
	set_intact_state()

func _attach_hand_cue_rim(accent_color: Color) -> void:
	if intact_node == null:
		return
	var rim_mat := StandardMaterial3D.new()
	rim_mat.albedo_color = accent_color
	rim_mat.emission_enabled = true
	rim_mat.emission = accent_color
	rim_mat.emission_energy_multiplier = 0.85
	rim_mat.roughness = 0.3

	var bar_mesh := BoxMesh.new()
	bar_mesh.size = Vector3(0.286, 0.011, 0.022)

	var top_bar := MeshInstance3D.new()
	top_bar.name = "AccentTop"
	top_bar.mesh = bar_mesh
	top_bar.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	top_bar.material_override = rim_mat
	top_bar.position = Vector3(0.0, 0.125, 0.0)
	intact_node.add_child(top_bar)

	var bot_bar := MeshInstance3D.new()
	bot_bar.name = "AccentBottom"
	bot_bar.mesh = bar_mesh
	bot_bar.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	bot_bar.material_override = rim_mat
	bot_bar.position = Vector3(0.0, -0.125, 0.0)
	intact_node.add_child(bot_bar)

func set_intact_state() -> void:
	is_broken = false
	if intact_node != null:
		intact_node.visible = true
	if half_left_node != null:
		half_left_node.visible = false
	if half_right_node != null:
		half_right_node.visible = false
	for sp in splinter_nodes:
		sp.visible = false
	if anim_player != null:
		anim_player.stop()

func trigger_break() -> void:
	if is_broken:
		return
	is_broken = true
	if intact_node != null:
		intact_node.visible = false
	if half_left_node != null:
		half_left_node.visible = true
	if half_right_node != null:
		half_right_node.visible = true
	for sp in splinter_nodes:
		sp.visible = true

	if anim_player != null:
		var anim_name := ""
		if anim_player.has_animation("Break"):
			anim_name = "Break"
		else:
			var list := anim_player.get_animation_list()
			if list.size() > 0:
				anim_name = list[0]
		if not anim_name.is_empty():
			var anim := anim_player.get_animation(anim_name)
			if anim != null:
				anim.loop_mode = Animation.LOOP_NONE
			anim_player.play(anim_name)

	if is_inside_tree():
		var tw := create_tween()
		tw.tween_interval(0.65)
		tw.tween_callback(queue_free)
