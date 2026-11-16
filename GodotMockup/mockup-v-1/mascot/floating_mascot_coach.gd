class_name FloatingMascotCoach
extends Node3D

## Interactive Floating Mascot & Exercise Coach using res://assets/Floating Mascots.glb.
## - Procedurally animates Arm_L, Arm_R, Neck/HeadShell, Leaf, and Torso around their anatomical pivots
##   to demonstrate all 10 ZenoFit mechanics (M01–M10).
## - Reacts with a happy bounce, wave, haptic pulse, and coaching tip when touched/poked by a hand.

const MASCOT_GLB_PATH: String = "res://assets/Floating Mascots.glb"
const POKE_RADIUS_M: float = 0.22

var base_spec_pos: Vector3 = Vector3(-0.52, -0.10, 1.05)
var active_demo_mechanic: int = ZenoEnums.MechanicId.M01_ASTEROID_BRAWLER
var poke_reaction_timer_s: float = 0.0
var poke_count: int = 0

var _visual_root: Node3D
var _left_shoulder_pivot: Node3D
var _right_shoulder_pivot: Node3D
var _neck_pivot: Node3D
var _leaf_node: Node3D
var _speech_label: Label3D
var _anim_time: float = 0.0
var _poke_cooldown_s: float = 0.0

func _ready() -> void:
	_build_mascot_hierarchy()
	if is_inside_tree() and get_tree().root.has_node("EventBus"):
		var eb := get_tree().root.get_node("EventBus")
		eb.mascot_demo_requested.connect(_on_mascot_demo_requested)
		eb.target_hit.connect(_on_target_hit)

func _build_mascot_hierarchy() -> void:
	_visual_root = Node3D.new()
	_visual_root.name = "MascotVisualRoot"
	_visual_root.scale = Vector3.ONE * 0.18
	# Rotate 180 deg around Y so local +Z face looks toward the seated player (+Z in Godot)
	_visual_root.rotation.y = PI
	add_child(_visual_root)

	if ResourceLoader.exists(MASCOT_GLB_PATH):
		var packed := load(MASCOT_GLB_PATH) as PackedScene
		if packed != null:
			var instance := packed.instantiate()
			_visual_root.add_child(instance)
			_setup_anatomical_pivots(instance)

	_speech_label = Label3D.new()
	_speech_label.name = "CoachBubble"
	_speech_label.position = Vector3(0.0, 0.48, 0.0)
	_speech_label.pixel_size = 0.0022
	_speech_label.font_size = 24
	_speech_label.outline_size = 6
	_speech_label.modulate = Color(0.85, 0.98, 1.0)
	_speech_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_speech_label.text = "ZenoBot Coach\n(Poke me or watch my form!)"
	add_child(_speech_label)

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

	# Hover near the player's front-left in BodyFrame
	var hover_y := sin(_anim_time * 2.2) * 0.035
	if poke_reaction_timer_s > 0.0:
		hover_y += absf(sin(_anim_time * 14.0)) * 0.06
	var target_world := body_frame.to_godot_world(base_spec_pos + Vector3(0.0, hover_y, 0.0))
	if is_inside_tree():
		global_position = target_world
	else:
		position = target_world
	rotation.y = body_frame.get_godot_yaw_rad() + deg_to_rad(22.0)

	# Check if either hand pokes/touches the mascot
	var base_pos := global_position if is_inside_tree() else position
	var center := base_pos + Vector3(0.0, 0.20, 0.0)
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
		_speech_label.text = "Hi there! (#%d)\nDemoing: %s" % [
			poke_count,
			ZenoEnums.get_mechanic_title(active_demo_mechanic).split("(")[0].strip_edges()
		]

func set_demo_mechanic(mechanic_id: int) -> void:
	active_demo_mechanic = mechanic_id
	if _speech_label != null:
		_speech_label.text = "Coach Demo:\n%s" % ZenoEnums.get_mechanic_title(mechanic_id)

func _on_mascot_demo_requested(mechanic_id: int) -> void:
	set_demo_mechanic(mechanic_id)

func _on_target_hit(_hand: int, points: int, streak: int, _is_solid: bool) -> void:
	if _speech_label != null and poke_reaction_timer_s <= 0.0:
		_speech_label.text = "Nice! +%d pts (Streak x%d)" % [points, streak]

func _animate_joints() -> void:
	if _left_shoulder_pivot == null or _right_shoulder_pivot == null or _neck_pivot == null or _visual_root == null:
		return

	_visual_root.rotation = Vector3(0.0, PI, 0.0)
	_left_shoulder_pivot.rotation = Vector3.ZERO
	_right_shoulder_pivot.rotation = Vector3.ZERO
	_neck_pivot.rotation = Vector3.ZERO

	# If recently poked, wave enthusiastically!
	if poke_reaction_timer_s > 0.0:
		_right_shoulder_pivot.rotation.z = deg_to_rad(135.0 + sin(_anim_time * 16.0) * 20.0)
		_left_shoulder_pivot.rotation.z = deg_to_rad(-35.0)
		_neck_pivot.rotation.z = deg_to_rad(sin(_anim_time * 10.0) * 12.0)
		return

	var t := _anim_time
	match active_demo_mechanic:
		ZenoEnums.MechanicId.M01_ASTEROID_BRAWLER:
			# Alternating forward punches
			_left_shoulder_pivot.rotation.x = deg_to_rad(-75.0 * maxf(0.0, sin(t * 4.0)))
			_right_shoulder_pivot.rotation.x = deg_to_rad(-75.0 * maxf(0.0, -sin(t * 4.0)))
		ZenoEnums.MechanicId.M02_FRUIT_HARVESTER:
			# Diagonal overhead reach
			_left_shoulder_pivot.rotation.x = deg_to_rad(-125.0 * (0.5 + 0.5 * sin(t * 2.5)))
			_right_shoulder_pivot.rotation.x = deg_to_rad(-125.0 * (0.5 + 0.5 * cos(t * 2.5)))
		ZenoEnums.MechanicId.M03_GLIDER_PILOT:
			# Lateral wing raise + slight steering tilt
			_left_shoulder_pivot.rotation.z = deg_to_rad(-75.0 + sin(t * 2.0) * 12.0)
			_right_shoulder_pivot.rotation.z = deg_to_rad(75.0 + sin(t * 2.0) * 12.0)
		ZenoEnums.MechanicId.M04_TURRET_GUNNER:
			# Hands at chest + trunk twist
			_left_shoulder_pivot.rotation.x = deg_to_rad(-65.0)
			_right_shoulder_pivot.rotation.x = deg_to_rad(-65.0)
			_visual_root.rotation.y = PI + deg_to_rad(sin(t * 2.0) * 38.0)
		ZenoEnums.MechanicId.M05_COSMIC_TUG_OF_WAR:
			# Rowing pull motion
			var row_angle := deg_to_rad(-45.0 - 45.0 * sin(t * 2.8))
			_left_shoulder_pivot.rotation.x = row_angle
			_right_shoulder_pivot.rotation.x = row_angle
		ZenoEnums.MechanicId.M06_FORCE_BLAST:
			# Double forward press and hold
			var press := clampf(sin(t * 1.8) * 1.4, 0.0, 1.0)
			_left_shoulder_pivot.rotation.x = deg_to_rad(-90.0 * press)
			_right_shoulder_pivot.rotation.x = deg_to_rad(-90.0 * press)
		ZenoEnums.MechanicId.M07_SHIELD_CRANK:
			# Arm circles at chest height
			_left_shoulder_pivot.rotation.x = deg_to_rad(-75.0 + sin(t * 4.5) * 25.0)
			_left_shoulder_pivot.rotation.z = deg_to_rad(-20.0 + cos(t * 4.5) * 25.0)
			_right_shoulder_pivot.rotation.x = deg_to_rad(-75.0 + sin(t * 4.5) * 25.0)
			_right_shoulder_pivot.rotation.z = deg_to_rad(20.0 - cos(t * 4.5) * 25.0)
		ZenoEnums.MechanicId.M08_RECON_SCANNER:
			# Slow head turns
			_neck_pivot.rotation.y = deg_to_rad(sin(t * 1.4) * 48.0)
		ZenoEnums.MechanicId.M09_POTION_BREWER:
			# Curl + wrist/arm pour tilt
			_right_shoulder_pivot.rotation.x = deg_to_rad(-80.0 - 30.0 * sin(t * 2.5))
			_right_shoulder_pivot.rotation.y = deg_to_rad(30.0 * maxf(0.0, cos(t * 2.5)))
		ZenoEnums.MechanicId.M10_LASER_EVADER:
			# Hands on overhead rail + side bend
			_left_shoulder_pivot.rotation.x = deg_to_rad(-130.0)
			_right_shoulder_pivot.rotation.x = deg_to_rad(-130.0)
			_visual_root.rotation.z = deg_to_rad(sin(t * 1.8) * 18.0)
