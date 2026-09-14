extends SceneTree

var frame_count: int = 0
var main_node: MainGame = null

func _init() -> void:
	var main_scene_res := load("res://scenes/main.tscn")
	main_node = main_scene_res.instantiate() as MainGame
	root.add_child(main_node)

func _process(_delta: float) -> bool:
	frame_count += 1
	if frame_count == 5:
		main_node.coins = 240
		main_node.inventory["rose"] = 2
		main_node.inventory["lavender"] = 2
		main_node.inventory["sunflower"] = 1
		main_node.bouquet_inventory["ethereal_lumina"] = 1
		main_node.completed_requests["order_1"] = false
		main_node.live_orders_patience["order_1"] = 72.0
		main_node._sync_hud_state()
		if is_instance_valid(main_node.hud) and is_instance_valid(main_node.hud._side_order_rail):
			main_node.hud._side_order_rail.select_order("order_1")
	elif frame_count == 15:
		var img = root.get_viewport().get_texture().get_image()
		img.save_png("tools/screen_orders_board.png")
		print("✓ Captured screen to tools/screen_orders_board.png")
		quit(0)
	return false
