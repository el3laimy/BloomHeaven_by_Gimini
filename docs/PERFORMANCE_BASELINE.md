# BloomHaven — historical performance measurement

The figures below were recorded by the earlier benchmark on **9 September 2026**.
They are preserved for reference, not presented as a new measurement of the
maintenance branch. The original report did not identify the device, hardware,
or whether a real graphics renderer was available.

**Historical budget result: FAIL.** Seven recorded metrics exceed their stated
limits. The old report's claims about smooth frame pacing, sub-0.5 ms Y-sorting,
and release readiness were not established by its measurements and are removed.

| Metric | Stated target | Historical value | Comparison |
|---|---|---|---|
| Average FPS monitor | >= 60 FPS | 57.9 FPS | FAIL |
| Minimum FPS monitor | >= 50 FPS | 23.0 FPS | FAIL |
| Average CPU process time | <= 16.67 ms | 39.42 ms | FAIL |
| Peak CPU process time | <= 20.00 ms | 431.67 ms | FAIL |
| Average draw calls | <= 120 | 156.9 | FAIL |
| Peak draw calls | <= 150 | 164 | FAIL |
| Average rendered objects | <= 300 | 533.2 | FAIL |
| Peak static engine memory | <= 250 MiB | 85.56 MiB | PASS |

The earlier script labelled `Performance.TIME_PROCESS` as frame time. It
measures CPU process time; actual wall-clock frame intervals were not collected
in that run. Its short sample also used the engine FPS monitor rather than
individual frame intervals. The displayed resolution was configured as
1280x720; it was not recorded from the running viewport.

## Current measurement workflow

The benchmark now records actual frame intervals separately from CPU process
time, engine/display/viewport metadata, and its sample duration. Shared budget
constants drive both comparisons and report labels. A 58 FPS result cannot pass
a 60 FPS target, and a 21 ms peak cannot pass a 20 ms target.

```sh
godot --path . -s scripts/tests/performance_benchmark.gd -- \
  --report=/absolute/path/performance.md \
  --screenshot=/absolute/path/performance.png
```

The default report is `user://performance_benchmark.md`. The script uses an
isolated benchmark save and does not overwrite this historical record or game
progress. Screenshots are optional and require a graphics renderer.

A headless smoke run can verify collection and report generation:

```sh
godot --headless --path . -s scripts/tests/performance_benchmark.gd
```

In headless mode rendering metrics remain **NOT MEASURED**, so the aggregate
result is **INCOMPLETE** unless a measured CPU/memory budget already fails.
Successful report generation exits zero for PASS or INCOMPLETE; a failed measured
budget or file-write failure exits nonzero. CI release gates must require a
rendered report with `Budget result: PASS`, not merely process exit zero.

A short desktop reference run does not establish Android FPS, thermal stability,
battery life, or release readiness. Those require measurements on target devices.
