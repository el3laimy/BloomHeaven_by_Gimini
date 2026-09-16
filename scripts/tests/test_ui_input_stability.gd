extends SceneTree

## BloomHaven UI, Signals, and Input Stability Verification Suite (Sprint D)
## Validates:
## 1. Real Pause Semantics (tree pause, plot freeze, timers freeze, character freeze, patience freeze, resume, settings, scene switch)
## 2. Audio Bus & Canonical SFX Routing
## 3. Order Card Signal Lifecycle & Zero Duplication
## 4. Specimen Reveal Zero-Leak Lifecycle
## 5. Flower Stand Signal Wiring
## 6. Breeding Domain Validator & Specimen Collision
## 7. Garden Adjacency Spatial Filtering
## 8. Camera Delta Clamping
## 9. RMB Pan vs Queue Cancel
## 10. Character Action Completion Callback Lifecycle

var _passed_tests: int = 0
var _failed_tests: int = 0

const BreedingService := preload("res://scripts/domain/breeding_service.gd")
const AudioManagerScript := preload("res://scripts/core/audio_manager.gd")


func _init() -> void:
	# Run async test suite
	_run_all_tests()


func _run_all_tests() -> void:
	print("==================================================")
	print("RUNNING BLOOMHAVEN SPRINT D UI & INPUT STABILITY SUITE")
	print("==================================================")

	# Normal scene tree pause behavior: child nodes inherit pausable
	root.process_mode = Node.PROCESS_MODE_PAUSABLE

	await _run_suite("1. Pause Menu Pauses Scene Tree", _test_pause_menu_pauses_scene_tree)
	await _run_suite("2. Pause Freezes Garden Plot Growth", _test_pause_freezes_garden_plot)
	await _run_suite("3. Pause Freezes Water & Fertilizer Timers", _test_pause_freezes_water_fertilizer_timers)
	await _run_suite("4. Pause Freezes Character Movement", _test_pause_freezes_character_movement)
	await _run_suite("5. Pause Freezes Order Patience", _test_pause_freezes_order_patience)
	await _run_suite("6. Resume Unpauses Scene Tree", _test_resume_unpauses_scene_tree)
	await _run_suite("7. Settings Sub-Menu Preserves Pause On Close", _test_settings_sub_menu_preserves_pause_on_close)
	await _run_suite("8. Main Menu Transition Clears Pause", _test_main_menu_transition_clears_pause)
	await _run_suite("9. Audio Bus & Canonical SFX Resolution", _test_audio_bus_and_sfx)
	await _run_suite("10. Audio Settings Volume Routing & Isolation", _test_audio_settings_routing)
	await _run_suite("11. Order Card No Duplicate Callbacks After Refreshes", _test_order_card_no_duplicate_callbacks)
	await _run_suite("12. Specimen Reveal No Leak On Repeated Shows", _test_specimen_reveal_no_leak)
	await _run_suite("13. Flower Stand Toggle Single Callback", _test_flower_stand_toggle_single_callback)
	await _run_suite("14. Breeding Validator Accepts Valid Pair", _test_breeding_validator_accepts_valid_pair)
	await _run_suite("15. Breeding Validator Rejects Incompatible Species", _test_breeding_validator_rejects_incompatible)
	await _run_suite("16. Breeding Validator Rejects Same Specimen In Both Slots", _test_breeding_validator_rejects_same_specimen)
	await _run_suite("17. Breeding Validator Enforces Roster Ownership", _test_breeding_validator_enforces_roster_ownership)
	await _run_suite("18. Garden Adjacency Explicit Geometry & Ring Filtering", _test_garden_adjacency_nearest_neighbor)
	await _run_suite("19. Camera Lerp Clamped On Extreme Delta", _test_camera_lerp_clamped)
	await _run_suite("20. RMB Drag Preserves Action Queue, Clean Click Cancels", _test_rmb_drag_vs_click_queue)
	await _run_suite("21. Character Action Completion Callback Lifecycle (Production Path)", _test_character_action_completion_callback)

	print("\n==================================================")
	print("RESULTS: %d PASSED, %d FAILED" % [_passed_tests, _failed_tests])
	print("==================================================")

	# Teardown safety
	paused = false

	if _failed_tests > 0:
		printerr("❌ SPRINT D TEST SUITE FAILED!")
		quit(1)
	else:
		print("🎉 ALL SPRINT D TESTS PASSED (100% OK)!")
		quit(0)


func _run_suite(suite_name: String, test_func: Callable) -> void:
	print("\n--- Suite: %s ---" % suite_name)
	paused = false
	var err: String = await test_func.call()
	paused = false
	if err == null or err == "":
		print("  ✓ Suite Passed: %s" % suite_name)
		_passed_tests += 1
	else:
		printerr("  ❌ Suite FAILED: %s -> %s" % [suite_name, err])
		_failed_tests += 1


func _setup_main_node() -> MainGame:
	var main_scene_res := load("res://scenes/main.tscn")
	var main_node: MainGame = main_scene_res.instantiate() as MainGame
	root.add_child(main_node)
	return main_node


func _test_pause_menu_pauses_scene_tree() -> String:
	var main_node := _setup_main_node()
	await process_frame

	# Initial state should be unpaused
	if paused:
		main_node.free()
		return "Tree initially paused"

	# Toggle pause menu
	main_node._toggle_pause_menu()
	if not paused:
		main_node.free()
		return "get_tree().paused was not set to true on pause menu open"

	if not is_instance_valid(main_node._pause_menu) or not main_node._pause_menu.visible:
		main_node.free()
		return "Pause menu was not made visible"

	main_node.free()
	return ""


func _test_pause_freezes_garden_plot() -> String:
	var plot := GardenPlot.new()
	root.add_child(plot)
	await process_frame

	plot.plant("rose")
	plot.water()
	var init_progress: float = plot.growth_progress

	# Pause tree
	paused = true
	plot._process(1.0)

	var after_progress: float = plot.growth_progress
	plot.free()
	if after_progress != init_progress:
		return "Plot growth progressed while tree was paused: %f -> %f" % [init_progress, after_progress]

	return ""


func _test_pause_freezes_water_fertilizer_timers() -> String:
	var plot := GardenPlot.new()
	root.add_child(plot)
	await process_frame

	plot.plant("rose")
	plot.water()
	var init_water: float = plot.water_duration_remaining

	paused = true
	plot._process(2.0)

	var after_water: float = plot.water_duration_remaining
	plot.free()
	if after_water != init_water:
		return "Water timer decayed while paused: %f -> %f" % [init_water, after_water]

	return ""


func _test_pause_freezes_character_movement() -> String:
	var char_node := GardenerCharacter.new()
	root.add_child(char_node)
	await process_frame

	char_node.position = Vector2.ZERO
	char_node.target_pos = Vector2(100, 100)
	char_node.is_moving = true

	paused = true
	char_node._physics_process(1.0)

	var after_pos: Vector2 = char_node.position
	char_node.free()
	if after_pos != Vector2.ZERO:
		return "Character moved while paused: pos is %s" % str(after_pos)

	return ""


func _test_pause_freezes_order_patience() -> String:
	var main_node := _setup_main_node()
	await process_frame

	var om: OrderManager = main_node.order_manager
	if om == null or om.order_runtime.is_empty():
		main_node.free()
		return "OrderManager or order_runtime not initialized"

	var first_key: String = om.order_runtime.keys()[0]
	var initial_pat: float = om.order_runtime[first_key]["remaining_patience"]

	paused = true
	main_node._process(2.0)

	var after_pat: float = om.order_runtime[first_key]["remaining_patience"]
	if after_pat != initial_pat:
		main_node.free()
		return "Order patience decayed while tree was paused: %f -> %f" % [initial_pat, after_pat]

	main_node.free()
	return ""


func _test_resume_unpauses_scene_tree() -> String:
	var main_node := _setup_main_node()
	await process_frame

	main_node._toggle_pause_menu()
	if not paused:
		main_node.free()
		return "Tree failed to pause"

	main_node._pause_menu.resume_btn.pressed.emit()
	if paused:
		main_node.free()
		return "Tree failed to unpause on resume button press"

	if main_node._pause_menu.visible:
		main_node.free()
		return "Pause menu remained visible after resume"

	main_node.free()
	return ""


func _test_settings_sub_menu_preserves_pause_on_close() -> String:
	var main_node := _setup_main_node()
	await process_frame

	main_node._toggle_pause_menu()
	if not paused:
		main_node.free()
		return "Tree failed to pause"

	# Open settings from pause menu
	main_node._pause_menu.settings_btn.pressed.emit()
	if not main_node._settings_menu.visible:
		main_node.free()
		return "Settings menu failed to open"

	# Close settings menu
	main_node._settings_menu.close_btn.pressed.emit()
	if main_node._settings_menu.visible:
		main_node.free()
		return "Settings menu failed to hide on close"

	if not paused:
		main_node.free()
		return "Tree unpaused prematurely when settings menu was closed"

	main_node.free()
	return ""


func _test_main_menu_transition_clears_pause() -> String:
	var main_node := _setup_main_node()
	await process_frame

	main_node._toggle_pause_menu()
	if not paused:
		main_node.free()
		return "Tree failed to pause"

	# When main_menu_requested is emitted, paused must be reset to false before scene change
	main_node._pause_menu.main_menu_requested.emit()
	if paused:
		main_node.free()
		return "Tree remained paused on main menu transition request"

	main_node.free()
	return ""


func _test_audio_bus_and_sfx() -> String:
	# 1. Bus existence
	var music_idx := AudioServer.get_bus_index("Music")
	var sfx_idx := AudioServer.get_bus_index("SFX")
	if music_idx == -1:
		return "Music bus not found in AudioServer"
	if sfx_idx == -1:
		return "SFX bus not found in AudioServer"

	var audio_mgr: AudioManagerClass = AudioManagerScript.new()

	# 2. Canonical SFX IDs & Stream Resolution
	var expected_ids := ["click", "coin", "plant", "water", "prune", "harvest", "upgrade", "error", "step"]
	for id in expected_ids:
		if not audio_mgr.CANONICAL_SFX_IDS.has(id):
			audio_mgr.free()
			return "Missing canonical SFX ID in list: %s" % id
		var stream := audio_mgr.get_sfx_stream(id)
		if stream == null:
			audio_mgr.free()
			return "AudioManager failed to resolve canonical SFX ID '%s' to an audio stream" % id
		if not (stream is AudioStream):
			audio_mgr.free()
			return "Resolved stream for '%s' is not of type AudioStream" % id

	# 3. Aliases
	if not audio_mgr.SFX_ALIASES.has("sfx_click") or audio_mgr.SFX_ALIASES["sfx_click"] != "click":
		audio_mgr.free()
		return "SFX alias sfx_click -> click missing or incorrect"
	if not audio_mgr.SFX_ALIASES.has("craft") or audio_mgr.SFX_ALIASES["craft"] != "harvest":
		audio_mgr.free()
		return "SFX alias craft -> harvest missing or incorrect"
	var alias_stream := audio_mgr.get_sfx_stream("sfx_click")
	if alias_stream == null or alias_stream != audio_mgr.get_sfx_stream("click"):
		audio_mgr.free()
		return "Alias sfx_click did not resolve to canonical click stream"

	audio_mgr.free()
	return ""


func _test_audio_settings_routing() -> String:
	var master_idx := AudioServer.get_bus_index("Master")
	var music_idx := AudioServer.get_bus_index("Music")
	var sfx_idx := AudioServer.get_bus_index("SFX")

	if master_idx == -1 or music_idx == -1 or sfx_idx == -1:
		return "Required audio buses (Master, Music, SFX) not found in AudioServer"

	# Save initial values for teardown
	var init_master_db := AudioServer.get_bus_volume_db(master_idx)
	var init_music_db := AudioServer.get_bus_volume_db(music_idx)
	var init_sfx_db := AudioServer.get_bus_volume_db(sfx_idx)

	var settings_scene := preload("res://scenes/ui/settings_menu.tscn")
	var settings: SettingsMenu = settings_scene.instantiate()
	root.add_child(settings)
	await process_frame

	var err := ""

	# 1. Test Music routing
	settings._on_music_volume_changed(0.4)
	var expected_music_db := linear_to_db(0.4)
	var new_music_db := AudioServer.get_bus_volume_db(music_idx)
	var cur_sfx_db := AudioServer.get_bus_volume_db(sfx_idx)
	var cur_master_db := AudioServer.get_bus_volume_db(master_idx)

	if abs(new_music_db - expected_music_db) > 0.01:
		err = "Changing Music volume failed to update Music bus db: expected %f, got %f" % [expected_music_db, new_music_db]
	elif abs(cur_sfx_db - init_sfx_db) > 0.01:
		err = "Changing Music volume unexpectedly altered SFX bus db: was %f, now %f" % [init_sfx_db, cur_sfx_db]
	elif abs(cur_master_db - init_master_db) > 0.01:
		err = "Changing Music volume unexpectedly altered Master bus db: was %f, now %f" % [init_master_db, cur_master_db]

	# 2. Test SFX routing
	if err.is_empty():
		settings._on_sfx_volume_changed(0.7)
		var expected_sfx_db := linear_to_db(0.7)
		var new_sfx_db := AudioServer.get_bus_volume_db(sfx_idx)
		var cur_music_db := AudioServer.get_bus_volume_db(music_idx)
		cur_master_db = AudioServer.get_bus_volume_db(master_idx)

		if abs(new_sfx_db - expected_sfx_db) > 0.01:
			err = "Changing SFX volume failed to update SFX bus db: expected %f, got %f" % [expected_sfx_db, new_sfx_db]
		elif abs(cur_music_db - expected_music_db) > 0.01:
			err = "Changing SFX volume unexpectedly altered Music bus db: was %f, now %f" % [expected_music_db, cur_music_db]
		elif abs(cur_master_db - init_master_db) > 0.01:
			err = "Changing SFX volume unexpectedly altered Master bus db: was %f, now %f" % [init_master_db, cur_master_db]

	# Teardown: restore initial bus volume settings
	AudioServer.set_bus_volume_db(master_idx, init_master_db)
	AudioServer.set_bus_volume_db(music_idx, init_music_db)
	AudioServer.set_bus_volume_db(sfx_idx, init_sfx_db)

	settings.free()
	return err


func _test_order_card_no_duplicate_callbacks() -> String:
	var content_scene := preload("res://scenes/ui/orders/order_board_content.tscn")
	var content: OrderBoardContent = content_scene.instantiate()
	root.add_child(content)
	await process_frame

	var om := OrderManager.new()
	var test_id: String = om.order_runtime.keys()[0]
	var selected_fired := [0]

	content.order_selected.connect(func(_o_id: String):
		selected_fired[0] += 1
	)

	# Refresh bottom carousel 20 times via update_state
	for i in range(20):
		content.update_state({}, {}, om.live_orders_patience, om.completed_requests)

	# Find a mini card in the bottom carousel
	var carousel_card: Control = null
	for child in content.mini_cards_row.get_children():
		if child is Control and child.has_meta("order_id"):
			carousel_card = child
			break

	if carousel_card == null:
		content.free()
		return "No mini card found in bottom carousel after refreshes"

	# Simulate GUI click on the mini card
	var mb := InputEventMouseButton.new()
	mb.button_index = MOUSE_BUTTON_LEFT
	mb.pressed = true
	carousel_card.gui_input.emit(mb)

	if selected_fired[0] != 1:
		content.free()
		return "Expected exactly 1 callback after 20 refreshes, got %d" % selected_fired[0]

	content.free()
	return ""


func _test_specimen_reveal_no_leak() -> String:
	var hud := HudController.new()
	root.add_child(hud)
	await process_frame

	var spec := GeneticsEngine.create_starter_specimen("rose", "REV-001")

	var preserve_count := [0]
	var harvest_count := [0]

	# Show reveal modal 5 times in succession
	for i in range(5):
		hud.show_specimen_reveal(spec, func(): preserve_count[0] += 1, func(): harvest_count[0] += 1)

	# Click preserve button
	hud._reveal_preserve_btn.pressed.emit()

	if preserve_count[0] != 1:
		hud.free()
		return "Expected preserve callback to fire exactly once, fired %d times" % preserve_count[0]

	if harvest_count[0] != 0:
		hud.free()
		return "Harvest callback fired unexpectedly: %d times" % harvest_count[0]

	# Subsequent clicks should not fire anything
	hud._reveal_preserve_btn.pressed.emit()
	if preserve_count[0] != 1:
		hud.free()
		return "Stored callable leaked and fired a second time!"

	hud.free()
	return ""


func _test_flower_stand_toggle_single_callback() -> String:
	var hud := HudController.new()
	root.add_child(hud)
	await process_frame

	if not is_instance_valid(hud._tool_dock_instance):
		hud.free()
		return "Tool dock instance missing in HUD"
	if not is_instance_valid(hud._inventory_drawer):
		hud.free()
		return "Inventory drawer instance missing in HUD"

	var initial_visible: bool = hud._inventory_drawer.visible

	# Emit toggle signal once
	hud._tool_dock_instance.flower_stand_toggle_requested.emit()
	if hud._inventory_drawer.visible == initial_visible:
		hud.free()
		return "Flower stand toggle did not toggle inventory drawer"

	# Emit toggle signal second time
	hud._tool_dock_instance.flower_stand_toggle_requested.emit()
	if hud._inventory_drawer.visible != initial_visible:
		hud.free()
		return "Flower stand toggle did not return inventory drawer to initial state"

	hud.free()
	return ""


func _test_breeding_validator_accepts_valid_pair() -> String:
	# 1. Hybrid cross with inventory
	var inv := {"rose": 2, "lavender": 1}
	var res := BreedingService.validate_pair("rose", "lavender", null, null, inv)
	if not res.get("valid", false):
		return "Valid hybrid cross rejected: %s" % res.get("error", "")
	if res.get("result_species", "") != "velvet_dusk":
		return "Incorrect result species: expected velvet_dusk, got %s" % res.get("result_species", "")

	# 2. Purebred cross with inventory (needs 2 flowers)
	var res_pure := BreedingService.validate_pair("rose", "rose", null, null, inv)
	if not res_pure.get("valid", false):
		return "Valid purebred cross rejected: %s" % res_pure.get("error", "")
	if not res_pure.get("is_purebred", false):
		return "is_purebred flag not set on purebred cross"

	return ""


func _test_breeding_validator_rejects_incompatible() -> String:
	# Incompatible cross: rose + blushbell (blushbell cannot breed with rose)
	var inv := {"rose": 2, "blushbell": 2}
	var res := BreedingService.validate_pair("rose", "blushbell", null, null, inv)
	if res.get("valid", false):
		return "Incompatible cross rose + blushbell was accepted"

	# Insufficient inventory
	var low_inv := {"rose": 1}
	var res_low := BreedingService.validate_pair("rose", "rose", null, null, low_inv)
	if res_low.get("valid", false):
		return "Purebred cross accepted with insufficient inventory (only 1 rose)"

	return ""


func _test_breeding_validator_rejects_same_specimen() -> String:
	var spec := FlowerSpecimen.new()
	spec.specimen_id = "SPEC-001"
	spec.species_id = "rose"

	var roster: Array[FlowerSpecimen] = [spec]
	var res := BreedingService.validate_pair("SPEC-001", "SPEC-001", spec, spec, null, roster)
	if res.get("valid", false):
		return "Breeding a specimen with itself was accepted"
	if res.get("error", "").find("itself") == -1:
		return "Error message did not mention self-breeding: %s" % res.get("error", "")

	return ""


func _test_breeding_validator_enforces_roster_ownership() -> String:
	var spec_a := FlowerSpecimen.new()
	spec_a.specimen_id = "SPEC-A"
	spec_a.species_id = "rose"

	var spec_b := FlowerSpecimen.new()
	spec_b.specimen_id = "SPEC-B"
	spec_b.species_id = "lavender"

	# Roster only contains spec_a
	var roster: Array[FlowerSpecimen] = [spec_a]
	var inv := {"rose": 5, "lavender": 5}

	# 1. Slot 1 in roster, Slot 2 NOT in roster
	var res1 := BreedingService.validate_pair("SPEC-A", "SPEC-B", spec_a, spec_b, inv, roster)
	if res1.get("valid", false):
		return "Accepted unrostered specimen in Slot B"
	if res1.get("error", "").find("Parent B") == -1:
		return "Error did not identify Parent B missing from stock: %s" % res1.get("error", "")

	# 2. Slot 1 NOT in roster, Slot 2 in roster
	var res2 := BreedingService.validate_pair("SPEC-B", "SPEC-A", spec_b, spec_a, inv, roster)
	if res2.get("valid", false):
		return "Accepted unrostered specimen in Slot A"
	if res2.get("error", "").find("Parent A") == -1:
		return "Error did not identify Parent A missing from stock: %s" % res2.get("error", "")

	# 3. Verify zero inventory or roster mutation
	if inv["rose"] != 5 or inv["lavender"] != 5:
		return "Inventory was mutated during failed validation"
	if roster.size() != 1 or roster[0] != spec_a:
		return "Roster was mutated during failed validation"

	# 4. Verify that standard species/inventory breeding without roster still works normally
	var res_species := BreedingService.validate_pair("rose", "lavender", null, null, inv, [])
	if not res_species.get("valid", false):
		return "Standard species inventory breeding without roster unexpectedly rejected: %s" % res_species.get("error", "")

	return ""


func _test_garden_adjacency_nearest_neighbor() -> String:
	var grid := GardenGrid.new()
	root.add_child(grid)
	await process_frame

	# Clear any auto-generated plots and construct a controlled geometric grid
	for child in grid.get_children():
		if child is GardenPlot:
			child.queue_free()
	grid.plots.clear()

	# Grid geometry with known spacing S = 60.0:
	# Center plot: (60, 60)
	# Orthogonal neighbor: (60, 120) -> distance = 60.0 (1.0 * S)
	# Diagonal neighbor: (120, 120) -> distance = 60 * sqrt(2) ~= 84.85 (~1.414 * S)
	# Second-ring neighbor: (60, 180) -> distance = 120.0 (2.0 * S)
	# Far plot: (300, 300) -> distance ~= 339.4 (> 5.0 * S)
	var p_center := GardenPlot.new()
	p_center.position = Vector2(60, 60)
	grid.add_child(p_center)
	grid.plots.append(p_center)

	var p_ortho := GardenPlot.new()
	p_ortho.position = Vector2(60, 120)
	grid.add_child(p_ortho)
	grid.plots.append(p_ortho)

	var p_diag := GardenPlot.new()
	p_diag.position = Vector2(120, 120)
	grid.add_child(p_diag)
	grid.plots.append(p_diag)

	var p_second_ring := GardenPlot.new()
	p_second_ring.position = Vector2(60, 180)
	grid.add_child(p_second_ring)
	grid.plots.append(p_second_ring)

	var p_far := GardenPlot.new()
	p_far.position = Vector2(300, 300)
	grid.add_child(p_far)
	grid.plots.append(p_far)

	await process_frame

	# 1. Test adjacent plots calculation (must include orthogonal & diagonal, exclude ring 2 & far)
	var adj := grid.get_adjacent_plots(p_center)

	if not adj.has(p_ortho):
		grid.free()
		return "Orthogonal neighbor (distance 1.0*S) was not included in adjacent plots"
	if not adj.has(p_diag):
		grid.free()
		return "Diagonal neighbor (distance sqrt(2)*S) was not included in adjacent plots"
	if adj.has(p_second_ring):
		grid.free()
		return "Second-ring neighbor (distance 2.0*S) was incorrectly included in adjacent plots"
	if adj.has(p_far):
		grid.free()
		return "Far plot was incorrectly included in adjacent plots"
	if adj.size() != 2:
		grid.free()
		return "Expected exactly 2 adjacent plots (orthogonal + diagonal), got %d" % adj.size()

	# 2. Test that shuffling the plots array does not change the result
	grid.plots.shuffle()
	var adj_shuffled := grid.get_adjacent_plots(p_center)
	if adj_shuffled.size() != 2 or not adj_shuffled.has(p_ortho) or not adj_shuffled.has(p_diag):
		grid.free()
		return "Adjacency result changed after plots array was shuffled"

	# 3. Test get_nearest_valid_neighbor with predicate
	p_ortho.state = GardenPlot.State.GROWING
	p_ortho.is_watered = false
	var nearest := grid.get_nearest_valid_neighbor(p_center, func(p: GardenPlot) -> bool:
		return p.state == GardenPlot.State.GROWING and not p.is_watered
	)
	if nearest != p_ortho:
		grid.free()
		return "get_nearest_valid_neighbor failed to find matching neighbor"

	# 4. Test when no adjacent plot matches predicate: must return null
	var none_valid := grid.get_nearest_valid_neighbor(p_center, func(_p: GardenPlot) -> bool:
		return false
	)
	if none_valid != null:
		grid.free()
		return "get_nearest_valid_neighbor returned non-null when predicate failed on all adjacent plots"

	grid.free()
	return ""


func _test_camera_lerp_clamped() -> String:
	var cam := GardenCamera.new()
	root.add_child(cam)
	await process_frame
	cam._target_position = Vector2(500, 500)
	cam._target_zoom = Vector2(1.5, 1.5)

	# Extreme delta spike (100.0 seconds)
	cam._process(100.0)

	if is_nan(cam.position.x) or is_inf(cam.position.x):
		cam.free()
		return "Camera position became NaN or Inf on extreme delta"
	if is_nan(cam.zoom.x) or is_inf(cam.zoom.x):
		cam.free()
		return "Camera zoom became NaN or Inf on extreme delta"

	if cam.position != Vector2(500, 500):
		cam.free()
		return "Camera position did not cleanly reach target: %s" % str(cam.position)
	if cam.zoom != Vector2(1.5, 1.5):
		cam.free()
		return "Camera zoom did not cleanly reach target: %s" % str(cam.zoom)

	cam.free()
	return ""


func _test_rmb_drag_vs_click_queue() -> String:
	var main_node := _setup_main_node()
	await process_frame

	var plot: GardenPlot = main_node.garden_grid.plots[0]

	# Queue an action
	main_node.character.queue_action_at_plot(plot, "water")
	if main_node.character.task_queue.size() != 1:
		main_node.free()
		return "Failed to queue action in character"

	# 1. Simulate RMB Drag: press at (100, 100), move to (150, 150) (> 8px), release
	var press_ev := InputEventMouseButton.new()
	press_ev.button_index = MOUSE_BUTTON_RIGHT
	press_ev.pressed = true
	press_ev.position = Vector2(100, 100)
	main_node._unhandled_input(press_ev)

	var move_ev := InputEventMouseMotion.new()
	move_ev.position = Vector2(150, 150)
	main_node._unhandled_input(move_ev)

	var release_ev := InputEventMouseButton.new()
	release_ev.button_index = MOUSE_BUTTON_RIGHT
	release_ev.pressed = false
	release_ev.position = Vector2(150, 150)
	main_node._unhandled_input(release_ev)

	# Queue MUST still have the task!
	if main_node.character.task_queue.is_empty():
		main_node.free()
		return "RMB drag cleared the action queue unexpectedly"

	# 2. Simulate clean RMB click & release: press at (100, 100), release at (100, 100)
	press_ev.position = Vector2(100, 100)
	main_node._unhandled_input(press_ev)
	release_ev.position = Vector2(100, 100)
	main_node._unhandled_input(release_ev)

	if not main_node.character.task_queue.is_empty():
		main_node.free()
		return "Clean RMB click failed to cancel the action queue"

	main_node.free()
	return ""


func _test_character_action_completion_callback() -> String:
	var char_node := GardenerCharacter.new()
	root.add_child(char_node)
	var plot := GardenPlot.new()
	root.add_child(plot)
	await process_frame

	var complete_called := [0]
	var trigger_called := [0]

	# 1. Test successful completion
	char_node.perform_action_at_plot(
		plot,
		"water",
		func(): trigger_called[0] += 1,
		func(): complete_called[0] += 1
	)

	if char_node.task_queue.is_empty():
		char_node.free()
		plot.free()
		return "Action not queued in character"

	# Call the real production completion method that runtime uses when tool action finishes
	char_node._finish_current_task(true)

	if complete_called[0] != 1:
		char_node.free()
		plot.free()
		return "Expected complete callback to fire once on task completion, got %d" % complete_called[0]

	# Extra frames / ticks / extra calls must NOT fire a second time
	char_node._finish_current_task(true)
	char_node._physics_process(0.1)
	if complete_called[0] != 1:
		char_node.free()
		plot.free()
		return "Complete callback fired a second time after task was finished: %d" % complete_called[0]

	# 2. Test rejection (plot == null) -> complete_called should not fire (0 calls)
	var rejected_called := [0]
	char_node.perform_action_at_plot(null, "water", Callable(), func(): rejected_called[0] += 1)
	if rejected_called[0] != 0:
		char_node.free()
		plot.free()
		return "Callback invoked on rejected action (plot == null)"
	if not char_node.task_queue.is_empty():
		char_node.free()
		plot.free()
		return "Rejected action was placed in task queue"

	# 3. Test cancellation via clear_queue() -> complete callback must not fire
	var cancelled_called := [0]
	char_node.queue_action_at_plot(plot, "prune", Callable(), func(): cancelled_called[0] += 1)
	if char_node.task_queue.size() != 1:
		char_node.free()
		plot.free()
		return "Task was not queued for cancellation test"

	char_node.clear_queue()
	if not char_node.task_queue.is_empty():
		char_node.free()
		plot.free()
		return "Task queue not empty after clear_queue"

	# Even if completion method is invoked after clear_queue, callback must not fire
	char_node._finish_current_task(true)
	if cancelled_called[0] != 0:
		char_node.free()
		plot.free()
		return "Callback invoked after action queue was cleared/cancelled"

	char_node.free()
	plot.free()
	return ""
