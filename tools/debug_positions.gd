extends SceneTree

func _init() -> void:
	var main_scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(main_scene)

func _process(_delta: float) -> bool:
	var rail = root.find_child("SideOrderRail", true, false)
	if rail != null:
		var board = rail.find_child("OrderBoard", true, false)
		if board != null:
			print("Board global_pos:", board.global_position, "size:", board.size)
			var pb = board.find_child("ProgressBar", true, false)
			print("PB global_pos:", pb.global_position, "size:", pb.size, "visible:", pb.is_visible_in_tree())
			var cards = board.find_child("CardsVBox", true, false)
			print("Cards global_pos:", cards.global_position, "size:", cards.size)
			var c1 = board.find_child("OrderCard_01", true, false)
			print("Card1 global_pos:", c1.global_position, "size:", c1.size)
			quit()
			return true
	return false
