extends RefCounted

## One source for displayed limits and their actual pass/fail comparisons.
const BUDGETS: Array[Dictionary] = [
	{"key": "avg_fps", "label": "Average FPS", "limit": 60.0, "minimum": true, "unit": "FPS", "rendered": true},
	{"key": "min_fps", "label": "Minimum FPS", "limit": 50.0, "minimum": true, "unit": "FPS", "rendered": true},
	{"key": "avg_frame_ms", "label": "Average frame interval", "limit": 16.67, "unit": "ms", "rendered": true},
	{"key": "max_frame_ms", "label": "Peak frame interval", "limit": 20.0, "unit": "ms", "rendered": true},
	{"key": "avg_process_ms", "label": "Average CPU process time", "limit": 16.67, "unit": "ms"},
	{"key": "max_process_ms", "label": "Peak CPU process time", "limit": 20.0, "unit": "ms"},
	{"key": "avg_draws", "label": "Average draw calls", "limit": 120.0, "unit": "calls", "rendered": true},
	{"key": "max_draws", "label": "Peak draw calls", "limit": 150.0, "unit": "calls", "rendered": true},
	{"key": "avg_objects", "label": "Average rendered objects", "limit": 300.0, "unit": "objects", "rendered": true},
	{"key": "max_memory_mb", "label": "Peak static memory", "limit": 250.0, "unit": "MiB"}
]


static func evaluate(metrics: Dictionary, rendering_available: bool) -> Dictionary:
	var rows: Array[Dictionary] = []
	var failed := false
	var incomplete := false
	for budget in BUDGETS:
		var value = metrics.get(budget["key"])
		var measured := (value is int or value is float) and is_finite(float(value)) and float(value) >= 0.0
		measured = measured and (rendering_available or not budget.get("rendered", false))
		var status := "NOT MEASURED"
		if measured:
			var passed: bool = value >= budget["limit"] if budget.get("minimum", false) else value <= budget["limit"]
			status = "PASS" if passed else "FAIL"
			failed = failed or not passed
		else:
			incomplete = true
		rows.append({"budget": budget, "value": value, "status": status})
	return {"rows": rows, "status": "FAIL" if failed else ("INCOMPLETE" if incomplete else "PASS")}


static func build(metrics: Dictionary, context: Dictionary) -> String:
	var result := evaluate(metrics, context.get("rendering_available", false))
	var report := "# BloomHaven reference performance measurement\n\n"
	for key in ["date", "engine", "os", "display", "configured_renderer", "resolution", "samples", "duration_seconds"]:
		report += "- **%s:** %s\n" % [key, str(context.get(key, "unavailable"))]
	report += "\n**Budget result: %s**\n\n" % result["status"]
	report += "| Metric | Target | Measured | Status |\n|---|---|---|---|\n"
	for row in result["rows"]:
		var budget: Dictionary = row["budget"]
		var comparison := ">=" if budget.get("minimum", false) else "<="
		var measured := "unavailable" if row["status"] == "NOT MEASURED" else "%.2f %s" % [row["value"], budget["unit"]]
		report += "| %s | %s %.2f %s | %s | %s |\n" % [budget["label"], comparison, budget["limit"], budget["unit"], measured, row["status"]]
	report += "\nFrame intervals use monotonic wall-clock samples. CPU process time comes from Godot's process monitor and is reported separately.\n"
	report += "\nHeadless runs cannot validate rendered FPS, GPU work, or draw budgets; those rows remain NOT MEASURED. Static memory excludes GPU allocations.\n"
	report += "\nThis short reference scene measurement does not establish Android performance, thermal stability, battery life, or release readiness. Re-run on target devices under representative sustained load.\n"
	return report
