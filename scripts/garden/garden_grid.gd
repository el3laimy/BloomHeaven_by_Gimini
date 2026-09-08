class_name GardenGrid
extends Node2D

## Manages 12 interactive garden plots with spatial layout presets and Y-sort depth ordering.
## Updated for Milestone P4 to support:
## - 3 Spatial Garden Layout Presets (Promenade, Botanist's Quad, Serpentine Oasis)
## - Y-sorting depth ordering with player character & garden architecture
## - Perspective switching (Top-Down vs 3/4 Angled)
## - Direct plot relocation / customization

signal plot_selected(plot: GardenPlot)
signal plot_action_requested(plot: GardenPlot)
signal flower_harvested(flower_id: String, count: int)
signal flower_revealed(flower_id: String, plot: GardenPlot)
signal prune_window_opened(plot: GardenPlot)
signal plot_relocated(plot_index: int, new_pos: Vector2)

const GardenLayoutManagerScript := preload("res://scripts/garden/garden_layout_manager.gd")

@export var total_plots: int = 25

var plots: Array[GardenPlot] = []
var selected_plot: GardenPlot = null
var hovered_plot: GardenPlot = null
var current_layout: int = 0
var perspective_mode: int = 1 # 3/4 Angled BloomHaven view

var _is_relocating_plot: bool = false
var _ambient_time: float = 0.0


func _ready() -> void:
	z_as_relative = true
	y_sort_enabled = true
	_create_grid()
	queue_redraw()


func _process(delta: float) -> void:
	_ambient_time += delta
	if int(_ambient_time * 10.0) % 30 == 0:
		queue_redraw()


func _create_grid() -> void:
	for child in get_children():
		if child is GardenPlot:
			child.queue_free()
	plots.clear()

	var total_count: int = total_plots
	var initial_positions: Array[Vector2] = GardenLayoutManagerScript.get_layout_positions(current_layout, total_count, perspective_mode)

	for i in range(total_count):
		var plot := GardenPlot.new()
		plot.name = "GardenPlot_%d" % i
		plot.plot_index = i
		plot.is_hero_showcase = (i == 24)
		plot.position = initial_positions[i]
		plot.z_as_relative = true
		plot.y_sort_enabled = true

		plot.plot_clicked.connect(_on_plot_clicked)
		plot.plot_hovered.connect(_on_plot_hovered)
		plot.flower_harvested.connect(_on_flower_harvested)
		plot.flower_revealed.connect(_on_flower_revealed)
		plot.prune_window_opened.connect(func(p: GardenPlot) -> void: emit_signal("prune_window_opened", p))

		add_child(plot)
		plots.append(plot)


func switch_layout(preset: int, animate: bool = true) -> void:
	current_layout = preset
	GardenLayoutManagerScript.apply_layout_to_grid(self, current_layout, perspective_mode, animate)


func set_perspective_mode(mode: int) -> void:
	perspective_mode = mode
	GardenLayoutManagerScript.apply_layout_to_grid(self, current_layout, perspective_mode, true)


func _on_plot_clicked(plot: GardenPlot) -> void:
	select_plot(plot)
	emit_signal("plot_selected", plot)
	emit_signal("plot_action_requested", plot)


func _on_plot_hovered(plot: GardenPlot, is_hover: bool) -> void:
	if is_hover:
		hovered_plot = plot
	elif hovered_plot == plot:
		hovered_plot = null


func _on_flower_harvested(flower_id: String, count: int) -> void:
	emit_signal("flower_harvested", flower_id, count)


func _on_flower_revealed(flower_id: String, plot: GardenPlot) -> void:
	emit_signal("flower_revealed", flower_id, plot)


func select_plot(plot: GardenPlot) -> void:
	if selected_plot != null and selected_plot != plot:
		selected_plot.set_selected(false)
	
	selected_plot = plot
	if selected_plot != null:
		selected_plot.set_selected(true)


func deselect_all() -> void:
	if selected_plot != null:
		selected_plot.set_selected(false)
		selected_plot = null


func get_plot(index: int) -> GardenPlot:
	if index >= 0 and index < plots.size():
		return plots[index]
	return null


func set_speed_multiplier(multiplier: float) -> void:
	for plot in plots:
		plot.growth_speed_multiplier = multiplier


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_check_hover()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_check_click()


func _check_hover() -> void:
	var global_mouse := get_global_mouse_position()
	for plot in plots:
		var local_pos: Vector2 = plot.to_local(global_mouse)
		var inside: bool = plot.is_point_inside_plot(local_pos)
		plot.set_hovered(inside)


func _check_click() -> void:
	var global_mouse := get_global_mouse_position()
	for plot in plots:
		var local_pos: Vector2 = plot.to_local(global_mouse)
		if plot.is_point_inside_plot(local_pos):
			_on_plot_clicked(plot)
			get_viewport().set_input_as_handled()
			break
