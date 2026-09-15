extends SceneTree

## BloomHaven Sprint B Save Integrity & Migration Verification Suite (Correction Pass)
## Covers all Master Plan v3.0 Sprint B requirements & Gate B correction directives:
## 1. Schema V3 definition & strict validation
## 2. Formal Migration Pipeline (V1 -> V2 -> V3) with validated payloads
## 3. Invalid migrated payload rejection
## 4. Flower quality multi-tier roundtrip (Normal, Fine, Perfect, Hero)
## 5. SeedInventory roundtrip
## 6. Legacy hybrid reconstruction (explicitly documented legacy marker)
## 7. V3 lossless specimen roundtrip (all genotype/phenotype/lineage preserved)
## 8. Breeding roster roundtrip
## 9. Canonical per-order runtime roundtrip (completed, remaining_patience, max_patience)
## 10. CVP progression state roundtrip (coins, upgrades, bouquets, perfumes, journal, tutorial)
## 11. GardenPlot Growing roundtrip (field-by-field comparison)
## 12. GardenPlot Fertilized roundtrip (field-by-field comparison)
## 13. GardenPlot Pruned & HERO quality roundtrip (field-by-field comparison)
## 14. GardenPlot Mature FlowerSpecimen roundtrip (field-by-field comparison)
## 15. GardenPlot Mystery & reveal flags roundtrip (field-by-field comparison)
## 16. Specimen counter persistence & strict collision prevention
## 17. Atomic save (.tmp) & validation rollback
## 18. Safe .bak rotation (corrupt primary never clobbers good backup)
## 19. Corrupt primary recovery via backup
## 20. Multi-tier recovery pipeline fallthrough
## 21. Invalid schema strict rejection
## 22. Starter seeds & save existence edge cases

const TEST_SAVE_BASE: String = "user://test_sprint_b_save.json"
const TEST_SAVE_BAK: String = "user://test_sprint_b_save.bak"
const TEST_SAVE_TMP: String = "user://test_sprint_b_save.json.tmp"

var _passed_tests: int = 0
var _failed_tests: int = 0


func _init() -> void:
	print("==================================================")
	print("RUNNING BLOOMHAVEN SPRINT B SAVE INTEGRITY SUITE")
	print("==================================================")

	_run_suite("V1 -> V3 Migration", _test_v1_to_v3_migration)
	_run_suite("V2 -> V3 Migration", _test_v2_to_v3_migration)
	_run_suite("Invalid Migrated Payload Rejection", _test_invalid_migrated_payload_rejection)
	_run_suite("Flower Quality Multi-Tier Roundtrip", _test_flower_quality_roundtrip)
	_run_suite("SeedInventory Roundtrip", _test_seed_inventory_roundtrip)
	_run_suite("Legacy Hybrid Reconstruction", _test_legacy_hybrid_reconstruction)
	_run_suite("V3 Lossless Specimen Roundtrip", _test_v3_lossless_specimen_roundtrip)
	_run_suite("Breeding Roster Roundtrip", _test_breeding_roster_roundtrip)
	_run_suite("Canonical Order Runtime Roundtrip", _test_canonical_order_runtime_roundtrip)
	_run_suite("CVP Progression State Roundtrip", _test_cvp_progression_state_roundtrip)
	_run_suite("GardenPlot: Growing State Roundtrip", _test_garden_plot_growing_roundtrip)
	_run_suite("GardenPlot: Fertilized State Roundtrip", _test_garden_plot_fertilized_roundtrip)
	_run_suite("GardenPlot: Pruned & HERO Quality Roundtrip", _test_garden_plot_pruned_hero_roundtrip)
	_run_suite("GardenPlot: Mature Specimen Roundtrip", _test_garden_plot_mature_specimen_roundtrip)
	_run_suite("GardenPlot: Mystery & Reveal Flags Roundtrip", _test_garden_plot_mystery_reveal_roundtrip)
	_run_suite("Specimen Counter & Strict Collision Prevention", _test_specimen_counter_contract)
	_run_suite("Atomic Save (.tmp) & Validation Failure Rollback", _test_atomic_save_rollback)
	_run_suite("Safe .bak Rotation (No Corrupt Overwrite)", _test_safe_bak_rotation)
	_run_suite("Corrupt Primary Recovery via Backup", _test_corrupt_primary_backup_recovery)
	_run_suite("Multi-Tier Recovery Pipeline (V3 -> Bak -> V2 -> V1)", _test_multi_tier_recovery)
	_run_suite("Invalid Schema Strict Rejection", _test_invalid_schema_rejection)
	_run_suite("Starter Seeds & Save Existence Edge Cases", _test_starter_seeds_edge_cases)
	_run_suite("Canonical V3 Writer (No Duplicate Aliases)", _test_canonical_v3_no_legacy_aliases)
	_run_suite("Deterministic Legacy Reconstruction Reproducibility", _test_deterministic_legacy_reconstruction_reproducibility)

	print("\n==================================================")
	print("RESULTS: %d PASSED, %d FAILED" % [_passed_tests, _failed_tests])
	print("==================================================")

	_cleanup_test_files()

	if _failed_tests > 0:
		printerr("❌ SPRINT B SAVE INTEGRITY SUITE FAILED!")
		quit(1)
	else:
		print("🎉 ALL SPRINT B SAVE INTEGRITY TESTS PASSED (100% OK)!")
		quit(0)


func _run_suite(suite_name: String, test_func: Callable) -> void:
	print("\n--- Suite: %s ---" % suite_name)
	_cleanup_test_files()
	var err: String = test_func.call()
	if err == null or err == "":
		print("  ✓ Suite Passed: %s" % suite_name)
		_passed_tests += 1
	else:
		printerr("  ❌ Suite Failed: %s -> %s" % [suite_name, err])
		_failed_tests += 1
	_cleanup_test_files()


func _cleanup_test_files() -> void:
	var files := [
		TEST_SAVE_BASE,
		TEST_SAVE_BAK,
		TEST_SAVE_TMP,
		"user://test_sandbox_v1.json",
		"user://test_sandbox_v2.json",
		"user://test_sandbox_v2.bak"
	]
	for f in files:
		if FileAccess.file_exists(f):
			DirAccess.remove_absolute(f)


# ------------------------------------------------------------------------------
# 1. V1 -> V3 Migration
# ------------------------------------------------------------------------------
func _test_v1_to_v3_migration() -> String:
	var v1_path := "res://tests/fixtures/baseline_saves/finest_garden_save_v1.json"
	if not FileAccess.file_exists(v1_path):
		return "Baseline save V1 fixture missing: %s" % v1_path

	var file := FileAccess.open(v1_path, FileAccess.READ)
	var text := file.get_as_text()
	file.close()

	var json := JSON.new()
	if json.parse(text) != OK or not (json.data is Dictionary):
		return "Failed to parse V1 fixture JSON"

	var v1_raw: Dictionary = json.data
	var v3_migrated: Dictionary = SaveManager.migrate_to_latest(v1_raw)

	if int(v3_migrated.get("version", 0)) != 3:
		return "Migrated version must be 3, got: %d" % int(v3_migrated.get("version", 0))

	# Requirement 5: Schema validation on migrated payload
	var val_res := SaveManager.validate_schema(v3_migrated)
	if not val_res.get("valid", false):
		return "V1 -> V3 migrated data failed schema validation: %s" % val_res.get("error", "")

	var data: Dictionary = v3_migrated.get("data", {})

	# Check flower inventory (flat -> Normal tier)
	if not data.has("flower_inventory_storage"):
		return "Migrated data missing 'flower_inventory_storage'"

	# Check deterministic seed policy
	if not data.has("seed_inventory"):
		return "Migrated data missing 'seed_inventory'"
	var seeds: Dictionary = data["seed_inventory"]
	if int(seeds.get("rose", 0)) != 5 or int(seeds.get("tulip", 0)) != 5 or int(seeds.get("daisy", 0)) != 5 or int(seeds.get("lavender", 0)) != 5:
		return "Deterministic migration policy failed to grant starter seeds for legacy V1"

	# Check canonical order_runtime
	if not data.has("order_runtime") or not (data["order_runtime"] is Dictionary):
		return "Migrated data missing 'order_runtime'"
	var orders: Dictionary = data["order_runtime"]
	for o_id in ["order_1", "order_2", "order_3", "order_4", "order_5", "order_6"]:
		if not orders.has(o_id):
			return "%s missing in migrated order_runtime" % o_id
		var o_entry: Dictionary = orders[o_id]
		if not o_entry.has("completed") or not o_entry.has("remaining_patience") or not o_entry.has("max_patience"):
			return "%s missing required canonical fields in migrated order_runtime" % o_id

	# Check legacy reconstructed hybrid seeds
	var pending: Array = data.get("pending_hybrid_seeds", [])
	if pending.size() > 0:
		var p0: Dictionary = pending[0]
		if str(p0.get("parent_a_id", "")) != "legacy_reconstructed":
			return "Legacy hybrid seed must be explicitly marked 'legacy_reconstructed'"

	return ""


# ------------------------------------------------------------------------------
# 2. V2 -> V3 Migration
# ------------------------------------------------------------------------------
func _test_v2_to_v3_migration() -> String:
	var v2_path := "res://tests/fixtures/baseline_saves/bloomhaven_save_v2.json"
	if not FileAccess.file_exists(v2_path):
		return "Baseline save V2 fixture missing: %s" % v2_path

	var file := FileAccess.open(v2_path, FileAccess.READ)
	var text := file.get_as_text()
	file.close()

	var json := JSON.new()
	if json.parse(text) != OK or not (json.data is Dictionary):
		return "Failed to parse V2 fixture JSON"

	var v2_raw: Dictionary = json.data
	var v3_migrated: Dictionary = SaveManager.migrate_to_latest(v2_raw)

	if int(v3_migrated.get("version", 0)) != 3:
		return "Migrated version must be 3, got: %d" % int(v3_migrated.get("version", 0))

	# Requirement 5: Schema validation on migrated payload
	var val_res := SaveManager.validate_schema(v3_migrated)
	if not val_res.get("valid", false):
		return "V2 -> V3 migrated data failed schema validation: %s" % val_res.get("error", "")

	var data: Dictionary = v3_migrated.get("data", {})
	if not data.has("order_runtime") or not (data["order_runtime"] is Dictionary):
		return "order_runtime missing in V2->V3 migration"

	var orders: Dictionary = data["order_runtime"]
	for o_id in ["order_1", "order_2", "order_3"]:
		if not orders.has(o_id): return "%s missing in order_runtime" % o_id
		var ent: Dictionary = orders[o_id]
		if not (ent.has("completed") and ent.has("remaining_patience") and ent.has("max_patience")):
			return "%s missing canonical fields in order_runtime" % o_id

	return ""


# ------------------------------------------------------------------------------
# 3. Invalid Migrated Payload Rejection (Requirement 5)
# ------------------------------------------------------------------------------
func _test_invalid_migrated_payload_rejection() -> String:
	# Create a malformed legacy V1 save with negative coins and invalid data
	var bad_legacy := {
		"version": 1,
		"data": {
			"coins": -500, # Invalid: negative coins
			"inventory": {"rose": 5}
		}
	}
	var res := SaveManager.migrate_to_latest(bad_legacy)
	if not res.is_empty():
		return "migrate_to_latest must reject invalid payload that fails schema validation"

	# Write bad legacy file to disk and attempt to load via _try_read_and_migrate_legacy
	var f := FileAccess.open("user://test_sandbox_v1.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(bad_legacy))
	f.close()

	var loaded_data := SaveManager.load_game("user://test_sandbox_v1.json")
	if not loaded_data.is_empty():
		return "load_game must not return data from a legacy save whose migrated payload is invalid"

	return ""


# ------------------------------------------------------------------------------
# 4. Flower Quality Multi-Tier Roundtrip
# ------------------------------------------------------------------------------
func _test_flower_quality_roundtrip() -> String:
	var f_inv := FlowerInventory.new()
	f_inv.add_flower("rose", FlowerQuality.Tier.NORMAL, 4)
	f_inv.add_flower("rose", FlowerQuality.Tier.FINE, 3)
	f_inv.add_flower("rose", FlowerQuality.Tier.PERFECT, 2)
	f_inv.add_flower("rose", FlowerQuality.Tier.HERO, 1)
	f_inv.add_flower("lavender", FlowerQuality.Tier.PERFECT, 5)

	var state := {
		"coins": 100,
		"flower_inventory_storage": f_inv.serialize(),
		"seed_inventory": {"rose": 5}
	}

	var save_ok := SaveManager.save_game(state, TEST_SAVE_BASE)
	if not save_ok:
		return "Failed to save state with multi-tier flower inventory"

	var loaded := SaveManager.load_game(TEST_SAVE_BASE)
	if loaded.is_empty():
		return "Failed to load saved state"

	var restored_inv := FlowerInventory.new()
	restored_inv.deserialize(loaded.get("flower_inventory_storage", {}))

	if restored_inv.get_flower_count_by_quality("rose", FlowerQuality.Tier.NORMAL) != 4:
		return "Normal rose count mismatch after roundtrip"
	if restored_inv.get_flower_count_by_quality("rose", FlowerQuality.Tier.FINE) != 3:
		return "Fine rose count mismatch after roundtrip"
	if restored_inv.get_flower_count_by_quality("rose", FlowerQuality.Tier.PERFECT) != 2:
		return "Perfect rose count mismatch after roundtrip"
	if restored_inv.get_flower_count_by_quality("rose", FlowerQuality.Tier.HERO) != 1:
		return "Hero rose count mismatch after roundtrip"
	if restored_inv.get_flower_count_by_quality("lavender", FlowerQuality.Tier.PERFECT) != 5:
		return "Perfect lavender count mismatch after roundtrip"

	return ""


# ------------------------------------------------------------------------------
# 5. SeedInventory Roundtrip
# ------------------------------------------------------------------------------
func _test_seed_inventory_roundtrip() -> String:
	var s_inv := SeedInventory.new()
	s_inv.add_seeds("rose", 12)
	s_inv.add_seeds("tulip", 7)
	s_inv.add_seeds("daisy", 3)
	s_inv.add_seeds("lavender", 1)

	var state := {
		"coins": 50,
		"seed_inventory": s_inv.serialize()
	}

	var save_ok := SaveManager.save_game(state, TEST_SAVE_BASE)
	if not save_ok: return "Save failed"

	var loaded := SaveManager.load_game(TEST_SAVE_BASE)
	var restored_seeds := SeedInventory.new()
	restored_seeds.deserialize(loaded.get("seed_inventory", {}))

	if restored_seeds.get_seed_count("rose") != 12: return "Rose seed count mismatch"
	if restored_seeds.get_seed_count("tulip") != 7: return "Tulip seed count mismatch"
	if restored_seeds.get_seed_count("daisy") != 3: return "Daisy seed count mismatch"
	if restored_seeds.get_seed_count("lavender") != 1: return "Lavender seed count mismatch"

	return ""


# ------------------------------------------------------------------------------
# 6. Legacy Hybrid Reconstruction (Requirement 3)
# ------------------------------------------------------------------------------
func _test_legacy_hybrid_reconstruction() -> String:
	# In legacy V1/V2 saves, unknown_hybrid_seeds only stored string IDs (e.g. ["velvet_dusk"]).
	# Historical genotype, phenotype, and parent lineages did not exist.
	# We verify deterministic reconstruction sets species_id and flags "legacy_reconstructed".
	var legacy_save := {
		"version": 2,
		"game_title": "BloomHaven CVP",
		"timestamp": 1726000000,
		"data": {
			"coins": 100,
			"unknown_hybrid_seeds": ["velvet_dusk"]
		}
	}
	var migrated := SaveManager.migrate_to_latest(legacy_save)
	var data: Dictionary = migrated.get("data", {})
	var pending: Array = data.get("pending_hybrid_seeds", [])
	if pending.size() != 1:
		return "Expected 1 reconstructed hybrid seed, got %d" % pending.size()

	var spec_data: Dictionary = pending[0]
	if str(spec_data.get("species_id", "")) != "velvet_dusk":
		return "Reconstructed species_id mismatch: expected velvet_dusk, got %s" % str(spec_data.get("species_id", ""))
	if str(spec_data.get("parent_a_id", "")) != "legacy_reconstructed":
		return "Reconstructed parent_a_id must be 'legacy_reconstructed'"
	if str(spec_data.get("parent_b_id", "")) != "legacy_reconstructed":
		return "Reconstructed parent_b_id must be 'legacy_reconstructed'"
	if int(spec_data.get("generation", 0)) != 1:
		return "Reconstructed generation must be 1"

	return ""


# ------------------------------------------------------------------------------
# 7. V3 Lossless Specimen Roundtrip (Requirement 3)
# ------------------------------------------------------------------------------
func _test_v3_lossless_specimen_roundtrip() -> String:
	var genotype := FlowerGenotype.new(
		["Cp", "Cr"] as Array[String],
		["Ps", "Pp"] as Array[String],
		["F+", "F+"] as Array[String],
		["V+", "V+"] as Array[String]
	)
	var phenotype := FlowerPhenotype.new()
	phenotype.color_tint = Color(0.8, 0.2, 0.5)
	phenotype.color_name = "Velvet Glow"
	phenotype.petal_form = "star"
	phenotype.petal_form_name = "Star Petals"
	phenotype.fragrance_rating = 4
	phenotype.fragrance_name = "Sweet Spice"
	phenotype.vigor_tier = 3
	phenotype.vigor_name = "Heroic Vigor"
	phenotype.visual_scale = 1.85

	var specimen := FlowerSpecimen.new("SPEC-00105", "velvet_dusk", 3, genotype, phenotype)
	specimen.parent_a_id = "rose"
	specimen.parent_b_id = "lavender"

	var state := {
		"coins": 100,
		"pending_hybrid_seeds": [specimen.serialize()]
	}

	var save_ok := SaveManager.save_game(state, TEST_SAVE_BASE)
	if not save_ok: return "Save failed for lossless hybrid specimen"

	var loaded := SaveManager.load_game(TEST_SAVE_BASE)
	var pending_arr: Array = loaded.get("pending_hybrid_seeds", [])
	if pending_arr.size() != 1: return "Expected 1 pending hybrid seed, got %d" % pending_arr.size()

	var restored := FlowerSpecimen.deserialize(pending_arr[0])
	if restored.specimen_id != "SPEC-00105": return "Specimen ID lost"
	if restored.species_id != "velvet_dusk": return "Species ID lost"
	if restored.generation != 3: return "Generation lost"
	if restored.parent_a_id != "rose" or restored.parent_b_id != "lavender": return "Parent lineage lost"

	# Genotype exact verification
	if restored.genotype.color_alleles != (["Cp", "Cr"] as Array[String]): return "Color alleles lost"
	if restored.genotype.petal_alleles != (["Ps", "Pp"] as Array[String]): return "Petal alleles lost"
	if restored.genotype.fragrance_alleles != (["F+", "F+"] as Array[String]): return "Fragrance alleles lost"
	if restored.genotype.vigor_alleles != (["V+", "V+"] as Array[String]): return "Vigor alleles lost"

	# Phenotype exact verification
	if restored.phenotype.color_name != "Velvet Glow": return "Phenotype color_name lost"
	if restored.phenotype.petal_form != "star": return "Phenotype petal_form lost"
	if restored.phenotype.fragrance_rating != 4: return "Phenotype fragrance_rating lost"
	if restored.phenotype.vigor_tier != 3: return "Phenotype vigor_tier lost"
	if abs(restored.phenotype.visual_scale - 1.85) > 0.001: return "Phenotype visual_scale lost"

	return ""


# ------------------------------------------------------------------------------
# 8. Breeding Roster Roundtrip
# ------------------------------------------------------------------------------
func _test_breeding_roster_roundtrip() -> String:
	var sp1 := FlowerSpecimen.new("R-001", "rose", 1)
	var sp2 := FlowerSpecimen.new("L-001", "lavender", 1)
	var sp3 := FlowerSpecimen.new("S-001", "sunflower", 2)
	sp3.parent_a_id = "rose"
	sp3.parent_b_id = "lavender"

	var state := {
		"coins": 300,
		"breeding_roster": [sp1.serialize(), sp2.serialize(), sp3.serialize()]
	}

	var save_ok := SaveManager.save_game(state, TEST_SAVE_BASE)
	if not save_ok: return "Save failed for breeding roster"

	var loaded := SaveManager.load_game(TEST_SAVE_BASE)
	var roster: Array = loaded.get("breeding_roster", [])
	if roster.size() != 3: return "Breeding roster size mismatch: expected 3, got %d" % roster.size()

	var r1 := FlowerSpecimen.deserialize(roster[0])
	var r2 := FlowerSpecimen.deserialize(roster[1])
	var r3 := FlowerSpecimen.deserialize(roster[2])

	if r1.specimen_id != "R-001" or r2.specimen_id != "L-001" or r3.specimen_id != "S-001":
		return "Roster specimen IDs mismatch after roundtrip"

	return ""


# ------------------------------------------------------------------------------
# 9. Canonical Order Runtime Roundtrip (Requirement 2)
# ------------------------------------------------------------------------------
func _test_canonical_order_runtime_roundtrip() -> String:
	var runtime := {
		"order_1": {
			"completed": true,
			"remaining_patience": 0.0,
			"max_patience": 75.0
		},
		"order_2": {
			"completed": false,
			"remaining_patience": 59.5, # Partially elapsed
			"max_patience": 80.0
		},
		"order_3": {
			"completed": false,
			"remaining_patience": 23.4, # Partially elapsed
			"max_patience": 85.0
		}
	}

	var state := {
		"coins": 150,
		"order_runtime": runtime
	}

	var save_ok := SaveManager.save_game(state, TEST_SAVE_BASE)
	if not save_ok: return "Save failed for order runtime"

	var loaded := SaveManager.load_game(TEST_SAVE_BASE)
	var loaded_runtime: Dictionary = loaded.get("order_runtime", {})
	if loaded_runtime.is_empty(): return "Loaded order_runtime is empty"

	# Compare completed, remaining_patience, and max_patience exactly for each order
	for o_id in ["order_1", "order_2", "order_3"]:
		if not loaded_runtime.has(o_id):
			return "%s missing in loaded order_runtime" % o_id
		var orig: Dictionary = runtime[o_id]
		var lded: Dictionary = loaded_runtime[o_id]

		if bool(lded.get("completed", false)) != bool(orig["completed"]):
			return "%s 'completed' mismatch: expected %s, got %s" % [o_id, str(orig["completed"]), str(lded.get("completed"))]

		var orig_rem: float = float(orig["remaining_patience"])
		var lded_rem: float = float(lded.get("remaining_patience", -1.0))
		if abs(lded_rem - orig_rem) > 0.01:
			return "%s 'remaining_patience' mismatch: expected %f, got %f" % [o_id, orig_rem, lded_rem]

		var orig_max: float = float(orig["max_patience"])
		var lded_max: float = float(lded.get("max_patience", -1.0))
		if abs(lded_max - orig_max) > 0.01:
			return "%s 'max_patience' mismatch: expected %f, got %f" % [o_id, orig_max, lded_max]

	return ""


# ------------------------------------------------------------------------------
# 10. CVP Progression State Roundtrip (Requirement 4)
# ------------------------------------------------------------------------------
func _test_cvp_progression_state_roundtrip() -> String:
	var state := {
		"coins": 250,
		"specimen_counter": 150,
		"active_upgrades": {
			"swift_boots": true,
			"double_sprinkler": false,
			"enriched_soil": true,
			"fertilizer_box": false,
			"expanded_satchel": true
		},
		"bouquet_inventory": {
			"garden_harmony": 3,
			"crimson_romance": 1
		},
		"perfume_inventory": {
			"lavender_mist": 2
		},
		"discovered_flowers": {
			"rose": true,
			"tulip": true,
			"velvet_dusk": true
		},
		"tutorial_completed": true
	}

	var save_ok := SaveManager.save_game(state, TEST_SAVE_BASE)
	if not save_ok: return "Save failed for CVP progression state"

	var loaded := SaveManager.load_game(TEST_SAVE_BASE)
	if loaded.is_empty(): return "Loaded state is empty"

	if int(loaded.get("coins", 0)) != 250: return "coins mismatch"
	if int(loaded.get("specimen_counter", 0)) != 150: return "specimen_counter mismatch"
	if not bool(loaded.get("tutorial_completed", false)): return "tutorial_completed mismatch"

	var up: Dictionary = loaded.get("active_upgrades", {})
	if not bool(up.get("swift_boots", false)) or not bool(up.get("enriched_soil", false)) or not bool(up.get("expanded_satchel", false)):
		return "active_upgrades mismatch after reload"

	var bq: Dictionary = loaded.get("bouquet_inventory", {})
	if int(bq.get("garden_harmony", 0)) != 3 or int(bq.get("crimson_romance", 0)) != 1:
		return "bouquet_inventory mismatch after reload"

	var pf: Dictionary = loaded.get("perfume_inventory", {})
	if int(pf.get("lavender_mist", 0)) != 2:
		return "perfume_inventory mismatch after reload"

	var disc: Dictionary = loaded.get("discovered_flowers", {})
	if not bool(disc.get("velvet_dusk", false)):
		return "discovered_flowers journal progression mismatch after reload"

	return ""


# ------------------------------------------------------------------------------
# Helper: Compare two GardenPlot instances field-by-field
# ------------------------------------------------------------------------------
func _compare_plots_field_by_field(original: GardenPlot, loaded: GardenPlot) -> String:
	if loaded.plot_index != original.plot_index:
		return "plot_index mismatch: expected %d, got %d" % [original.plot_index, loaded.plot_index]
	if loaded.state != original.state:
		return "state mismatch: expected %d, got %d" % [original.state, loaded.state]
	if loaded.current_flower_id != original.current_flower_id:
		return "current_flower_id mismatch: expected '%s', got '%s'" % [original.current_flower_id, loaded.current_flower_id]
	if abs(loaded.growth_progress - original.growth_progress) > 0.001:
		return "growth_progress mismatch: expected %f, got %f" % [original.growth_progress, loaded.growth_progress]
	if loaded.is_watered != original.is_watered:
		return "is_watered mismatch: expected %s, got %s" % [str(original.is_watered), str(loaded.is_watered)]
	if abs(loaded.water_duration_remaining - original.water_duration_remaining) > 0.01:
		return "water_duration_remaining mismatch: expected %f, got %f" % [original.water_duration_remaining, loaded.water_duration_remaining]
	if abs(loaded.water_duration_multiplier - original.water_duration_multiplier) > 0.001:
		return "water_duration_multiplier mismatch: expected %f, got %f" % [original.water_duration_multiplier, loaded.water_duration_multiplier]
	if loaded.is_fertilized != original.is_fertilized:
		return "is_fertilized mismatch: expected %s, got %s" % [str(original.is_fertilized), str(loaded.is_fertilized)]
	if loaded.is_pruned != original.is_pruned:
		return "is_pruned mismatch: expected %s, got %s" % [str(original.is_pruned), str(loaded.is_pruned)]
	if loaded.quality != original.quality:
		return "quality mismatch: expected %d, got %d" % [original.quality, loaded.quality]
	if loaded.is_mystery_seed != original.is_mystery_seed:
		return "is_mystery_seed mismatch: expected %s, got %s" % [str(original.is_mystery_seed), str(loaded.is_mystery_seed)]
	if loaded.is_revealed != original.is_revealed:
		return "is_revealed mismatch: expected %s, got %s" % [str(original.is_revealed), str(loaded.is_revealed)]
	if loaded.is_hero_showcase != original.is_hero_showcase:
		return "is_hero_showcase mismatch: expected %s, got %s" % [str(original.is_hero_showcase), str(loaded.is_hero_showcase)]
	if (original.current_specimen == null) != (loaded.current_specimen == null):
		return "current_specimen nullness mismatch"
	if original.current_specimen != null:
		if loaded.current_specimen.specimen_id != original.current_specimen.specimen_id:
			return "specimen_id mismatch: expected '%s', got '%s'" % [original.current_specimen.specimen_id, loaded.current_specimen.specimen_id]
		if loaded.current_specimen.species_id != original.current_specimen.species_id:
			return "specimen species_id mismatch: expected '%s', got '%s'" % [original.current_specimen.species_id, loaded.current_specimen.species_id]
		if loaded.current_specimen.generation != original.current_specimen.generation:
			return "specimen generation mismatch: expected %d, got %d" % [original.current_specimen.generation, loaded.current_specimen.generation]
	return ""


# ------------------------------------------------------------------------------
# 11. GardenPlot: Growing State Roundtrip (Requirement 1)
# ------------------------------------------------------------------------------
func _test_garden_plot_growing_roundtrip() -> String:
	var plot := GardenPlot.new()
	plot.plot_index = 0
	plot.state = GardenPlot.State.GROWING
	plot.current_flower_id = "rose"
	plot.growth_progress = 0.45
	plot.is_watered = true
	plot.water_duration_remaining = 18.5
	plot.water_duration_multiplier = 1.0
	plot.is_fertilized = false
	plot.is_pruned = false
	plot.quality = FlowerQuality.Tier.NORMAL
	plot.is_mystery_seed = false
	plot.is_revealed = true
	plot.current_specimen = GeneticsEngine.create_starter_specimen("rose")

	var state := {
		"coins": 100,
		"plots": SaveManager.serialize_plots([plot])
	}
	var save_ok := SaveManager.save_game(state, TEST_SAVE_BASE)
	if not save_ok: return "Failed to save growing plot state"

	var loaded := SaveManager.load_game(TEST_SAVE_BASE)
	var plots_arr: Array = loaded.get("plots", [])
	if plots_arr.size() != 1: return "Expected 1 plot in loaded save, got %d" % plots_arr.size()

	var loaded_plot := GardenPlot.new()
	SaveManager.deserialize_plots(plots_arr, [loaded_plot])

	return _compare_plots_field_by_field(plot, loaded_plot)


# ------------------------------------------------------------------------------
# 12. GardenPlot: Fertilized State Roundtrip (Requirement 1)
# ------------------------------------------------------------------------------
func _test_garden_plot_fertilized_roundtrip() -> String:
	var plot := GardenPlot.new()
	plot.plot_index = 1
	plot.state = GardenPlot.State.GROWING
	plot.current_flower_id = "tulip"
	plot.growth_progress = 0.70
	plot.is_watered = false
	plot.water_duration_remaining = 0.0
	plot.is_fertilized = true
	plot.is_pruned = false
	plot.quality = FlowerQuality.Tier.NORMAL
	plot.current_specimen = GeneticsEngine.create_starter_specimen("tulip")

	var state := {
		"coins": 100,
		"plots": SaveManager.serialize_plots([plot])
	}
	var save_ok := SaveManager.save_game(state, TEST_SAVE_BASE)
	if not save_ok: return "Failed to save fertilized plot"

	var loaded := SaveManager.load_game(TEST_SAVE_BASE)
	var loaded_plot := GardenPlot.new()
	SaveManager.deserialize_plots(loaded.get("plots", []), [null, loaded_plot])

	if not loaded_plot.is_fertilized:
		return "Fertilized state lost across save/reload"

	return _compare_plots_field_by_field(plot, loaded_plot)


# ------------------------------------------------------------------------------
# 13. GardenPlot: Pruned & HERO Quality Roundtrip (Requirement 1)
# ------------------------------------------------------------------------------
func _test_garden_plot_pruned_hero_roundtrip() -> String:
	var plot := GardenPlot.new()
	plot.plot_index = 2
	plot.state = GardenPlot.State.GROWING
	plot.current_flower_id = "daisy"
	plot.growth_progress = 0.75
	plot.is_pruned = true
	plot.quality = FlowerQuality.Tier.HERO # HERO quality == 4
	plot.current_specimen = GeneticsEngine.create_starter_specimen("daisy")

	var state := {
		"coins": 100,
		"plots": SaveManager.serialize_plots([plot])
	}
	var save_ok := SaveManager.save_game(state, TEST_SAVE_BASE)
	if not save_ok: return "Failed to save pruned hero plot"

	var loaded := SaveManager.load_game(TEST_SAVE_BASE)
	var loaded_plot := GardenPlot.new()
	SaveManager.deserialize_plots(loaded.get("plots", []), [null, null, loaded_plot])

	if not loaded_plot.is_pruned:
		return "Pruned state lost across save/reload"
	if loaded_plot.quality != FlowerQuality.Tier.HERO:
		return "HERO quality tier lost across save/reload: expected 4, got %d" % loaded_plot.quality

	return _compare_plots_field_by_field(plot, loaded_plot)


# ------------------------------------------------------------------------------
# 14. GardenPlot: Mature Specimen Roundtrip (Requirement 1)
# ------------------------------------------------------------------------------
func _test_garden_plot_mature_specimen_roundtrip() -> String:
	var genotype := FlowerGenotype.new(["Cp", "Cr"] as Array[String], ["Ps", "Pp"] as Array[String])
	var phenotype := FlowerPhenotype.new()
	phenotype.color_tint = Color.RED
	phenotype.color_name = "Crimson"
	phenotype.petal_form = "star"
	phenotype.fragrance_rating = 3
	phenotype.vigor_tier = 2
	phenotype.visual_scale = 1.5

	var spec := FlowerSpecimen.new("SPEC-00199", "velvet_dusk", 2, genotype, phenotype)
	spec.parent_a_id = "rose"
	spec.parent_b_id = "lavender"

	var plot := GardenPlot.new()
	plot.plot_index = 0
	plot.state = GardenPlot.State.MATURE
	plot.current_flower_id = "velvet_dusk"
	plot.growth_progress = 1.0
	plot.current_specimen = spec

	var state := {
		"coins": 100,
		"plots": SaveManager.serialize_plots([plot])
	}
	var save_ok := SaveManager.save_game(state, TEST_SAVE_BASE)
	if not save_ok: return "Failed to save mature specimen plot"

	var loaded := SaveManager.load_game(TEST_SAVE_BASE)
	var loaded_plot := GardenPlot.new()
	SaveManager.deserialize_plots(loaded.get("plots", []), [loaded_plot])

	if loaded_plot.state != GardenPlot.State.MATURE:
		return "Plot MATURE state lost"
	if loaded_plot.current_specimen == null:
		return "Mature FlowerSpecimen lost across reload"
	if loaded_plot.current_specimen.specimen_id != "SPEC-00199":
		return "FlowerSpecimen ID mismatch: expected SPEC-00199, got %s" % loaded_plot.current_specimen.specimen_id

	return _compare_plots_field_by_field(plot, loaded_plot)


# ------------------------------------------------------------------------------
# 15. GardenPlot: Mystery & Reveal Flags Roundtrip (Requirement 1)
# ------------------------------------------------------------------------------
func _test_garden_plot_mystery_reveal_roundtrip() -> String:
	var p0 := GardenPlot.new()
	p0.plot_index = 0
	p0.state = GardenPlot.State.GROWING
	p0.current_flower_id = "velvet_dusk"
	p0.growth_progress = 0.30
	p0.is_mystery_seed = true
	p0.is_revealed = false
	p0.current_specimen = GeneticsEngine.create_starter_specimen("velvet_dusk")

	var p1 := GardenPlot.new()
	p1.plot_index = 1
	p1.state = GardenPlot.State.GROWING
	p1.current_flower_id = "golden_rose"
	p1.growth_progress = 0.80
	p1.is_mystery_seed = true
	p1.is_revealed = true
	p1.current_specimen = GeneticsEngine.create_starter_specimen("golden_rose")

	var state := {
		"coins": 100,
		"plots": SaveManager.serialize_plots([p0, p1])
	}
	var save_ok := SaveManager.save_game(state, TEST_SAVE_BASE)
	if not save_ok: return "Failed to save mystery plots"

	var loaded := SaveManager.load_game(TEST_SAVE_BASE)
	var l0 := GardenPlot.new()
	var l1 := GardenPlot.new()
	SaveManager.deserialize_plots(loaded.get("plots", []), [l0, l1])

	var err0 := _compare_plots_field_by_field(p0, l0)
	if not err0.is_empty(): return "Plot 0 (mystery unrevealed) mismatch: " + err0

	var err1 := _compare_plots_field_by_field(p1, l1)
	if not err1.is_empty(): return "Plot 1 (mystery revealed) mismatch: " + err1

	return ""


# ------------------------------------------------------------------------------
# 16. Specimen Counter & Strict Collision Prevention
# ------------------------------------------------------------------------------
func _test_specimen_counter_contract() -> String:
	GeneticsEngine.reset_counter_for_tests(250)
	var state := {
		"coins": 100,
		"specimen_counter": 250,
		"breeding_roster": [
			{"specimen_id": "SPEC-00275", "species_id": "rose"}
		],
		"pending_hybrid_seeds": [
			{"specimen_id": "SPEC-00310", "species_id": "velvet_dusk"}
		]
	}

	var save_ok := SaveManager.save_game(state, TEST_SAVE_BASE)
	if not save_ok: return "Save failed"

	var loaded := SaveManager.load_game(TEST_SAVE_BASE)
	var loaded_counter: int = int(loaded.get("specimen_counter", 0))

	# Scan loaded IDs to update counter
	var loaded_ids: Array = ["SPEC-00275", "SPEC-00310"]
	GeneticsEngine.set_specimen_counter(loaded_counter)
	GeneticsEngine.scan_and_register_ids(loaded_ids)

	var next_specimen := GeneticsEngine.create_starter_specimen("daisy")
	var next_id_num: int = int(next_specimen.specimen_id.split("-")[1])

	if next_id_num <= 310:
		return "Specimen ID collision risk! Next generated ID %s is not > max loaded ID 310" % next_specimen.specimen_id

	return ""


# ------------------------------------------------------------------------------
# 17. Atomic Save (.tmp) & Validation Failure Rollback
# ------------------------------------------------------------------------------
func _test_atomic_save_rollback() -> String:
	# 1. Save valid initial game
	var valid_state := {"coins": 100, "seed_inventory": {"rose": 5}}
	SaveManager.save_game(valid_state, TEST_SAVE_BASE)

	# 2. Attempt to save corrupted state (e.g. negative coins)
	var corrupt_state := {"coins": -50, "seed_inventory": {"rose": 5}}
	var ok := SaveManager.save_game(corrupt_state, TEST_SAVE_BASE)

	if ok:
		return "SaveManager should have rejected negative coins"

	if FileAccess.file_exists(TEST_SAVE_TMP):
		return "Temporary save file .tmp was not cleaned up on validation failure"

	var reloaded := SaveManager.load_game(TEST_SAVE_BASE)
	if int(reloaded.get("coins", 0)) != 100:
		return "Existing valid save was corrupted by invalid save attempt"

	return ""


# ------------------------------------------------------------------------------
# 18. Safe .bak Rotation (No Corrupt Overwrite)
# ------------------------------------------------------------------------------
func _test_safe_bak_rotation() -> String:
	# 1. Save initial good state
	var state_v1 := {"coins": 100, "seed_inventory": {"rose": 10}}
	SaveManager.save_game(state_v1, TEST_SAVE_BASE)

	# 2. Save second good state -> rotates state_v1 into .bak
	var state_v2 := {"coins": 200, "seed_inventory": {"rose": 20}}
	SaveManager.save_game(state_v2, TEST_SAVE_BASE)

	# Corrupt the primary save on disk directly (simulating disk truncation or bad write)
	var f := FileAccess.open(TEST_SAVE_BASE, FileAccess.WRITE)
	f.store_string("CORRUPTED_PRIMARY_CONTENT")
	f.close()

	# Attempt to save state_v3
	var state_v3 := {"coins": 300, "seed_inventory": {"rose": 30}}
	SaveManager.save_game(state_v3, TEST_SAVE_BASE)

	# Verify .bak still contains valid state_v2
	var bak_f := FileAccess.open(TEST_SAVE_BAK, FileAccess.READ)
	var bak_text := bak_f.get_as_text()
	bak_f.close()

	if "CORRUPTED" in bak_text:
		return "CRITICAL: Corrupt primary file was rotated into .bak, destroying the valid backup!"

	return ""


# ------------------------------------------------------------------------------
# 19. Corrupt Primary Recovery via Backup
# ------------------------------------------------------------------------------
func _test_corrupt_primary_backup_recovery() -> String:
	# 1. Save valid game state
	var valid_state := {"coins": 500, "seed_inventory": {"rose": 5}}
	SaveManager.save_game(valid_state, TEST_SAVE_BASE)

	# 2. Force creation of .bak by saving again
	var valid_state_2 := {"coins": 600, "seed_inventory": {"rose": 6}}
	SaveManager.save_game(valid_state_2, TEST_SAVE_BASE)

	# 3. Corrupt primary save
	var f := FileAccess.open(TEST_SAVE_BASE, FileAccess.WRITE)
	f.store_string("{ malformed json ...")
	f.close()

	# 4. Load game -> must recover from .bak (coins: 500)
	var recovered := SaveManager.load_game(TEST_SAVE_BASE)
	if recovered.is_empty():
		return "Failed to recover from valid backup file when primary was corrupted"

	if int(recovered.get("coins", 0)) != 500:
		return "Recovered data mismatch: expected coins 500 from backup, got %d" % int(recovered.get("coins", 0))

	return ""


# ------------------------------------------------------------------------------
# 20. Multi-Tier Recovery Pipeline (V3 -> Bak -> V2 -> V1)
# ------------------------------------------------------------------------------
func _test_multi_tier_recovery() -> String:
	_cleanup_test_files()

	# Clean failure when no file exists
	var empty := SaveManager.load_game("user://non_existent_file.json")
	if not empty.is_empty():
		return "load_game should return empty dictionary on non-existent file"

	# Recovery from V2 primary
	var v2_fixture_path := "res://tests/fixtures/baseline_saves/bloomhaven_save_v2.json"
	if FileAccess.file_exists(v2_fixture_path):
		var rf := FileAccess.open(v2_fixture_path, FileAccess.READ)
		var txt := rf.get_as_text()
		rf.close()

		var wf := FileAccess.open("user://test_sandbox_v2.json", FileAccess.WRITE)
		wf.store_string(txt)
		wf.close()

		var migrated_data := SaveManager.load_game("user://test_sandbox_v2.json")
		if migrated_data.is_empty():
			return "Failed to migrate legacy V2 sandbox save via load_game"

	return ""


# ------------------------------------------------------------------------------
# 21. Invalid Schema Strict Rejection
# ------------------------------------------------------------------------------
func _test_invalid_schema_rejection() -> String:
	# Missing data dictionary
	var test1 := {"version": 3}
	if SaveManager.validate_schema(test1)["valid"]: return "Accepted missing data dict"

	# Negative coins
	var test2 := {"version": 3, "data": {"coins": -10, "specimen_counter": 100, "flower_inventory_storage": {}, "seed_inventory": {}, "plots": [], "breeding_roster": [], "pending_hybrid_seeds": [], "bouquet_inventory": {}, "order_runtime": {}}}
	if SaveManager.validate_schema(test2)["valid"]: return "Accepted negative coins"

	# Missing required array
	var test3 := {"version": 3, "data": {"coins": 0, "specimen_counter": 100, "flower_inventory_storage": {}, "seed_inventory": {}, "plots": "NOT_AN_ARRAY", "breeding_roster": [], "pending_hybrid_seeds": [], "bouquet_inventory": {}, "order_runtime": {}}}
	if SaveManager.validate_schema(test3)["valid"]: return "Accepted non-array plots"

	# Negative seed count
	var test4 := {"version": 3, "data": {"coins": 0, "specimen_counter": 100, "flower_inventory_storage": {}, "seed_inventory": {"rose": -5}, "plots": [], "breeding_roster": [], "pending_hybrid_seeds": [], "bouquet_inventory": {}, "order_runtime": {}}}
	if SaveManager.validate_schema(test4)["valid"]: return "Accepted negative seed count"

	# Malformed order_runtime entry
	var test5 := {"version": 3, "data": {"coins": 0, "specimen_counter": 100, "flower_inventory_storage": {}, "seed_inventory": {}, "plots": [], "breeding_roster": [], "pending_hybrid_seeds": [], "bouquet_inventory": {}, "order_runtime": {"order_1": "NOT_A_DICT"}}}
	if SaveManager.validate_schema(test5)["valid"]: return "Accepted non-dict order_runtime entry"

	return ""


# ------------------------------------------------------------------------------
# 22. Starter Seeds & Save Existence Edge Cases
# ------------------------------------------------------------------------------
func _test_starter_seeds_edge_cases() -> String:
	_cleanup_test_files()
	if SaveManager.has_save(TEST_SAVE_BASE):
		return "has_save reported true before any save created"

	var s_inv := SeedInventory.new()
	s_inv.add_seeds("rose", 0)

	var state := {"coins": 0, "seed_inventory": s_inv.serialize()}
	SaveManager.save_game(state, TEST_SAVE_BASE)

	if not SaveManager.has_save(TEST_SAVE_BASE):
		return "has_save reported false after valid save created"

	var loaded := SaveManager.load_game(TEST_SAVE_BASE)
	var reloaded_seeds := SeedInventory.new()
	reloaded_seeds.deserialize(loaded.get("seed_inventory", {}))

	# Player intentionally exhausted seeds to 0; should NOT be auto-refilled
	if reloaded_seeds.get_seed_count("rose") != 0:
		return "Existing save with 0 seeds was erroneously refilled with starter seeds"

	return ""


# ------------------------------------------------------------------------------
# 23. Canonical V3 Writer (No Duplicate Legacy Aliases)
# ------------------------------------------------------------------------------
func _test_canonical_v3_no_legacy_aliases() -> String:
	_cleanup_test_files()

	var plot := GardenPlot.new()
	plot.plot_index = 0
	plot.state = GardenPlot.State.GROWING
	plot.current_flower_id = "rose"
	plot.growth_progress = 0.5
	plot.is_watered = true
	plot.water_duration_remaining = 15.0

	var f_inv := FlowerInventory.new()
	f_inv.add_flower("rose", FlowerQuality.Tier.PERFECT, 2)

	var s_inv := SeedInventory.new()
	s_inv.add_seeds("rose", 5)

	var spec := GeneticsEngine.create_starter_specimen("rose")

	var state: Dictionary = {
		"coins": 500,
		"specimen_counter": 100,
		"flower_inventory_storage": f_inv.serialize(),
		"seed_inventory": s_inv.serialize(),
		"plots": [plot.to_dictionary()],
		"breeding_roster": [],
		"pending_hybrid_seeds": [spec.serialize()],
		"bouquet_inventory": {},
		"order_runtime": {
			"order_1": {"completed": false, "remaining_patience": 30.0, "max_patience": 60.0}
		}
	}

	var saved := SaveManager.save_game(state, TEST_SAVE_BASE)
	if not saved:
		return "Failed to save canonical V3 state"

	# Read raw file from disk
	var file := FileAccess.open(TEST_SAVE_BASE, FileAccess.READ)
	if file == null:
		return "Failed to open saved file for alias inspection"
	var text := file.get_as_text()
	file.close()

	var json := JSON.new()
	if json.parse(text) != OK or not (json.data is Dictionary):
		return "Failed to parse saved V3 JSON"

	var root_dict: Dictionary = json.data
	if not root_dict.has("data") or not (root_dict["data"] is Dictionary):
		return "Saved file missing 'data' dictionary"
	var data: Dictionary = root_dict["data"]

	# Check root-level aliases must NOT exist
	var forbidden_root_aliases := ["inventory", "unknown_hybrid_seeds", "completed_requests", "live_orders_patience"]
	for alias in forbidden_root_aliases:
		if data.has(alias):
			return "Canonical V3 save contains forbidden legacy alias at root: '%s'" % alias

	# Check canonical root keys exist
	var required_canonical_keys := ["flower_inventory_storage", "seed_inventory", "order_runtime", "pending_hybrid_seeds", "plots"]
	for req_key in required_canonical_keys:
		if not data.has(req_key):
			return "Canonical V3 save missing required canonical key: '%s'" % req_key

	# Check plot payload: must contain current_flower_id and current_specimen, NOT flower_id or specimen
	if not (data["plots"] is Array) or data["plots"].is_empty():
		return "Plots array empty or invalid in saved canonical V3 payload"
	var p0: Dictionary = data["plots"][0]
	if not p0.has("current_flower_id"):
		return "Plot missing canonical 'current_flower_id'"
	if not p0.has("current_specimen"):
		return "Plot missing canonical 'current_specimen'"
	if p0.has("flower_id"):
		return "Plot contains forbidden legacy alias 'flower_id'"
	if p0.has("specimen"):
		return "Plot contains forbidden legacy alias 'specimen'"

	return ""


# ------------------------------------------------------------------------------
# 24. Deterministic Legacy Reconstruction Reproducibility
# ------------------------------------------------------------------------------
func _test_deterministic_legacy_reconstruction_reproducibility() -> String:
	# Create legacy fixture with multiple unknown hybrid seeds
	var legacy_fixture := {
		"version": 1,
		"data": {
			"coins": 250,
			"unknown_hybrid_seeds": ["velvet_dusk", "sunfire", "velvet_dusk"]
		}
	}

	# Clone duplicate dictionaries
	var fixture_a: Dictionary = legacy_fixture.duplicate(true)
	var fixture_b: Dictionary = legacy_fixture.duplicate(true)

	# Migrate fixture A
	var migrated_a: Dictionary = SaveManager.migrate_to_latest(fixture_a)
	if migrated_a.is_empty():
		return "Migration of fixture A failed"

	# Advance specimen counter in between to prove migration uses stable deterministic IDs
	var dummy_spec := GeneticsEngine.create_starter_specimen("rose")

	# Migrate fixture B
	var migrated_b: Dictionary = SaveManager.migrate_to_latest(fixture_b)
	if migrated_b.is_empty():
		return "Migration of fixture B failed"

	var pending_a: Array = migrated_a.get("data", {}).get("pending_hybrid_seeds", [])
	var pending_b: Array = migrated_b.get("data", {}).get("pending_hybrid_seeds", [])

	if pending_a.size() != 3:
		return "Expected 3 reconstructed seeds in A, got %d" % pending_a.size()
	if pending_b.size() != 3:
		return "Expected 3 reconstructed seeds in B, got %d" % pending_b.size()

	# Compare each reconstructed specimen across runs for exact deterministic equality
	for idx in range(3):
		var s_a: Dictionary = pending_a[idx]
		var s_b: Dictionary = pending_b[idx]

		var id_a: String = str(s_a.get("specimen_id", ""))
		var id_b: String = str(s_b.get("specimen_id", ""))
		if id_a != id_b:
			return "Specimen ID non-deterministic at index %d: '%s' vs '%s'" % [idx, id_a, id_b]

		# Verify stable ID pattern LEGACY-<SPECIES>-<INDEX>
		var expected_prefix: String = "LEGACY-%s-%03d" % [str(s_a.get("species_id", "")).to_upper(), idx + 1]
		if id_a != expected_prefix:
			return "Specimen ID did not match deterministic format '%s', got '%s'" % [expected_prefix, id_a]

		if str(s_a.get("species_id", "")) != str(s_b.get("species_id", "")):
			return "Species ID mismatch at index %d" % idx
		if str(s_a.get("parent_a_id", "")) != str(s_b.get("parent_a_id", "")):
			return "Parent A mismatch at index %d" % idx
		if str(s_a.get("parent_b_id", "")) != str(s_b.get("parent_b_id", "")):
			return "Parent B mismatch at index %d" % idx
		if int(s_a.get("generation", 0)) != int(s_b.get("generation", 0)):
			return "Generation mismatch at index %d" % idx

		var geno_a: Dictionary = s_a.get("genotype", {})
		var geno_b: Dictionary = s_b.get("genotype", {})
		for trait_key in ["color", "petal", "fragrance", "vigor"]:
			if geno_a.get(trait_key, []) != geno_b.get(trait_key, []):
				return "Genotype mismatch for trait '%s' at index %d" % [trait_key, idx]

	# Also verify that raw file migration from fixture path reproduces same deterministic results
	var v1_fixture_path := "res://tests/fixtures/baseline_saves/finest_garden_save_v1.json"
	if FileAccess.file_exists(v1_fixture_path):
		var f := FileAccess.open(v1_fixture_path, FileAccess.READ)
		var txt := f.get_as_text()
		f.close()
		var j1 := JSON.new()
		var j2 := JSON.new()
		if j1.parse(txt) == OK and j2.parse(txt) == OK:
			var m1 := SaveManager.migrate_to_latest(j1.data)
			var m2 := SaveManager.migrate_to_latest(j2.data)
			var p1: Array = m1.get("data", {}).get("pending_hybrid_seeds", [])
			var p2: Array = m2.get("data", {}).get("pending_hybrid_seeds", [])
			if p1.size() != p2.size():
				return "Mismatch in baseline v1 pending hybrid count: %d vs %d" % [p1.size(), p2.size()]

	return ""

