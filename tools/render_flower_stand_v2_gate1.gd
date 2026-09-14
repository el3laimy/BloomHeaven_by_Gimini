extends SceneTree

var frame_count: int = 0
var main_node: Node = null
var stand_node: Control = null

func _init() -> void:
	var main_scene_res := load("res://scenes/main.tscn")
	main_node = main_scene_res.instantiate()
	root.add_child(main_node)

	var stand_res := load("res://scenes/ui/flower_stand/flower_stand_v2.tscn")
	stand_node = stand_res.instantiate() as Control
	stand_node.z_index = 100
	stand_node.modulate.a = 1.0
	root.add_child(stand_node)

func _process(_delta: float) -> bool:
	frame_count += 1
	if frame_count == 5:
		if is_instance_valid(main_node.hud):
			# Hide any overlapping HUD elements for full isolation
			if is_instance_valid(main_node.hud._side_order_rail):
				main_node.hud._side_order_rail.hide()
		stand_node.show()
		stand_node.move_to_front()
	elif frame_count == 15:
		var img = root.get_viewport().get_texture().get_image()
		img.save_png("tools/gate1_shell_live.png")
		print("✓ Captured Gate 1 shell live render to tools/gate1_shell_live.png")
		quit(0)
	return false
