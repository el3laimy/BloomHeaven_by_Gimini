extends SceneTree

const Report := preload("res://scripts/tests/benchmark_report.gd")
var _failed: int = 0


func _init() -> void:
	var metrics: Dictionary = {}
	for budget in Report.BUDGETS:
		metrics[budget["key"]] = budget["limit"]
	_check(Report.evaluate(metrics, true)["status"] == "PASS", "Every exact boundary passes")
	for budget in Report.BUDGETS:
		var invalid := metrics.duplicate()
		invalid[budget["key"]] += -0.01 if budget.get("minimum", false) else 0.01
		_check(Report.evaluate(invalid, true)["status"] == "FAIL", "Actual comparison uses advertised limit: " + budget["key"])
	var old_false_pass := metrics.duplicate()
	old_false_pass["avg_fps"] = 58.0
	_check(Report.evaluate(old_false_pass, true)["status"] == "FAIL", "58 FPS cannot pass a 60 FPS budget")
	old_false_pass = metrics.duplicate()
	old_false_pass["max_frame_ms"] = 21.0
	_check(Report.evaluate(old_false_pass, true)["status"] == "FAIL", "21 ms cannot pass a 20 ms peak budget")
	_check(Report.evaluate(metrics, false)["status"] == "INCOMPLETE", "Headless measurement cannot approve rendering budgets")
	_check(Report.evaluate({}, true)["status"] == "INCOMPLETE", "Missing metrics never pass")
	var invalid_metric := metrics.duplicate()
	invalid_metric["avg_fps"] = NAN
	_check(Report.evaluate(invalid_metric, true)["status"] == "INCOMPLETE", "Non-finite metrics never pass")
	var report := Report.build(metrics, {"engine": "test-engine", "rendering_available": false})
	_check(report.contains("test-engine") and report.contains("INCOMPLETE"), "Report uses supplied engine metadata and measured outcome")
	_check(report.contains(">= 60.00 FPS") and report.contains("<= 20.00 ms"), "Report prints the same limits it evaluates")
	print("Benchmark report failures: %d" % _failed)
	quit(1 if _failed else 0)


func _check(condition: bool, description: String) -> void:
	if not condition:
		_failed += 1
		printerr("FAIL: " + description)
