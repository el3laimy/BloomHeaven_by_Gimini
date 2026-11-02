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


## Runtime fixes and follow-up verification

- Manual Save reports the actual result; a failed save keeps the game open when
  returning to the main menu, with a visible retry instruction.
- Gameplay save requests within a 0.25-second window are coalesced. Manual Save,
  return to menu, application suspension, and desktop close use immediate saves.
  The timer runs during pause and ignores gameplay speed. Failed saves retain
  pending state; `last_save_duration_usec` records actual synchronous save cost.
  File writing remains synchronous; no Android latency improvement is claimed.
- Seed packets use `SeedInventory` rather than harvested flower counts. Missing
  seed IDs show zero instead of invented starter values.
- Both the side board and standalone requests modal read live order patience.
  Timer updates preserve existing cards; identical dial states skip redraws.
- Periodic plot refresh runs at most ten times per second and never opens a
  closed card. Selection opens it explicitly, respecting beauty mode.
- Flower and bouquet crates persist across count updates. Only newly visible
  catalog entries are created, and exhausted optional entries are removed.
  Sell All reads current stock instead of a count captured at construction.
- Performance reports share their displayed/evaluated thresholds, distinguish
  wall-clock intervals from CPU time, record runtime metadata, and never approve
  rendering budgets in headless mode. The historical report retains its values
  with corrected labels and conclusions.

Validation after these changes: all **12/12** unified groups pass, including
runtime tests reproducing the four reported bugs, save batching while paused,
failed save retry, suspension flush, retained card identity and live sale counts.
Budget report tests check every exact limit and just-failing value, missing and
non-finite data, and headless incompleteness. The project validator and whitespace
check pass. The benchmark headless smoke run produces **INCOMPLETE**, correctly
leaving rendering budgets unmeasured. Earlier resource/RID teardown warnings
remain outside this change's scope.
