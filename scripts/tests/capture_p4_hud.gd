extends SceneTree

## Visual Capture Suite for Storybook Main In-Game HUD Overhaul (Fiona Finch Direction).

var frame_count: int = 0
var main_node: MainGame = null
var output_dir: String = "/home/el3laimy/.gemini/antigravity-ide/brain/eb1af34d-36d1-4c02-afee-20db3b1389ab"


func _init() -> void:
	var main_scene_res := load("res://scenes/main.tscn")
	main_node = main_scene_res.instantiate() as MainGame
	root.add_child(main_node)


func _process(_delta: float) -> bool:
	frame_count += 1

	match frame_count:
		5:
			# Setup rich cozy garden state
			main_node.coins = 350
			main_node.inventory["rose"] = 4
			main_node.inventory["lavender"] = 6
			main_node.inventory["sunflower"] = 3
			main_node.bouquet_inventory["garden_harmony"] = 1
			main_node._sync_hud_state()

			# Plant and water some plots for rich visual life
			if main_node.garden_grid != null and not main_node.garden_grid.plots.is_empty():
				var p0: GardenPlot = main_node.garden_grid.plots[0]
				p0.plant("rose", false)
				p0.water()
				p0.growth_progress = 0.68 # Inside pruning window!

				var p1: GardenPlot = main_node.garden_grid.plots[1]
				p1.plant("sunflower", false)
				p1.water()
				p1.growth_progress = 1.0 # Mature Bloom!
				p1.state = GardenPlot.State.MATURE

				var p2: GardenPlot = main_node.garden_grid.plots[2]
				p2.plant("lavender", false)
				p2.growth_progress = 0.35 # Sprout

			# Lily character equipped with watering can
			if main_node.character != null:
				main_node.character.position = Vector2(0, 40)
				main_node.character.set_active_tool("water")

		10:
			# 1. Capture Main Storybook Overview (75% garden, slim top bar, side order rail, toolbelt)
			_capture_screen("hud_storybook_overview.png")

		15:
			# 2. Select Plot #1 to trigger Plot Inspector with 4-stage timeline and pruning alert
			if main_node.garden_grid != null and not main_node.garden_grid.plots.is_empty():
				var p0: GardenPlot = main_node.garden_grid.plots[0]
				main_node.hud.update_plot_info(p0)
				# Also give Lily pruning shears
				if main_node.character != null:
					main_node.character.set_active_tool("prune")

		20:
			_capture_screen("hud_plot_inspector_timeline.png")

		25:
			# 3. Open Lily's Character Hub [👒 Lily]
			if main_node.hud._lily_hub != null:
				main_node.hud._lily_hub.show()

		30:
			_capture_screen("hud_lily_hub_menu.png")
			if main_node.hud._lily_hub != null:
				main_node.hud._lily_hub.hide()

		35:
			# 4. Open Satchel Inventory Drawer [🎒 Satchel]
			if main_node.hud._inventory_drawer != null:
				main_node.hud._inventory_drawer.show()

		40:
			_capture_screen("hud_satchel_drawer.png")
			if main_node.hud._inventory_drawer != null:
				main_node.hud._inventory_drawer.hide()

		45:
			print("✓ [HUD-VISUALS] All Storybook Main HUD visual artifacts successfully captured!")
			quit(0)

	return false


func _capture_screen(filename: String) -> void:
	var image: Image = root.get_viewport().get_texture().get_image()
	if image != null:
		var dest_path: String = output_dir + "/" + filename
		var err := image.save_png(dest_path)
		if err == OK:
			print("✓ Captured visual artifact: " + filename)
		else:
			printerr("Failed to save screenshot: " + dest_path)
	else:
		printerr("Viewport image was null for: " + filename)
