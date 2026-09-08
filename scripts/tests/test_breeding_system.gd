extends SceneTree

## Dedicated End-to-End Test for the Breeding System Lifecycle.

var frame_count: int = 0
var main_node: MainGame = null


func _init() -> void:
	var main_scene_res := load("res://scenes/main.tscn") as PackedScene
	main_node = main_scene_res.instantiate() as MainGame
	root.add_child(main_node)


func _process(_delta: float) -> bool:
	frame_count += 1
	if frame_count == 6:
		_run_all_tests()
	return false


func _run_all_tests() -> void:
	print("\n==================================================")
	print("TESTING FULL BREEDING SYSTEM LIFECYCLE")
	print("==================================================")

	# 1. Setup inventory
	main_node.unknown_hybrid_seeds.clear()
	main_node.unknown_hybrid_specimens.clear()
	main_node.inventory["rose"] = 5
	main_node.inventory["lavender"] = 5
	main_node.inventory["sunflower"] = 5
	main_node.inventory["tulip"] = 5
	main_node.inventory["daisy"] = 5

	# TEST 1: Rose + Lavender -> Roselight Bloom
	print("-> Test 1: Breeding Rose + Lavender from inventory...")
	main_node._on_breed_requested("rose", "lavender", 100)
	assert(main_node.unknown_hybrid_seeds.size() == 1, "Expected 1 hybrid seed generated")
	assert(main_node.unknown_hybrid_seeds[0] == "roselight", "Expected roselight hybrid")
	assert(main_node.inventory["rose"] == 4, "Expected 1 rose consumed")
	assert(main_node.inventory["lavender"] == 4, "Expected 1 lavender consumed")
	print("   ✓ Rose + Lavender successfully bred Roselight! (Inventory deducted correctly)")

	# TEST 2: Rose + Sunflower -> Golden Rose
	print("-> Test 2: Breeding Rose + Sunflower from inventory...")
	main_node._on_breed_requested("rose", "sunflower", 200)
	assert(main_node.unknown_hybrid_seeds.size() == 2, "Expected 2 hybrid seeds generated")
	assert(main_node.unknown_hybrid_seeds[1] == "golden_rose", "Expected golden_rose hybrid")
	assert(main_node.inventory["rose"] == 3, "Expected 1 rose consumed")
	assert(main_node.inventory["sunflower"] == 4, "Expected 1 sunflower consumed")
	print("   ✓ Rose + Sunflower successfully bred Golden Rose!")

	# TEST 3: Lavender + Sunflower -> Sunflare Spike
	print("-> Test 3: Breeding Lavender + Sunflower from inventory...")
	main_node._on_breed_requested("lavender", "sunflower", 300)
	assert(main_node.unknown_hybrid_seeds.size() == 3, "Expected 3 hybrid seeds generated")
	assert(main_node.unknown_hybrid_seeds[2] == "sunflare_spike", "Expected sunflare_spike hybrid")
	print("   ✓ Lavender + Sunflower successfully bred Sunflare Spike!")

	# TEST 4: Purebred Rose + Rose
	print("-> Test 4: Purebred Rose + Rose from inventory...")
	main_node._on_breed_requested("rose", "rose", 400)
	assert(main_node.unknown_hybrid_seeds.size() == 4, "Expected 4 hybrid seeds generated")
	assert(main_node.unknown_hybrid_seeds[3] == "rose", "Expected purebred rose hybrid")
	assert(main_node.inventory["rose"] == 1, "Expected 2 roses consumed")
	print("   ✓ Purebred Rose + Rose successfully refined!")

	# TEST 5: Planting & Growing a Mystery Seed
	print("-> Test 5: Planting bred Mystery Seed into GardenPlot...")
	var plot: GardenPlot = main_node.garden_grid.plots[0]
	plot.harvest() # Ensure empty
	main_node.current_seed = "mystery_seed"
	main_node._handle_planting_action(plot)

	assert(plot.state == GardenPlot.State.GROWING, "Expected plot to be growing")
	assert(plot.is_mystery_seed == true, "Expected plot to hold mystery seed")
	assert(plot.current_flower_id == "roselight", "Expected first popped seed to be roselight")
	print("   ✓ Mystery Seed successfully planted in plot!")

	# Fast forward growth to bloom
	plot.growth_progress = 0.99
	plot._process(1.0) # Triggers transition to MATURE and reveals flower
	assert(plot.state == GardenPlot.State.MATURE, "Expected plot to be mature")
	assert(plot.is_revealed == true, "Expected mystery flower to be revealed upon blooming")
	print("   ✓ Mystery Seed successfully blossomed and revealed Roselight Bloom!")

	# TEST 6: Incompatible pair (Tulip + Daisy)
	print("-> Test 6: Incompatible pair (Tulip + Daisy)...")
	var count_before: int = main_node.unknown_hybrid_seeds.size()
	main_node._on_breed_requested("tulip", "daisy", 500)
	assert(main_node.unknown_hybrid_seeds.size() == count_before, "Incompatible pair should not produce seeds")
	assert(main_node.inventory["tulip"] == 5, "No tulips should be consumed")
	assert(main_node.inventory["daisy"] == 5, "No daisies should be consumed")
	print("   ✓ Incompatible pair rejected safely without wasting items!")

	print("\n==================================================")
	print("ALL BREEDING LIFECYCLE TESTS PASSED 100% OK!")
	print("==================================================\n")
	quit(0)
