# BloomHaven — Baseline Status & Regression Capture (Sprint 0)

**Generated:** 2026-09-15  
**Original Base Commit (`main`):** `46c3a65b64cd338800f8067e76fdd9c8fb6b2aad` (`feat(ui): add Flower Stand V2 and modular Customer Orders board with responsive mobile layout`)  
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

| Tool / Test Script | Exit Code | Result Status | Key Output / Classification |
| :--- | :---: | :---: | :--- |
| `tools/validate_project.py` | `0` | **PASS** | `🎉 ALL COMPREHENSIVE VALIDATION CHECKS PASSED (0 ERRORS)!` *(Note: Only verifies file existence on disk, not semantic data integrity).* |
| `tests/runner.gd` | `1` | **FAIL (Stale Legacy Test Expectation)** | `❌ TEST RUNNER FAILED WITH 1 ERRORS:`<br>`- Genetics hybrid cross expected 'roselight', got 'velvet_dusk'`<br>*Classification:* Stale legacy test expectation. The canonical CVP result for `rose + lavender` in `flower_data.gd` is `velvet_dusk`. Code will not be altered to match stale test. |
| `scripts/tests/smoke_test.gd` | `0` | **PASS (with Cleanup Warnings)** | `ALL FIONA FINCH & P4.1/P4.2 VERIFICATION TESTS PASSED (100% OK)`<br>*ObjectDB/RID cleanup warnings requiring investigation:* 91 CanvasItem RIDs, 13 DummyTexture, 40 ShapedTextDataAdvanced, 1 FontAdvanced, 272 ObjectDB instances, 7 resources still in use at exit. Investigation deferred to determine if caused by test teardown or runtime. |
| `scripts/tests/test_quick_sell.gd` | `0` | **PASS** | `🎉 ALL QUICK SELL TESTS PASSED (100% OK)!`<br>Sold 1 Rose (10c), 3 Daisies (24c), batch remaining (64c). Final: 148c. 2 ObjectDB cleanup warnings at exit. |
| `scripts/tests/test_breeding_system.gd` | `1` (Hangs on assert) | **FAIL (Stale Legacy Test Expectation)** | `SCRIPT ERROR: Assertion failed: Expected roselight hybrid`<br>`at: _run_all_tests (res://scripts/tests/test_breeding_system.gd:40)`<br>*Classification:* Stale legacy test expectation expecting `roselight` instead of canonical CVP `velvet_dusk`. |

---

## 3. Save State Fixture Archives

Saved fixtures preserved without modification in `tests/fixtures/baseline_saves/`:
- `tests/fixtures/baseline_saves/bloomhaven_save_v2.json` (V2 Schema from `~/.local/share/godot/app_userdata/BloomHaven/`)
- `tests/fixtures/baseline_saves/finest_garden_save_v1.json` (V1 Schema from `~/.local/share/godot/app_userdata/Finest Garden Prototype/`)

---

## 4. Documented Core Gameplay Flows (Baseline Evaluation)

| Flow | Baseline Status | Primary Observation |
| :--- | :---: | :--- |
| **Plant** | **BROKEN** | No seed stock verification or deduction for standard seeds (infinite planting); mystery seed pops from queue before planting succeeds (permanent seed loss on failure); unplanted hybrid specimens are omitted from save data. |
| **Water** | **PARTIAL** | Works on growing plants, but permits watering EMPTY and MATURE plots; Double Water upgrade relies on array index parity instead of layout spatial coordinates. |
| **Prune** | **BROKEN** | Pruning succeeds at any growth stage (0.01 to 0.99), completely bypassing the intended 60%–85% skill timing window while still awarding a Hero Bloom. |
| **Harvest** | **PARTIAL** | Gated to MATURE state and clears plot, but the emitted signal drops the quality tier into flat inventory count; plot reset fails to clear watered and fertilized state. |
| **Sell** | **PARTIAL** | Quick sell math works, but all flowers sell at Normal 1.0x due to harvest quality loss; batch sell executes single sell iteratively triggering repetitive saves, toasts, and audio. |
| **Breed** | **PARTIAL** | Crossover logic works, but UI permits duplicate specimen selection in both slots or 1-count inventory selection; static `_specimen_counter` resets on reload causing ID collisions. |
| **Save/Load** | **BROKEN** | Direct file write with no atomic `.tmp` or `.bak` backup; unplanted hybrid specimens in `unknown_hybrid_specimens` are completely omitted from save payload (genetic data lost on reload). |
| **Orders** | **PARTIAL** | Fulfills valid orders and awards rewards/combo, but domain allows repeat fulfillment of already completed orders, and unknown request types pass without item deductions. |

---

## 5. Summary of Baseline Status

1. **Test Failures:** 2 test failures identified and classified as **stale legacy test expectations** (`velvet_dusk` vs `roselight`).
2. **Engine Warnings:** 272 ObjectDB and 91 CanvasItem RID warnings classified as **cleanup warnings requiring investigation** during test teardown.
3. **Save Vulnerability:** Direct non-atomic writes and missing hybrid specimen serialization confirmed.
4. **Domain Vulnerabilities:** Missing seed stock deduction, prune window bypass, dropped harvest quality, and duplicate order fulfillment confirmed.

---
*Sprint 0 Baseline Capture Complete. Ready for Gate 0 evaluation.*
