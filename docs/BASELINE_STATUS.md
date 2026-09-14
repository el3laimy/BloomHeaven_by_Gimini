# BloomHaven Baseline Status — Sprint 0 Lock

**Date:** 2026-09-15  
**Target Branch:** `stabilization/code-audit-fixes`  
**Baseline Git Commit:** `46c3a65b64cd338800f8067e76fdd9c8fb6b2aad`  
**Working Tree Status:** Clean  

---

## 1. Baseline Test Execution Results

### 1.1 Project Validator (`tools/validate_project.py`)
- **Command:** `python3 tools/validate_project.py`
- **Exit Code:** `0`
- **Output Summary:** `ALL COMPREHENSIVE VALIDATION CHECKS PASSED (0 ERRORS)`
- **Finding:** The validator only performs filesystem existence checks (`os.path.exists`) on JSON files, scenes, audio assets, and sprite files. It does not perform semantic validation of data recipes, IDs, enums, or runtime contracts.

### 1.2 Unified Headless Runner (`tests/runner.gd`)
- **Command:** `godot --headless --script tests/runner.gd`
- **Exit Code:** `1` (FAILED)
- **Failure Reason:**
  ```text
  ❌ TEST RUNNER FAILED WITH 1 ERRORS:
    - Genetics hybrid cross expected 'roselight', got 'velvet_dusk'
  ```
- **Finding:** In `FlowerData.get_breeding_result()`, crossing `rose` + `lavender` was updated to the CVP curated hybrid `velvet_dusk`, while `tests/runner.gd` still expects the legacy `roselight` cross.

### 1.3 Smoke & Regression Suite (`scripts/tests/smoke_test.gd`)
- **Command:** `godot --headless --script scripts/tests/smoke_test.gd`
- **Exit Code:** `0` (PASS)
- **Memory & Resource Leak Log at Exit:**
  ```text
  WARNING: 91 RIDs of type "CanvasItem" were leaked.
  ERROR: 13 RID allocations of type 'DummyTexture' were leaked at exit.
  ERROR: 40 RID allocations of type 'ShapedTextDataAdvanced' were leaked at exit.
  ERROR: 1 RID allocations of type 'FontAdvanced' were leaked at exit.
  WARNING: 272 ObjectDB instances were leaked at exit.
  ERROR: 7 resources still in use at exit.
  ```

### 1.4 Quick Sell Verification (`scripts/tests/test_quick_sell.gd`)
- **Command:** `godot --headless --script scripts/tests/test_quick_sell.gd`
- **Exit Code:** `0` (PASS)
- **Finding:** Confirmed that batch selling in `quick_sell_all_flowers()` triggers individual saves per flower item (observed multiple `Game state saved successfully` lines for a single batch sell).

### 1.5 Breeding System Lifecycle (`scripts/tests/test_breeding_system.gd`)
- **Command:** `godot --headless --script scripts/tests/test_breeding_system.gd`
- **Exit Code:** FAILED (Hangs after assertion failure)
- **Failure Reason:**
  ```text
  SCRIPT ERROR: Assertion failed: Expected roselight hybrid
            at: _run_all_tests (res://scripts/tests/test_breeding_system.gd:40)
  ```
- **Finding:** `test_breeding_system.gd` expects `rose` + `lavender` to yield `roselight`, but `flower_data.gd` resolves it to `velvet_dusk`. Because assert fails in `_process` without calling `quit(1)`, the script hangs.

---

## 2. Baseline Runtime Problems & Known Issues

1. **P0-01 (Invalid Method Call):**
   `main.gd:597` calls `plot.preserve_for_breeding()`, which does not exist on `GardenPlot` (actual method name: `preserve_specimen_for_breeding()`).
2. **P0-02 (Genetic Data Loss on Save/Load):**
   `unknown_hybrid_seeds: Array[String]` is saved, but `unknown_hybrid_specimens: Array[FlowerSpecimen]` is never serialized. On restart, all custom hybrid offspring lose their genotype, phenotype, parents, and generation.
3. **P0-03 (Specimen ID Collisions):**
   `GeneticsEngine._specimen_counter` is static, initialized to 100, and never saved or restored. On game restart, subsequent hybrid generations re-issue previously used IDs (e.g. `H-101`).
4. **P0-04 (Pruning Window Invariant Bypass):**
   `GardenPlot.prune()` does not verify `growth_progress` within `0.60..0.85`. Prune can be called at any growth percentage to produce a Hero Bloom.
5. **P0-05 (Quality System Desynchronization):**
   `GardenPlot.harvest()` returns quality, but emits `flower_harvested(flower_id, count)` without quality. `main.gd` stores flat counts in `inventory[flower_id]`. Hero Blooms degrade into standard flowers in inventory. `quick_sell_flower()` defaults to quality 1. Hero tier is 3 in plot vs 4 in quick sell.
6. **P0-06 (Fake Seed Inventory):**
   `SeedBar` displays harvested flower counts or a default `10` fallback. `_handle_planting_action()` plants base species without checking seed stock, without deducting seeds, allowing infinite free planting.
7. **P0-07 (Repeat Order Fulfillment Exploit):**
   `OrderManager.fulfill_order()` does not guard against `completed_requests[order_id] == true` at the top of the function.
8. **P0-08 (Invalid ID Gameplay Masking):**
   `FlowerData.get_flower(invalid)` returns Rose; `BouquetData.get_bouquet(invalid)` returns Garden Harmony; `FloristRequestData.get_request(invalid)` returns Order 1.
9. **P0-09 (Malformed Request Type Bypass):**
   `FloristRequestData.check_fulfillment()` initializes `can_fulfill = true`. Unknown request types pass requirement checks and pay rewards without deducting items.
10. **P0-10 (Bouquet Recipe Drift):**
    `BouquetModal.gd` hardcodes `BOUQUET_RECIPES` with ingredients that contradict `data/bouquets.json`.

---

## 3. Save State Baseline Fixtures

Archived under `tests/fixtures/baseline_saves/`:
- `tests/fixtures/baseline_saves/bloomhaven_save_v2.json` (5,100 bytes, Schema V2)
- `tests/fixtures/baseline_saves/finest_garden_save_v1.json` (11,863 bytes, Schema V1)

These fixtures are preserved unchanged for regression and schema migration verification during Sprint B.

---

## 4. Pre-Fix Core Gameplay Loops Behavior Record

| Gameplay Loop | Pre-Fix Behavior |
| :--- | :--- |
| **Plant** | Sows base species infinitely without checking or deducting seeds. Sowing mystery seed pops from arrays before plant check, losing seed if plot is occupied. |
| **Water** | Waters any plot regardless of state (EMPTY or MATURE). Water duration timer does not reset cleanly upon plot clear. |
| **Prune** | Allows pruning outside the gold window (before 60% or after 85%). Discrepancy between GardenPlot (quality 3) and Quick Sell (quality 4). |
| **Harvest** | Emits flat count; discards quality rating. Hero flowers become Normal flowers in inventory. |
| **Sell** | Sells at flat quality 1. Batch sell executes redundant save, sound, UI, and toast calls per flower item. |
| **Breed** | UI allows selecting same specimen in both slots, or selecting 1-count species in both slots. Signal from HUD discards specimen references. |
| **Save / Load** | Loses hybrid specimen genetic data. Counter resets to 100 on restart. No atomic write, no `.bak` backup, no schema validation. |
| **Orders** | Domain allows duplicate fulfillment. Patience timers in `OrderManager` diverge from `requests.json`. Runtime state split across multiple dictionaries. |
