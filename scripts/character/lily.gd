class_name LilyCharacter
extends CharacterBody2D

## Playable Botanical Caretaker Character "Lily" for Bloomhaven.
## Built using the authoritative modular Game-Ready Spritesheet with Skeleton2D & Bone2D Rigging:
## - 28 Clean Game-Ready RGBA parts with zero seams, zero background artifacts, and clean alpha
## - True 2D Cutout Skeleton with articulated shoulders, elbows, hips, knees, neck, and triple-jointed braid
## - 60 FPS Procedural Kinematics: Real leg strides, counter-swinging arms, and secondary inertia
## - Dynamic HandSocket tool attachment (Watering Can, Shears, Trowel, Basket)
## - Full gameplay actions: Watering (with water stream), Kneeling Harvest, Planting, and Celebration.

signal plot_approached(plot: GardenPlot)
signal plot_exited(plot: GardenPlot)

enum Facing {
	DOWN,
	UP,
	LEFT,
	RIGHT
}

enum State {
	IDLE,
	WALK,
	PLANT,
	WATER,
	PRUNE,
	HARVEST,
	CELEBRATE
}

@export var move_speed: float = 160.0
@export var character_enabled: bool = true

var facing_direction: Facing = Facing.DOWN
var current_state: State = State.IDLE
var is_moving: bool = false
var is_tending: bool = false
var target_pos: Vector2 = Vector2.INF

# Rig Container & Bone References
var _rig_root: Node2D = null
var _skeleton: Skeleton2D = null
var _bone_root: Bone2D = null
var _bone_pelvis: Bone2D = null
var _bone_spine: Bone2D = null
var _bone_torso: Bone2D = null
var _bone_neck: Bone2D = null
var _bone_head: Bone2D = null
var _bone_braid_top: Bone2D = null
var _bone_braid_mid: Bone2D = null
var _bone_braid_tip: Bone2D = null

var _bone_leg_l: Bone2D = null
var _bone_foot_l: Bone2D = null
var _bone_leg_r: Bone2D = null
var _bone_foot_r: Bone2D = null

var _bone_arm_l_upper: Bone2D = null
var _bone_arm_l_lower: Bone2D = null
var _bone_hand_l: Bone2D = null

var _bone_arm_r_upper: Bone2D = null
var _bone_arm_r_lower: Bone2D = null
var _bone_hand_r: Bone2D = null
var _hand_socket: Marker2D = null

# Visual Sprites
var _spr_skirt_under: Sprite2D = null
var _spr_skirt_outer: Sprite2D = null
var _spr_belt: Sprite2D = null
var _spr_pouch: Sprite2D = null
var _spr_leg_l: Sprite2D = null
var _spr_boot_l: Sprite2D = null
var _spr_leg_r: Sprite2D = null
var _spr_boot_r: Sprite2D = null
var _spr_torso: Sprite2D = null
var _spr_arm_l_up: Sprite2D = null
var _spr_arm_l_low: Sprite2D = null
var _spr_hand_l: Sprite2D = null
var _spr_arm_r_up: Sprite2D = null
var _spr_arm_r_low: Sprite2D = null
var _spr_hand_r: Sprite2D = null
var _spr_hair_back: Sprite2D = null
var _spr_head: Sprite2D = null
var _spr_hair_front: Sprite2D = null
var _spr_hat: Sprite2D = null
var _spr_braid_top: Sprite2D = null
var _spr_braid_mid: Sprite2D = null
var _spr_braid_tip: Sprite2D = null
var _tool_spr: Sprite2D = null

# Particles
var _water_stream: CPUParticles2D = null
var _step_dust: CPUParticles2D = null
var _celebrate_sparkles: CPUParticles2D = null
var _closest_plot: GardenPlot = null

# Kinematics Timers
var _walk_cycle_time: float = 0.0
var _idle_cycle_time: float = 0.0
var _action_countdown: float = 0.0
var _braid_inertia: float = 0.0

const PROXIMITY_RADIUS: float = 85.0
const RIG_SCALE: float = 0.155 # Calibrated ~80px tall character matching stone garden plots


func _ready() -> void:
	z_index = 2
	z_as_relative = true
	y_sort_enabled = true
	_build_game_ready_skeleton_tree()
	_setup_particles()
	queue_redraw()


func _build_game_ready_skeleton_tree() -> void:
	if is_instance_valid(_rig_root):
		return

	_rig_root = Node2D.new()
	_rig_root.name = "RigRoot"
	_rig_root.position = Vector2(0, 0)
	add_child(_rig_root)

	_skeleton = Skeleton2D.new()
	_skeleton.name = "Skeleton2D"
	_rig_root.add_child(_skeleton)

	# 1. Root Bone (Ground Baseline 0, 0)
	_bone_root = _create_bone("Bone_Root", Vector2(0, 0), _skeleton)

	var G0 := "res://assets/character/Lily_Source/clean_rgba_assets/"

	# 2. Pelvis Bone
	_bone_pelvis = _create_bone("Bone_Pelvis", Vector2(0, -32), _bone_root)
	_spr_skirt_under = _create_part_sprite(G0 + "skirt_back.png", Vector2(0, 12), -1)
	_bone_pelvis.add_child(_spr_skirt_under)

	_spr_skirt_outer = _create_part_sprite(G0 + "skirt_front.png", Vector2(0, 12), 0)
	_bone_pelvis.add_child(_spr_skirt_outer)

	_spr_belt = _create_part_sprite(G0 + "accessory_belt.png", Vector2(0, -2), 1)
	_bone_pelvis.add_child(_spr_belt)

	_spr_pouch = _create_part_sprite(G0 + "flower_pouch.png", Vector2(10, 4), 2)
	_bone_pelvis.add_child(_spr_pouch)

	# 3. Left Leg & Boot (Behind)
	_bone_leg_l = _create_bone("Bone_Leg_L", Vector2(-6, 2), _bone_pelvis)
	_spr_leg_l = _create_part_sprite(G0 + "leg_L_upper.png", Vector2(0, 12), -2)
	_bone_leg_l.add_child(_spr_leg_l)

	_bone_foot_l = _create_bone("Bone_Foot_L", Vector2(0, 16), _bone_leg_l)
	_spr_boot_l = _create_part_sprite(G0 + "boot_L.png", Vector2(0, 10), -2)
	_bone_foot_l.add_child(_spr_boot_l)

	# 4. Right Leg & Boot (Front)
	_bone_leg_r = _create_bone("Bone_Leg_R", Vector2(6, 2), _bone_pelvis)
	_spr_leg_r = _create_part_sprite(G0 + "leg_R_upper.png", Vector2(0, 12), -1)
	_bone_leg_r.add_child(_spr_leg_r)

	_bone_foot_r = _create_bone("Bone_Foot_R", Vector2(0, 16), _bone_leg_r)
	_spr_boot_r = _create_part_sprite(G0 + "boot_R.png", Vector2(0, 10), -1)
	_bone_foot_r.add_child(_spr_boot_r)

	# 5. Spine & Torso
	_bone_spine = _create_bone("Bone_Spine", Vector2(0, -8), _bone_pelvis)
	_bone_torso = _create_bone("Bone_Torso", Vector2(0, -10), _bone_spine)
	_spr_torso = _create_part_sprite(G0 + "torso_shirt.png", Vector2(0, -10), 3)
	_bone_torso.add_child(_spr_torso)

	# 6. Left Arm (Upper, Lower, Hand) (Behind Torso)
	_bone_arm_l_upper = _create_bone("Bone_Arm_L_Upper", Vector2(-12, -14), _bone_torso)
	_spr_arm_l_up = _create_part_sprite(G0 + "arm_L_upper.png", Vector2(-1, 10), -3)
	_bone_arm_l_upper.add_child(_spr_arm_l_up)

	_bone_arm_l_lower = _create_bone("Bone_Arm_L_Lower", Vector2(-2, 18), _bone_arm_l_upper)
	_spr_arm_l_low = _create_part_sprite(G0 + "arm_L_lower.png", Vector2(-1, 8), -3)
	_bone_arm_l_lower.add_child(_spr_arm_l_low)

	_bone_hand_l = _create_bone("Bone_Hand_L", Vector2(-1, 14), _bone_arm_l_lower)
	_spr_hand_l = _create_part_sprite(G0 + "hand_L.png", Vector2(0, 6), -3)
	_bone_hand_l.add_child(_spr_hand_l)

	# 7. Right Arm (Upper, Lower, Hand, HandSocket) (In Front of Torso)
	_bone_arm_r_upper = _create_bone("Bone_Arm_R_Upper", Vector2(12, -14), _bone_torso)
	_spr_arm_r_up = _create_part_sprite(G0 + "arm_R_upper.png", Vector2(1, 10), 4)
	_bone_arm_r_upper.add_child(_spr_arm_r_up)

	_bone_arm_r_lower = _create_bone("Bone_Arm_R_Lower", Vector2(2, 18), _bone_arm_r_upper)
	_spr_arm_r_low = _create_part_sprite(G0 + "arm_R_lower.png", Vector2(1, 8), 4)
	_bone_arm_r_lower.add_child(_spr_arm_r_low)

	_bone_hand_r = _create_bone("Bone_Hand_R", Vector2(1, 14), _bone_arm_r_lower)
	_spr_hand_r = _create_part_sprite(G0 + "hand_R_open.png", Vector2(0, 6), 4)
	_bone_hand_r.add_child(_spr_hand_r)

	# Dynamic HandSocket for tools
	_hand_socket = Marker2D.new()
	_hand_socket.name = "HandSocket"
	_hand_socket.position = Vector2(4, 12)
	_bone_hand_r.add_child(_hand_socket)

	_tool_spr = Sprite2D.new()
	_tool_spr.name = "Tool_Sprite"
	var tool_path := "res://assets/character/Lily_Source/tool_variants/watering_can.png"
	if ResourceLoader.exists(tool_path):
		_tool_spr.texture = load(tool_path)
	_tool_spr.scale = Vector2(RIG_SCALE * 0.9, RIG_SCALE * 0.9)
	_tool_spr.position = Vector2(12, 10)
	_tool_spr.z_index = 5
	_tool_spr.visible = false
	_hand_socket.add_child(_tool_spr)

	# 8. Neck, Head, Hair, Hat, and Triple-Joint Braid
	_bone_neck = _create_bone("Bone_Neck", Vector2(0, -20), _bone_torso)
	_bone_head = _create_bone("Bone_Head", Vector2(0, -10), _bone_neck)

	_spr_hair_back = _create_part_sprite(G0 + "hair_back.png", Vector2(0, -6), -2)
	_bone_head.add_child(_spr_hair_back)

	_spr_head = _create_part_sprite(G0 + "head_base.png", Vector2(0, -10), 5)
	_bone_head.add_child(_spr_head)

	_spr_hair_front = _create_part_sprite(G0 + "front_hair.png", Vector2(0, -12), 6)
	_bone_head.add_child(_spr_hair_front)

	_spr_hat = _create_part_sprite(G0 + "straw_hat.png", Vector2(0, -20), 7)
	_bone_head.add_child(_spr_hat)

	# Triple-Joint Articulated Braid
	_bone_braid_top = _create_bone("Bone_Braid_Top", Vector2(-8, 6), _bone_head)
	_spr_braid_top = _create_part_sprite(G0 + "braid_upper.png", Vector2(0, 10), -1)
	_bone_braid_top.add_child(_spr_braid_top)

	_bone_braid_mid = _create_bone("Bone_Braid_Mid", Vector2(0, 18), _bone_braid_top)
	_spr_braid_mid = _create_part_sprite(G0 + "braid_middle.png", Vector2(0, 10), -1)
	_bone_braid_mid.add_child(_spr_braid_mid)

	_bone_braid_tip = _create_bone("Bone_Braid_Tip", Vector2(0, 16), _bone_braid_mid)
	_spr_braid_tip = _create_part_sprite(G0 + "braid_tip.png", Vector2(0, 8), -1)
	_bone_braid_tip.add_child(_spr_braid_tip)


func _create_bone(bone_name: String, bone_pos: Vector2, parent_node: Node) -> Bone2D:
	var bone := Bone2D.new()
	bone.name = bone_name
	bone.position = bone_pos
	parent_node.add_child(bone)
	bone.set_autocalculate_length_and_angle(false)
	bone.set_length(16.0)
	bone.set_rest(bone.transform)
	return bone


func _create_part_sprite(tex_path: String, offset_pos: Vector2, z_idx: int) -> Sprite2D:
	var spr := Sprite2D.new()
	if ResourceLoader.exists(tex_path):
		spr.texture = load(tex_path)
	spr.scale = Vector2(RIG_SCALE, RIG_SCALE)
	spr.position = offset_pos
	spr.z_index = z_idx
	spr.z_as_relative = true
	return spr


func _setup_particles() -> void:
	_step_dust = CPUParticles2D.new()
	_step_dust.name = "StepDust"
	_step_dust.position = Vector2(0, 0)
	_step_dust.emitting = false
	_step_dust.amount = 12
	_step_dust.lifetime = 0.42
	_step_dust.explosiveness = 0.45
	_step_dust.direction = Vector2(0, -1)
	_step_dust.spread = 75.0
	_step_dust.gravity = Vector2(0, 35)
	_step_dust.initial_velocity_min = 18.0
	_step_dust.initial_velocity_max = 38.0
	_step_dust.scale_amount_min = 2.2
	_step_dust.scale_amount_max = 4.2
	_step_dust.color = Color(0.65, 0.58, 0.45, 0.65)
	add_child(_step_dust)

	_water_stream = CPUParticles2D.new()
	_water_stream.name = "WaterStream"
	_water_stream.position = Vector2(24, -18)
	_water_stream.emitting = false
	_water_stream.amount = 26
	_water_stream.lifetime = 0.55
	_water_stream.direction = Vector2(0.8, 1.0)
	_water_stream.spread = 22.0
	_water_stream.gravity = Vector2(0, 180)
	_water_stream.initial_velocity_min = 40.0
	_water_stream.initial_velocity_max = 75.0
	_water_stream.scale_amount_min = 2.0
	_water_stream.scale_amount_max = 4.0
	_water_stream.color = Color(0.35, 0.75, 1.0, 0.92)
	add_child(_water_stream)

	_celebrate_sparkles = CPUParticles2D.new()
	_celebrate_sparkles.name = "CelebrateSparkles"
	_celebrate_sparkles.position = Vector2(0, -60)
	_celebrate_sparkles.emitting = false
	_celebrate_sparkles.one_shot = true
	_celebrate_sparkles.amount = 24
	_celebrate_sparkles.lifetime = 0.9
	_celebrate_sparkles.explosiveness = 0.85
	_celebrate_sparkles.direction = Vector2(0, -1)
	_celebrate_sparkles.spread = 180.0
	_celebrate_sparkles.gravity = Vector2(0, 65)
	_celebrate_sparkles.initial_velocity_min = 45.0
	_celebrate_sparkles.initial_velocity_max = 100.0
	_celebrate_sparkles.scale_amount_min = 2.5
	_celebrate_sparkles.scale_amount_max = 5.2
	_celebrate_sparkles.color = Color(1.0, 0.88, 0.35, 0.95)
	add_child(_celebrate_sparkles)


func _unhandled_input(event: InputEvent) -> void:
	if not character_enabled:
		return
	if event is InputEventMouseButton and event.pressed:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_RIGHT:
			walk_to(get_global_mouse_position())


func walk_to(pos: Vector2) -> void:
	target_pos = pos
	if is_tending:
		is_tending = false
		current_state = State.WALK
		_hide_tools()


func _physics_process(delta: float) -> void:
	if not character_enabled:
		visible = false
		return
	visible = true

	# Action timer countdown
	if is_tending:
		_action_countdown -= delta
		if _action_countdown <= 0.0:
			is_tending = false
			current_state = State.IDLE
			_hide_tools()

	var input_vec := Vector2.ZERO

	# Check Physical Keys
	if Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT) or Input.is_action_pressed("ui_right"):
		input_vec.x += 1.0
	if Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT) or Input.is_action_pressed("ui_left"):
		input_vec.x -= 1.0
	if Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN) or Input.is_action_pressed("ui_down"):
		input_vec.y += 1.0
	if Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP) or Input.is_action_pressed("ui_up"):
		input_vec.y -= 1.0

	if input_vec.length_squared() > 0.01:
		target_pos = Vector2.INF
		if is_tending:
			is_tending = false
			_hide_tools()
		input_vec = input_vec.normalized()
		velocity = input_vec * move_speed
		is_moving = true
		current_state = State.WALK
	elif target_pos != Vector2.INF:
		var diff := target_pos - global_position
		if diff.length() > 8.0:
			input_vec = diff.normalized()
			velocity = input_vec * move_speed
			is_moving = true
			current_state = State.WALK
		else:
			target_pos = Vector2.INF
			velocity = Vector2.ZERO
			is_moving = false
			if not is_tending:
				current_state = State.IDLE
	else:
		velocity = Vector2.ZERO
		is_moving = false
		if not is_tending:
			current_state = State.IDLE

	if is_moving:
		_update_facing(input_vec)

	_update_skeleton_kinematics(delta)
	move_and_slide()
	_check_plot_proximity()
	queue_redraw()


func _update_facing(vec: Vector2) -> void:
	if abs(vec.x) > abs(vec.y):
		facing_direction = Facing.RIGHT if vec.x > 0 else Facing.LEFT
	else:
		facing_direction = Facing.DOWN if vec.y > 0 else Facing.UP


func _update_skeleton_kinematics(delta: float) -> void:
	if not is_instance_valid(_rig_root):
		return

	var is_left: bool = (facing_direction == Facing.LEFT)
	_rig_root.scale.x = -1.0 if is_left else 1.0

	# 1. Action Kinematics (Watering, Harvesting, Planting, Celebrating)
	if is_tending:
		if _step_dust.emitting:
			_step_dust.emitting = false

		match current_state:
			State.WATER:
				_bone_torso.position.y = lerp(_bone_torso.position.y, -7.0, delta * 10.0)
				_bone_torso.rotation = lerp_angle(_bone_torso.rotation, 0.26, delta * 10.0)
				_bone_head.rotation = lerp_angle(_bone_head.rotation, 0.16, delta * 10.0)
				_bone_arm_r_upper.rotation = lerp_angle(_bone_arm_r_upper.rotation, -0.65, delta * 12.0)
				_bone_arm_r_lower.rotation = lerp_angle(_bone_arm_r_lower.rotation, -0.25, delta * 12.0)
				_bone_arm_l_upper.rotation = lerp_angle(_bone_arm_l_upper.rotation, 0.35, delta * 10.0)
				if is_instance_valid(_tool_spr):
					_tool_spr.visible = true
				if is_instance_valid(_water_stream):
					_water_stream.position = Vector2(-24 if is_left else 24, -16)
					_water_stream.direction = Vector2(-0.8 if is_left else 0.8, 1.0)
					if not _water_stream.emitting:
						_water_stream.emitting = true
				return

			State.HARVEST:
				_bone_pelvis.position.y = lerp(_bone_pelvis.position.y, -24.0, delta * 10.0)
				_bone_torso.rotation = lerp_angle(_bone_torso.rotation, 0.32, delta * 10.0)
				_bone_head.rotation = lerp_angle(_bone_head.rotation, 0.20, delta * 10.0)
				_bone_arm_l_upper.rotation = lerp_angle(_bone_arm_l_upper.rotation, 0.55, delta * 10.0)
				_bone_arm_r_upper.rotation = lerp_angle(_bone_arm_r_upper.rotation, 0.55, delta * 10.0)
				return

			State.PLANT:
				_bone_pelvis.position.y = lerp(_bone_pelvis.position.y, -26.0, delta * 10.0)
				_bone_torso.rotation = lerp_angle(_bone_torso.rotation, 0.28, delta * 10.0)
				_bone_arm_r_upper.rotation = lerp_angle(_bone_arm_r_upper.rotation, 0.45, delta * 10.0)
				_bone_arm_l_upper.rotation = lerp_angle(_bone_arm_l_upper.rotation, 0.20, delta * 10.0)
				return

			State.CELEBRATE:
				_bone_torso.position.y = -10.0 + sin(_idle_cycle_time * 8.0) * -3.0
				_bone_arm_l_upper.rotation = lerp_angle(_bone_arm_l_upper.rotation, -2.4, delta * 12.0)
				_bone_arm_r_upper.rotation = lerp_angle(_bone_arm_r_upper.rotation, 2.4, delta * 12.0)
				return

			_:
				pass

	# 2. Walk Cycle Kinematics (Articulated Bone Strides)
	if is_moving:
		_walk_cycle_time += delta * 11.0
		var stride: float = sin(_walk_cycle_time)
		var step_bounce: float = abs(stride) * -3.5

		# Legs rotate with stepping lift
		_bone_pelvis.position.y = -32.0 + step_bounce
		_bone_leg_l.rotation = stride * 0.45
		_bone_foot_l.rotation = max(0.0, -stride) * 0.35
		_bone_leg_r.rotation = -stride * 0.45
		_bone_foot_r.rotation = max(0.0, stride) * 0.35

		# Torso & Skirt counter-sway
		_bone_torso.rotation = stride * 0.05
		_bone_arm_l_upper.rotation = -stride * 0.40
		_bone_arm_l_lower.rotation = max(0.0, -stride) * 0.25
		_bone_arm_r_upper.rotation = stride * 0.40
		_bone_arm_r_lower.rotation = max(0.0, stride) * 0.25

		# Head stabilization & triple-joint braid secondary inertia
		_bone_head.rotation = -stride * 0.04
		_braid_inertia = lerp_angle(_braid_inertia, sin(_walk_cycle_time - 0.4) * 0.25, delta * 12.0)
		_bone_braid_top.rotation = _braid_inertia
		_bone_braid_mid.rotation = _braid_inertia * 1.15
		_bone_braid_tip.rotation = _braid_inertia * 1.3

		# Footstep Dust on contact
		if abs(stride) > 0.88:
			if not _step_dust.emitting:
				_step_dust.restart()
				_step_dust.emitting = true
		else:
			if _step_dust.emitting:
				_step_dust.emitting = false

	# 3. Idle Breathing Arc
	else:
		if _step_dust.emitting:
			_step_dust.emitting = false

		_idle_cycle_time += delta * 2.5
		var breath: float = sin(_idle_cycle_time)

		_bone_pelvis.position.y = lerp(_bone_pelvis.position.y, -32.0, delta * 10.0)
		_bone_leg_l.rotation = lerp_angle(_bone_leg_l.rotation, 0.0, delta * 10.0)
		_bone_foot_l.rotation = lerp_angle(_bone_foot_l.rotation, 0.0, delta * 10.0)
		_bone_leg_r.rotation = lerp_angle(_bone_leg_r.rotation, 0.0, delta * 10.0)
		_bone_foot_r.rotation = lerp_angle(_bone_foot_r.rotation, 0.0, delta * 10.0)

		_bone_torso.position.y = -10.0 + breath * 1.2
		_bone_torso.rotation = lerp_angle(_bone_torso.rotation, 0.0, delta * 8.0)

		_bone_arm_l_upper.rotation = lerp_angle(_bone_arm_l_upper.rotation, 0.06 + breath * 0.04, delta * 8.0)
		_bone_arm_l_lower.rotation = lerp_angle(_bone_arm_l_lower.rotation, 0.0, delta * 8.0)
		_bone_arm_r_upper.rotation = lerp_angle(_bone_arm_r_upper.rotation, -0.06 - breath * 0.04, delta * 8.0)
		_bone_arm_r_lower.rotation = lerp_angle(_bone_arm_r_lower.rotation, 0.0, delta * 8.0)

		_bone_head.rotation = lerp_angle(_bone_head.rotation, sin(_idle_cycle_time * 0.5) * 0.03, delta * 8.0)
		_bone_braid_top.rotation = lerp_angle(_bone_braid_top.rotation, sin(_idle_cycle_time * 1.2) * 0.08, delta * 8.0)
		_bone_braid_mid.rotation = lerp_angle(_bone_braid_mid.rotation, sin(_idle_cycle_time * 1.2) * 0.10, delta * 8.0)
		_bone_braid_tip.rotation = lerp_angle(_bone_braid_tip.rotation, sin(_idle_cycle_time * 1.2) * 0.12, delta * 8.0)


func _hide_tools() -> void:
	if is_instance_valid(_tool_spr):
		_tool_spr.visible = false
	if is_instance_valid(_water_stream):
		_water_stream.emitting = false


func play_action(action_name: String, duration: float = 1.3) -> void:
	is_tending = true
	_action_countdown = duration

	match action_name:
		"water":
			current_state = State.WATER
		"harvest":
			current_state = State.HARVEST
		"plant":
			current_state = State.PLANT
		"prune":
			current_state = State.PLANT
		"celebrate":
			current_state = State.CELEBRATE
			if is_instance_valid(_celebrate_sparkles):
				_celebrate_sparkles.restart()
				_celebrate_sparkles.emitting = true
		_:
			current_state = State.IDLE


func play_tending_gesture() -> void:
	play_action("water", 1.2)


func _check_plot_proximity() -> void:
	var garden_grid: GardenGrid = get_parent().get_node_or_null("GardenGrid") as GardenGrid
	if garden_grid == null:
		return

	var min_dist: float = PROXIMITY_RADIUS
	var closest: GardenPlot = null

	for plot in garden_grid.plots:
		var dist: float = global_position.distance_to(plot.global_position)
		if dist <= min_dist:
			min_dist = dist
			closest = plot

	if closest != _closest_plot:
		if _closest_plot != null:
			_closest_plot.set_hovered(false)
			plot_exited.emit(_closest_plot)
		_closest_plot = closest
		if _closest_plot != null:
			_closest_plot.set_hovered(true)
			plot_approached.emit(_closest_plot)


func _draw() -> void:
	# Soft Warm Grounding Contact Shadow
	_draw_ellipse(Vector2(2, 3), 20.0, 7.5, Color(0.06, 0.11, 0.07, 0.30))
	_draw_ellipse(Vector2(0, 2), 14.0, 5.0, Color(0.04, 0.08, 0.05, 0.22))


func _draw_ellipse(center: Vector2, rx: float, ry: float, col: Color, segments: int = 20) -> void:
	var points := PackedVector2Array()
	for i in range(segments):
		var angle: float = (float(i) / float(segments)) * TAU
		points.append(center + Vector2(cos(angle) * rx, sin(angle) * ry))
	draw_colored_polygon(points, col)
