extends SceneTree

## Verification Test for Flower Stand Quick Sell Transactions

func _init() -> void:
	print("--- Testing Quick Sell Transactions ---")
	var main_scene = load("res://scenes/main.tscn")
	var main_node = main_scene.instantiate()
	root.add_child(main_node)

	for i in range(5):
		await process_frame

	main_node.coins = 50
	main_node.inventory = {"rose": 5, "daisy": 3, "lavender": 2}
	main_node._sync_hud_state()

	var initial_coins: int = main_node.coins

	# 1. Test Sell 1 Rose (base value 10)
	var earned_1: int = main_node.quick_sell_flower("rose", 1)
	if earned_1 != 10:
		printerr("FAIL: Expected 10 coins, got %d" % earned_1)
		quit(1)
	if main_node.inventory["rose"] != 4:
		printerr("FAIL: Inventory not decremented correctly")
		quit(1)
	if main_node.coins != initial_coins + 10:
		printerr("FAIL: Coins not updated correctly")
		quit(1)
	print("✓ Test 1 Passed: Sold 1 Rose for 10 coins. Total coins: %d" % main_node.coins)

	# 2. Test Sell All Daisies (3 x 8 = 24 coins)
	var earned_daisies: int = main_node.quick_sell_flower("daisy", 3)
	if earned_daisies != 24:
		printerr("FAIL: Expected 24 coins for 3 daisies, got %d" % earned_daisies)
		quit(1)
	if main_node.inventory.has("daisy"):
		printerr("FAIL: Empty daisy key was not cleaned up")
		quit(1)
	print("✓ Test 2 Passed: Sold 3 Daisies for 24 coins. Total coins: %d" % main_node.coins)

	# 3. Test Batch Quick Sell All (remaining: 4 roses = 40, 2 lavenders = 24 => 64 coins)
	var batch_earned: int = main_node.quick_sell_all_flowers()
	if batch_earned != 64:
		printerr("FAIL: Expected 64 coins from batch sell, got %d" % batch_earned)
		quit(1)
	if not main_node.inventory.is_empty():
		printerr("FAIL: Inventory should be completely empty after sell all")
		quit(1)
	if main_node.coins != 50 + 10 + 24 + 64:
		printerr("FAIL: Expected 148 total coins, got %d" % main_node.coins)
		quit(1)
	print("✓ Test 3 Passed: Batch sold all remaining flowers for 64 coins. Final coins: %d" % main_node.coins)

	print("🎉 ALL QUICK SELL TESTS PASSED (100% OK)!")
	quit(0)
