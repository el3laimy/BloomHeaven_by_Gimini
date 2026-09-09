extends SceneTree

## Capture In-Engine Screenshot of the Flower Stand & Satchel Quick Sell UI

func _init() -> void:
	print("--- Starting Flower Stand UI Capture ---")
	var main_scene = load("res://scenes/main.tscn")
	var main_node = main_scene.instantiate()
	root.add_child(main_node)

	for i in range(10):
		await process_frame

	# Setup rich inventory for sale
	main_node.coins = 120
	main_node.inventory["rose"] = 5
	main_node.inventory["daisy"] = 8
	main_node.inventory["lavender"] = 3
	main_node.inventory["tulip"] = 2
	main_node.bouquet_inventory["garden_harmony"] = 1
	main_node._sync_hud_state()

	# Open the Flower Stand / Satchel Drawer
	if is_instance_valid(main_node.hud) and is_instance_valid(main_node.hud._inventory_drawer):
		main_node.hud._inventory_drawer.show()

	for i in range(15):
		await process_frame

	var vp = root.get_viewport()
	if vp != null and vp.get_texture() != null:
		var img = vp.get_texture().get_image()
		if img != null:
			var dest_path = "/home/el3laimy/.gemini/antigravity/brain/c18f39df-35cc-4bc9-9225-9e72dac391af/flower_stand_live.png"
			img.save_png(dest_path)
			print("✓ Captured Flower Stand UI to: " + dest_path)

	quit(0)
