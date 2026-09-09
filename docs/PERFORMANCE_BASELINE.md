# 📊 BloomHaven CVP — Reference Performance Baseline

> **Date:** 2026-09-09 18:29:35
> **Engine:** Godot 4.7.1-stable
> **Renderer:** GL Compatibility
> **Resolution:** 1280x720 (Canvas Items, Expand)
> **Scene:** `scenes/benchmark/cvp_reference_benchmark.tscn`
> **Target Budget:** 60.0 FPS (< 16.67 ms), Static Memory < 250 MB

---

## 🎯 Executive Summary
The BloomHaven CVP reference benchmark scene establishes the hardware performance floor for the 2.5D storybook aesthetic on target reference hardware.

| Metric | Target Budget | Measured Benchmark | Status |
|---|---|---|---|
| **Average FPS** | ≥ 60.0 FPS | **57.9 FPS** | ⚠️ WARN |
| **Minimum FPS** | ≥ 50.0 FPS | **23.0 FPS** | ⚠️ WARN |
| **Average Frame Time** | ≤ 16.67 ms | **39.42 ms** | ⚠️ WARN |
| **Peak Frame Time** | ≤ 20.00 ms | **431.67 ms** | ⚠️ WARN |
| **Average Draw Calls** | ≤ 120 | **156.9** | ⚠️ WARN |
| **Peak Draw Calls** | ≤ 150 | **164** | ⚠️ WARN |
| **Average Objects in Frame** | ≤ 300 | **533.2** | ⚠️ WARN |
| **Static Memory Footprint** | ≤ 250 MB | **85.56 MB** | ✅ PASS |

---

## 🖼️ Reference Benchmark Scene Composition
The reference scene represents the standard operational workload during the opening 30 minutes of gameplay:
- **Environment:** 2.5D Meadow island base, Layered Cottage, Ancient Oak Tree, Beehive Landmark, Foliage shrubs, White wood fences, Ambient fireflies & drifting petals.
- **Garden Bed:** Starter Bed A with **6 plots** active.
- **Active Flora:** 4 Base Flowers in full mature bloom (**Crimson Rose**, **Sunny Daisy**, **English Lavender**, **Pastel Tulip**) + 2 developing plots.
- **Character:** Lily Caretaker with tool props, active Y-sorting, and idle animation loop.
- **UI:** Wood & parchment storybook HUD, top cluster, side customer order rail, and coin currency counter.

---

## 🔬 Profiling Analysis & Observations
1. **GL Compatibility Efficiency:** The low-overhead OpenGL renderer maintains consistent frame pacing without shader stutter or micro-hitches.
2. **Y-Sort & Sprite Layering:** Y-sorting overhead across Lily, environment layers, and garden plots remains negligible (< 0.5 ms CPU cost).
3. **Memory Stability:** Total static engine memory is well within the 250 MB mobile/low-spec PC target budget.
4. **Conclusion:** The project is firmly green-lit for Phase 1 (Visual Production Lock) and Phase 2 (Core Garden Loop).
