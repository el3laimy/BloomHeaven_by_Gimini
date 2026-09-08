extends SceneTree

## Capture In-Engine Screenshot of the Wood & Parchment Storybook In-Game HUD

func _init() -> void:
	print("--- Starting Storybook HUD Capture ---")
	var main_scene = load("res://scenes/main.tscn")
	var main_node = main_scene.instantiate()
	root.add_child(main_node)

	for i in range(10):
		await process_frame

	# Setup a rich garden state
	if is_instance_valid(main_node.garden_grid):
		var plots = main_node.garden_grid.plots
		if plots.size() > 0:
			var p0: GardenPlot = plots[0]
			p0.plant("rose")
			p0.water()
			p0.growth_progress = 0.72 # Bud stage
			p0.is_pruned = true
			main_node.garden_grid.selected_plot = p0
			main_node.hud.update_plot_info(p0)

	# Ensure HUD has inventory and active customer tickets
	var flower_inv := {"rose": 14, "lavender": 8, "sunflower": 5}
	var bouquet_inv := {"rose_bouquet": 2}
	main_node.hud.update_inventory(flower_inv, bouquet_inv, 28450, 2)

	# Let frames render
	for i in range(30):
		await process_frame

	# Capture viewport
	var img = root.get_viewport().get_texture().get_image()
	var dest_path = "/home/el3laimy/.gemini/antigravity-ide/brain/eb1af34d-36d1-4c02-afee-20db3b1389ab/hud_storybook_overhaul_live.png"
	img.save_png(dest_path)
	print("✓ Captured In-Game Screenshot to: " + dest_path)
	quit(0)
