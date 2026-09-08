extends SceneTree

## Visual verification & capture script for Lily's upgraded character motion.
## Captures high-resolution beauty frames of the new walk cycle, living idle, and tending gesture.

func _init() -> void:
	print("--- Starting Character Motion Visual Capture ---")
	call_deferred("_run_capture")


func _run_capture() -> void:
	var main_scene: PackedScene = load("res://scenes/main.tscn")
	var main_node: Node = main_scene.instantiate()
	root.add_child(main_node)

	await process_frame
	await process_frame

	var char_node: GardenerCharacter = main_node.get_node_or_null("GardenerCharacter") as GardenerCharacter
	if char_node == null:
		print("Error: GardenerCharacter not found!")
		quit(1)
		return

	# Position character on center path
	char_node.position = Vector2(0, 40)
	char_node.clear_queue()

	# --- Phase 1: Capture Living Idle Frame ---
	print("Capturing Frame 1: Living Idle...")
	char_node._idle_timer = 1.2
	char_node._update_animation_frames(0.016)
	char_node.queue_redraw()
	await process_frame
	await process_frame
	_save_viewport_image("character_motion_idle.png")

	# --- Phase 2: Capture Walking Stride (Contact Phase & Dust) ---
	print("Capturing Frame 2: Walking Stride with Foot Plant & Dust...")
	char_node.velocity = Vector2(140.0, 0.0)
	char_node.is_moving = true
	char_node.facing_direction = GardenerCharacter.Facing.RIGHT
	char_node._walk_frame_index = 0
	char_node._char_sprite.texture = char_node._walk_frames[0]
	char_node._update_animation_frames(0.016)
	if is_instance_valid(char_node._step_dust):
		char_node._step_dust.position = Vector2(-4, 2)
		char_node._step_dust.restart()
		char_node._step_dust.emitting = true
	char_node.queue_redraw()
	await process_frame
	await process_frame
	_save_viewport_image("character_motion_walk_stride.png")

	# --- Phase 3: Capture Tending Gesture (Forward Bend with Watering Can) ---
	print("Capturing Frame 3: Forward Bend Tending Gesture...")
	var plot: GardenPlot = null
	if main_node.has_node("GardenGrid"):
		var grid: GardenGrid = main_node.get_node("GardenGrid") as GardenGrid
		if not grid.plots.is_empty():
			plot = grid.plots[0]

	if plot != null:
		char_node.position = plot.global_position + Vector2(0, 30.0)
		char_node.set_active_tool("water")
		char_node._execute_tool_action(plot, "water", Callable(), Callable())
		# Set mid-action apex pose
		if is_instance_valid(char_node._char_sprite):
			char_node._char_sprite.position.y = 3.5
			char_node._char_sprite.rotation = 0.09
		char_node.queue_redraw()

	await process_frame
	await process_frame
	_save_viewport_image("character_motion_tending.png")

	print("✓ All character motion frames captured successfully!")
	quit(0)


func _save_viewport_image(filename: String) -> void:
	var vp: Viewport = root.get_viewport()
	var tex: Texture2D = vp.get_texture()
	var img: Image = tex.get_image()
	var out_path: String = "/home/el3laimy/.gemini/antigravity-ide/brain/eb1af34d-36d1-4c02-afee-20db3b1389ab/" + filename
	img.save_png(out_path)
	print("   ✓ Saved beauty capture to: ", out_path)
