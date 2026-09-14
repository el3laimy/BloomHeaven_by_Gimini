extends SceneTree

var resolutions := [
	Vector2i(360, 800),
	Vector2i(390, 844),
	Vector2i(430, 932)
]
var res_idx := 0
var frame_count := 0
var current_board: Control = null
var current_subview: SubViewport = null

func _init() -> void:
	print("Starting multi-resolution mobile verification...")

func _process(_delta: float) -> bool:
	frame_count += 1
	if current_board == null and res_idx < resolutions.size():
		var res: Vector2i = resolutions[res_idx]
		print("Setting up viewport for: ", res.x, "x", res.y)
		
		# Create SubViewport with exact resolution
		current_subview = SubViewport.new()
		current_subview.size = res
		current_subview.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		root.add_child(current_subview)
		
		# Instantiate OrderBoardContent centered
		var scene_res := load("res://scenes/ui/orders/order_board_content.tscn")
		current_board = scene_res.instantiate() as Control
		current_board.custom_minimum_size = Vector2(410, 660)
		current_board.size = Vector2(410, 660)
		current_board.pivot_offset = Vector2(205, 330)
		current_board.scale = Vector2(1.15, 1.15)
		var center_box := CenterContainer.new()
		center_box.size = Vector2(res.x, res.y)
		center_box.anchors_preset = Control.PRESET_FULL_RECT
		current_subview.add_child(center_box)
		center_box.add_child(current_board)
		
		# Supply test data matching reference states:
		# Card 1 (Maya): lavender 2, sunflower 1 -> has both -> Ready to Deliver (Green Action Button)
		# Card 2 (Lucian): rose 2, lavender 1 -> has rose 1 -> In Progress (Neutral Button)
		# Card 3 (Clara): Completed -> Delivered with Laurel Wax Seal
		var inv := {"lavender": 2, "sunflower": 1, "rose": 1}
		var b_inv := {"ethereal_lumina": 1}
		var pat := {"order_1": 75.0, "order_2": 35.0}
		var comp := {"order_3": true}
		current_board.call("update_state", inv, b_inv, pat, comp)
		current_board.call("select_order", "order_1")
		frame_count = 0
		
	elif current_board != null:
		if frame_count >= 8:
			var res: Vector2i = resolutions[res_idx]
			var img := current_subview.get_texture().get_image()
			var filename := "tools/screen_order_board_%dx%d.png" % [res.x, res.y]
			img.save_png(filename)
			print("✓ Captured in-engine screenshot: ", filename)
			
			# Clean up
			current_board.queue_free()
			current_subview.queue_free()
			current_board = null
			current_subview = null
			res_idx += 1
			frame_count = 0
			
			if res_idx >= resolutions.size():
				print("✓ Multi-resolution mobile verification complete!")
				quit(0)
				
	return false
