extends SceneTree

## Visual capture for the Overhauled Botanical Breeding Conservatory Modal.

var frame_count: int = 0
var main_node: MainGame = null
var output_file: String = "/home/el3laimy/.gemini/antigravity-ide/brain/eb1af34d-36d1-4c02-afee-20db3b1389ab/hud_breeding_modal_overhaul.png"


func _init() -> void:
	var main_scene_res := load("res://scenes/main.tscn")
	main_node = main_scene_res.instantiate() as MainGame
	root.add_child(main_node)


func _process(_delta: float) -> bool:
	frame_count += 1

	match frame_count:
		8:
			main_node.coins = 500
			main_node.inventory["rose"] = 5
			main_node.inventory["lavender"] = 6
			main_node.inventory["sunflower"] = 3
			main_node.inventory["tulip"] = 4
			main_node.inventory["daisy"] = 8
			main_node._sync_hud_state()

			# Open the breeding modal
			main_node.hud.open_breeding_modal()

			var modal: BreedingModal = main_node.hud._breeding_modal_instance
			if modal != null:
				modal.selected_parent_a_id = "rose"
				modal.selected_parent_b_id = "lavender"
				modal._update_slots_ui()
				modal._populate_roster()

		16:
			var image: Image = root.get_viewport().get_texture().get_image()
			if image != null:
				var err := image.save_png(output_file)
				if err == OK:
					print("✓ Captured visual artifact: hud_breeding_modal_overhaul.png")
				else:
					printerr("Failed to save PNG")
			else:
				printerr("Viewport image was null")
			quit(0)

	return false
