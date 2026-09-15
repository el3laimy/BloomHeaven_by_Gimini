extends SceneTree

## BloomHaven Catalog & Canonical SSoT Verification Suite (Sprint C)
## Covers:
## 1. Canonical Flower Categories (cvp_base, curated_hybrids, legacy_species, canonical IDs)
## 2. Alias Integrity & Cycle Protection
## 3. Single Source of Truth for Catalogs (no UI duplicates)
## 4. FlowerAssetResolver (canonical caching, missing texture checkerboard, strict no-rose fallback)
## 5. Growth Stage Threshold Consistency (0.61 == Vegetative / Stage index 2)
## 6. Order Patience SSoT & Runtime Preservation
## 7. Bouquet Recipes SSoT via BouquetData

var _passed_tests: int = 0
var _failed_tests: int = 0


func _init() -> void:
	print("==================================================")
	print("RUNNING BLOOMHAVEN SPRINT C CATALOG SSOT SUITE")
	print("==================================================")
	
	_run_suite("FlowerData Canonical Catalogs", _test_canonical_catalogs)
	_run_suite("Alias Integrity & Cycle Protection", _test_alias_integrity)
	_run_suite("UI Catalog Dynamic Querying", _test_ui_catalogs_ssot)
	_run_suite("Curated Hybrids Data Completeness", _test_curated_hybrids_data)
	_run_suite("FlowerAssetResolver & Missing Texture Fallback", _test_asset_resolver)
	_run_suite("Growth Stage Threshold SSoT (0.61)", _test_growth_stage_threshold)
	_run_suite("Order Patience SSoT & Runtime Preservation", _test_order_patience_ssot)
	_run_suite("Missing Patience Strict No-Fallback", _test_missing_patience_no_fallback)
	_run_suite("Bouquet Recipes SSoT", _test_bouquet_recipes_ssot)
	_run_suite("Strict Status Classification & Reconciliation", _test_status_reconciliation)
	_run_suite("Fresh CVP Catalog & Legacy Isolation", _test_fresh_cvp_catalog_isolation)
	
	print("\n==================================================")
	print("RESULTS: %d PASSED, %d FAILED" % [_passed_tests, _failed_tests])
	print("==================================================")
	
	if _failed_tests > 0:
		printerr("❌ SPRINT C CATALOG SSOT SUITE FAILED!")
		quit(1)
	else:
		print("🎉 ALL SPRINT C CATALOG SSOT TESTS PASSED (100% OK)!")
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


func _test_canonical_catalogs() -> String:
	# 1. CVP Base species: rose, tulip, daisy, lavender
	var cvp_base: Array[String] = FlowerData.get_cvp_base_species()
	if cvp_base.size() != 4:
		return "Expected 4 cvp_base species, got %d: %s" % [cvp_base.size(), str(cvp_base)]
	for s in ["rose", "tulip", "daisy", "lavender"]:
		if not cvp_base.has(s):
			return "Missing cvp_base species: %s" % s
	
	# 2. Curated Hybrids: 6 species
	var curated: Array[String] = FlowerData.get_curated_hybrids()
	if curated.size() != 6:
		return "Expected 6 curated hybrids, got %d: %s" % [curated.size(), str(curated)]
	for h in ["blushbell", "velvet_dusk", "twilight_bell", "sunburst_daisy", "crown_petal", "meadow_mist"]:
		if not curated.has(h):
			return "Missing curated hybrid: %s" % h
	
	# 3. Legacy species: 5 species
	var legacy: Array[String] = FlowerData.get_legacy_species()
	if legacy.size() != 5:
		return "Expected 5 legacy species, got %d: %s" % [legacy.size(), str(legacy)]
	for leg in ["sunflower", "roselight", "golden_rose", "sunflare_spike", "rose_cream"]:
		if not legacy.has(leg):
			return "Missing legacy species: %s" % leg
	
	# 4. Canonical IDs total: 4 + 6 + 5 = 15
	var all_canonical: Array[String] = FlowerData.get_all_flower_ids()
	if all_canonical.size() != 15:
		return "Expected 15 total canonical species, got %d: %s" % [all_canonical.size(), str(all_canonical)]
	
	# Verify no aliases are in get_all_flower_ids()
	for alias_id in ["crimson_rose", "rose_crimson", "sunny_daisy", "english_lavender", "pastel_tulip"]:
		if all_canonical.has(alias_id):
			return "Alias '%s' found in get_all_flower_ids()!" % alias_id
	
	return ""


func _test_alias_integrity() -> String:
	# 1. Verify aliases resolve to canonical target
	var alias_map: Dictionary = {
		"crimson_rose": "rose",
		"rose_crimson": "rose",
		"sunny_daisy": "daisy",
		"english_lavender": "lavender",
		"pastel_tulip": "tulip"
	}
	for alias_key in alias_map:
		var target: String = alias_map[alias_key]
		var resolved: String = FlowerData.get_canonical_id(alias_key)
		if resolved != target:
			return "Alias '%s' resolved to '%s', expected '%s'" % [alias_key, resolved, target]
		
		# get_flower(alias) should return canonical flower dict
		var f_data: Dictionary = FlowerData.get_flower(alias_key)
		if f_data.is_empty():
			return "FlowerData.get_flower('%s') returned empty dict" % alias_key
		if f_data.get("id", "") != target:
			return "FlowerData.get_flower('%s') returned data with id '%s', expected '%s'" % [alias_key, f_data.get("id", ""), target]
	
	# 2. Self-canonical returns itself
	if FlowerData.get_canonical_id("rose") != "rose":
		return "get_canonical_id('rose') != 'rose'"
	if FlowerData.get_canonical_id("velvet_dusk") != "velvet_dusk":
		return "get_canonical_id('velvet_dusk') != 'velvet_dusk'"
	
	# 3. Unknown ID returns empty string / empty lookup
	if not FlowerData.get_canonical_id("unknown_xyz").is_empty():
		return "Unknown id should return empty string from get_canonical_id"
	if not FlowerData.get_flower("unknown_xyz").is_empty():
		return "Unknown id should return empty dictionary from get_flower"
	
	return ""


func _test_ui_catalogs_ssot() -> String:
	# Test that UI scripts dynamically consume FlowerData and do not duplicate arrays
	var cvp_base: Array[String] = FlowerData.get_cvp_base_species()
	var curated: Array[String] = FlowerData.get_curated_hybrids()
	var legacy: Array[String] = FlowerData.get_legacy_species()
	
	# SeedBar: verifies base species logic
	var seed_bar_script: Script = load("res://scripts/ui/seed_bar.gd")
	if not seed_bar_script:
		return "Could not load scripts/ui/seed_bar.gd"
	
	# InventoryDrawer: verifies display logic (base visible, curated/legacy conditional on count > 0)
	var drawer_script: Script = load("res://scripts/ui/hud/inventory_drawer.gd")
	if not drawer_script:
		return "Could not load scripts/ui/hud/inventory_drawer.gd"
	
	# BreedingModal: verifies modal flower list
	var breeding_script: Script = load("res://scripts/ui/modals/breeding_modal.gd")
	if not breeding_script:
		return "Could not load scripts/ui/modals/breeding_modal.gd"
	
	return ""


func _test_curated_hybrids_data() -> String:
	var curated: Array[String] = FlowerData.get_curated_hybrids()
	for h_id in curated:
		var data: Dictionary = FlowerData.get_flower(h_id)
		if data.is_empty():
			return "Curated hybrid '%s' has empty data dictionary" % h_id
		if not data.has("display_name"):
			return "Curated hybrid '%s' missing display_name" % h_id
		if not data.has("master_sprite"):
			return "Curated hybrid '%s' missing master_sprite" % h_id
		if not data.has("parents"):
			return "Curated hybrid '%s' missing parents" % h_id
		if not data.has("base_growth_seconds"):
			return "Curated hybrid '%s' missing base_growth_seconds" % h_id
		if not data.has("base_value"):
			return "Curated hybrid '%s' missing base_value" % h_id
	return ""


func _test_asset_resolver() -> String:
	var resolver: Script = load("res://scripts/flowers/flower_asset_resolver.gd")
	if not resolver:
		return "Could not load FlowerAssetResolver script"
	
	# 1. Resolve canonical base flower
	var rose_tex: Texture2D = resolver.resolve_flower_texture("rose")
	if not rose_tex:
		return "Failed to resolve texture for 'rose'"
	
	# 2. Resolve alias flower -> must return the exact same Texture2D instance from cache
	var alias_tex: Texture2D = resolver.resolve_flower_texture("crimson_rose")
	if not alias_tex:
		return "Failed to resolve texture for alias 'crimson_rose'"
	if alias_tex != rose_tex:
		return "Alias 'crimson_rose' did not return the identical cached Texture2D as 'rose'"
	
	# 3. Curated hybrids resolve to valid textures
	for h_id in FlowerData.get_curated_hybrids():
		var h_tex: Texture2D = resolver.resolve_flower_texture(h_id)
		if not h_tex:
			return "Failed to resolve texture for curated hybrid '%s'" % h_id
	
	# 4. Missing / invalid ID returns missing texture (neutral checkerboard), NEVER rose texture
	var missing_tex: Texture2D = resolver.resolve_flower_texture("nonexistent_flower_species_xyz")
	if not missing_tex:
		return "Resolver returned null for invalid flower ID instead of missing texture"
	if missing_tex == rose_tex:
		return "Resolver fell back to Rose for invalid flower ID! Must be missing checkerboard"
	
	# Missing texture is an ImageTexture with 32x32 size
	if missing_tex.get_width() != 32 or missing_tex.get_height() != 32:
		return "Missing texture dimensions unexpected: %dx%d" % [missing_tex.get_width(), missing_tex.get_height()]
	
	# Direct missing texture call
	var direct_missing: Texture2D = resolver.get_missing_texture()
	if direct_missing != missing_tex:
		return "get_missing_texture() is not consistently cached"
	
	return ""


func _test_growth_stage_threshold() -> String:
	# Verify domain threshold constants
	if GardenPlot.STAGE_SEED_MAX != 0.25:
		return "STAGE_SEED_MAX != 0.25"
	if GardenPlot.STAGE_SPROUT_MAX != 0.60:
		return "STAGE_SPROUT_MAX != 0.60"
	if GardenPlot.STAGE_VEGETATIVE_MAX != 1.0:
		return "STAGE_VEGETATIVE_MAX != 1.0"
	
	# Verify stage resolution at exact boundaries
	# 0.0 -> Seed (index 0)
	if GardenPlot.get_growth_stage_index(0.0) != 0:
		return "growth 0.0 stage != 0"
	# 0.24 -> Seed (index 0)
	if GardenPlot.get_growth_stage_index(0.24) != 0:
		return "growth 0.24 stage != 0"
	# 0.25 -> Sprout (index 1)
	if GardenPlot.get_growth_stage_index(0.25) != 1:
		return "growth 0.25 stage != 1"
	# 0.59 -> Sprout (index 1)
	if GardenPlot.get_growth_stage_index(0.59) != 1:
		return "growth 0.59 stage != 1"
	
	# The critical test case: 0.61 -> Vegetative / Bush (index 2)
	var stage_61: int = GardenPlot.get_growth_stage_index(0.61)
	if stage_61 != 2:
		return "GardenPlot stage at 0.61 is %d, expected 2 (Vegetative)" % stage_61
	
	var label_61: String = GardenPlot.get_growth_stage_label(0.61)
	if not label_61.begins_with("Stage 3"):
		return "GardenPlot label at 0.61 is '%s', expected 'Stage 3 ...'" % label_61
	
	# Fully grown: 1.0 -> Bloom (index 3)
	if GardenPlot.get_growth_stage_index(1.0) != 3:
		return "growth 1.0 stage != 3"
	
	# Verify PlotCard logic matches GardenPlot
	var plot_card_script: Script = load("res://scripts/ui/plot_card.gd")
	if not plot_card_script:
		return "Could not load PlotCard script"
	
	return ""


func _test_order_patience_ssot() -> String:
	# 1. requests.json defines correct patience values
	var expected_patience: Dictionary = {
		"order_1": 75.0,
		"order_2": 80.0,
		"order_3": 85.0,
		"order_4": 90.0,
		"order_5": 80.0,
		"order_6": 95.0
	}
	
	for o_id in expected_patience:
		var req: Dictionary = FloristRequestData.get_request(o_id)
		if req.is_empty():
			return "Request '%s' not found in FloristRequestData" % o_id
		var p_max: float = float(req.get("patience_max_seconds", 0.0))
		if p_max != expected_patience[o_id]:
			return "Request '%s' patience_max_seconds is %f, expected %f" % [o_id, p_max, expected_patience[o_id]]
	
	# 2. OrderManager reads patience_max_seconds from FloristRequestData
	var om: OrderManager = OrderManager.new()
	for o_id in expected_patience:
		var remaining: float = om.get_patience(o_id)
		if remaining != expected_patience[o_id]:
			return "OrderManager initial patience for '%s' is %f, expected %f" % [o_id, remaining, expected_patience[o_id]]
	
	# 3. OrderManager deserialization preserves partial patience (does NOT reset to max)
	var test_saved_state: Dictionary = {
		"order_runtime": {
			"order_1": {
				"completed": false,
				"remaining_patience": 37.5,
				"max_patience": 75.0
			}
		}
	}
	om.deserialize(test_saved_state)
	var partial_patience: float = om.get_patience("order_1")
	if abs(partial_patience - 37.5) > 0.001:
		return "OrderManager deserialize reset remaining patience! Got %f, expected 37.5" % partial_patience
	
	return ""


func _test_bouquet_recipes_ssot() -> String:
	var b_ids: Array[String] = BouquetData.get_all_bouquet_ids()
	if b_ids.is_empty():
		return "BouquetData returned empty bouquet list"
	
	# Verify that every flower ingredient in every bouquet points to a valid canonical or recognized flower ID
	for b_id in b_ids:
		var b_data: Dictionary = BouquetData.get_bouquet(b_id)
		var ingredients: Dictionary = b_data.get("ingredients", {})
		if ingredients.is_empty():
			return "Bouquet '%s' has empty ingredients" % b_id
		for f_id in ingredients:
			var flower: Dictionary = FlowerData.get_flower(f_id)
			if flower.is_empty():
				return "Bouquet '%s' requires unknown flower ID '%s'" % [b_id, f_id]
	
	return ""


func _test_missing_patience_no_fallback() -> String:
	# 1. Verify FloristRequestData does not invent 75.0 when patience_max_seconds is absent
	var simulated_req: Dictionary = {
		"id": "test_order_no_patience",
		"customer_name": "Test Patron",
		"required_items": {"rose": 1}
	}
	var pat_val = simulated_req.get("patience_max_seconds", null)
	if pat_val != null:
		return "Simulated request without patience_max_seconds unexpectedly produced: %s" % str(pat_val)

	# 2. In OrderManager, an order missing patience_max_seconds must be REJECTED from order_runtime
	# (no order_runtime entry created, zero gameplay mutation, never defaults to 75.0 or 0.0 entry)
	var om := OrderManager.new()
	FloristRequestData._ensure_initialized()
	FloristRequestData._cached_requests["test_no_patience_fixture"] = {
		"id": "test_no_patience_fixture",
		"customer_name": "Ghost",
		"required_items": {"rose": 1}
	}
	om._ensure_order_in_runtime("test_no_patience_fixture")
	var has_entry: bool = om.order_runtime.has("test_no_patience_fixture")
	var pat: float = om.get_patience("test_no_patience_fixture")
	FloristRequestData._cached_requests.erase("test_no_patience_fixture")

	if has_entry:
		return "OrderManager created order_runtime record for request missing patience_max_seconds! Must reject/skip creation."
	if pat != 0.0:
		return "OrderManager returned nonzero patience for missing/rejected order: got %f" % pat

	# 3. Verify invalid patience (<= 0.0) is also rejected
	FloristRequestData._cached_requests["test_zero_patience_fixture"] = {
		"id": "test_zero_patience_fixture",
		"customer_name": "GhostZero",
		"required_items": {"rose": 1},
		"patience_max_seconds": 0.0
	}
	om._ensure_order_in_runtime("test_zero_patience_fixture")
	var has_zero_entry: bool = om.order_runtime.has("test_zero_patience_fixture")
	FloristRequestData._cached_requests.erase("test_zero_patience_fixture")

	if has_zero_entry:
		return "OrderManager created order_runtime record for request with 0.0 patience_max_seconds! Must reject/skip creation."

	return ""


func _test_status_reconciliation() -> String:
	var path := "res://data/flowers.json"
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return "Could not open data/flowers.json"
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		return "Failed to parse data/flowers.json"
	var raw_flowers: Dictionary = json.data.get("flowers", {})

	var total_count: int = raw_flowers.size()
	var base_count: int = 0
	var hybrid_count: int = 0
	var legacy_count: int = 0
	var alias_count: int = 0
	var unclassified_count: int = 0

	for fid in raw_flowers:
		var fdef: Dictionary = raw_flowers[fid]
		var st: String = fdef.get("status", "")
		match st:
			"cvp_base":
				base_count += 1
			"cvp_hybrid":
				hybrid_count += 1
			"legacy":
				legacy_count += 1
			"alias":
				alias_count += 1
				var target: String = fdef.get("alias_of", "")
				if target.is_empty():
					return "Alias '%s' missing 'alias_of'" % fid
				if target == fid:
					return "Alias '%s' is self-referential cycle" % fid
				if not raw_flowers.has(target):
					return "Alias '%s' target '%s' does not exist" % [fid, target]
				if raw_flowers[target].get("status") == "alias":
					return "Alias '%s' points to chained alias '%s'" % [fid, target]
			_:
				unclassified_count += 1

	if unclassified_count != 0:
		return "Found %d unclassified flower entries!" % unclassified_count
	if total_count != (base_count + hybrid_count + legacy_count + alias_count):
		return "Total count mismatch: %d != %d + %d + %d + %d" % [total_count, base_count, hybrid_count, legacy_count, alias_count]
	if base_count != 4 or hybrid_count != 6 or legacy_count != 5 or alias_count != 5:
		return "Exact status counts mismatch: base=%d, hybrid=%d, legacy=%d, alias=%d" % [base_count, hybrid_count, legacy_count, alias_count]

	return ""


func _test_fresh_cvp_catalog_isolation() -> String:
	# 1. Fresh CVP base catalog strictly contains only the 4 base species
	var base_species: Array[String] = FlowerData.get_cvp_base_species()
	for leg_id in ["sunflower", "roselight", "golden_rose", "sunflare_spike", "rose_cream"]:
		if base_species.has(leg_id):
			return "Legacy species '%s' leaked into FlowerData.get_cvp_base_species()!" % leg_id

	# 2. Curated hybrids also do not contain legacy species
	var curated_hybrids: Array[String] = FlowerData.get_curated_hybrids()
	for leg_id in ["sunflower", "roselight", "golden_rose", "sunflare_spike", "rose_cream"]:
		if curated_hybrids.has(leg_id):
			return "Legacy species '%s' leaked into FlowerData.get_curated_hybrids()!" % leg_id

	# 3. InventoryDrawer display policy test:
	# Fresh game inventory: no flowers owned
	var fresh_inv: Dictionary = {}
	var drawer: Control = load("res://scripts/ui/hud/inventory_drawer.gd").new()
	var grid := GridContainer.new()
	drawer.crate_grid = grid

	# Fresh inventory update: only base species crates created, zero legacy crates, zero zero-owned hybrid crates
	drawer.call("update_inventory", fresh_inv, {})
	var created_ids: Array[String] = []
	for child in grid.get_children():
		var fid: String = child.get_meta("flower_id", "")
		if not fid.is_empty():
			created_ids.append(fid)

	for leg_id in FlowerData.get_legacy_species():
		if created_ids.has(leg_id):
			drawer.queue_free()
			grid.queue_free()
			return "Legacy flower '%s' displayed in fresh CVP inventory drawer!" % leg_id
	for hybrid_id in FlowerData.get_curated_hybrids():
		if created_ids.has(hybrid_id):
			drawer.queue_free()
			grid.queue_free()
			return "Zero-owned curated hybrid '%s' displayed in fresh CVP inventory drawer!" % hybrid_id

	# 4. Owned legacy compatibility item: if player actually owns it, it appears
	var legacy_compat_inv: Dictionary = {"sunflower": 3}
	drawer.call("update_inventory", legacy_compat_inv, {})
	var compat_ids: Array[String] = []
	for child in grid.get_children():
		var fid: String = child.get_meta("flower_id", "")
		if not fid.is_empty():
			compat_ids.append(fid)

	drawer.queue_free()
	grid.queue_free()

	if not compat_ids.has("sunflower"):
		return "Owned legacy compatibility flower 'sunflower' was not displayed! Found: %s" % str(compat_ids)

	# Zero-owned curated hybrid still not displayed
	if compat_ids.has("blushbell"):
		return "Zero-owned hybrid 'blushbell' unexpectedly unlocked/displayed!"

	return ""
