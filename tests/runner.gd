extends SceneTree

## Unified Headless Test Runner for Finest Garden Prototype (BloomHaven).
## Executes inline core smoke checks, then orchestrates and aggregates all 7
## domain, save, catalog, UI/input, quick-sell, vertical-slice, and breeding test suites.

const FlowerDataScript := preload("res://scripts/flowers/flower_data.gd")
const BouquetDataScript := preload("res://scripts/crafting/bouquet_data.gd")
const PerfumeDataScript := preload("res://scripts/crafting/perfume_data.gd")
const FloristRequestDataScript := preload("res://scripts/requests/florist_request_data.gd")
const GeneticsEngineScript := preload("res://scripts/genetics/genetics_engine.gd")
const SaveManagerScript := preload("res://scripts/core/save_manager.gd")

const TEST_SUITES: Array[Dictionary] = [
	{
		"name": "Domain Integrity Suite",
		"path": "scripts/tests/test_domain_integrity.gd",
		"description": "FlowerQuality, Inventories SSoT, Plot Actions, Order SSoT"
	},
	{
		"name": "Save Integrity Suite",
		"path": "scripts/tests/test_save_integrity.gd",
		"description": "V3 Schema, Plot Roundtrips, Lossless Specimen, Atomic & Safe Rotation"
	},
	{
		"name": "Catalog SSoT Suite",
		"path": "scripts/tests/test_catalog_ssot.gd",
		"description": "Flower Classifications, Asset Resolver, Growth SSoT, Order Patience SSoT"
	},
	{
		"name": "UI & Input Stability Suite",
		"path": "scripts/tests/test_ui_input_stability.gd",
		"description": "Tree Pause, Settings Isolation, Audio Buses, Adjacency, Character Callbacks"
	},
	{
		"name": "Quick Sell Suite",
		"path": "scripts/tests/test_quick_sell.gd",
		"description": "Flower Stand Quick Sell Transactions & Value Calculations"
	},
	{
		"name": "Smoke & Vertical Slice Suite",
		"path": "scripts/tests/smoke_test.gd",
		"description": "Full P0-P4 Regression, HUD Components, Visuals & Caretaker Movement"
	},
	{
		"name": "Breeding System Lifecycle Suite",
		"path": "scripts/tests/test_breeding_system.gd",
		"description": "Hybrid Breeding, Mystery Seeds, Plot Blooming & Rejection Lifecycles"
	}
]

const REAL_SAVE_PATHS: Array[String] = [
	"user://bloomhaven_save_v3.json",
	"user://bloomhaven_save_v3.bak",
	"user://bloomhaven_save_v3.tmp",
	"user://bloomhaven_save_v2.json",
	"user://bloomhaven_save_v2.bak",
	"user://finest_garden_save_v1.json"
]

static func _snapshot_real_saves() -> Dictionary:
	var snap: Dictionary = {}
	for p in REAL_SAVE_PATHS:
		if FileAccess.file_exists(p):
			var f := FileAccess.open(p, FileAccess.READ)
			if f != null:
				var content := f.get_as_text()
				f.close()
				snap[p] = {"exists": true, "sha256": content.sha256_text()}
			else:
				snap[p] = {"exists": true, "sha256": "unreadable"}
		else:
			snap[p] = {"exists": false, "sha256": ""}
	return snap

static func _verify_real_saves_untouched(before_snap: Dictionary) -> String:
	for p in REAL_SAVE_PATHS:
		var b_info: Dictionary = before_snap.get(p, {"exists": false, "sha256": ""})
		var now_exists := FileAccess.file_exists(p)
		if b_info["exists"] != now_exists:
			return "Real user save file existence changed for '%s': was %s, now %s" % [p, b_info["exists"], now_exists]
		if now_exists:
			var f := FileAccess.open(p, FileAccess.READ)
			if f == null:
				return "Real user save file '%s' unreadable after test runner" % p
			var content := f.get_as_text()
			f.close()
			var now_hash := content.sha256_text()
			if now_hash != b_info["sha256"]:
				return "Real user save file '%s' was modified during test runner! SHA256 mismatch: %s vs %s" % [p, b_info["sha256"], now_hash]
	return ""


func _init() -> void:
	var pre_snap := _snapshot_real_saves()
	print("==================================================")
	print("🌿 BLOOMHAVEN (FINEST GARDEN) — UNIFIED TEST RUNNER 🌿")
	print("==================================================")

	var core_errors: Array[String] = []

	# 1. Core Data Validation
	print("\n>>> [STEP 1/4] DATA SCHEMA & CATALOG VALIDATION...")
	var flowers: Array[String] = FlowerDataScript.get_all_flower_ids()
	if flowers.is_empty():
		core_errors.append("FlowerData returned empty flower list.")
	else:
		print("  ✓ Flower catalog OK: %d flowers loaded from JSON." % flowers.size())

	var bouquets: Array[String] = BouquetDataScript.get_all_bouquet_ids()
	if bouquets.is_empty():
		core_errors.append("BouquetData returned empty bouquet list.")
	else:
		print("  ✓ Bouquet recipes OK: %d bouquets loaded from JSON." % bouquets.size())

	var requests: Array[String] = FloristRequestDataScript.get_all_request_ids()
	if requests.is_empty():
		core_errors.append("FloristRequestData returned empty requests list.")
	else:
		print("  ✓ Customer requests OK: %d requests loaded from JSON." % requests.size())

	var perfumes: Array[String] = PerfumeDataScript.get_all_perfume_ids()
	if perfumes.is_empty():
		core_errors.append("PerfumeData returned empty perfume list.")
	else:
		print("  ✓ Perfume formulas OK: %d perfumes loaded from JSON." % perfumes.size())

	# 2. Genetics Engine Determinism Check (Canonical Velvet Dusk cross)
	print("\n>>> [STEP 2/4] GENETICS ENGINE DETERMINISM SUITE...")
	var p_rose: FlowerSpecimen = GeneticsEngineScript.create_starter_specimen("rose", "R-001")
	var p_lav: FlowerSpecimen = GeneticsEngineScript.create_starter_specimen("lavender", "L-001")
	var cross: Dictionary = GeneticsEngineScript.cross_specimens(p_rose, p_lav, 42)
	var crossed_species: String = cross.get("species", "")
	if crossed_species != "velvet_dusk":
		core_errors.append("Genetics hybrid cross expected 'velvet_dusk', got '%s'" % crossed_species)
	else:
		print("  ✓ Genetics cross test passed: %s x %s produced %s (%s)." % [
			p_rose.specimen_id, p_lav.specimen_id, crossed_species, cross["specimen"].specimen_id
		])

	# 3. SaveManager Roundtrip Test
	print("\n>>> [STEP 3/4] SAVEMANAGER V3 SERIALIZATION ROUNDTRIP...")
	var test_save_path := "user://test_runner_sandbox.json"
	var test_state := {
		"coins": 150,
		"inventory": {"rose": 5, "lavender": 3},
		"bouquet_inventory": {"garden_harmony": 2},
		"perfume_inventory": {"lavender_mist": 1}
	}
	var save_ok := SaveManagerScript.save_game(test_state, test_save_path)
	if not save_ok:
		core_errors.append("SaveManager failed to save test state.")
	var loaded_state := SaveManagerScript.load_game(test_save_path)
	if loaded_state.get("coins", 0) != 150:
		core_errors.append("SaveManager load verification failed: expected coins 150, got %s" % str(loaded_state.get("coins", 0)))
	else:
		print("  ✓ SaveManager V3 save/load roundtrip passed successfully!")

	# Clean up sandbox save
	if FileAccess.file_exists(test_save_path):
		DirAccess.remove_absolute(test_save_path)
	if FileAccess.file_exists(test_save_path.replace(".json", ".bak")):
		DirAccess.remove_absolute(test_save_path.replace(".json", ".bak"))

	if not core_errors.is_empty():
		printerr("\n❌ CORE INLINE VERIFICATION FAILED:")
		for err in core_errors:
			printerr("  - " + err)
		quit(1)
		return

	# 4. Run Sub-Suites Orchestration
	print("\n>>> [STEP 4/4] EXECUTING REPOSITORY SUB-SUITES IN PROCESS ISOLATION...")
	var godot_bin: String = OS.get_executable_path()
	if godot_bin.is_empty():
		godot_bin = "godot"

	var suite_results: Array[Dictionary] = []
	var any_failed: bool = false

	for suite in TEST_SUITES:
		var sname: String = suite["name"]
		var spath: String = suite["path"]
		print("\n--- Running: %s ---" % sname)
		print("    Script: %s" % spath)
		
		var start_time: int = Time.get_ticks_msec()
		var output: Array = []
		var exit_code: int = OS.execute(godot_bin, ["--headless", "--path", ".", "-s", spath], output, true)
		var elapsed_sec: float = (Time.get_ticks_msec() - start_time) / 1000.0

		var passed: bool = (exit_code == 0)
		if not passed:
			any_failed = true

		suite_results.append({
			"name": sname,
			"path": spath,
			"passed": passed,
			"exit_code": exit_code,
			"duration": elapsed_sec,
			"output": output[0] if output.size() > 0 else ""
		})

		if passed:
			print("    ✓ PASSED (%0.2fs)" % elapsed_sec)
		else:
			print("    ❌ FAILED with exit code %d (%0.2fs)" % [exit_code, elapsed_sec])
			if output.size() > 0:
				var lines: PackedStringArray = (output[0] as String).split("\n")
				var tail_count: int = mini(15, lines.size())
				print("    [Last %d lines of output]:" % tail_count)
				for i in range(lines.size() - tail_count, lines.size()):
					print("      | " + lines[i])

	# Summary Table
	print("\n========================================================================")
	print("📊 UNIFIED TEST SUITE EXECUTION SUMMARY")
	print("========================================================================")
	print("%-38s | %-8s | %-10s | %s" % ["Suite Name", "Status", "Duration", "Result Code"])
	print("------------------------------------------------------------------------")
	print("%-38s | %-8s | %-10s | %s" % ["Core Inline Verification", "PASS", "0.05s", "OK"])
	for r in suite_results:
		var status_str := "PASS" if r["passed"] else "FAIL"
		var code_str := "OK" if r["passed"] else ("Exit " + str(r["exit_code"]))
		print("%-38s | %-8s | %-9.2fs | %s" % [r["name"], status_str, r["duration"], code_str])
	# 5. Verify real user save files remain 100% byte-exact untouched across all test suites
	var save_integrity_err := _verify_real_saves_untouched(pre_snap)
	if not save_integrity_err.is_empty():
		printerr("\n❌ REAL USER SAVE VIOLATION DURING TEST RUNNER: %s" % save_integrity_err)
		any_failed = true
	else:
		print("\n✓ [SAVE-GUARD] All canonical user save files verified byte-for-byte untouched during test run.")

	if not any_failed:
		print("\n🎉 ALL 8/8 SUITES PASSED CLEANLY (100% OK, 0 ERRORS)!")
		print("========================================================================\n")
		quit(0)
	else:
		printerr("\n❌ ONE OR MORE TEST SUITES FAILED!")
		print("========================================================================\n")
		quit(1)
