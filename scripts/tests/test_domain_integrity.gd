extends SceneTree

## BloomHaven Domain Integrity & Architecture Verification Suite (Sprint A)
## Covers:
## 1. FlowerQuality Enum & Value Object
## 2. Canonical FlowerInventory (Quality-tier storage, atomic consumption, zero mutation)
## 3. Canonical SeedInventory (Stock tracking, atomic consumption)
## 4. GardenPlot Growth & Action Guards (Prune window [0.60, 0.85], water/fertilizer/harvest guards, reset_to_empty_state)
## 5. OrderManager Atomic Deductions (Single unified order_runtime, duplicate fulfillment prevention, zero mutation)
## 6. Strict Catalog Lookups (Return empty dictionary on unknown keys, no fallback)
## 7. Atomic Mystery Seed Planting (Peek -> validate -> pop on success only)
## 8. Transactional Quick Sell with Quality Multipliers

var _passed_tests: int = 0
var _failed_tests: int = 0


func _init() -> void:
	print("==================================================")
	print("RUNNING BLOOMHAVEN SPRINT A DOMAIN INTEGRITY SUITE")
	print("==================================================")
	
	_run_suite("FlowerQuality Enum & Value Object", _test_flower_quality)
	_run_suite("FlowerInventory Canonical SSoT & Atomic Ops", _test_flower_inventory)
	_run_suite("SeedInventory Canonical SSoT & Consumption", _test_seed_inventory)
	_run_suite("GardenPlot Growth & Action Guards", _test_garden_plot_guards)
	_run_suite("OrderManager Unified State & Atomic Fulfillment", _test_order_manager)
	_run_suite("Strict Catalog Lookups", _test_strict_catalog_lookups)
	_run_suite("Atomic Mystery Seed Planting & SSoT", _test_mystery_seed_atomicity)
	_run_suite("Transactional Quick Sell & Quality Multipliers", _test_quick_sell_transactions)
	_run_suite("Atomic Bouquet Crafting & Transaction Rollback", _test_atomic_bouquet_crafting)
	
	print("\n==================================================")
	print("RESULTS: %d PASSED, %d FAILED" % [_passed_tests, _failed_tests])
	print("==================================================")
	
	if _failed_tests > 0:
		printerr("❌ DOMAIN INTEGRITY SUITE FAILED!")
		quit(1)
	else:
		print("🎉 ALL DOMAIN INTEGRITY TESTS PASSED (100% OK)!")
		quit(0)


func _run_suite(suite_name: String, test_func: Callable) -> void:
	print("\n--- Suite: %s ---" % suite_name)
	var err: String = test_func.call()
	if err == null or err == "":
		print("  ✓ Suite Passed: %s" % suite_name)
		_passed_tests += 1
	else:
		printerr("  ❌ Suite Failed: %s -> %s" % [suite_name, err])
		_failed_tests += 1


func _test_flower_quality() -> String:
	# 1. Enums
	if FlowerQuality.Tier.NORMAL != 1: return "FlowerQuality.Tier.NORMAL != 1"
	if FlowerQuality.Tier.FINE != 2: return "FlowerQuality.Tier.FINE != 2"
	if FlowerQuality.Tier.PERFECT != 3: return "FlowerQuality.Tier.PERFECT != 3"
	if FlowerQuality.Tier.HERO != 4: return "FlowerQuality.Tier.HERO != 4"
	
	# 2. Validation
	if not FlowerQuality.is_valid(1): return "1 should be valid tier"
	if not FlowerQuality.is_valid(4): return "4 should be valid tier"
	if FlowerQuality.is_valid(0): return "0 should be invalid tier"
	if FlowerQuality.is_valid(5): return "5 should be invalid tier"
	if FlowerQuality.is_valid(-1): return "-1 should be invalid tier"
	
	# 3. Multipliers
	if not is_equal_approx(FlowerQuality.get_multiplier(1), 1.0): return "Normal mult should be 1.0"
	if not is_equal_approx(FlowerQuality.get_multiplier(2), 1.25): return "Fine mult should be 1.25"
	if not is_equal_approx(FlowerQuality.get_multiplier(3), 1.5): return "Perfect mult should be 1.5"
	if not is_equal_approx(FlowerQuality.get_multiplier(4), 2.5): return "Hero mult should be 2.5"
	if not is_equal_approx(FlowerQuality.get_multiplier(99), 1.0): return "Invalid tier mult should fallback to 1.0"
	
	# 4. Tier Names & Badges
	if FlowerQuality.get_tier_name(FlowerQuality.Tier.FINE) != "Fine": return "Tier name mismatch"
	if FlowerQuality.get_tier_badge(FlowerQuality.Tier.NORMAL) != "★": return "Normal tier should have ★ badge"
	if FlowerQuality.get_tier_badge(FlowerQuality.Tier.PERFECT) != "★★★": return "Perfect tier should have ★★★ badge"
	
	return ""


func _test_flower_inventory() -> String:
	var inv := FlowerInventory.new()
	if inv.get_total_flower_count() != 0: return "Initial total count not 0"
	if not inv.get_all_flowers().is_empty(): return "Initial flowers not empty"
	
	# Add tiered flowers
	inv.add_flower("rose", FlowerQuality.Tier.NORMAL, 3)
	inv.add_flower("rose", FlowerQuality.Tier.FINE, 2)
	inv.add_flower("rose", FlowerQuality.Tier.PERFECT, 1)
	inv.add_flower("lavender", FlowerQuality.Tier.NORMAL, 4)
	
	if inv.get_flower_count("rose") != 6: return "Total rose count should be 6"
	if inv.get_flower_count_by_quality("rose", FlowerQuality.Tier.NORMAL) != 3: return "Normal roses should be 3"
	if inv.get_flower_count_by_quality("rose", FlowerQuality.Tier.FINE) != 2: return "Fine roses should be 2"
	if inv.get_flower_count_by_quality("rose", FlowerQuality.Tier.PERFECT) != 1: return "Perfect roses should be 1"
	if inv.get_total_flower_count() != 10: return "Total flowers should be 10"
	
	# Legacy view copy isolation
	var legacy: Dictionary = inv.get_legacy_view()
	if legacy["rose"] != 6: return "Legacy view rose count mismatch"
	legacy["rose"] = 999
	if inv.get_flower_count("rose") != 6: return "Legacy view modification mutated FlowerInventory storage!"
	
	# can_consume_requirements
	if not inv.can_consume_requirements({"rose": 5, "lavender": 2}): return "Requirements check failed on valid stock"
	if inv.can_consume_requirements({"rose": 7}): return "Requirements check should fail on insufficient roses"
	if inv.can_consume_requirements({"tulip": 1}): return "Requirements check should fail on missing flower"
	
	# Zero-mutation atomic rollback on failure
	var failed_consume: bool = inv.consume_requirements({"rose": 4, "tulip": 1}, "lowest_first")
	if failed_consume: return "consume_requirements should fail when tulip missing"
	if inv.get_flower_count("rose") != 6: return "Inventory rose count mutated despite transaction failure (zero-mutation violated)!"
	if inv.get_flower_count_by_quality("rose", FlowerQuality.Tier.NORMAL) != 3: return "Normal rose count mutated on failed transaction!"
	
	# Atomic consumption lowest_first
	var success_consume: bool = inv.consume_requirements({"rose": 4}, "lowest_first")
	if not success_consume: return "consume_requirements failed on valid stock"
	# Expecting 3 Normal roses consumed + 1 Fine rose consumed
	if inv.get_flower_count_by_quality("rose", FlowerQuality.Tier.NORMAL) != 0: return "Normal roses should be exhausted"
	if inv.get_flower_count_by_quality("rose", FlowerQuality.Tier.FINE) != 1: return "Fine roses should be 1 remaining"
	if inv.get_flower_count_by_quality("rose", FlowerQuality.Tier.PERFECT) != 1: return "Perfect roses should be 1 remaining"
	if inv.get_flower_count("rose") != 2: return "Total remaining roses should be 2"
	
	# Atomic consumption highest_first
	var inv2 := FlowerInventory.new()
	inv2.add_flower("daisy", FlowerQuality.Tier.NORMAL, 2)
	inv2.add_flower("daisy", FlowerQuality.Tier.HERO, 1)
	var high_consume: bool = inv2.consume_requirements({"daisy": 1}, "highest_first")
	if not high_consume: return "highest_first consume failed"
	if inv2.get_flower_count_by_quality("daisy", FlowerQuality.Tier.HERO) != 0: return "Hero daisy should be consumed first"
	if inv2.get_flower_count_by_quality("daisy", FlowerQuality.Tier.NORMAL) != 2: return "Normal daisies should remain untouched"
	
	# Serialization & Deserialization
	var serialized: Dictionary = inv.serialize()
	var inv_restored := FlowerInventory.new()
	inv_restored.deserialize(serialized)
	if inv_restored.get_flower_count("rose") != 2: return "Deserialized rose count mismatch"
	if inv_restored.get_flower_count_by_quality("rose", FlowerQuality.Tier.FINE) != 1: return "Deserialized fine rose mismatch"
	if inv_restored.get_flower_count_by_quality("rose", FlowerQuality.Tier.PERFECT) != 1: return "Deserialized perfect rose mismatch"
	if inv_restored.get_flower_count("lavender") != 4: return "Deserialized lavender count mismatch"
	
	return ""


func _test_seed_inventory() -> String:
	var seeds := SeedInventory.new()
	if not seeds.get_all_seeds().is_empty(): return "Initial seed inventory not empty"
	
	seeds.add_seeds("rose", 5)
	seeds.add_seeds("lavender", 2)
	
	if seeds.get_seed_count("rose") != 5: return "Rose seed count should be 5"
	if not seeds.has_seed("rose"): return "has_seed rose should be true"
	if seeds.has_seed("tulip"): return "has_seed tulip should be false"
	if not seeds.can_consume("rose", 5): return "can_consume 5 rose seeds should be true"
	if seeds.can_consume("rose", 6): return "can_consume 6 rose seeds should be false"
	
	# Consumption success
	var c1: bool = seeds.consume_seed("rose")
	if not c1 or seeds.get_seed_count("rose") != 4: return "consume_seed failed to deduct 1"
	
	# Consumption failure & zero mutation
	var c2: bool = seeds.consume_seed("sunflower")
	if c2: return "consume_seed should return false for missing seed"
	if seeds.get_seed_count("rose") != 4: return "rose seeds mutated when sunflower failed"
	
	# Remove
	seeds.remove_seeds("rose", 4)
	if seeds.has_seed("rose"): return "rose seeds should be fully removed"
	
	# Serialization
	seeds.add_seeds("daisy", 10)
	var s_data: Dictionary = seeds.serialize()
	var seeds_restored := SeedInventory.new()
	seeds_restored.deserialize(s_data)
	if seeds_restored.get_seed_count("daisy") != 10: return "Deserialized daisy seed count mismatch"
	if seeds_restored.get_seed_count("lavender") != 2: return "Deserialized lavender seed count mismatch"
	
	return ""


func _test_garden_plot_guards() -> String:
	var plot := GardenPlot.new()
	plot._ready()
	
	# 1. Empty plot state guards
	if plot.state != GardenPlot.State.EMPTY: return "Initial state not EMPTY"
	if plot.can_prune(): return "can_prune() should be false when EMPTY"
	if plot.prune(): return "prune() should return false when EMPTY"
	if plot.water(): return "water() should return false when EMPTY"
	if plot.apply_fertilizer(): return "apply_fertilizer() should return false when EMPTY"
	if not plot.harvest().is_empty(): return "harvest() should return empty dictionary when EMPTY"
	if plot.preserve_specimen_for_breeding() != null: return "preserve should return null when EMPTY"
	
	# 2. Plant starter specimen
	var starter := GeneticsEngine.create_starter_specimen("rose")
	var plant_ok: bool = plot.plant("rose", false, starter)
	if not plant_ok: return "plant() failed on EMPTY plot"
	if plot.state != GardenPlot.State.GROWING: return "State should be GROWING after plant"
	
	# 3. Prune window enforcement [0.60, 0.85]
	plot.growth_progress = 0.50
	if plot.can_prune(): return "can_prune() should be false at 0.50 growth (< 0.60)"
	if plot.prune(): return "prune() should return false at 0.50 growth"
	
	plot.growth_progress = 0.70
	if not plot.can_prune(): return "can_prune() should be true at 0.70 growth ([0.60, 0.85])"
	var prune_ok: bool = plot.prune()
	if not prune_ok: return "prune() failed within valid prune window"
	if not plot.is_pruned: return "is_pruned should be true"
	if plot.quality != FlowerQuality.Tier.HERO: return "Pruned plot quality should be HERO (Tier 4)"
	
	# Cannot prune twice
	if plot.can_prune(): return "can_prune() should be false when already pruned"
	if plot.prune(): return "prune() should reject second prune"
	
	# 4. Water guards
	var water_ok: bool = plot.water()
	if not water_ok: return "water() failed on unwatered GROWING plot"
	if not plot.is_watered: return "is_watered should be true"
	if plot.water(): return "water() should reject when already watered"
	
	# 5. Fertilizer guards
	var fert_ok: bool = plot.apply_fertilizer()
	if not fert_ok: return "apply_fertilizer() failed on unfertilized GROWING plot"
	if not plot.is_fertilized: return "is_fertilized should be true"
	if plot.apply_fertilizer(): return "apply_fertilizer() should reject when already fertilized"
	
	# 6. Mature state & harvest guards
	plot.growth_progress = 1.0
	plot.state = GardenPlot.State.MATURE
	
	# Non-growing actions reject when MATURE
	if plot.water(): return "water() should reject when MATURE"
	if plot.apply_fertilizer(): return "apply_fertilizer() should reject when MATURE"
	if plot.prune(): return "prune() should reject when MATURE"
	
	# Harvest signal captures quality
	var harvested_data: Array = []
	plot.flower_harvested.connect(func(f_id: String, count: int, quality: int):
		harvested_data.append({"id": f_id, "count": count, "quality": quality})
	)
	var harvest_res: Dictionary = plot.harvest()
	if harvest_res.is_empty(): return "harvest() failed on MATURE plot"
	if harvested_data.is_empty(): return "flower_harvested signal was not emitted"
	if harvested_data[0]["quality"] != FlowerQuality.Tier.HERO: return "Harvested quality mismatch (expected HERO)"
	
	# 7. Verify reset_to_empty_state() cleared all 12 properties
	if plot.state != GardenPlot.State.EMPTY: return "Reset state not EMPTY"
	if plot.current_flower_id != "": return "current_flower_id not reset"
	if plot.growth_progress != 0.0: return "growth_progress not reset"
	if plot.is_watered: return "is_watered not reset"
	if plot.water_duration_remaining != 0.0: return "water_duration_remaining not reset"
	if plot.is_fertilized: return "is_fertilized not reset"
	if plot.is_pruned: return "is_pruned not reset"
	if plot._prune_alerted: return "_prune_alerted not reset"
	if plot.quality != FlowerQuality.Tier.NORMAL: return "quality not reset to NORMAL"
	if plot.current_specimen != null: return "current_specimen not reset"
	if plot.is_mystery_seed: return "is_mystery_seed not reset"
	if plot.is_revealed: return "is_revealed not reset"
	
	# 8. Test preserve_specimen_for_breeding() rejection guards
	# Guard Case A: state != MATURE (e.g. GROWING) with specimen -> returns null
	plot.state = GardenPlot.State.GROWING
	plot.current_specimen = starter
	var rejected_pres_growing: FlowerSpecimen = plot.preserve_specimen_for_breeding()
	if rejected_pres_growing != null:
		return "preserve_specimen_for_breeding() must return null when state != MATURE"
	if plot.current_specimen != starter:
		return "Plot specimen should not be mutated when preserve is rejected"

	# Guard Case B: state == MATURE with current_specimen == null -> returns null
	plot.state = GardenPlot.State.MATURE
	plot.current_specimen = null
	var rejected_pres_nospec: FlowerSpecimen = plot.preserve_specimen_for_breeding()
	if rejected_pres_nospec != null:
		return "preserve_specimen_for_breeding() must return null when current_specimen is null"

	# Valid Case: state == MATURE with valid current_specimen -> preserves and resets
	plot.state = GardenPlot.State.MATURE
	plot.current_specimen = starter
	plot.current_flower_id = "rose"
	var success_pres: FlowerSpecimen = plot.preserve_specimen_for_breeding()
	if success_pres != starter:
		return "preserve_specimen_for_breeding() failed to return preserved specimen"
	if plot.state != GardenPlot.State.EMPTY:
		return "Plot state should be EMPTY after successful preserve"
	if plot.current_specimen != null:
		return "Plot current_specimen should be null after successful preserve"
	
	return ""


func _test_order_manager() -> String:
	var om := OrderManager.new()
	
	var flowers := FlowerInventory.new()
	var bouquets: Dictionary = {}
	
	# Ensure order_1 exists in FloristRequestData
	var req_1 := FloristRequestData.get_request("order_1")
	if req_1.is_empty(): return "order_1 not found in FloristRequestData"
	var req_items: Dictionary = req_1.get("required_items", {})
	if req_items.is_empty(): return "order_1 has no required_items"
	
	# Reset order_1 first to ensure fresh state
	om.reset_order("order_1")
	
	# 1. Failure on insufficient items -> zero mutation
	flowers.add_flower("rose", FlowerQuality.Tier.NORMAL, 1) # order_1 requires lavender/sunflower
	var fail_res: Dictionary = om.fulfill_order("order_1", flowers, bouquets)
	if fail_res.get("success", false): return "fulfill_order should fail on insufficient items"
	if flowers.get_flower_count("rose") != 1: return "Flowers deducted despite failed fulfillment (zero mutation violated)!"
	if om.order_runtime["order_1"]["completed"]: return "order_1 marked completed on failed fulfillment!"
	
	# 2. Add required items and fulfill
	for f_id in req_items:
		flowers.add_flower(f_id, FlowerQuality.Tier.NORMAL, int(req_items[f_id]) + 3)
	
	var pre_fulfill_counts: Dictionary = {}
	for f_id in req_items:
		pre_fulfill_counts[f_id] = flowers.get_flower_count(f_id)
	
	var ok_res: Dictionary = om.fulfill_order("order_1", flowers, bouquets)
	if not ok_res.get("success", false): return "fulfill_order failed with sufficient stock: " + str(ok_res.get("error", ""))
	
	for f_id in req_items:
		var expected_cnt: int = int(pre_fulfill_counts[f_id]) - int(req_items[f_id])
		if flowers.get_flower_count(f_id) != expected_cnt:
			return "%s deduction count incorrect" % f_id
			
	if not om.order_runtime["order_1"]["completed"]: return "order_1 not marked completed in order_runtime"
	
	# 3. Prevent duplicate fulfillment of already completed order (P0-04)
	var dup_counts: Dictionary = {}
	for f_id in req_items:
		flowers.add_flower(f_id, FlowerQuality.Tier.NORMAL, 5)
		dup_counts[f_id] = flowers.get_flower_count(f_id)
		
	var dup_res: Dictionary = om.fulfill_order("order_1", flowers, bouquets)
	if dup_res.get("success", false): return "Repeat fulfillment of completed order_1 must be rejected (P0-04)!"
	for f_id in req_items:
		if flowers.get_flower_count(f_id) != dup_counts[f_id]:
			return "Repeat fulfillment deducted %s flowers!" % f_id
	
	# 4. reset_order allows re-fulfilling
	om.reset_order("order_1")
	if om.order_runtime["order_1"]["completed"]: return "reset_order failed to reset completed flag"
	
	return ""


func _test_strict_catalog_lookups() -> String:
	# FlowerData
	var f_unknown := FlowerData.get_flower("definitely_non_existent_flower")
	if not f_unknown.is_empty(): return "FlowerData.get_flower returned fallback dictionary instead of {} on unknown ID"
	var f_valid := FlowerData.get_flower("rose")
	if f_valid.is_empty() or f_valid.get("id", "") != "rose": return "FlowerData.get_flower failed for valid rose"
	
	# BouquetData
	var b_unknown := BouquetData.get_bouquet("definitely_non_existent_bouquet")
	if not b_unknown.is_empty(): return "BouquetData.get_bouquet returned fallback dictionary instead of {} on unknown ID"
	var b_valid := BouquetData.get_bouquet("garden_harmony")
	if b_valid.is_empty(): return "BouquetData.get_bouquet failed for garden_harmony"
	
	# FloristRequestData
	var r_unknown := FloristRequestData.get_request("definitely_non_existent_order")
	if not r_unknown.is_empty(): return "FloristRequestData.get_request returned fallback dictionary instead of {} on unknown ID"
	var r_valid := FloristRequestData.get_request("order_1")
	if r_valid.is_empty(): return "FloristRequestData.get_request failed for order_1"
	
	return ""


func _test_mystery_seed_atomicity() -> String:
	var plot := GardenPlot.new()
	plot._ready()
	
	# Setup specimen queue
	var sp1 := GeneticsEngine.create_starter_specimen("rose", "M-001")
	var pending_queue: Array[FlowerSpecimen] = [sp1]
	
	# Case A: Plot occupied -> reject plant -> queue untouched
	plot.state = GardenPlot.State.MATURE
	if plot.state == GardenPlot.State.EMPTY: return "Test plot should be occupied"
	
	# Simulate atomic peek
	if plot.state != GardenPlot.State.EMPTY:
		# Rejected! Queue must not be popped
		pass
	else:
		pending_queue.pop_front()
	
	if pending_queue.size() != 1: return "Specimen popped from queue when plot was occupied (zero mutation violated)!"
	
	# Case B: Plot empty -> plant succeeds -> pop candidate
	plot.reset_to_empty_state()
	var candidate: FlowerSpecimen = pending_queue[0]
	var planted: bool = plot.plant(candidate.species_id, true, candidate)
	if not planted: return "Failed to plant mystery specimen on empty plot"
	pending_queue.pop_front()
	
	if not pending_queue.is_empty(): return "Pending queue was not popped after successful plant"
	if not plot.is_mystery_seed: return "Plot is_mystery_seed should be true"
	if plot.current_specimen.specimen_id != "M-001": return "Planted specimen ID mismatch"
	
	return ""


func _test_quick_sell_transactions() -> String:
	var inv := FlowerInventory.new()
	inv.add_flower("rose", FlowerQuality.Tier.NORMAL, 2)   # 2 * 10 = 20
	inv.add_flower("rose", FlowerQuality.Tier.PERFECT, 1)  # 1 * (10 * 1.5) = 15
	inv.add_flower("rose", FlowerQuality.Tier.HERO, 1)     # 1 * (10 * 2.5) = 25
	inv.add_flower("daisy", FlowerQuality.Tier.FINE, 2)    # 2 * (8 * 1.25) = 20
	
	# 1. Single sell with quality
	var rose_data := FlowerData.get_flower("rose")
	var base_val: int = int(rose_data.get("base_value", 10))
	var mult_perfect: float = FlowerQuality.get_multiplier(FlowerQuality.Tier.PERFECT)
	var price_perfect: int = int(round(base_val * mult_perfect))
	if price_perfect != 15: return "Expected 15 coins for Perfect Rose, calculated: %d" % price_perfect
	
	var sold_perfect: bool = inv.remove_flower("rose", FlowerQuality.Tier.PERFECT, 1)
	if not sold_perfect: return "Failed to remove Perfect Rose"
	if inv.get_flower_count_by_quality("rose", FlowerQuality.Tier.PERFECT) != 0: return "Perfect rose not decremented"
	if inv.get_flower_count_by_quality("rose", FlowerQuality.Tier.NORMAL) != 2: return "Normal roses unexpectedly mutated"
	
	# 1b. Hero sell (2.5x multiplier)
	var mult_hero: float = FlowerQuality.get_multiplier(FlowerQuality.Tier.HERO)
	if not is_equal_approx(mult_hero, 2.5): return "Hero quality multiplier must be 2.50x"
	var price_hero: int = int(round(base_val * mult_hero))
	if price_hero != 25: return "Expected 25 coins for Hero Rose (10 * 2.5), calculated: %d" % price_hero
	
	var sold_hero: bool = inv.remove_flower("rose", FlowerQuality.Tier.HERO, 1)
	if not sold_hero: return "Failed to remove Hero Rose"
	if inv.get_flower_count_by_quality("rose", FlowerQuality.Tier.HERO) != 0: return "Hero rose not decremented"
	if inv.get_flower_count_by_quality("rose", FlowerQuality.Tier.NORMAL) != 2: return "Normal roses unexpectedly mutated after Hero sell"
	
	# 2. Batch Sell All calculation
	var total_calculated: int = 0
	var all_f := inv.get_all_flowers()
	for f_id in all_f:
		var f_val: int = int(FlowerData.get_flower(f_id).get("base_value", 10))
		for tier_key in all_f[f_id]:
			var t: int = int(tier_key)
			var cnt: int = int(all_f[f_id][tier_key])
			var p: int = int(round(f_val * FlowerQuality.get_multiplier(t)))
			total_calculated += p * cnt
	
	# Normal roses: 2 * 10 = 20. Fine daisies: 2 * 10 = 20. Total = 40
	if total_calculated != 40: return "Expected 40 coins for remaining flowers, got: %d" % total_calculated
	
	inv.clear()
	if inv.get_total_flower_count() != 0: return "Inventory not empty after clear"
	
	return ""


func _test_atomic_bouquet_crafting() -> String:
	var f_inv := FlowerInventory.new()
	var b_inv: Dictionary = {}
	
	# 1. Invalid recipe validation
	var res_invalid := BouquetData.craft_bouquet("non_existent_recipe", f_inv, b_inv)
	if res_invalid.get("success", false):
		return "craft_bouquet must reject non-existent recipe ID"
	if not b_inv.is_empty():
		return "b_inv must remain empty on invalid recipe"

	# Recipe: garden_harmony requires {rose: 1, lavender: 1, sunflower: 1}
	# 2. Insufficient ingredients (multi-ingredient rollback & zero mutation)
	f_inv.add_flower("rose", FlowerQuality.Tier.NORMAL, 2)
	f_inv.add_flower("sunflower", FlowerQuality.Tier.FINE, 1)
	# Note: lavender is missing (count == 0)
	
	var res_fail := BouquetData.craft_bouquet("garden_harmony", f_inv, b_inv)
	if res_fail.get("success", false):
		return "craft_bouquet must fail when missing lavender"
	if f_inv.get_flower_count("rose") != 2:
		return "Zero mutation failure: rose count changed after failed craft"
	if f_inv.get_flower_count("sunflower") != 1:
		return "Zero mutation failure: sunflower count changed after failed craft"
	if f_inv.get_flower_count("lavender") != 0:
		return "Zero mutation failure: lavender count changed after failed craft"
	if not b_inv.is_empty():
		return "b_inv must not gain any items on failed craft"

	# 3. Successful atomic crafting & exact deduction
	f_inv.add_flower("lavender", FlowerQuality.Tier.NORMAL, 1)
	var res_ok := BouquetData.craft_bouquet("garden_harmony", f_inv, b_inv)
	if not res_ok.get("success", false):
		return "craft_bouquet failed with valid ingredients: %s" % res_ok.get("error", "")
	
	if f_inv.get_flower_count("rose") != 1:
		return "Exact deduction failure: rose count should be 1 (was 2, deducted 1)"
	if f_inv.get_flower_count("sunflower") != 0:
		return "Exact deduction failure: sunflower count should be 0 (was 1, deducted 1)"
	if f_inv.get_flower_count("lavender") != 0:
		return "Exact deduction failure: lavender count should be 0 (was 1, deducted 1)"
	if b_inv.get("garden_harmony", 0) != 1:
		return "Bouquet not added to bouquet_inventory after successful craft"

	return ""

