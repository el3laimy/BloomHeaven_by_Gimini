extends SceneTree

## BloomHaven CVP Reference Performance Benchmark Runner
## Executes standard benchmark: Lily + 6 starter plots + 4 base flowers + HUD + Environment.
## Samples 180 frames. Outputs user://performance_benchmark.md by default.
## Override with -- --report=/absolute/path.md --screenshot=/absolute/path.png.

const Report := preload("res://scripts/tests/benchmark_report.gd")
const SANDBOX_SAVE := "user://test_reference_benchmark.json"

func _init() -> void:
	print("==================================================")
	print("🌸 BLOOMHAVEN CVP — PERFORMANCE BENCHMARK RUNNER 🌸")
	print("==================================================")

	var scene = load("res://scenes/benchmark/cvp_reference_benchmark.tscn")
	if scene == null:
		printerr("Failed to load benchmark scene!")
		quit(1)
		return

	var main_node = scene.instantiate()
	SaveManager.delete_save(SANDBOX_SAVE)
	main_node.active_save_path = SANDBOX_SAVE
	root.add_child(main_node)

	# Initial settle
	for i in range(15):
		await process_frame

	main_node.set_process(false)
	main_node._tutorial_overlay.hide()

	# Setup reference garden state
	if is_instance_valid(main_node.garden_grid):
		var plots = main_node.garden_grid.plots
		print("Detected %d garden plots in benchmark scene." % plots.size())
		if plots.size() >= 4:
			# Plot 0: Crimson Rose (Mature + Watered)
			plots[0].plant("rose")
			plots[0].growth_progress = 1.0
			plots[0].water()
			plots[0].state = GardenPlot.State.MATURE
			plots[0].is_revealed = true
			if plots[0].has_method("_update_flower_visual"):
				plots[0]._update_flower_visual()

			# Plot 1: Sunny Daisy (Mature + Watered)
			plots[1].plant("daisy")
			plots[1].growth_progress = 1.0
			plots[1].water()
			plots[1].state = GardenPlot.State.MATURE
			plots[1].is_revealed = true
			if plots[1].has_method("_update_flower_visual"):
				plots[1]._update_flower_visual()

			# Plot 2: English Lavender (Mature + Watered)
			plots[2].plant("lavender")
			plots[2].growth_progress = 1.0
			plots[2].water()
			plots[2].state = GardenPlot.State.MATURE
			plots[2].is_revealed = true
			if plots[2].has_method("_update_flower_visual"):
				plots[2]._update_flower_visual()

			# Plot 3: Pastel Tulip (Mature + Watered)
			plots[3].plant("tulip")
			plots[3].growth_progress = 1.0
			plots[3].water()
			plots[3].state = GardenPlot.State.MATURE
			plots[3].is_revealed = true
			if plots[3].has_method("_update_flower_visual"):
				plots[3]._update_flower_visual()

		if plots.size() >= 6:
			# Plots 4 & 5: Sprout / Growing
			plots[4].plant("rose")
			plots[4].growth_progress = 0.5
			plots[5].plant("daisy")
			plots[5].growth_progress = 0.25

	# Setup character
	if is_instance_valid(main_node.character):
		main_node.character.position = Vector2(-120, -50)
		if main_node.character.has_method("set_active_tool"):
			main_node.character.set_active_tool("water")

	# Setup HUD
	if is_instance_valid(main_node.hud):
		var flower_inv := {"rose": 5, "daisy": 8, "lavender": 3, "tulip": 2}
		var bouquet_inv := {"garden_harmony": 1}
		main_node.hud.update_inventory(flower_inv, bouquet_inv, 150, 0)

	# 1. Warm-up Phase (60 frames)
	print("Warming up render pipeline (60 frames)...")
	for i in range(60):
		await process_frame

	# Measurement uses actual frame intervals, not the lower-frequency FPS monitor.
	var frames: Array[float] = []
	var processes: Array[float] = []
	var draws: Array[float] = []
	var objects: Array[float] = []
	var memories: Array[float] = []
	var previous_usec := Time.get_ticks_usec()
	var start_usec := previous_usec
	for frame in range(180):
		await process_frame
		var now_usec := Time.get_ticks_usec()
		frames.append(float(now_usec - previous_usec) / 1000.0)
		previous_usec = now_usec
		processes.append(Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0)
		draws.append(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
		objects.append(Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME))
		memories.append(Performance.get_monitor(Performance.MEMORY_STATIC) / (1024.0 * 1024.0))
	var duration := float(Time.get_ticks_usec() - start_usec) / 1000000.0
	var metrics := {
		"avg_fps": float(frames.size()) / maxf(duration, 0.000001),
		"min_fps": 1000.0 / maxf(frames.max(), 0.001),
		"avg_frame_ms": _average(frames), "max_frame_ms": frames.max(),
		"avg_process_ms": _average(processes), "max_process_ms": processes.max(),
		"avg_draws": _average(draws), "max_draws": draws.max(),
		"avg_objects": _average(objects), "max_memory_mb": memories.max()
	}
	var rendered := DisplayServer.get_name() != "headless"
	var context := {
		"date": Time.get_datetime_string_from_system(false, true),
		"engine": Engine.get_version_info().get("string", "unknown"),
		"os": OS.get_name(), "display": DisplayServer.get_name(),
		"configured_renderer": ProjectSettings.get_setting("rendering/renderer/rendering_method", "unknown"),
		"resolution": str(root.size), "samples": frames.size(),
		"duration_seconds": duration, "rendering_available": rendered
	}
	var path := _argument("--report=", "user://performance_benchmark.md")
	var report_file := FileAccess.open(path, FileAccess.WRITE)
	if report_file == null:
		printerr("Could not write performance report: " + path)
		main_node.free()
		SaveManager.delete_save(SANDBOX_SAVE)
		quit(1)
		return
	report_file.store_string(Report.build(metrics, context))
	report_file.close()
	print("Report saved: " + ProjectSettings.globalize_path(path))
	var screenshot := _argument("--screenshot=", "")
	if rendered and not screenshot.is_empty():
		await RenderingServer.frame_post_draw
		var img := root.get_texture().get_image()
		if img != null:
			var err := img.save_png(screenshot)
			if err != OK:
				printerr("Screenshot write failed: %d" % err)
	var result := Report.evaluate(metrics, rendered)
	print("Budget result: " + result["status"])
	main_node.free()
	SaveManager.delete_save(SANDBOX_SAVE)
	quit(1 if result["status"] == "FAIL" else 0)


func _average(values: Array[float]) -> float:
	var total := 0.0
	for value in values:
		total += value
	return total / maxf(float(values.size()), 1.0)


func _argument(prefix: String, fallback: String) -> String:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with(prefix):
			return argument.substr(prefix.length())
	return fallback
