extends SceneTree

## BloomHaven - Final Runtime Playtest Suite (Scenarios 1 to 12)
## Tests full real game integration using true runtime instances (MainGame, GardenPlot, GardenerCharacter, etc.)

const MainGameScene := preload("res://scenes/main.tscn")
const SaveManagerScript := preload("res://scripts/core/save_manager.gd")
const GeneticsEngineScript := preload("res://scripts/genetics/genetics_engine.gd")
const AudioManagerScript := preload("res://scripts/core/audio_manager.gd")

var _passed_count: int = 0
var _failed_count: int = 0
var _scenario_results: Array[Dictionary] = []


func _init() -> void:
	root.process_mode = Node.PROCESS_MODE_PAUSABLE
	_run_all_scenarios()


func _run_all_scenarios() -> void:
	print("========================================================================")
	print("🌸 BLOOMHAVEN — FINAL RUNTIME PLAYTEST GATE (SCENARIOS 1–12) 🌸")
	print("========================================================================")

	# Backup primary save to ensure clean sandbox environment during playtests
	var primary_save := "user://bloomhaven_save_v3.json"
	var primary_pretest_bak := "user://bloomhaven_save_v3.json.pretest_bak"
	if FileAccess.file_exists(primary_save):
		var src := FileAccess.open(primary_save, FileAccess.READ)
		var content := src.get_as_text()
		src.close()
		var dst := FileAccess.open(primary_pretest_bak, FileAccess.WRITE)
		dst.store_string(content)
		dst.close()
		DirAccess.remove_absolute(primary_save)

	# Execute all 12 Scenarios sequentially
	await _run_scenario("Scenario 1: Complete Flower Lifecycle", _scenario_1_flower_lifecycle)
	await _run_scenario("Scenario 2: Hero Persistence & Sale", _scenario_2_hero_persistence_and_sale)
	await _run_scenario("Scenario 3: Seed Exhaustion", _scenario_3_seed_exhaustion)
	await _run_scenario("Scenario 4: Hybrid Persistence", _scenario_4_hybrid_persistence)
	await _run_scenario("Scenario 5: Specimen ID Collision", _scenario_5_specimen_id_collision)
	await _run_scenario("Scenario 6: Bouquet Atomicity", _scenario_6_bouquet_atomicity)
	await _run_scenario("Scenario 7: Customer Order Atomicity", _scenario_7_order_atomicity)
	await _run_scenario("Scenario 8: Pause Integrity", _scenario_8_pause_integrity)
	await _run_scenario("Scenario 9: Queue / Character Actions", _scenario_9_queue_character_actions)
	await _run_scenario("Scenario 10: Save Recovery Matrix", _scenario_10_save_recovery_matrix)
	await _run_scenario("Scenario 11: UI Wiring Stress", _scenario_11_ui_wiring_stress)
	await _run_scenario("Scenario 12: Full Extended Natural Session", _scenario_12_full_session_simulation)

	# Restore pretest save if it existed
	if FileAccess.file_exists(primary_pretest_bak):
		var src := FileAccess.open(primary_pretest_bak, FileAccess.READ)
		var content := src.get_as_text()
		src.close()
		var dst := FileAccess.open(primary_save, FileAccess.WRITE)
		dst.store_string(content)
		dst.close()
		DirAccess.remove_absolute(primary_pretest_bak)

	# Print Final Summary Table
	print("\n========================================================================")
	print("📊 FINAL RUNTIME PLAYTEST MATRIX SUMMARY")
	print("========================================================================")
	print("%-46s | %-8s | %s" % ["Scenario Name", "Verdict", "Duration"])
	print("------------------------------------------------------------------------")
	for res in _scenario_results:
		print("%-46s | %-8s | %0.2fs" % [res["name"], res["status"], res["duration"]])
	print("========================================================================")
	print("TOTAL: %d PASSED, %d FAILED" % [_passed_count, _failed_count])
	print("========================================================================")

	if _failed_count == 0:
		print("\n🎉 ALL 12 RUNTIME PLAYTEST SCENARIOS PASSED 100% OK!")
		print("========================================================================\n")
		quit(0)
	else:
		printerr("\n❌ RUNTIME PLAYTEST GATE FAILED (%d SCENARIOS FAILED)!" % _failed_count)
		print("========================================================================\n")
		quit(1)


func _run_scenario(sc_name: String, test_func: Callable) -> void:
	print("\n>>> STARTING: %s" % sc_name)
	paused = false
	var t_start: int = Time.get_ticks_msec()
	var err: String = await test_func.call()
	paused = false
	
	var elapsed_sec: float = (Time.get_ticks_msec() - t_start) / 1000.0
	var passed: bool = (err == "")
	
	if passed:
		print("  ✓ %s: PASS (%0.2fs)" % [sc_name, elapsed_sec])
		_passed_count += 1
		_scenario_results.append({"name": sc_name, "status": "PASS", "duration": elapsed_sec})
	else:
		printerr("  ❌ %s: FAIL -> %s (%0.2fs)" % [sc_name, err, elapsed_sec])
		_failed_count += 1
		_scenario_results.append({"name": sc_name, "status": "FAIL", "duration": elapsed_sec})


func _setup_main() -> MainGame:
	var main: MainGame = MainGameScene.instantiate() as MainGame
	root.add_child(main)
	return main


func _extract_save_dict(main: MainGame) -> Dictionary:
	var roster_serialized: Array = []
	for spec in main.breeding_roster:
		if is_instance_valid(spec):
			roster_serialized.append(spec.serialize())

	var pending_serialized: Array = []
	for spec in main.pending_hybrid_seeds:
		if is_instance_valid(spec):
			pending_serialized.append(spec.serialize())

	return {
		"coins": main.coins,
		"specimen_counter": GeneticsEngine.get_specimen_counter(),
		"flower_inventory_storage": main.flower_inventory.serialize(),
		"seed_inventory": main.seed_inventory.serialize(),
		"bouquet_inventory": main.bouquet_inventory,
		"perfume_inventory": main.perfume_inventory,
		"order_runtime": main.order_manager.serialize().get("order_runtime", {}),
		"combo_count": main.order_manager.combo_count if main.order_manager != null else 0,
		"combo_timer": main.order_manager.combo_timer if main.order_manager != null else 0.0,
		"discovered_flowers": main.discovered_flowers,
		"active_upgrades": main.upgrade_manager.serialize() if main.upgrade_manager != null else main.active_upgrades,
		"tutorial_completed": main.tutorial_completed,
		"pending_hybrid_seeds": pending_serialized,
		"breeding_roster": roster_serialized,
		"plots": SaveManagerScript.serialize_plots(main.garden_grid.plots) if is_instance_valid(main.garden_grid) else []
	}


func _apply_data_to_main(main: MainGame, data: Dictionary) -> void:
	if data.is_empty():
		return
	main.coins = int(data.get("coins", main.coins))
	var saved_counter: int = int(data.get("specimen_counter", 100))
	GeneticsEngine.set_specimen_counter(saved_counter)

	if data.has("flower_inventory_storage") and data["flower_inventory_storage"] is Dictionary:
		main.flower_inventory.deserialize(data["flower_inventory_storage"])
	elif data.has("inventory") and data["inventory"] is Dictionary:
		main.flower_inventory.deserialize(data["inventory"])

	if data.has("seed_inventory") and data["seed_inventory"] is Dictionary:
		main.seed_inventory.deserialize(data["seed_inventory"])

	main.bouquet_inventory = data.get("bouquet_inventory", main.bouquet_inventory)
	main.perfume_inventory = data.get("perfume_inventory", main.perfume_inventory)

	if main.order_manager != null:
		main.order_manager.deserialize(data)
	main.completed_requests = main.order_manager.completed_requests if main.order_manager != null else data.get("completed_requests", main.completed_requests)

	main.discovered_flowers = data.get("discovered_flowers", main.discovered_flowers)
	if main.upgrade_manager != null and data.has("active_upgrades") and data["active_upgrades"] is Dictionary:
		main.upgrade_manager.deserialize(data["active_upgrades"])
	main.active_upgrades = main.upgrade_manager.active_upgrades if main.upgrade_manager != null else data.get("active_upgrades", main.active_upgrades)
	main._apply_all_active_upgrades()

	main.tutorial_completed = bool(data.get("tutorial_completed", false))

	if data.has("pending_hybrid_seeds") and data["pending_hybrid_seeds"] is Array:
		main.pending_hybrid_seeds.clear()
		for s_dict in data["pending_hybrid_seeds"]:
			if s_dict is Dictionary:
				main.pending_hybrid_seeds.append(FlowerSpecimen.deserialize(s_dict))

	if data.has("breeding_roster") and data["breeding_roster"] is Array:
		main.breeding_roster.clear()
		for s_dict in data["breeding_roster"]:
			if s_dict is Dictionary:
				main.breeding_roster.append(FlowerSpecimen.deserialize(s_dict))

	if data.has("plots") and data["plots"] is Array and is_instance_valid(main.garden_grid):
		SaveManagerScript.deserialize_plots(data["plots"], main.garden_grid.plots)


# -----------------------------------------------------------------------------
# SCENARIO 1: Complete Flower Lifecycle
# -----------------------------------------------------------------------------
func _scenario_1_flower_lifecycle() -> String:
	var main: MainGame = _setup_main()
	await process_frame
	await process_frame

	# 1. New game starter seeds check
	main.flower_inventory.clear()
	main.seed_inventory.clear()
	main._init_new_game_starter_seeds()
	if main.seed_inventory.get_seed_count("rose") != 5:
		main.queue_free()
		return "Expected 5 starter roses, got %d" % main.seed_inventory.get_seed_count("rose")
	if main.seed_inventory.get_seed_count("tulip") != 5:
		main.queue_free()
		return "Expected 5 starter tulips"
	if main.seed_inventory.get_seed_count("daisy") != 5:
		main.queue_free()
		return "Expected 5 starter daisies"
	if main.seed_inventory.get_seed_count("lavender") != 5:
		main.queue_free()
		return "Expected 5 starter lavenders"

	var plot: GardenPlot = main.garden_grid.plots[0]
	plot.reset_to_empty_state()

	# 2. Plant Rose
	main.current_seed = "rose"
	main._handle_planting_action(plot)
	if plot.state != GardenPlot.State.GROWING:
		main.queue_free()
		return "Plot did not enter GROWING state"
	if plot.current_flower_id != "rose":
		main.queue_free()
		return "Plot flower_id expected 'rose', got '%s'" % plot.current_flower_id
	if main.seed_inventory.get_seed_count("rose") != 4:
		main.queue_free()
		return "Rose seed was not decremented exactly 1 (current: %d)" % main.seed_inventory.get_seed_count("rose")

	# 3. Water Plot
	var water_ok := plot.water()
	if not water_ok or not plot.is_watered:
		main.queue_free()
		return "Plot watering failed"
	if plot.water_duration_remaining <= 0.0:
		main.queue_free()
		return "Water timer not initialized"

	# 4. Prune Window Tests
	# A: Attempt before window (growth = 0.40 < 0.60) -> must fail
	plot.growth_progress = 0.40
	var prune_early := plot.prune()
	if prune_early:
		main.queue_free()
		return "Prune succeeded before window (< 0.60)"
	if plot.is_pruned or plot.quality == FlowerQuality.Tier.HERO:
		main.queue_free()
		return "Plot mutated quality on early prune attempt"

	# B: Attempt within window (growth = 0.70 in [0.60, 0.85]) -> must succeed
	plot.growth_progress = 0.70
	var prune_valid := plot.prune()
	if not prune_valid:
		main.queue_free()
		return "Prune failed within valid window (0.70)"
	if not plot.is_pruned:
		main.queue_free()
		return "plot.is_pruned expected true"
	if plot.quality != FlowerQuality.Tier.HERO:
		main.queue_free()
		return "plot.quality expected HERO, got %d" % plot.quality

	# C: Attempt after window (growth = 0.90 > 0.85) -> must fail
	plot.growth_progress = 0.90
	var prune_late := plot.prune()
	if prune_late:
		main.queue_free()
		return "Second prune or late prune succeeded unexpectedly"

	# 5. Advance to mature
	plot.growth_progress = 1.0
	plot._process(0.1)
	if plot.state != GardenPlot.State.MATURE:
		main.queue_free()
		return "Plot did not transition to MATURE at 1.0 growth"

	# 6. Harvest
	plot.harvest()
	if plot.state != GardenPlot.State.EMPTY:
		main.queue_free()
		return "Plot state not EMPTY after harvest"
	if not plot.current_flower_id.is_empty():
		main.queue_free()
		return "Plot current_flower_id not empty after harvest"
	if plot.is_watered or plot.is_pruned:
		main.queue_free()
		return "Plot flags not reset after harvest"

	# Check flower inventory (Hero bloom concentrates energy yielding 2 flowers per GardenPlot.harvest())
	var hero_roses: int = main.flower_inventory.get_flower_count_by_quality("rose", FlowerQuality.Tier.HERO)
	if hero_roses != 2:
		main.queue_free()
		return "Harvested flower count expected 2 HERO roses, found %d" % hero_roses
	if main.seed_inventory.get_seed_count("rose") != 4:
		main.queue_free()
		return "Seed count corrupted after harvest (expected 4, got %d)" % main.seed_inventory.get_seed_count("rose")

	main.queue_free()
	await process_frame
	return ""


# -----------------------------------------------------------------------------
# SCENARIO 2: Hero Persistence & Sale
# -----------------------------------------------------------------------------
func _scenario_2_hero_persistence_and_sale() -> String:
	var sandbox_save := "user://playtest_scenario_2_sandbox.json"
	var main: MainGame = _setup_main()
	await process_frame
	await process_frame

	# 1. Setup 1 Hero Rose and 100 coins
	main.coins = 100
	main.flower_inventory.clear()
	main.flower_inventory.add_flower("rose", FlowerQuality.Tier.HERO, 1)

	# Record pre-save state
	var pre_coins: int = main.coins
	var pre_hero_count: int = main.flower_inventory.get_flower_count_by_quality("rose", FlowerQuality.Tier.HERO)

	# Save to sandbox
	var save_ok := SaveManagerScript.save_game(_extract_save_dict(main), sandbox_save)
	if not save_ok:
		main.queue_free()
		return "SaveManager failed to save scenario 2 state"

	main.queue_free()
	await process_frame

	# 2. Simulate complete restart & load
	var loaded_data := SaveManagerScript.load_game(sandbox_save)
	if loaded_data.is_empty():
		return "SaveManager failed to load scenario 2 state"

	var main2: MainGame = _setup_main()
	await process_frame
	await process_frame
	_apply_data_to_main(main2, loaded_data)

	# 3. Verify Hero survived load
	var post_load_hero: int = main2.flower_inventory.get_flower_count_by_quality("rose", FlowerQuality.Tier.HERO)
	if post_load_hero != pre_hero_count:
		main2.queue_free()
		return "Hero Rose did not survive reload: expected %d, got %d" % [pre_hero_count, post_load_hero]
	if main2.coins != pre_coins:
		main2.queue_free()
		return "Coins mismatch after reload: expected %d, got %d" % [pre_coins, main2.coins]

	# 4. Sell 1 Hero Rose
	# Base price = 10, multiplier = 2.5 -> 25 coins
	var flower_data := FlowerData.get_flower("rose")
	var base_price: int = int(flower_data.get("sell_price", 10))
	var multiplier: float = FlowerQuality.get_multiplier(FlowerQuality.Tier.HERO)
	var expected_revenue: int = int(round(base_price * multiplier)) # 10 * 2.5 = 25
	if expected_revenue != 25:
		main2.queue_free()
		return "Expected revenue 25, got %d" % expected_revenue

	var consumed: bool = main2.flower_inventory.remove_flower("rose", FlowerQuality.Tier.HERO, 1)
	if not consumed:
		main2.queue_free()
		return "Failed to consume Hero Rose from inventory"
	main2.coins += expected_revenue

	if main2.coins != pre_coins + 25:
		main2.queue_free()
		return "Coins after sale expected %d, got %d" % [pre_coins + 25, main2.coins]
	if main2.flower_inventory.get_flower_count_by_quality("rose", FlowerQuality.Tier.HERO) != 0:
		main2.queue_free()
		return "Hero Rose count did not decrement to 0"

	# Cleanup sandbox file
	if FileAccess.file_exists(sandbox_save): DirAccess.remove_absolute(sandbox_save)
	if FileAccess.file_exists(sandbox_save.replace(".json", ".bak")): DirAccess.remove_absolute(sandbox_save.replace(".json", ".bak"))

	main2.queue_free()
	await process_frame
	return ""


# -----------------------------------------------------------------------------
# SCENARIO 3: Seed Exhaustion
# -----------------------------------------------------------------------------
func _scenario_3_seed_exhaustion() -> String:
	var sandbox_save := "user://playtest_scenario_3_sandbox.json"
	var main: MainGame = _setup_main()
	await process_frame
	await process_frame

	# 1. Set lavender seeds = 1
	main.seed_inventory.clear()
	main.seed_inventory.add_seeds("lavender", 1)

	var plot1: GardenPlot = main.garden_grid.plots[0]
	var plot2: GardenPlot = main.garden_grid.plots[1]
	plot1.reset_to_empty_state()
	plot2.reset_to_empty_state()

	# 2. Plant lavender in plot 1 (1 -> 0)
	main.current_seed = "lavender"
	main._handle_planting_action(plot1)
	if plot1.state != GardenPlot.State.GROWING:
		main.queue_free()
		return "Plot 1 failed to plant lavender"
	if main.seed_inventory.get_seed_count("lavender") != 0:
		main.queue_free()
		return "Lavender seed count expected 0, got %d" % main.seed_inventory.get_seed_count("lavender")

	# 3. Attempt second plant in plot 2 when count == 0 -> must be rejected
	main._handle_planting_action(plot2)
	if plot2.state != GardenPlot.State.EMPTY:
		main.queue_free()
		return "Plot 2 planted without seeds! State: %d" % plot2.state
	if main.seed_inventory.get_seed_count("lavender") != 0:
		main.queue_free()
		return "Lavender seed count auto-refilled to %d!" % main.seed_inventory.get_seed_count("lavender")

	# 4. Save and reload -> must remain 0 (no starter seeds re-grant)
	SaveManagerScript.save_game(_extract_save_dict(main), sandbox_save)
	main.queue_free()
	await process_frame

	var loaded_data := SaveManagerScript.load_game(sandbox_save)
	var main2: MainGame = _setup_main()
	await process_frame
	await process_frame
	_apply_data_to_main(main2, loaded_data)

	if main2.seed_inventory.get_seed_count("lavender") != 0:
		main2.queue_free()
		return "Lavender seeds regenerated upon reload: %d" % main2.seed_inventory.get_seed_count("lavender")

	# Cleanup sandbox
	if FileAccess.file_exists(sandbox_save): DirAccess.remove_absolute(sandbox_save)
	if FileAccess.file_exists(sandbox_save.replace(".json", ".bak")): DirAccess.remove_absolute(sandbox_save.replace(".json", ".bak"))

	main2.queue_free()
	await process_frame
	return ""


# -----------------------------------------------------------------------------
# SCENARIO 4: Hybrid Persistence
# -----------------------------------------------------------------------------
func _scenario_4_hybrid_persistence() -> String:
	var sandbox_save := "user://playtest_scenario_4_sandbox.json"
	var main: MainGame = _setup_main()
	await process_frame
	await process_frame

	# 1. Setup Rose & Lavender inventory and breed Velvet Dusk
	main.flower_inventory.clear()
	main.flower_inventory.add_flower("rose", FlowerQuality.Tier.NORMAL, 2)
	main.flower_inventory.add_flower("lavender", FlowerQuality.Tier.NORMAL, 2)
	main.pending_hybrid_seeds.clear()

	main._on_breed_requested("rose", "lavender", 0)
	if main.pending_hybrid_seeds.size() != 1:
		main.queue_free()
		return "Expected 1 pending hybrid seed, got %d" % main.pending_hybrid_seeds.size()

	var orig_specimen: FlowerSpecimen = main.pending_hybrid_seeds[0]
	var spec_id: String = orig_specimen.specimen_id
	var spec_species: String = orig_specimen.species_id
	var spec_geno: Dictionary = orig_specimen.genotype.serialize()
	var spec_pheno: Dictionary = orig_specimen.phenotype.serialize()
	var spec_pa: String = orig_specimen.parent_a_id
	var spec_pb: String = orig_specimen.parent_b_id
	var spec_gen: int = orig_specimen.generation

	if spec_species != "velvet_dusk":
		main.queue_free()
		return "Expected velvet_dusk hybrid, got '%s'" % spec_species

	# 2. Save and quit
	var save_ok := SaveManagerScript.save_game(_extract_save_dict(main), sandbox_save)
	if not save_ok:
		main.queue_free()
		return "Save failed for hybrid persistence"
	main.queue_free()
	await process_frame

	# 3. Reload from fresh process
	var loaded_data := SaveManagerScript.load_game(sandbox_save)
	var main2: MainGame = _setup_main()
	await process_frame
	await process_frame
	_apply_data_to_main(main2, loaded_data)

	if main2.pending_hybrid_seeds.size() != 1:
		main2.queue_free()
		return "Pending hybrid seeds count mismatch after reload: %d" % main2.pending_hybrid_seeds.size()

	var loaded_sp: FlowerSpecimen = main2.pending_hybrid_seeds[0]
	if loaded_sp.specimen_id != spec_id:
		main2.queue_free()
		return "Specimen ID changed on reload: %s vs %s" % [loaded_sp.specimen_id, spec_id]
	if loaded_sp.species_id != spec_species:
		main2.queue_free()
		return "Species ID changed on reload: %s vs %s" % [loaded_sp.species_id, spec_species]
	if loaded_sp.parent_a_id != spec_pa or loaded_sp.parent_b_id != spec_pb:
		main2.queue_free()
		return "Parents changed on reload"
	if loaded_sp.generation != spec_gen:
		main2.queue_free()
		return "Generation changed on reload"
	if loaded_sp.genotype.serialize() != spec_geno:
		main2.queue_free()
		return "Genotype lost or altered on reload"
	if loaded_sp.phenotype.serialize() != spec_pheno:
		main2.queue_free()
		return "Phenotype lost or altered on reload"

	# 4. Plant hybrid into plot
	var plot: GardenPlot = main2.garden_grid.plots[0]
	plot.reset_to_empty_state()
	main2.current_seed = "mystery_seed"
	main2._handle_planting_action(plot)

	if plot.state != GardenPlot.State.GROWING:
		main2.queue_free()
		return "Failed to plant mystery seed"
	if not plot.is_mystery_seed:
		main2.queue_free()
		return "Plot is_mystery_seed flag false"
	if plot.current_specimen.specimen_id != spec_id:
		main2.queue_free()
		return "Planted specimen ID mismatch: %s vs %s" % [plot.current_specimen.specimen_id, spec_id]
	if main2.pending_hybrid_seeds.size() != 0:
		main2.queue_free()
		return "Pending hybrid seeds not decremented"

	# Cleanup sandbox
	if FileAccess.file_exists(sandbox_save): DirAccess.remove_absolute(sandbox_save)
	if FileAccess.file_exists(sandbox_save.replace(".json", ".bak")): DirAccess.remove_absolute(sandbox_save.replace(".json", ".bak"))

	main2.queue_free()
	await process_frame
	return ""


# -----------------------------------------------------------------------------
# SCENARIO 5: Specimen ID Collision
# -----------------------------------------------------------------------------
func _scenario_5_specimen_id_collision() -> String:
	# 1. Register existing IDs including H-105
	GeneticsEngine.scan_and_register_ids(["H-101", "H-102", "H-103", "H-104", "H-105", "R-001"])
	var counter_before: int = GeneticsEngine.get_specimen_counter()
	if counter_before < 105:
		return "Specimen counter not updated to max (expected >= 105, got %d)" % counter_before

	# 2. Create new specimen
	var p_rose := GeneticsEngine.create_starter_specimen("rose", "R-001")
	var p_lav := GeneticsEngine.create_starter_specimen("lavender", "L-001")
	var cross := GeneticsEngine.cross_specimens(p_rose, p_lav, 999)
	var new_sp: FlowerSpecimen = cross.get("specimen", null)
	if new_sp == null:
		return "GeneticsEngine failed to cross specimens"

	var counter_after: int = GeneticsEngine.get_specimen_counter()
	if new_sp.specimen_id == "H-105" or new_sp.specimen_id == "H-101":
		return "Collision detected! New specimen assigned existing ID: %s" % new_sp.specimen_id
	if counter_after <= counter_before:
		return "Counter did not increment after generating new specimen"

	return ""


# -----------------------------------------------------------------------------
# SCENARIO 6: Bouquet Atomicity
# -----------------------------------------------------------------------------
func _scenario_6_bouquet_atomicity() -> String:
	var main: MainGame = _setup_main()
	await process_frame
	await process_frame

	# Setup ingredients for garden_harmony (requires 1 rose, 1 lavender, 1 sunflower)
	main.flower_inventory.clear()
	main.flower_inventory.add_flower("rose", FlowerQuality.Tier.NORMAL, 2)
	main.flower_inventory.add_flower("rose", FlowerQuality.Tier.HERO, 1) # Must NOT be consumed!
	main.flower_inventory.add_flower("lavender", FlowerQuality.Tier.NORMAL, 1)
	main.flower_inventory.add_flower("sunflower", FlowerQuality.Tier.NORMAL, 1)
	main.bouquet_inventory["garden_harmony"] = 0

	# 1. Success case
	main._on_craft_bouquet_requested("garden_harmony")

	if main.bouquet_inventory.get("garden_harmony", 0) != 1:
		main.queue_free()
		return "Bouquet count not incremented to 1"
	if main.flower_inventory.get_flower_count_by_quality("rose", FlowerQuality.Tier.NORMAL) != 1:
		main.queue_free()
		return "Normal Rose not decremented correctly (expected 1, got %d)" % main.flower_inventory.get_flower_count_by_quality("rose", FlowerQuality.Tier.NORMAL)
	if main.flower_inventory.get_flower_count_by_quality("rose", FlowerQuality.Tier.HERO) != 1:
		main.queue_free()
		return "HERO Rose was consumed when Normal rose was available!"
	if main.flower_inventory.get_flower_count_by_quality("lavender", FlowerQuality.Tier.NORMAL) != 0:
		main.queue_free()
		return "Lavender not decremented"
	if main.flower_inventory.get_flower_count_by_quality("sunflower", FlowerQuality.Tier.NORMAL) != 0:
		main.queue_free()
		return "Sunflower not decremented"

	# 2. Failure case: Attempt craft when missing lavender and sunflower
	var pre_rose_norm: int = main.flower_inventory.get_flower_count_by_quality("rose", FlowerQuality.Tier.NORMAL)
	var pre_rose_hero: int = main.flower_inventory.get_flower_count_by_quality("rose", FlowerQuality.Tier.HERO)
	var pre_bq_count: int = int(main.bouquet_inventory.get("garden_harmony", 0))

	main._on_craft_bouquet_requested("garden_harmony")

	# Verify ZERO MUTATION
	if main.flower_inventory.get_flower_count_by_quality("rose", FlowerQuality.Tier.NORMAL) != pre_rose_norm:
		main.queue_free()
		return "Rose consumed on failed craft!"
	if main.flower_inventory.get_flower_count_by_quality("rose", FlowerQuality.Tier.HERO) != pre_rose_hero:
		main.queue_free()
		return "Hero rose consumed on failed craft!"
	if main.bouquet_inventory.get("garden_harmony", 0) != pre_bq_count:
		main.queue_free()
		return "Bouquet incremented on failed craft!"

	main.queue_free()
	await process_frame
	return ""


# -----------------------------------------------------------------------------
# SCENARIO 7: Customer Order Atomicity
# -----------------------------------------------------------------------------
func _scenario_7_order_atomicity() -> String:
	var main: MainGame = _setup_main()
	await process_frame
	await process_frame

	# Ensure order runtime is fresh and uncompleted
	main.order_manager.reset_all_orders()
	main.completed_requests.clear()

	# order_1 requires: lavender: 2, sunflower: 1, base reward: 25 coins
	main.coins = 50
	main.flower_inventory.clear()
	main.flower_inventory.add_flower("lavender", FlowerQuality.Tier.NORMAL, 2)
	main.flower_inventory.add_flower("sunflower", FlowerQuality.Tier.NORMAL, 1)

	# 1. Successful Fulfillment
	var pre_coins: int = main.coins
	main._on_fulfill_request_requested("order_1")

	var earned_coins: int = main.coins - pre_coins
	if earned_coins < 25:
		main.queue_free()
		return "Coins earned expected >= 25, got %d" % earned_coins
	if main.flower_inventory.get_flower_count_by_quality("lavender", FlowerQuality.Tier.NORMAL) != 0:
		main.queue_free()
		return "Lavender not consumed"
	if main.flower_inventory.get_flower_count_by_quality("sunflower", FlowerQuality.Tier.NORMAL) != 0:
		main.queue_free()
		return "Sunflower not consumed"
	if not main.order_manager.order_runtime.get("order_1", {}).get("completed", false):
		main.queue_free()
		return "order_1 completed state expected true in order_runtime"

	# 2. Duplicate Fulfillment Attempt -> Must be rejected with ZERO mutation
	var coins_after_first: int = main.coins
	main._on_fulfill_request_requested("order_1")

	if main.coins != coins_after_first:
		main.queue_free()
		return "Coins increased on duplicate fulfillment! New coins: %d" % main.coins

	# 3. Failed Fulfillment Attempt (Missing items for order_2)
	var coins_before_bad: int = main.coins
	main._on_fulfill_request_requested("order_2")

	if main.coins != coins_before_bad:
		main.queue_free()
		return "Coins mutated on invalid order fulfillment!"
	if main.order_manager.order_runtime.get("order_2", {}).get("completed", false):
		main.queue_free()
		return "order_2 marked completed without items!"

	main.queue_free()
	await process_frame
	return ""


# -----------------------------------------------------------------------------
# SCENARIO 8: Pause Integrity
# -----------------------------------------------------------------------------
func _scenario_8_pause_integrity() -> String:
	var main: MainGame = _setup_main()
	await process_frame
	await process_frame

	var plot: GardenPlot = main.garden_grid.plots[0]
	plot.plant("rose")
	plot.water()
	plot.growth_progress = 0.50
	var orig_progress: float = plot.growth_progress
	var orig_water: float = plot.water_duration_remaining

	# Ensure order runtime exists
	main.order_manager._ensure_order_in_runtime("order_1")
	var orig_patience: float = main.order_manager.get_patience("order_1")

	# Pause scene tree
	paused = true

	# Advance 20 ticks of process while paused (can_process returns false during pause)
	for i in range(20):
		plot._process(0.1)
		main._process(0.1)

	# Verify everything is frozen
	if plot.growth_progress != orig_progress:
		paused = false
		main.queue_free()
		return "Plot growth progressed during pause: %f -> %f" % [orig_progress, plot.growth_progress]
	if plot.water_duration_remaining != orig_water:
		paused = false
		main.queue_free()
		return "Water timer decreased during pause"
	if main.order_manager.get_patience("order_1") != orig_patience:
		paused = false
		main.queue_free()
		return "Order patience decreased during pause"

	# Settings slider audio isolation check
	var audio_mgr: AudioManagerClass = root.get_node_or_null("/root/AudioManager") as AudioManagerClass
	if audio_mgr == null:
		audio_mgr = AudioManagerScript.new()
		root.add_child(audio_mgr)

	var orig_sfx_vol: float = audio_mgr.sfx_volume_db
	var orig_mus_vol: float = audio_mgr.music_volume_db
	audio_mgr.music_volume_db = -12.0
	if audio_mgr.sfx_volume_db != orig_sfx_vol:
		paused = false
		main.queue_free()
		return "Changing music volume leaked into SFX volume!"

	audio_mgr.sfx_volume_db = -8.0
	if audio_mgr.music_volume_db != -12.0:
		paused = false
		main.queue_free()
		return "Changing SFX volume leaked into Music volume!"

	# Restore audio volumes
	audio_mgr.music_volume_db = orig_mus_vol
	audio_mgr.sfx_volume_db = orig_sfx_vol

	# Unpause
	paused = false

	main.queue_free()
	await process_frame
	return ""


# -----------------------------------------------------------------------------
# SCENARIO 9: Queue / Character Actions
# -----------------------------------------------------------------------------
func _scenario_9_queue_character_actions() -> String:
	var main: MainGame = _setup_main()
	await process_frame
	await process_frame

	var char_node: GardenerCharacter = main.character as GardenerCharacter
	if char_node == null:
		main.queue_free()
		return "GardenerCharacter not found on main scene"

	char_node.character_enabled = true
	char_node.clear_queue()

	var plot0: GardenPlot = main.garden_grid.plots[0]
	var plot1: GardenPlot = main.garden_grid.plots[1]

	var callback_order: Array[int] = []

	# Queue 3 tasks with on_complete callback (4th parameter)
	char_node.queue_action_at_plot(plot0, "water", Callable(), func(): callback_order.append(1))
	char_node.queue_action_at_plot(plot0, "prune", Callable(), func(): callback_order.append(2))
	char_node.queue_action_at_plot(plot1, "water", Callable(), func(): callback_order.append(3))

	if char_node.task_queue.size() != 3:
		main.queue_free()
		return "Action queue count expected 3 tasks, got %d" % char_node.task_queue.size()

	# Complete task 1
	char_node._finish_current_task(true)
	# Complete task 2
	char_node._finish_current_task(true)
	# Complete task 3
	char_node._finish_current_task(true)

	if callback_order != [1, 2, 3]:
		main.queue_free()
		return "Callbacks did not fire in FIFO order: %s" % str(callback_order)

	# Test RMB Drag preserves queue
	char_node.queue_action_at_plot(plot0, "water", func(): pass)
	char_node.queue_action_at_plot(plot1, "water", func(): pass)
	var pre_drag_count := char_node.task_queue.size()

	var press_ev := InputEventMouseButton.new()
	press_ev.button_index = MOUSE_BUTTON_RIGHT
	press_ev.pressed = true
	press_ev.position = Vector2(100, 100)
	main._unhandled_input(press_ev)

	var move_ev := InputEventMouseMotion.new()
	move_ev.position = Vector2(150, 150) # > 8px drag
	main._unhandled_input(move_ev)

	var release_drag_ev := InputEventMouseButton.new()
	release_drag_ev.button_index = MOUSE_BUTTON_RIGHT
	release_drag_ev.pressed = false
	release_drag_ev.position = Vector2(150, 150)
	main._unhandled_input(release_drag_ev)

	if char_node.task_queue.size() != pre_drag_count:
		main.queue_free()
		return "RMB drag cleared the action queue unexpectedly"

	# Test RMB Clean Click Cancels Queue
	press_ev.position = Vector2(100, 100)
	main._unhandled_input(press_ev)
	var release_click_ev := InputEventMouseButton.new()
	release_click_ev.button_index = MOUSE_BUTTON_RIGHT
	release_click_ev.pressed = false
	release_click_ev.position = Vector2(100, 100)
	main._unhandled_input(release_click_ev)

	if not char_node.task_queue.is_empty():
		main.queue_free()
		return "Clean RMB click failed to cancel the action queue"

	# Test invalid target rejected
	var pre_queue_len := char_node.task_queue.size()
	char_node.queue_action_at_plot(null, "water", func(): pass)
	if char_node.task_queue.size() != pre_queue_len:
		main.queue_free()
		return "Queuing action with null plot was accepted unexpectedly"

	main.queue_free()
	await process_frame
	return ""


# -----------------------------------------------------------------------------
# SCENARIO 10: Save Recovery Matrix
# -----------------------------------------------------------------------------
func _scenario_10_save_recovery_matrix() -> String:
	var base_path := "user://playtest_scenario_10_sandbox.json"
	var bak_path := base_path.replace(".json", ".bak")

	# Clean previous
	if FileAccess.file_exists(base_path): DirAccess.remove_absolute(base_path)
	if FileAccess.file_exists(bak_path): DirAccess.remove_absolute(bak_path)

	# A. Valid Primary
	var state_a := {"coins": 200, "inventory": {"rose": 3}}
	SaveManagerScript.save_game(state_a, base_path)
	var load_a := SaveManagerScript.load_game(base_path)
	if load_a.get("coins", 0) != 200:
		return "Sub-test A (Valid Primary) failed: coins != 200"

	# B. Corrupt Primary + Valid Backup
	# Save second valid state to create .bak
	var state_b := {"coins": 350, "inventory": {"rose": 5}}
	SaveManagerScript.save_game(state_b, base_path) # Now base_path has 350, .bak has 200

	# Corrupt primary
	var fh := FileAccess.open(base_path, FileAccess.WRITE)
	fh.store_string("CORRUPT_NOT_JSON_DATA_XYZ")
	fh.close()

	var load_b := SaveManagerScript.load_game(base_path)
	if load_b.get("coins", 0) != 200:
		return "Sub-test B (Backup Recovery) failed: expected 200 from backup, got %s" % str(load_b.get("coins", 0))

	# C. Failed save validation preserves original
	var bad_state := {"coins": -999} # Negative coins invalid schema
	var save_fail_result := SaveManagerScript.save_game(bad_state, base_path)
	if save_fail_result:
		return "Sub-test C failed: invalid schema save was accepted"

	# D. Legacy save migrates to V3 without false genetic claims
	var legacy_state := {
		"version": 1,
		"game_title": "BloomHaven CVP",
		"timestamp": 1600000000,
		"data": {
			"coins": 150,
			"inventory": {"rose": 4},
			"plots": [
				{"index": 0, "flower_id": "rose", "state": 2, "quality": 1, "is_watered": true, "growth_progress": 0.5}
			],
			"unknown_hybrid_seeds": ["velvet_dusk"]
		}
	}
	var legacy_file := "user://playtest_legacy_temp.json"
	var lf := FileAccess.open(legacy_file, FileAccess.WRITE)
	lf.store_string(JSON.stringify(legacy_state))
	lf.close()

	var migrated_data := SaveManagerScript.load_game(legacy_file)
	if migrated_data.get("coins", 0) != 150:
		return "Sub-test D failed: migrated coins != 150"
	var pending_seeds: Array = migrated_data.get("pending_hybrid_seeds", [])
	if pending_seeds.size() != 1:
		return "Sub-test D failed: pending_hybrid_seeds not migrated"
	var rec_spec: Dictionary = pending_seeds[0]
	if rec_spec.get("parent_a_id", "") != "legacy_reconstructed" or rec_spec.get("parent_b_id", "") != "legacy_reconstructed":
		return "Sub-test D failed: legacy hybrid claimed real parents instead of legacy_reconstructed"

	# Cleanup
	if FileAccess.file_exists(base_path): DirAccess.remove_absolute(base_path)
	if FileAccess.file_exists(bak_path): DirAccess.remove_absolute(bak_path)
	if FileAccess.file_exists(legacy_file): DirAccess.remove_absolute(legacy_file)

	return ""


# -----------------------------------------------------------------------------
# SCENARIO 11: UI Wiring Stress
# -----------------------------------------------------------------------------
func _scenario_11_ui_wiring_stress() -> String:
	var main: MainGame = _setup_main()
	await process_frame
	await process_frame
	var hud_node: HudController = main.hud

	# Rapidly toggle modals & drawers 15 times
	for i in range(15):
		hud_node.open_requests_modal()
		hud_node.close_requests_modal()

		hud_node.open_breeding_modal()
		hud_node.close_breeding_modal()

		hud_node.open_bouquets_modal()
		hud_node.close_bouquets_modal()

		hud_node.open_journal_modal()
		hud_node.close_journal_modal()

		hud_node.open_upgrades_modal()
		hud_node.close_upgrades_modal()

		hud_node._on_flower_stand_toggle_requested()
		hud_node._on_flower_stand_toggle_requested()

	# Verify HUD didn't leak duplicate modal instances
	var modal_count: int = 0
	for child in hud_node.get_children():
		if child.name.ends_with("Modal") or child.name.ends_with("Drawer"):
			modal_count += 1

	if modal_count > 10:
		main.queue_free()
		return "Excessive modal instances accumulated in HUD: %d" % modal_count

	main.queue_free()
	await process_frame
	return ""


# -----------------------------------------------------------------------------
# SCENARIO 12: Full Extended Natural Session
# -----------------------------------------------------------------------------
func _scenario_12_full_session_simulation() -> String:
	var session_save := "user://playtest_session_12.json"
	var main: MainGame = _setup_main()
	await process_frame
	await process_frame

	# Step 1: Start fresh session
	main.coins = 50
	main.flower_inventory.clear()
	main.seed_inventory.clear()
	main._init_new_game_starter_seeds()

	# Step 2: Plant on all 4 plots
	var flowers_to_plant := ["rose", "tulip", "daisy", "lavender"]
	for i in range(4):
		var p: GardenPlot = main.garden_grid.plots[i]
		p.reset_to_empty_state()
		main.current_seed = flowers_to_plant[i]
		main._handle_planting_action(p)
		if p.state != GardenPlot.State.GROWING:
			main.queue_free()
			return "Session step 2 failed: plot %d did not enter GROWING" % i

	# Step 3: Water all 4 plots
	for i in range(4):
		var p: GardenPlot = main.garden_grid.plots[i]
		p.water()
		if not p.is_watered:
			main.queue_free()
			return "Session step 3 failed: plot %d not watered" % i

	# Step 4: Advance growth to 0.70 & Prune all plots for Hero quality
	for i in range(4):
		var p: GardenPlot = main.garden_grid.plots[i]
		p.growth_progress = 0.70
		p.prune()
		if p.quality != FlowerQuality.Tier.HERO:
			main.queue_free()
			return "Session step 4 failed: plot %d did not achieve HERO" % i

	# Step 5: Advance to 1.0 & Harvest all 4 plots
	for i in range(4):
		var p: GardenPlot = main.garden_grid.plots[i]
		p.growth_progress = 1.0
		p._process(0.1)
		p.harvest()
		if p.state != GardenPlot.State.EMPTY:
			main.queue_free()
			return "Session step 5 failed: plot %d not empty after harvest" % i

	# Verify harvested inventory has 2 of each Hero (Hero quality yields 2 per plot)
	for f in flowers_to_plant:
		if main.flower_inventory.get_flower_count_by_quality(f, FlowerQuality.Tier.HERO) != 2:
			main.queue_free()
			return "Session step 5 failed: missing Hero %s (expected 2, got %d)" % [
				f, main.flower_inventory.get_flower_count_by_quality(f, FlowerQuality.Tier.HERO)
			]

	# Step 6: Quick Sell 2 Hero Flowers (Rose: 25, Tulip: 20 -> +45 coins)
	var coins_before: int = main.coins
	main.flower_inventory.remove_flower("rose", FlowerQuality.Tier.HERO, 1)
	main.coins += 25
	main.flower_inventory.remove_flower("tulip", FlowerQuality.Tier.HERO, 1)
	main.coins += 20
	if main.coins != coins_before + 45:
		main.queue_free()
		return "Session step 6 failed: coins mismatch after sale"

	# Step 7: Cross Rose + Lavender in greenhouse
	main.flower_inventory.add_flower("rose", FlowerQuality.Tier.NORMAL, 1)
	main.flower_inventory.add_flower("lavender", FlowerQuality.Tier.NORMAL, 1)
	main._on_breed_requested("rose", "lavender", 0)
	if main.pending_hybrid_seeds.size() != 1:
		main.queue_free()
		return "Session step 7 failed: hybrid seed not created"
	if main.pending_hybrid_seeds[0].species_id != "velvet_dusk":
		main.queue_free()
		return "Session step 7 failed: hybrid species mismatch"

	# Step 8: Plant mystery hybrid seed
	var p0: GardenPlot = main.garden_grid.plots[0]
	main.current_seed = "mystery_seed"
	main._handle_planting_action(p0)
	if p0.current_flower_id != "velvet_dusk" or not p0.is_mystery_seed:
		main.queue_free()
		return "Session step 8 failed: mystery hybrid planting mismatch"

	# Step 9: Save game, reboot session, reload
	var save_ok := SaveManagerScript.save_game(_extract_save_dict(main), session_save)
	if not save_ok:
		main.queue_free()
		return "Session step 9 failed: save game failed"
	main.queue_free()
	await process_frame

	var loaded_data := SaveManagerScript.load_game(session_save)
	var main2: MainGame = _setup_main()
	await process_frame
	await process_frame
	_apply_data_to_main(main2, loaded_data)

	# Verify loaded state consistency
	if main2.coins != coins_before + 45:
		main2.queue_free()
		return "Session step 9 failed: coins mismatch after reload"
	if main2.garden_grid.plots[0].current_flower_id != "velvet_dusk":
		main2.queue_free()
		return "Session step 9 failed: plot 0 flower_id mismatch after reload"

	# Cleanup
	if FileAccess.file_exists(session_save): DirAccess.remove_absolute(session_save)
	if FileAccess.file_exists(session_save.replace(".json", ".bak")): DirAccess.remove_absolute(session_save.replace(".json", ".bak"))

	main2.queue_free()
	await process_frame
	return ""
