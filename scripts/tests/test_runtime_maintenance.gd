extends SceneTree

const TEST_SAVE := "user://test_runtime_maintenance.json"
var _failed: int = 0


func _init() -> void:
	_run.call_deferred()


func _check(condition: bool, description: String) -> void:
	if condition:
		print("PASS: " + description)
	else:
		_failed += 1
		printerr("FAIL: " + description)


func _run() -> void:
	SaveManager.delete_save(TEST_SAVE)
	var main: MainGame = load("res://scenes/main.tscn").instantiate()
	main.active_save_path = TEST_SAVE
	root.add_child(main)
	await process_frame
	main.set_process(false)
	main._tutorial_overlay.hide()

	var seeds: SeedBar = main.hud._seed_bar_instance
	var rose_label: Label = seeds.seed_cards["rose"].get_node("CountMargin/CountPill/CountLabel")
	_check(rose_label.text == "🍃 5", "Starter seed label shows the actual five seeds")
	main.flower_inventory.add_flower("rose", FlowerQuality.Tier.HERO, 99)
	main._sync_hud_state()
	_check(rose_label.text == "🍃 5", "Harvested flowers do not affect seed stock")
	main.seed_inventory.remove_seeds("rose", 5)
	main._sync_hud_state()
	_check(rose_label.text == "🍃 0", "Exhausted seeds show zero without a fake default")

	var plot: GardenPlot = main.garden_grid.plots[0]
	main.garden_grid.select_plot(plot)
	main._on_plot_selected(plot)
	var card: PlotCard = main.hud._plot_card_instance
	card.close_btn.pressed.emit()
	main._process(0.12)
	_check(not card.visible, "Periodic plot updates preserve an explicitly closed card")
	main._on_plot_selected(main.garden_grid.plots[1])
	_check(card.visible, "Explicit selection opens the plot card again")
	main.hud.toggle_beauty_mode()
	main._process(0.12)
	_check(not card.visible, "Plot refresh respects beauty mode")
	main.hud.toggle_beauty_mode()

	var manager := main.order_manager
	var board: OrderBoardContent = main.hud._side_order_rail._get_order_board()
	var id: String = board._active_orders[0]
	manager.reset_all_patience()
	board.update_state({}, {}, manager.live_orders_patience, manager.completed_requests)
	var carousel_id := board.mini_cards_row.get_child(0).get_instance_id()
	var max_pat: float = manager.order_runtime[id]["max_patience"]
	manager.tick(max_pat * 0.8)
	board._process(0.1)
	var dial: WatchTimerDial = board._cards[0].find_child("WatchDial", true, false)
	_check(is_equal_approx(float(board._ticket_cards[id]["patience"]), manager.get_patience(id)), "Order dial reads current domain patience without an inventory refresh")
	_check(dial.progress_ratio == 0.75, "Order watch transitions to its final visual zone")
	board.update_state({}, {}, manager.live_orders_patience, manager.completed_requests)
	_check(board.mini_cards_row.get_child(0).get_instance_id() == carousel_id, "Timer-only refresh preserves carousel nodes")
	main.hud.open_requests_modal()
	var modal: RequestsModal = main.hud._requests_modal_instance
	var modal_card_id := modal._card_container.get_child(0).get_instance_id()
	modal._process(0.11)
	var row: Dictionary = modal._patience_rows[id]
	_check(is_equal_approx(row["bar"].value, 20.0), "Standalone requests modal also shows current patience")
	_check(modal._card_container.get_child(0).get_instance_id() == modal_card_id, "Live modal timers preserve order cards")
	modal.hide()

	var drawer: InventoryDrawer = main.hud._inventory_drawer
	drawer.update_inventory({"rose": 3}, {"garden_harmony": 1})
	var crate: Control = drawer._flower_crates["rose"]
	var crate_id := crate.get_instance_id()
	var bouquet_id: int = drawer._bouquet_crates["garden_harmony"].get_instance_id()
	var sold: Array[int] = []
	drawer.quick_sell_requested.connect(func(_flower: String, count: int) -> void: sold.append(count))
	var stock := {"rose": 3}
	for count in range(4, 24):
		stock["rose"] = count
		drawer.update_inventory(stock, {"garden_harmony": 2})
	_check(drawer._flower_crates["rose"].get_instance_id() == crate_id, "Twenty stock updates reuse the same flower crate")
	_check(drawer._bouquet_crates["garden_harmony"].get_instance_id() == bouquet_id, "Bouquet counts update without recreating their crate")
	crate.get_node("SellAll").pressed.emit()
	_check(sold == [23], "Reused Sell All callback reads current stock once")
	drawer.update_inventory({}, {})
	_check(not crate.get_node("SellOne").visible and not crate.get_node("SellAll").visible, "Empty base crates hide sale controls")
	_check(drawer._bouquet_crates.is_empty(), "Exhausted bouquet cards are removed")

	main.coins = 10
	main._request_save()
	main.coins = 20
	main._request_save()
	main.coins = 30
	main._request_save()
	_check(not FileAccess.file_exists(TEST_SAVE), "Rapid gameplay saves wait for one bounded batching window")
	paused = true
	await create_timer(0.4, true, false, true).timeout
	paused = false
	var saved := SaveManager.load_game(TEST_SAVE)
	_check(saved.get("coins") == 30, "Batched save persists the latest state even while paused")
	_check(not FileAccess.file_exists(TEST_SAVE.get_basename() + ".bak"), "Three rapid requests produce one disk save")
	_check(not main._save_pending, "Successful save clears pending state")

	main.active_save_path = "user://missing_maintenance_parent/save.json"
	main._pause_menu.save_requested.emit()
	_check(not FileAccess.file_exists(main.active_save_path), "Failure injection actually prevents disk writes")
	_check(main.hud._last_toast_message.contains("Could not save"), "Failed manual save displays failure instead of success")
	paused = true
	main._pause_menu.main_menu_requested.emit()
	_check(paused and is_instance_valid(main), "Failed save keeps the game and pause menu available for retry")
	paused = false
	main.active_save_path = TEST_SAVE
	main._pause_menu.save_requested.emit()
	_check(main.hud._last_toast_message.contains("saved successfully") and not main._save_pending, "Manual retry succeeds and reports success")
	main.coins = 42
	main._request_save()
	main._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	_check(SaveManager.load_game(TEST_SAVE).get("coins") == 42, "Application suspension immediately flushes the latest state")
	_check(main._save_debounce_timer.is_stopped(), "Immediate save cancels the pending timer")

	main.queue_free()
	await process_frame
	SaveManager.delete_save(TEST_SAVE)
	print("Runtime maintenance failures: %d" % _failed)
	quit(1 if _failed else 0)
