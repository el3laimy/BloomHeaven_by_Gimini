# BloomHaven — Baseline Status & Regression Capture (Sprint 0)

**Generated:** 2026-09-15  
**Baseline Git Commit:** `04326f320760008d02d08320e90dbdf3d182ed1b`  
**Target Branch:** `stabilization/code-audit-fixes`  
**Status:** Sprint 0 Baseline Locked

---

## 1. Environment & Runtime Information

- **OS:** Linux (x86_64)
- **Godot Engine:** v4.7.1.stable.official.a13da4feb
- **Rendering Method:** GL Compatibility
- **Project Name:** BloomHaven (`res://scenes/main.tscn`)

---

## 2. Test Execution Baseline & Results

| Tool / Test Script | Exit Code | Result Status | Key Output / Error Signature |
| :--- | :---: | :---: | :--- |
| `tools/validate_project.py` | `0` | **PASS** | `🎉 ALL COMPREHENSIVE VALIDATION CHECKS PASSED (0 ERRORS)!` *(Note: Only verifies file existence on disk, not semantic data integrity).* |
| `tests/runner.gd` | `1` | **FAIL** | `❌ TEST RUNNER FAILED WITH 1 ERRORS:`<br>`- Genetics hybrid cross expected 'roselight', got 'velvet_dusk'` |
| `scripts/tests/smoke_test.gd` | `0` | **PASS (with Leaks)** | `ALL FIONA FINCH & P4.1/P4.2 VERIFICATION TESTS PASSED (100% OK)`<br>*Memory Leaks:* 91 CanvasItem RIDs, 13 DummyTexture, 40 ShapedTextDataAdvanced, 1 FontAdvanced, 272 ObjectDB instances, 7 resources still in use. |
| `scripts/tests/test_quick_sell.gd` | `0` | **PASS** | `🎉 ALL QUICK SELL TESTS PASSED (100% OK)!`<br>Sold 1 Rose (10c), 3 Daisies (24c), batch remaining (64c). Final: 148c. Leaked 2 ObjectDB instances. |
| `scripts/tests/test_breeding_system.gd` | `1` (Hangs on assert) | **FAIL** | `SCRIPT ERROR: Assertion failed: Expected roselight hybrid`<br>`at: _run_all_tests (res://scripts/tests/test_breeding_system.gd:40)` |

---

## 3. Save State Fixture Archives

Saved fixtures preserved without modification in `tests/fixtures/baseline_saves/`:
- `tests/fixtures/baseline_saves/bloomhaven_save_v2.json` (V2 Schema from `~/.local/share/godot/app_userdata/BloomHaven/`)
- `tests/fixtures/baseline_saves/finest_garden_save_v1.json` (V1 Schema from `~/.local/share/godot/app_userdata/Finest Garden Prototype/`)

---

## 4. Documented Core Gameplay Flows (Baseline State)

### 4.1 Plant Loop
- **Method:** `MainGame._handle_planting_action(plot)` (`scripts/main.gd:554`)
- **Baseline Behavior:**
  - Standard seeds (Rose, Tulip, Daisy, Lavender) do NOT check seed stock and do NOT deduct seeds from any inventory. Infinite planting is currently permitted.
  - Mystery seeds: `unknown_hybrid_seeds.pop_front()` is executed **before** `plot.plant()` succeeds. If `plot.plant()` fails, the seed is permanently lost.
  - `unknown_hybrid_specimens` is not persisted to disk. On restart, planting a mystery seed generates a generic starter specimen, wiping all player-bred lineage data.
  - `SeedBar` displays harvested flower counts or a default fallback of 10.

### 4.2 Water Loop
- **Method:** `GardenPlot.water()` (`scripts/garden/garden_plot.gd:266`)
- **Baseline Behavior:**
  - Does NOT check `state == State.GROWING`. Allows watering EMPTY and MATURE plots.
  - `Double Water` upgrade (`main.gd:516`) selects adjacent plot using index parity `target_idx + 1 if (target_idx % 2 == 0) else target_idx - 1`, failing on non-grid spatial layouts.

### 4.3 Prune Loop
- **Method:** `GardenPlot.prune()` (`scripts/garden/garden_plot.gd:299`)
- **Baseline Behavior:**
  - Checks only `state == State.GROWING and not is_pruned`.
  - Does NOT enforce the 60%–85% skill timing window. Pruning is accepted at any growth percentage (e.g. 5% or 95%) and awards a Hero Bloom.

### 4.4 Harvest Loop
- **Method:** `GardenPlot.harvest()` (`scripts/garden/garden_plot.gd:328`)
- **Baseline Behavior:**
  - Correctly requires `state == State.MATURE`.
  - Calculates `harvest_count = 2 if quality >= 3 else 1`.
  - Emits `flower_harvested(harvested_id, harvest_count)` — completely dropping the quality tier!
  - `main.gd` receives only flower ID and count, adding to flat `inventory[flower_id]`.
  - Plot reset does not clean up `is_watered` or `water_duration_remaining`.

### 4.5 Sell Loop
- **Method:** `MainGame.quick_sell_flower()` & `quick_sell_all_flowers()` (`scripts/main.gd:774`)
- **Baseline Behavior:**
  - Quality defaults to 1. Because harvest drops quality, Hero Blooms are sold at standard 1.0x price.
  - `quick_sell_all_flowers()` invokes `quick_sell_flower()` in a loop, triggering repetitive save writes, toasts, and audio playback.

### 4.6 Breed Loop
- **Method:** `BreedingModal` & `MainGame._on_breed_requested()` (`scripts/main.gd:638`)
- **Baseline Behavior:**
  - UI permits selecting the exact same `FlowerSpecimen` instance in both slots, or selecting the same species when only 1 unit exists in inventory.
  - CVP Curated Hybrids resolve `rose + lavender -> velvet_dusk`, causing legacy assertions expecting `roselight` to fail.
  - Specimen counter `_specimen_counter = 100` in `GeneticsEngine` is static and unpersisted, leading to ID collisions upon game reload.

### 4.7 Save / Load Loop
- **Method:** `SaveManager.save_game()` & `load_game()` (`scripts/core/save_manager.gd`)
- **Baseline Behavior:**
  - Save writes directly to `SAVE_PATH_V2` with no temporary file or backup rotation.
  - Corrupt main save file results in total loss (empty dictionary fallback with no `.bak` recovery).
  - Unplanted hybrid specimens in `unknown_hybrid_specimens` are omitted from save payload.

### 4.8 Customer Orders Loop
- **Method:** `OrderManager.fulfill_order()` (`scripts/core/order_manager.gd:55`)
- **Baseline Behavior:**
  - Does NOT verify if `completed_requests[order_id]` is already true at entry. Multiple fulfillment can be triggered at domain level.
  - Unknown request types pass `can_fulfill()` as true and pay out rewards with zero item deductions.
  - Customer patience values in `OrderManager` diverge from `requests.json`.

---

## 5. Summary of Baseline Issues Documented

1. **2 Out of 5 Test Scripts Fail / Hang:**
   - `tests/runner.gd` fails on curated hybrid cross expectation (`velvet_dusk` vs `roselight`).
   - `scripts/tests/test_breeding_system.gd` hangs on assertion error for the same reason.
2. **Object and RID Leaks:**
   - Godot engine logs 272 ObjectDB leaks and 91 CanvasItem RID leaks upon headless exit.
3. **Save System Risk:**
   - Single-file direct write without atomic promotion or schema-validated backups.
4. **Data Contract Vulnerabilities:**
   - Fallback masking in `FlowerData`, `BouquetData`, and `FloristRequestData`.
   - Disconnected seed vs flower inventory state.

---
*Sprint 0 Baseline Capture Complete. Ready for Gate 0 evaluation.*
