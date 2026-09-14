extends SceneTree

func _init() -> void:
	var main_scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(main_scene)
	
	var timer := 0
	process_frame.connect(func():
		timer += 1
		if timer == 15:
			if is_instance_valid(main_scene) and "hud" in main_scene and is_instance_valid(main_scene.hud):
				var rail = main_scene.hud.get("_side_order_rail")
				if is_instance_valid(rail):
					rail.select_order("order_1")
					print("✓ Opened side order rail on order_1")
		elif timer == 40:
			RenderingServer.frame_post_draw.connect(func():
				var img = root.get_viewport().get_texture().get_image()
				if img != null:
					img.save_png("tools/screen_orders_board_live.png")
					print("✓ Successfully saved tools/screen_orders_board_live.png: ", img.get_size())
				quit(0)
			, CONNECT_ONE_SHOT)
	)


