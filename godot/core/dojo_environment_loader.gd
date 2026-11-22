class_name DojoEnvironmentLoader
extends RefCounted

## Loads res://assets/Environment.glb, strips the 28 stray modular sample pieces
## outside the room bounds, disables real-time shadow casting for mobile VR budget,
## sets CULL_DISABLED on shoji/wood materials, and centers the 9m x 6m room on Seated BodyFrame.

const DOJO_ENV_GLB_PATH: String = "res://assets/Environment.glb"
const KEEP_DOJO_GROUPS: PackedStringArray = ["group3", "group4", "walls", "roof", "group7", "group8"]

static func load_and_clean_dojo_environment() -> Node3D:
	var scene_root: Node = null
	if ResourceLoader.exists(DOJO_ENV_GLB_PATH):
		var loaded := ResourceLoader.load(DOJO_ENV_GLB_PATH)
		if loaded is PackedScene:
			scene_root = (loaded as PackedScene).instantiate()
	if scene_root == null and FileAccess.file_exists(DOJO_ENV_GLB_PATH):
		var bytes := FileAccess.get_file_as_bytes(DOJO_ENV_GLB_PATH)
		if bytes.size() > 0:
			var gltf := GLTFDocument.new()
			var st := GLTFState.new()
			if gltf.append_from_buffer(bytes, "res://assets/", st) == OK:
				scene_root = gltf.generate_scene(st)
	if scene_root == null:
		return null

	var holder := Node3D.new()
	holder.name = "ZenDojoEnvironment"
	if scene_root is Node3D:
		# GLB horizontal center is (0, 0, -0.75)m; shift +0.75 Z so seated player sits centered inside the 9m x 6m room.
		(scene_root as Node3D).position = Vector3(0.0, 0.0, 0.75)
	holder.add_child(scene_root)

	var root_group := scene_root.find_child("RootNode", true, false)
	if root_group != null:
		for child in root_group.get_children():
			if not KEEP_DOJO_GROUPS.has(child.name):
				root_group.remove_child(child)
				child.free()

	optimize_dojo_meshes(holder)
	return holder

static func optimize_dojo_meshes(node: Node) -> void:
	if node is MeshInstance3D:
		var mi := node as MeshInstance3D
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		if mi.mesh != null:
			for surf_idx in range(mi.mesh.get_surface_count()):
				var mat := mi.get_surface_override_material(surf_idx)
				if mat == null:
					mat = mi.mesh.surface_get_material(surf_idx)
				if mat is BaseMaterial3D:
					var bm := (mat as BaseMaterial3D).duplicate() as BaseMaterial3D
					bm.cull_mode = BaseMaterial3D.CULL_DISABLED
					bm.roughness = maxf(bm.roughness, 0.65)
					mi.set_surface_override_material(surf_idx, bm)
	for child in node.get_children():
		optimize_dojo_meshes(child)
