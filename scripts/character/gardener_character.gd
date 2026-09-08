class_name GardenerCharacter
extends CharacterBody2D

## Playable Botanical Caretaker "Lily" for Bloomhaven.
## Upgraded with Frame-by-Frame Sequential Animation (صور متتابعة - Flipbook Illusion of Motion):
## - Uses authentic hand-rendered sequential frames provided directly by the user.
## - Crisp frame-by-frame walk cycle driven by true footstep cadence.
## - Beautiful 3/4 front idle pose.
## - Perfect feet baseline alignment (y=240, x=128 on 256x256 canvas).
## - Direct, snappy velocity response with zero input lag.
## - Directional flip without zero-width squashing or artificial distortions.
## - Smooth, direct plot approach and arrival.

signal plot_approached(plot: GardenPlot)
signal plot_exited(plot: GardenPlot)
signal queue_updated(queue_length: int)

enum Facing {
	DOWN,
	UP,
	LEFT,
	RIGHT
}

# --- Exported Parameters ---
@export var move_speed: float = 165.0
@export var character_enabled: bool = true

# --- State Variables ---
var facing_direction: Facing = Facing.DOWN
var is_moving: bool = false
var is_tending: bool = false
var current_held_tool: String = ""
var target_pos: Vector2 = Vector2.INF
var task_queue: Array[Dictionary] = []
var active_selected_tool: String = "plant"

# --- Calibration Constants ---
const STEP_DISTANCE: float = 18.0       # Pixels of real world movement to advance 1 walk frame
const CHAR_SCALE_FACTOR: float = 0.455  # Calibrated for 256x256 canvas to produce ~88px tall grounded character
const PROXIMITY_RADIUS: float = 90.0
const MAX_QUEUE_SIZE: int = 6
const ARRIVAL_THRESHOLD: float = 4.0

# --- Internal Walk Cycle & Timers ---
var _walk_distance_accum: float = 0.0
var _walk_frame_index: int = 0
var _idle_timer: float = 0.0
var _closest_plot: GardenPlot = null
var _on_arrival_callback: Callable = Callable()

# --- Visual Nodes & Particles ---
var _char_sprite: Sprite2D = null
var _held_tool_sprite: Sprite2D = null
var _step_dust: CPUParticles2D = null
var _tool_spray_particles: CPUParticles2D = null

# --- Animation Textures (User Sequential Frames) ---
var _tex_idle_front: Texture2D = null
var _tex_idle_back: Texture2D = null
var _walk_down_frames: Array[Texture2D] = []
var _walk_up_frames: Array[Texture2D] = []
var _walk_side_frames: Array[Texture2D] = []
var _walk_frames: Array[Texture2D] = [] # Fallback
var _tex_action_water: Texture2D = null
var _tex_action_plant: Texture2D = null
var _tex_action_harvest: Texture2D = null
var _tex_action_celebrate: Texture2D = null

# --- Props ---
var _prop_watering_can: Texture2D = null
var _prop_trowel: Texture2D = null
var _prop_shears: Texture2D = null


func _ready() -> void:
	z_index = 2
	z_as_relative = true
	y_sort_enabled = true
	_load_poses()
	_setup_particles()
	_setup_character_sprite()
	queue_redraw()


func _load_poses() -> void:
	# Load User-Provided High-Res Sequential Frames
	_tex_idle_front = load("res://assets/character/frames/lily_idle_front.png")
	if ResourceLoader.exists("res://assets/character/frames/lily_idle_back.png"):
		_tex_idle_back = load("res://assets/character/frames/lily_idle_back.png")

	# Down Walk Cycle: authentic 4-beat cycle
	var tex_down_1: Texture2D = null
	var tex_down_2: Texture2D = null
	var tex_down_pass1: Texture2D = null
	var tex_down_pass2: Texture2D = null
	if ResourceLoader.exists("res://assets/character/frames/lily_walk_down_01.png"):
		tex_down_1 = load("res://assets/character/frames/lily_walk_down_01.png")
	if ResourceLoader.exists("res://assets/character/frames/lily_walk_down_02.png"):
		tex_down_2 = load("res://assets/character/frames/lily_walk_down_02.png")
	if ResourceLoader.exists("res://assets/character/frames/lily_walk_down_pass1.png"):
		tex_down_pass1 = load("res://assets/character/frames/lily_walk_down_pass1.png")
	if ResourceLoader.exists("res://assets/character/frames/lily_walk_down_pass2.png"):
		tex_down_pass2 = load("res://assets/character/frames/lily_walk_down_pass2.png")

	if tex_down_1 and tex_down_2:
		var p1 := tex_down_pass1 if tex_down_pass1 else _tex_idle_front
		var p2 := tex_down_pass2 if tex_down_pass2 else _tex_idle_front
		_walk_down_frames = [tex_down_1, p1, tex_down_2, p2]
	elif tex_down_1:
		_walk_down_frames = [tex_down_1, _tex_idle_front]
	else:
		_walk_down_frames = [_tex_idle_front]

	# Up Walk Cycle: authentic 4-beat back cycle
	if ResourceLoader.exists("res://assets/character/frames/lily_walk_up_01.png"):
		var tex_up_1 = load("res://assets/character/frames/lily_walk_up_01.png")
		var tex_up_2 = load("res://assets/character/frames/lily_walk_up_02.png") if ResourceLoader.exists("res://assets/character/frames/lily_walk_up_02.png") else tex_up_1
		var tex_up_3 = load("res://assets/character/frames/lily_walk_up_03.png") if ResourceLoader.exists("res://assets/character/frames/lily_walk_up_03.png") else _tex_idle_back
		var back_pass = _tex_idle_back if _tex_idle_back else tex_up_1
		_walk_up_frames = [tex_up_1, back_pass, tex_up_2, tex_up_3]
	else:
		_walk_up_frames = _walk_down_frames

	# Side Walk Cycle: authentic 4-beat side cycle
	if ResourceLoader.exists("res://assets/character/frames/lily_walk_side_01.png"):
		var tex_side_1 = load("res://assets/character/frames/lily_walk_side_01.png")
		var tex_side_2 = load("res://assets/character/frames/lily_walk_side_02.png") if ResourceLoader.exists("res://assets/character/frames/lily_walk_side_02.png") else tex_side_1
		var tex_side_3 = load("res://assets/character/frames/lily_walk_side_03.png") if ResourceLoader.exists("res://assets/character/frames/lily_walk_side_03.png") else tex_side_1
		var tex_side_4 = load("res://assets/character/frames/lily_walk_side_04.png") if ResourceLoader.exists("res://assets/character/frames/lily_walk_side_04.png") else tex_side_2
		_walk_side_frames = [tex_side_1, tex_side_2, tex_side_3, tex_side_4]
	elif ResourceLoader.exists("res://assets/character/frames/lily_walk_stride.png"):
		_walk_side_frames = [
			load("res://assets/character/frames/lily_walk_stride.png"),
			load("res://assets/character/frames/lily_walk_step.png"),
			load("res://assets/character/frames/lily_walk_pass.png")
		]
	else:
		_walk_side_frames = _walk_down_frames

	_walk_frames = _walk_down_frames

	# Authentic Hand-Rendered Action Poses
	_tex_action_water = load("res://assets/character/poses/action_water.png")
	_tex_action_plant = load("res://assets/character/poses/action_plant.png")
	_tex_action_celebrate = load("res://assets/character/poses/action_celebrate.png")
	_tex_action_harvest = _tex_action_celebrate

	_prop_watering_can = load("res://assets/character/props/prop_watering_can.png")
	_prop_trowel = load("res://assets/character/props/prop_trowel.png")
	_prop_shears = load("res://assets/character/props/prop_shears.png")


func _setup_particles() -> void:
	_step_dust = CPUParticles2D.new()
	_step_dust.name = "StepDust"
	_step_dust.emitting = false
	_step_dust.one_shot = true
	_step_dust.explosiveness = 0.9
	_step_dust.amount = 3
	_step_dust.lifetime = 0.25
	_step_dust.direction = Vector2(0, -1)
	_step_dust.spread = 45.0
	_step_dust.gravity = Vector2(0, 15)
	_step_dust.initial_velocity_min = 8.0
	_step_dust.initial_velocity_max = 18.0
	_step_dust.scale_amount_min = 1.5
	_step_dust.scale_amount_max = 2.8
	_step_dust.color = Color(0.72, 0.64, 0.50, 0.50)
	_step_dust.position = Vector2(0, 2)
	add_child(_step_dust)

	_tool_spray_particles = CPUParticles2D.new()
	_tool_spray_particles.name = "ToolSprayParticles"
	_tool_spray_particles.emitting = false
	_tool_spray_particles.one_shot = true
	_tool_spray_particles.amount = 16
	_tool_spray_particles.lifetime = 0.45
	_tool_spray_particles.direction = Vector2(0, -1)
	_tool_spray_particles.spread = 35.0
	_tool_spray_particles.gravity = Vector2(0, 150)
	_tool_spray_particles.initial_velocity_min = 40.0
	_tool_spray_particles.initial_velocity_max = 75.0
	_tool_spray_particles.scale_amount_min = 2.0
	_tool_spray_particles.scale_amount_max = 3.6
	_tool_spray_particles.color = Color(0.38, 0.78, 1.0, 0.9)
	add_child(_tool_spray_particles)


func _setup_character_sprite() -> void:
	if not is_instance_valid(_char_sprite):
		_char_sprite = Sprite2D.new()
		_char_sprite.name = "CharacterSprite"
		_char_sprite.texture = _tex_idle_front
		_char_sprite.centered = false
		_align_sprite_offset()
		_char_sprite.scale = Vector2(CHAR_SCALE_FACTOR, CHAR_SCALE_FACTOR)
		_char_sprite.position = Vector2(0, 0)
		add_child(_char_sprite)


func _align_sprite_offset() -> void:
	if not is_instance_valid(_char_sprite) or _char_sprite.texture == null:
		return
	var tex_size := _char_sprite.texture.get_size()
	if tex_size.y >= 300.0:
		# 320x320 canvas: ground baseline is at y = 310
		_char_sprite.offset = Vector2(-tex_size.x * 0.5, -310.0)
	else:
		# 256x256 canvas: ground baseline is at y = 240
		_char_sprite.offset = Vector2(-tex_size.x * 0.5, -240.0)

	if not is_instance_valid(_held_tool_sprite):
		_held_tool_sprite = Sprite2D.new()
		_held_tool_sprite.name = "HeldToolSprite"
		_held_tool_sprite.centered = true
		_held_tool_sprite.z_index = 1
		add_child(_held_tool_sprite)
		_update_held_tool_visual()


func walk_to(destination: Vector2, on_arrival: Callable = Callable()) -> void:
	target_pos = destination
	_on_arrival_callback = on_arrival


func queue_action_at_plot(plot: GardenPlot, action_name: String, on_trigger: Callable = Callable()) -> void:
	if plot == null or task_queue.size() >= MAX_QUEUE_SIZE:
		return

	task_queue.append({
		"plot": plot,
		"action": action_name,
		"on_trigger": on_trigger
	})
	queue_updated.emit(task_queue.size())
	queue_redraw()

	if not is_tending and not is_moving:
		_process_next_queue_task()


func perform_action_at_plot(plot: GardenPlot, action_name: String, on_trigger: Callable = Callable(), on_complete: Callable = Callable()) -> void:
	queue_action_at_plot(plot, action_name, on_trigger)


func _process_next_queue_task() -> void:
	if task_queue.is_empty():
		is_tending = false
		current_held_tool = ""
		queue_updated.emit(0)
		queue_redraw()
		return

	var current_task: Dictionary = task_queue[0]
	var target_plot: GardenPlot = current_task.plot
	if not is_instance_valid(target_plot):
		task_queue.pop_front()
		queue_updated.emit(task_queue.size())
		_process_next_queue_task()
		return

	var stand_pos := target_plot.global_position + Vector2(0, 30.0)
	walk_to(stand_pos, func() -> void:
		_execute_tool_action(target_plot, current_task.action, current_task.on_trigger, func() -> void:
			if not task_queue.is_empty():
				task_queue.pop_front()
			queue_updated.emit(task_queue.size())
			_process_next_queue_task()
		)
	)


func clear_queue() -> void:
	task_queue.clear()
	target_pos = Vector2.INF
	velocity = Vector2.ZERO
	is_moving = false
	is_tending = false
	current_held_tool = ""
	_on_arrival_callback = Callable()
	queue_updated.emit(0)
	queue_redraw()


func _physics_process(delta: float) -> void:
	if not character_enabled:
		velocity = Vector2.ZERO
		is_moving = false
		if is_instance_valid(_char_sprite):
			_char_sprite.visible = false
		queue_redraw()
		return

	if is_instance_valid(_char_sprite):
		_char_sprite.visible = true

	var input_vec := Vector2.ZERO

	if not is_tending:
		# 1. Keyboard Input
		input_vec.x = Input.get_axis("ui_left", "ui_right")
		input_vec.y = Input.get_axis("ui_up", "ui_down")

		if input_vec == Vector2.ZERO:
			if Input.is_key_pressed(KEY_A): input_vec.x -= 1.0
			if Input.is_key_pressed(KEY_D): input_vec.x += 1.0
			if Input.is_key_pressed(KEY_W): input_vec.y -= 1.0
			if Input.is_key_pressed(KEY_S): input_vec.y += 1.0

		if input_vec != Vector2.ZERO:
			# Direct keyboard control: crisp, zero floatiness
			target_pos = Vector2.INF
			_on_arrival_callback = Callable()
			input_vec = input_vec.normalized()
			velocity = input_vec * move_speed
			_update_facing(input_vec)
			is_moving = true
			_idle_timer = 0.0

		elif target_pos != Vector2.INF:
			# Direct Click-to-Move: clean linear travel
			var to_target: Vector2 = target_pos - global_position
			var dist: float = to_target.length()

			if dist > ARRIVAL_THRESHOLD:
				var current_speed: float = move_speed
				if dist < 24.0:
					current_speed = move_speed * (dist / 24.0)
					current_speed = maxf(current_speed, 40.0)

				velocity = to_target.normalized() * current_speed
				_update_facing(to_target)
				is_moving = true
				_idle_timer = 0.0
			else:
				velocity = Vector2.ZERO
				target_pos = Vector2.INF
				is_moving = false
				if _on_arrival_callback.is_valid():
					var cb := _on_arrival_callback
					_on_arrival_callback = Callable()
					cb.call()
		else:
			# Direct stop: no ice-skating coast
			velocity = Vector2.ZERO
			is_moving = false
	else:
		velocity = Vector2.ZERO
		is_moving = false

	move_and_slide()

	# --- Sequential Animation Updates ---
	_update_animation_frames(delta)
	_update_held_tool_visual()
	_check_plot_proximity()
	queue_redraw()


func _update_animation_frames(delta: float) -> void:
	if not is_instance_valid(_char_sprite):
		return

	# Discrete horizontal facing (clean binary sign flip, zero squashing)
	var flip: bool = (facing_direction == Facing.LEFT)
	_char_sprite.scale.x = -CHAR_SCALE_FACTOR if flip else CHAR_SCALE_FACTOR
	_char_sprite.scale.y = CHAR_SCALE_FACTOR
	_char_sprite.rotation = 0.0
	_char_sprite.position = Vector2.ZERO

	if is_tending:
		return

	if is_moving:
		# Pick the correct directional frame list
		var active_frames: Array[Texture2D] = _walk_down_frames
		match facing_direction:
			Facing.DOWN:
				active_frames = _walk_down_frames
			Facing.UP:
				active_frames = _walk_up_frames
			Facing.LEFT, Facing.RIGHT:
				active_frames = _walk_side_frames

		if active_frames.is_empty():
			active_frames = [_tex_idle_front]

		# Distance-driven frame advance: 1 frame per STEP_DISTANCE world pixels
		var dist_delta: float = velocity.length() * delta
		_walk_distance_accum += dist_delta

		if _walk_distance_accum >= STEP_DISTANCE:
			_walk_distance_accum -= STEP_DISTANCE
			_walk_frame_index = (_walk_frame_index + 1) % active_frames.size()
			_char_sprite.texture = active_frames[_walk_frame_index]
			_align_sprite_offset()

			# Play soft step audio and emit dust on contact frames
			if _walk_frame_index == 0 or _walk_frame_index == 2:
				_play_sfx("step", randf_range(-0.05, 0.05), -14.0)
				if is_instance_valid(_step_dust):
					var foot_x: float = -4.0 if _walk_frame_index == 0 else 4.0
					if flip: foot_x = -foot_x
					_step_dust.position = Vector2(foot_x, 2.0)
					_step_dust.restart()
					_step_dust.emitting = true
	else:
		# Idle: stable pose
		_walk_distance_accum = 0.0
		_walk_frame_index = 0
		var target_idle: Texture2D = _tex_idle_front
		if facing_direction == Facing.UP and _tex_idle_back != null:
			target_idle = _tex_idle_back
		if _char_sprite.texture != target_idle:
			_char_sprite.texture = target_idle
			_align_sprite_offset()


func _update_facing(dir: Vector2) -> void:
	if dir.length_squared() < 0.01:
		return

	var abs_x: float = absf(dir.x)
	var abs_y: float = absf(dir.y)

	# Directional Hysteresis (1.25 ratio prevents 45-degree diagonal jitter)
	var is_horizontal: bool = (facing_direction == Facing.LEFT or facing_direction == Facing.RIGHT)

	if is_horizontal:
		if abs_y > abs_x * 1.25:
			facing_direction = Facing.DOWN if dir.y > 0.0 else Facing.UP
		else:
			facing_direction = Facing.RIGHT if dir.x > 0.0 else Facing.LEFT
	else:
		if abs_x > abs_y * 1.25:
			facing_direction = Facing.RIGHT if dir.x > 0.0 else Facing.LEFT
		else:
			facing_direction = Facing.DOWN if dir.y > 0.0 else Facing.UP


func _execute_tool_action(plot: GardenPlot, action_name: String, on_trigger: Callable, on_complete: Callable) -> void:
	if is_tending:
		return

	is_tending = true
	current_held_tool = action_name

	# Face plot center directly
	var to_plot: Vector2 = plot.global_position - global_position
	_update_facing(to_plot)
	var flip: bool = (facing_direction == Facing.LEFT)
	_char_sprite.scale.x = -CHAR_SCALE_FACTOR if flip else CHAR_SCALE_FACTOR
	queue_redraw()

	# Action pose
	match action_name:
		"water":
			_char_sprite.texture = _tex_action_water
			_tool_spray_particles.color = Color(0.38, 0.78, 1.0, 0.9)
			_tool_spray_particles.position = Vector2(-16.0 if flip else 16.0, -18.0)
			_tool_spray_particles.direction = (plot.global_position - global_position).normalized()
			_tool_spray_particles.restart()
			_tool_spray_particles.emitting = true
		"prune":
			_char_sprite.texture = _tex_action_plant
			_tool_spray_particles.color = Color(0.38, 0.85, 0.42, 0.9)
			_tool_spray_particles.position = Vector2(-12.0 if flip else 12.0, -16.0)
			_tool_spray_particles.direction = Vector2(0, -1)
			_tool_spray_particles.restart()
			_tool_spray_particles.emitting = true
		"harvest":
			_char_sprite.texture = _tex_action_harvest
		"celebrate":
			_char_sprite.texture = _tex_action_celebrate
		_:
			_char_sprite.texture = _tex_action_plant

	_align_sprite_offset()

	var tween := create_tween()
	if tween:
		tween.tween_property(_char_sprite, "position:y", 2.0, 0.15).set_trans(Tween.TRANS_QUAD)
		tween.tween_callback(func() -> void:
			if on_trigger.is_valid():
				on_trigger.call()
		)
		tween.tween_interval(0.15)
		tween.tween_property(_char_sprite, "position:y", 0.0, 0.15).set_trans(Tween.TRANS_QUAD)
		tween.tween_callback(func() -> void:
			is_tending = false
			current_held_tool = ""
			queue_redraw()
			if on_complete.is_valid():
				on_complete.call()
		)
	else:
		if on_trigger.is_valid():
			on_trigger.call()
		is_tending = false
		current_held_tool = ""
		queue_redraw()
		if on_complete.is_valid():
			on_complete.call()


func play_tending_gesture(plot_pos: Vector2 = Vector2.ZERO) -> void:
	play_action("water", 1.0)


func play_action(action_name: String = "plant", duration: float = 1.0) -> void:
	if is_tending:
		return
	is_tending = true
	current_held_tool = action_name
	queue_redraw()

	var tween := create_tween()
	if tween:
		tween.tween_property(_char_sprite, "position:y", 2.0, duration * 0.35).set_trans(Tween.TRANS_QUAD)
		tween.tween_property(_char_sprite, "position:y", 0.0, duration * 0.45).set_trans(Tween.TRANS_QUAD)
		tween.tween_interval(duration * 0.2)
		tween.tween_callback(func() -> void:
			is_tending = false
			current_held_tool = ""
			queue_redraw()
		)
	else:
		is_tending = false
		current_held_tool = ""


func set_active_tool(tool_name: String) -> void:
	active_selected_tool = tool_name
	_update_held_tool_visual()


func _update_held_tool_visual() -> void:
	if not is_instance_valid(_held_tool_sprite):
		return

	# When performing dedicated action poses, Lily already holds the tools in the authentic art
	if is_tending:
		_held_tool_sprite.visible = false
		return

	var tool_to_show := current_held_tool if not current_held_tool.is_empty() else active_selected_tool
	if tool_to_show.is_empty():
		_held_tool_sprite.visible = false
		return

	var is_left: bool = (facing_direction == Facing.LEFT)
	var sign_x: float = -1.0 if is_left else 1.0

	# Scale and position calibrated to Lily's natural hand level (y = -36)
	match tool_to_show:
		"water":
			_held_tool_sprite.visible = true
			_held_tool_sprite.texture = _prop_watering_can
			_held_tool_sprite.scale = Vector2(0.09 * sign_x, 0.09)
			_held_tool_sprite.position = Vector2(15.0 * sign_x, -36.0)
			_held_tool_sprite.rotation = 0.12 * sign_x
		"prune":
			_held_tool_sprite.visible = true
			_held_tool_sprite.texture = _prop_shears
			_held_tool_sprite.scale = Vector2(0.10 * sign_x, 0.10)
			_held_tool_sprite.position = Vector2(14.0 * sign_x, -35.0)
			_held_tool_sprite.rotation = -0.15 * sign_x
		"plant":
			_held_tool_sprite.visible = true
			_held_tool_sprite.texture = _prop_trowel
			_held_tool_sprite.scale = Vector2(0.09 * sign_x, 0.09)
			_held_tool_sprite.position = Vector2(14.0 * sign_x, -35.0)
			_held_tool_sprite.rotation = 0.20 * sign_x
		_:
			_held_tool_sprite.visible = false


func _unhandled_input(event: InputEvent) -> void:
	if not character_enabled:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var target := get_global_mouse_position()
		var p_parent := get_parent()
		if p_parent != null:
			var grid_node := p_parent.get_node_or_null("GardenGrid")
			if grid_node != null and "plots" in grid_node:
				for p in grid_node.plots:
					if p is GardenPlot and p.is_point_inside_plot(p.to_local(target)):
						return
		target_pos = target
		if p_parent != null and p_parent.has_node("GardenEnvironment"):
			var env_node := p_parent.get_node("GardenEnvironment") as GardenEnvironment
			if env_node != null:
				env_node.show_destination_marker(target)


func _check_plot_proximity() -> void:
	var plots: Array = []
	if is_inside_tree() and get_tree() != null:
		plots = get_tree().get_nodes_in_group("garden_plots")
	if plots.is_empty():
		var p_parent := get_parent()
		if p_parent != null:
			var grid_node := p_parent.get_node_or_null("GardenGrid")
			if grid_node != null and "plots" in grid_node:
				plots = grid_node.plots

	var nearest: GardenPlot = null
	var min_dist := PROXIMITY_RADIUS

	for p in plots:
		if p is GardenPlot:
			var d: float = global_position.distance_to(p.global_position)
			if d < min_dist:
				min_dist = d
				nearest = p

	if nearest != _closest_plot:
		if _closest_plot != null:
			plot_exited.emit(_closest_plot)
		_closest_plot = nearest
		if _closest_plot != null:
			plot_approached.emit(_closest_plot)


func _play_sfx(sfx_name: String, pitch_rand: float = 0.06, vol_db: float = 0.0) -> void:
	if is_inside_tree() and get_tree() != null and get_tree().root != null and get_tree().root.has_node("AudioManager"):
		var am = get_tree().root.get_node("AudioManager")
		if am != null and am.has_method("play_sfx"):
			am.play_sfx(sfx_name, pitch_rand, vol_db)


func _draw() -> void:
	# Grounding Contact Shadow
	_draw_custom_ellipse(Vector2(0, 0), 16.0, 7.0, Color(0.06, 0.11, 0.07, 0.30))
	_draw_custom_ellipse(Vector2(0, -1), 11.0, 4.5, Color(0.04, 0.08, 0.05, 0.20))

	# Action Queue Badges
	for idx in range(task_queue.size()):
		var task: Dictionary = task_queue[idx]
		var plot: GardenPlot = task.get("plot", null)
		if is_instance_valid(plot):
			var local_badge_pos: Vector2 = to_local(plot.global_position + Vector2(0, -28.0))
			draw_circle(local_badge_pos, 13.0, Color(1.0, 0.85, 0.25, 0.95))
			draw_circle(local_badge_pos, 10.0, Color(0.18, 0.12, 0.06, 0.95))
			var num_str := str(idx + 1)
			draw_string(ThemeDB.fallback_font, local_badge_pos + Vector2(-3.5, 4.0), num_str, HORIZONTAL_ALIGNMENT_CENTER, -1, 12, Color(1.0, 0.95, 0.6))


func _draw_custom_ellipse(center: Vector2, radius_x: float, radius_y: float, color: Color, segments: int = 18) -> void:
	var points := PackedVector2Array()
	for i in range(segments):
		var angle: float = (float(i) / float(segments)) * TAU
		points.append(center + Vector2(cos(angle) * radius_x, sin(angle) * radius_y))
	draw_colored_polygon(points, color)
