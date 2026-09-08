extends SceneTree

## UI Visual Capture Suite for Phase 3 — Modular Modals & Theming.

var frame_count: int = 0
var main_node: MainGame = null
var output_dir: String = "/home/el3laimy/.gemini/antigravity-ide/brain/eb1af34d-36d1-4c02-afee-20db3b1389ab"


func _init() -> void:
	var main_scene_res := load("res://scenes/main.tscn")
	main_node = main_scene_res.instantiate() as MainGame
	root.add_child(main_node)


func _process(delta: float) -> bool:
	frame_count += 1

	match frame_count:
		5:
			# Setup inventory & state
			main_node.coins = 240
			main_node.combo_count = 3
			main_node.inventory["rose"] = 5
			main_node.inventory["lavender"] = 6
			main_node.inventory["sunflower"] = 4
			main_node._sync_hud_state()

		10:
			# Open Requests Modal
			pass

		15:
			_capture_screen("current_hud_overview.png")
			main_node.hud.close_requests_modal()

		20:
			# Open Shed Shop Upgrades Modal
			main_node.hud.open_upgrades_modal()

		25:
			_capture_screen("p3_shed_shop_upgrades_themed.png")
			main_node.hud.close_upgrades_modal()

		30:
			# Open Bouquet Workshop Modal
			main_node.hud.open_bouquets_modal()

		35:
			_capture_screen("p3_bouquet_workshop_themed.png")
			main_node.hud.close_bouquets_modal()

		40:
			print("✓ [P3-VISUAL] All Phase 3 UI visual artifacts captured successfully.")
			quit(0)

	return false


func _capture_screen(filename: String) -> void:
	var image: Image = root.get_viewport().get_texture().get_image()
	var dest_path: String = output_dir + "/" + filename
	var err := image.save_png(dest_path)
	if err == OK:
		print("✓ Captured visual artifact: " + filename)
	else:
		printerr("Failed to save screenshot: " + dest_path)
