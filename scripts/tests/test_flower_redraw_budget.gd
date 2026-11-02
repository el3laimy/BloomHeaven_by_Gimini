extends SceneTree

## Verifies that continuous growth only redraws flowers at visual boundaries.
## Counts actual CanvasItem draw notifications; works with the headless renderer.

var _draw_count: int = 0
var _failed: bool = false


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var visual := FlowerVisual.new()
	root.add_child(visual)
	visual.draw.connect(func() -> void: _draw_count += 1)
	visual.current_stage = FlowerVisual.Stage.VEGETATIVE
	visual.growth_progress = 0.65
	await _settle()
	_check(_draw_count > 0, "Renderer must deliver draw notifications")
	var baseline := _draw_count
	for frame in range(60):
		visual.growth_progress = 0.65 + float(frame) * 0.002
		visual.is_late_unpruned = false
		visual.current_stage = FlowerVisual.Stage.VEGETATIVE
		await _settle()
	var redundant_draws := _draw_count - baseline
	print("Within-stage growth: %d redraws over 60 updates" % redundant_draws)
	_check(redundant_draws == 0, "Growth inside one visual state must reuse cached drawing")

	visual.growth_progress = 0.86
	await _settle()
	_check(_draw_count == baseline + 1, "Crossing the prune boundary must redraw once")
	_check(visual._branch_sprite.texture.resource_path.ends_with("plant_rose_red_cluster_buds.png"), "Late growth must select the cluster bud texture")
	baseline = _draw_count
	visual.is_pruned = true
	await _settle()
	_check(_draw_count == baseline + 1, "Pruning must redraw immediately")
	_check(visual._branch_sprite.texture.resource_path.ends_with("plant_rose_red_prime_bud.png"), "Pruning must select the prime bud texture")

	visual.queue_free()
	await process_frame
	quit(1 if _failed else 0)


func _settle() -> void:
	await process_frame
	await process_frame


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failed = true
		printerr("FAIL: " + message)
