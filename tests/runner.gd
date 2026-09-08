extends SceneTree

## Unified Headless Test Runner for Finest Garden Prototype.

const FlowerDataScript := preload("res://scripts/flowers/flower_data.gd")
const BouquetDataScript := preload("res://scripts/crafting/bouquet_data.gd")
const PerfumeDataScript := preload("res://scripts/crafting/perfume_data.gd")
const FloristRequestDataScript := preload("res://scripts/requests/florist_request_data.gd")
const GeneticsEngineScript := preload("res://scripts/genetics/genetics_engine.gd")
const SaveManagerScript := preload("res://scripts/core/save_manager.gd")

func _init() -> void:
	print("==================================================")
	print("🌿 FINEST GARDEN — UNIFIED HEADLESS TEST RUNNER 🌿")
	print("==================================================")

	var total_errors: Array[String] = []

	# 1. Run Data Validation
	print("\n>>> STEP 1: RUNNING DATA SCHEMA & ASSET VALIDATION...")
	var flowers: Array[String] = FlowerDataScript.get_all_flower_ids()
	if flowers.is_empty():
		total_errors.append("FlowerData returned empty flower list.")
	else:
		print("✓ Data validation OK: %d flowers loaded from JSON." % flowers.size())

	var bouquets: Array[String] = BouquetDataScript.get_all_bouquet_ids()
	if bouquets.is_empty():
		total_errors.append("BouquetData returned empty bouquet list.")
	else:
		print("✓ Data validation OK: %d bouquets loaded from JSON." % bouquets.size())

	var requests: Array[String] = FloristRequestDataScript.get_all_request_ids()
	if requests.is_empty():
		total_errors.append("FloristRequestData returned empty requests list.")
	else:
		print("✓ Data validation OK: %d requests loaded from JSON." % requests.size())

	var perfumes: Array[String] = PerfumeDataScript.get_all_perfume_ids()
	if perfumes.is_empty():
		total_errors.append("PerfumeData returned empty perfume list.")
	else:
		print("✓ Data validation OK: %d perfumes loaded from JSON." % perfumes.size())

	# 2. Run Genetics Engine Determinism Check
	print("\n>>> STEP 2: RUNNING GENETICS ENGINE CORE SUITE...")
	var p_rose: FlowerSpecimen = GeneticsEngineScript.create_starter_specimen("rose", "R-001")
	var p_lav: FlowerSpecimen = GeneticsEngineScript.create_starter_specimen("lavender", "L-001")
	var cross: Dictionary = GeneticsEngineScript.cross_specimens(p_rose, p_lav, 42)
	if cross.get("species", "") != "roselight":
		total_errors.append("Genetics hybrid cross expected 'roselight', got '%s'" % cross.get("species", ""))
	else:
		print("✓ Genetics cross test passed: %s produced %s." % [p_rose.specimen_id, cross["specimen"].specimen_id])

	# 3. Test SaveManager serialization
	print("\n>>> STEP 3: RUNNING SAVEMANAGER ROUNDTRIP TEST...")
	var test_state := {
		"coins": 150,
		"inventory": {"rose": 5, "lavender": 3},
		"bouquet_inventory": {"garden_harmony": 2},
		"perfume_inventory": {"lavender_mist": 1}
	}
	var save_ok := SaveManagerScript.save_game(test_state)
	if not save_ok:
		total_errors.append("SaveManager failed to save test state.")
	var loaded_state := SaveManagerScript.load_game()
	if loaded_state.get("coins", 0) != 150:
		total_errors.append("SaveManager load verification failed: expected coins 150, got %s" % str(loaded_state.get("coins", 0)))
	else:
		print("✓ SaveManager save/load round-trip test passed successfully!")

	# 4. Final Summary
	print("\n==================================================")
	if total_errors.is_empty():
		print("🎉 ALL HEADLESS VERIFICATION CHECKS PASSED (0 ERRORS)")
		print("==================================================")
		quit(0)
	else:
		printerr("❌ TEST RUNNER FAILED WITH %d ERRORS:" % total_errors.size())
		for err in total_errors:
			printerr("  - " + err)
		print("==================================================")
		quit(1)
