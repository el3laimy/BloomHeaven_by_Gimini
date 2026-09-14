extends SceneTree

func _init() -> void:
	var board = load("res://scenes/ui/orders/order_board_content.tscn").instantiate()
	root.add_child(board)
	var pb = board.get_node("HeaderArea/ProgressBar")
	print("PB visible:", pb.visible)
	print("PB size:", pb.size, "position:", pb.position)
	print("PB val:", pb.value, "under:", pb.texture_under, "prog:", pb.texture_progress)
	var satchel = board.get_node("HeaderArea/Satchel")
	print("Satchel visible:", satchel.visible, "pos:", satchel.position, "size:", satchel.size, "tex:", satchel.texture)
	quit()
