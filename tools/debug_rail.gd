extends SceneTree

func _init() -> void:
	var main_scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(main_scene)

func _process(_delta: float) -> bool:
	var rail = root.find_child("SideOrderRail", true, false)
	if rail != null:
		print("Rail pos:", rail.position, "global_pos:", rail.global_position, "size:", rail.size)
		print("Rail anchors:", rail.anchor_left, rail.anchor_top, rail.anchor_right, rail.anchor_bottom)
		print("Rail offsets:", rail.offset_left, rail.offset_top, rail.offset_right, rail.offset_bottom)
		print("Rail parent:", rail.get_parent().name, "parent size:", rail.get_parent().size)
		var bp = rail.get_node("BoardPanel")
		print("BP pos:", bp.position, "size:", bp.size)
		var ob = bp.get_node("OrderBoard")
		print("OB pos:", ob.position, "size:", ob.size)
		print("OB offsets:", ob.offset_left, ob.offset_top, ob.offset_right, ob.offset_bottom)
		quit()
		return true
	return false
