extends SceneTree

## Dedicated End-to-End Test for the Breeding System Lifecycle.

var frame_count: int = 0
var main_node: MainGame = null
var test_executed: bool = false


func _init() -> void:
	var main_scene_res := load("res://scenes/main.tscn") as PackedScene
	main_node = main_scene_res.instantiate() as MainGame
	root.add_child(main_node)


func _process(_delta: float) -> bool:
	frame_count += 1
	if frame_count >= 6 and not test_executed:
		test_executed = true
		_run_all_tests()
	elif frame_count >= 120:
		printerr("❌ Breeding system test timed out waiting for frames.")
		quit(1)
	return false


func _run_all_tests() -> void:
	print("\n==================================================")
	print("TESTING FULL BREEDING SYSTEM LIFECYCLE")
	print("==================================================")

	var errors: Array[String] = []

	# 1. Setup inventory
	main_node.pending_hybrid_seeds.clear()
	main_node.flower_inventory.clear()
	main_node.flower_inventory.add_flower("rose", FlowerQuality.Tier.NORMAL, 5)
	main_node.flower_inventory.add_flower("lavender", FlowerQuality.Tier.NORMAL, 5)
	main_node.flower_inventory.add_flower("sunflower", FlowerQuality.Tier.NORMAL, 5)
	main_node.flower_inventory.add_flower("tulip", FlowerQuality.Tier.NORMAL, 5)
	main_node.flower_inventory.add_flower("daisy", FlowerQuality.Tier.NORMAL, 5)

	# TEST 1: Rose + Lavender -> Velvet Dusk Bloom
	print("-> Test 1: Breeding Rose + Lavender from inventory...")
	main_node._on_breed_requested("rose", "lavender", 100)
	if main_node.unknown_hybrid_seeds.size() != 1:
		errors.append("Expected 1 hybrid seed generated, got %d" % main_node.unknown_hybrid_seeds.size())
	elif main_node.unknown_hybrid_seeds[0] != "velvet_dusk":
		errors.append("Expected velvet_dusk hybrid, got '%s'" % main_node.unknown_hybrid_seeds[0])
	if main_node.inventory.get("rose", 0) != 4:
		errors.append("Expected 1 rose consumed (remaining 4), got %d" % main_node.inventory.get("rose", 0))
	if main_node.inventory.get("lavender", 0) != 4:
		errors.append("Expected 1 lavender consumed (remaining 4), got %d" % main_node.inventory.get("lavender", 0))
	if errors.is_empty():
		print("   ✓ Rose + Lavender successfully bred Velvet Dusk! (Inventory deducted correctly)")

	# TEST 2: Rose + Sunflower -> Golden Rose
	print("-> Test 2: Breeding Rose + Sunflower from inventory...")
	main_node._on_breed_requested("rose", "sunflower", 200)
	if main_node.unknown_hybrid_seeds.size() != 2:
		errors.append("Expected 2 hybrid seeds generated")
	elif main_node.unknown_hybrid_seeds[1] != "golden_rose":
		errors.append("Expected golden_rose hybrid, got '%s'" % main_node.unknown_hybrid_seeds[1])
	if main_node.inventory.get("rose", 0) != 3:
		errors.append("Expected rose consumed (remaining 3)")
	if main_node.inventory.get("sunflower", 0) != 4:
		errors.append("Expected sunflower consumed (remaining 4)")
	print("   ✓ Rose + Sunflower successfully bred Golden Rose!")

	# TEST 3: Lavender + Sunflower -> Sunflare Spike
	print("-> Test 3: Breeding Lavender + Sunflower from inventory...")
	main_node._on_breed_requested("lavender", "sunflower", 300)
	if main_node.unknown_hybrid_seeds.size() != 3:
		errors.append("Expected 3 hybrid seeds generated")
	elif main_node.unknown_hybrid_seeds[2] != "sunflare_spike":
		errors.append("Expected sunflare_spike hybrid, got '%s'" % main_node.unknown_hybrid_seeds[2])
	print("   ✓ Lavender + Sunflower successfully bred Sunflare Spike!")

	# TEST 4: Purebred Rose + Rose
	print("-> Test 4: Purebred Rose + Rose from inventory...")
	main_node._on_breed_requested("rose", "rose", 400)
	if main_node.unknown_hybrid_seeds.size() != 4:
		errors.append("Expected 4 hybrid seeds generated")
	elif main_node.unknown_hybrid_seeds[3] != "rose":
		errors.append("Expected purebred rose hybrid, got '%s'" % main_node.unknown_hybrid_seeds[3])
	if main_node.inventory.get("rose", 0) != 1:
		errors.append("Expected 2 roses consumed (remaining 1), got %d" % main_node.inventory.get("rose", 0))
	print("   ✓ Purebred Rose + Rose successfully refined!")

	# TEST 5: Planting & Growing a Mystery Seed
	print("-> Test 5: Planting bred Mystery Seed into GardenPlot...")
	var plot: GardenPlot = main_node.garden_grid.plots[0]
	plot.harvest() # Ensure empty
	main_node.current_seed = "mystery_seed"
	main_node._handle_planting_action(plot)

	if plot.state != GardenPlot.State.GROWING:
		errors.append("Expected plot to be growing")
	if not plot.is_mystery_seed:
		errors.append("Expected plot to hold mystery seed")
	if plot.current_flower_id != "velvet_dusk":
		errors.append("Expected first popped seed to be velvet_dusk, got '%s'" % plot.current_flower_id)
	print("   ✓ Mystery Seed successfully planted in plot!")

	# Fast forward growth to bloom
	plot.growth_progress = 0.99
	plot._process(1.0) # Triggers transition to MATURE and reveals flower
	if plot.state != GardenPlot.State.MATURE:
		errors.append("Expected plot to be mature after growth")
	if not plot.is_revealed:
		errors.append("Expected mystery flower to be revealed upon blooming")
	print("   ✓ Mystery Seed successfully blossomed and revealed Velvet Dusk Bloom!")

	# TEST 6: Incompatible pair (Tulip + Sunflower)
	print("-> Test 6: Incompatible pair (Tulip + Sunflower)...")
	var count_before: int = main_node.unknown_hybrid_seeds.size()
	main_node._on_breed_requested("tulip", "sunflower", 500)
	if main_node.unknown_hybrid_seeds.size() != count_before:
		errors.append("Incompatible pair should not produce seeds")
	if main_node.inventory.get("tulip", 0) != 5:
		errors.append("No tulips should be consumed on invalid pair")
	if main_node.inventory.get("sunflower", 0) != 3:
		errors.append("No sunflowers should be consumed on invalid pair")
	print("   ✓ Incompatible pair rejected safely without wasting items!")

	if not errors.is_empty():
		printerr("\n❌ BREEDING SYSTEM TESTS FAILED WITH %d ERRORS:" % errors.size())
		for e in errors:
			printerr("  - " + e)
		quit(1)
		return

	print("\n==================================================")
	print("ALL BREEDING LIFECYCLE TESTS PASSED 100% OK!")
	print("==================================================\n")
	quit(0)
