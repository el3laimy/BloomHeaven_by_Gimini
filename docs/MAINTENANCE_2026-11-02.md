# BloomHaven maintenance — 2 November 2026

Base: `83b3917` on `main`. Engine used for verification: Godot 4.7.1 stable.

## Inventory correctness

Previously, consuming three quality buckets called `remove_flower()` three
times, emitting notifications while later deductions were still pending.
Synchronous listeners could observe partial inventory or consume stock needed
by the remainder of the transaction.

Consumption now builds and validates a complete deduction plan, commits it
without callbacks, then emits the bucket removal notifications and one
`inventory_changed` event. Empty transactions do not emit a change. Numeric and
serialized string keys for the same quality tier are aggregated before stock
checks. Negative, fractional, non-finite, and malformed requirements fail
without changing stock.

## Flower drawing

Growth previously requested a redraw every frame, including when the selected
artwork and geometry stayed identical. Growth and late-pruning setters now
invalidate drawing only when the resolved visual state changes. Reassigning
unchanged stage and boolean values also skips redundant invalidation. Sprite
sway continues to update its transform independently.

The new headless regression counts actual `CanvasItem.draw` notifications:
60 within-stage growth updates produced 60 redraws before the fix and zero
afterward. Crossing the late-pruning boundary and pruning each still redraw
once and select their expected rose textures. This measures drawing invalidation,
not Android FPS, GPU time, or total application performance.

## Verification

- Before changes: all 9 existing unified test groups passed.
- Added regression tests reproduced the partial-notification and redraw issues.
- After changes: all 10 unified test groups passed, including the new redraw
  budget suite and inventory validation/reentrancy cases.
- Save guard confirmed canonical save files were unchanged by the unified run.
- `test_flower_sway_anchor.gd` passed; the base remained stationary and top sway
  was 2.96 px in that run.
- `tools/validate_project.py` passed; `git diff --check` passed.

Run the complete suite from the repository root:

```sh
godot --headless --path . --editor --import
godot --headless --path . -s tests/runner.gd
```

The existing domain test process still prints resource/RID teardown warnings;
its assertions and exit status pass. These warnings also appeared before the
maintenance changes and have not been resolved in this pass.
