extends SceneTree

## Tool: capture_main_gui.gd
## Renders the canonical main game world (res://scenes/main.tscn) in active GUI mode
## and captures a high-fidelity screenshot with complete environment, HUD, and garden plots.
##
## Usage:
##   godot -s tools/visual_qa/capture_main_gui.gd --out=<path> [--plot=<index>] [--flower=<id>] [--stage=<stage>] [--pruned=<0|1>]

var _out_path: String = "/tmp/main_gui_capture.png"
var _plot_index: int = 4
var _flower_id: String = "rose"
var _stage_name: String = "bloom_hero"
var _is_pruned: bool = true
var _is_watered: bool = true

func _init() -> void:
	# Parse command-line args (support both user args and direct args)
	var args := OS.get_cmdline_user_args()
	if args.is_empty():
		args = OS.get_cmdline_args()
	for a in args:
		if a.begins_with("--out="):
			_out_path = a.replace("--out=", "")
		elif a.begins_with("--plot="):
			_plot_index = int(a.replace("--plot=", ""))
		elif a.begins_with("--flower="):
			_flower_id = a.replace("--flower=", "")
		elif a.begins_with("--stage="):
			_stage_name = a.replace("--stage=", "")
		elif a.begins_with("--pruned="):
			_is_pruned = (a.replace("--pruned=", "") == "1" or a.replace("--pruned=", "").to_lower() == "true")
		elif a.begins_with("--watered="):
			_is_watered = (a.replace("--watered=", "") == "1" or a.replace("--watered=", "").to_lower() == "true")

	# Safe sandboxing: isolate SaveManager before anything touches it
	var save_mgr = Engine.get_singleton("SaveManager") if Engine.has_singleton("SaveManager") else null
	if save_mgr and save_mgr.has_method("set_sandbox_save_path"):
		save_mgr.set_sandbox_save_path("user://visual_qa_sandbox_save.json")

	_run_capture()

func _run_capture() -> void:
	print("==================================================")
	print("🌿 BLOOMHAVEN GUI CAPTURE: %s 🌿" % _out_path)
	print("Plot: %d | Flower: %s | Stage: %s | Pruned: %s" % [_plot_index, _flower_id, _stage_name, str(_is_pruned)])
	print("==================================================")

	var main_res := load("res://scenes/main.tscn")
	if main_res == null:
		printerr("❌ ERROR: Failed to load res://scenes/main.tscn")
		quit(1)
		return

	var main_scene = main_res.instantiate()
	main_scene.active_save_path = "user://visual_qa_sandbox_save.json"
	main_scene.tutorial_completed = true
	root.add_child(main_scene)

	# Allow _ready() and _create_grid() to execute
	await process_frame

	# Configure target plot
	var grid: GardenGrid = main_scene.find_child("GardenGrid", true, false)
	if grid and _plot_index >= 0 and _plot_index < grid.plots.size():
		var target_plot: GardenPlot = grid.plots[_plot_index]
		target_plot.plant(_flower_id)
		target_plot.is_watered = _is_watered
		target_plot.is_pruned = _is_pruned
		
		# Set stage progress based on stage_name
		match _stage_name:
			"sprout":
				target_plot.growth_progress = 0.35
				target_plot.is_pruned = false
			"vegetative_branching":
				target_plot.growth_progress = 0.65
				target_plot.is_pruned = false
			"vegetative_single":
				target_plot.growth_progress = 0.70
				target_plot.is_pruned = true
			"vegetative_late_unpruned":
				target_plot.growth_progress = 0.88
				target_plot.is_pruned = false
			"bloom_standard":
				target_plot.growth_progress = 1.0
				target_plot.is_pruned = false
			"bloom_hero":
				target_plot.growth_progress = 1.0
				target_plot.is_pruned = true
			_:
				target_plot.growth_progress = 1.0

		target_plot._update_growth_stage()
		var fv = target_plot.find_child("FlowerVisual")
		if fv:
			fv.is_pruned = target_plot.is_pruned
			fv.queue_redraw()
		target_plot.queue_redraw()
		print("✓ Planted %s (%s) on Plot %d" % [_flower_id, _stage_name, _plot_index])

	# Adjust character position slightly to avoid occluding Plot 4
	var character = main_scene.find_child("GardenerCharacter", true, false)
	if character:
		character.position = Vector2(30, 40)

	# Wait for rendering to settle
	for i in range(12):
		await process_frame

	# Ensure post-draw has completed
	var post_draw_fired := false
	var cb := func(): post_draw_fired = true
	RenderingServer.frame_post_draw.connect(cb, CONNECT_ONE_SHOT)
	for i in range(6):
		await process_frame
		if post_draw_fired:
			break

	var tex := root.get_texture()
	if tex == null:
		printerr("❌ ERROR: root.get_texture() returned null")
		quit(1)
		return

	var img: Image = tex.get_image()
	if img == null:
		printerr("❌ ERROR: tex.get_image() returned null")
		quit(1)
		return

	# Ensure parent directory exists
	var dir_path := _out_path.get_base_dir()
	if not DirAccess.dir_exists_absolute(dir_path):
		DirAccess.make_dir_recursive_absolute(dir_path)

	var err := img.save_png(_out_path)
	if err == OK:
		print("🎉 Main GUI capture saved successfully to: %s (%dx%d)" % [_out_path, img.get_width(), img.get_height()])
		quit(0)
	else:
		printerr("❌ ERROR: Failed to save PNG to %s (code %d)" % [_out_path, err])
		quit(1)
