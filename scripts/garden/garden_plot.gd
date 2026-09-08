class_name GardenPlot
extends Node2D

## Interactive garden plot with soil rendering, moisture state, growth cycle, and juicy juice.
## Updated for Milestone P3 to support individual FlowerSpecimen genetics and mutually
## exclusive Harvest-to-Bulk vs Preserve-for-Breeding flows.

signal plot_clicked(plot: GardenPlot)
signal plot_hovered(plot: GardenPlot, is_hover: bool)
signal flower_harvested(flower_id: String, count: int)
signal flower_revealed(flower_id: String, plot: GardenPlot)
signal specimen_preserved(specimen: FlowerSpecimen, plot: GardenPlot)
signal prune_window_opened(plot: GardenPlot)

enum State {
	EMPTY,
	GROWING,
	MATURE
}

@export var plot_index: int = 0
@export var growth_speed_multiplier: float = 1.0

var state: State = State.EMPTY
var current_flower_id: String = ""
var current_specimen: FlowerSpecimen = null
var growth_progress: float = 0.0 # 0.0 to 1.0
var is_watered: bool = false
var water_duration_remaining: float = 0.0
var is_mystery_seed: bool = false
var is_revealed: bool = false
var is_pruned: bool = false
var is_fertilized: bool = false
var water_duration_multiplier: float = 1.0
var quality: int = 1

var is_hovered: bool = false
var is_selected: bool = false
var is_hero_showcase: bool = false
var _prune_badge_time: float = 0.0
var _thirsty_badge_time: float = 0.0
var _prune_alerted: bool = false

# Internal nodes
var _flower_visual: FlowerVisual = null
var _bed_sprite: Sprite2D = null
var _soil_node: Node2D = null
var _water_particles: CPUParticles2D = null
var _harvest_particles: CPUParticles2D = null
var _plant_particles: CPUParticles2D = null

const PLOT_WIDTH: float = 64.0
const PLOT_HEIGHT: float = 44.0
const WATER_EFFECT_DURATION: float = 25.0 # Seconds plot stays wet


func _init() -> void:
	z_as_relative = true
	y_sort_enabled = true
	add_to_group("garden_plots")
	_setup_nodes()


func _ready() -> void:
	queue_redraw()


func _setup_nodes() -> void:
	if not is_instance_valid(_flower_visual):
		_flower_visual = FlowerVisual.new()
		_flower_visual.name = "FlowerVisual"
		_flower_visual.position = Vector2(0, 2)
		_flower_visual.visible = false
		add_child(_flower_visual)

	if is_instance_valid(_water_particles):
		return

	# Water Splash Particles
	_water_particles = CPUParticles2D.new()
	_water_particles.name = "WaterParticles"
	_water_particles.emitting = false
	_water_particles.one_shot = true
	_water_particles.amount = 20
	_water_particles.lifetime = 0.6
	_water_particles.explosiveness = 0.85
	_water_particles.direction = Vector2(0, -1)
	_water_particles.spread = 65.0
	_water_particles.gravity = Vector2(0, 180)
	_water_particles.initial_velocity_min = 40.0
	_water_particles.initial_velocity_max = 90.0
	_water_particles.scale_amount_min = 2.5
	_water_particles.scale_amount_max = 4.5
	_water_particles.color = Color(0.35, 0.75, 1.0, 0.9)
	add_child(_water_particles)

	# Planting Earth Dust Particles
	_plant_particles = CPUParticles2D.new()
	_plant_particles.name = "PlantParticles"
	_plant_particles.emitting = false
	_plant_particles.one_shot = true
	_plant_particles.amount = 14
	_plant_particles.lifetime = 0.5
	_plant_particles.direction = Vector2(0, -1)
	_plant_particles.spread = 45.0
	_plant_particles.gravity = Vector2(0, 120)
	_plant_particles.initial_velocity_min = 25.0
	_plant_particles.initial_velocity_max = 50.0
	_plant_particles.scale_amount_min = 2.0
	_plant_particles.scale_amount_max = 4.0
	_plant_particles.color = Color(0.48, 0.32, 0.18, 0.9)
	add_child(_plant_particles)

	# Harvest Sparkle Particles
	_harvest_particles = CPUParticles2D.new()
	_harvest_particles.name = "HarvestParticles"
	_harvest_particles.emitting = false
	_harvest_particles.one_shot = true
	_harvest_particles.amount = 24
	_harvest_particles.lifetime = 0.8
	_harvest_particles.direction = Vector2(0, -1)
	_harvest_particles.spread = 180.0
	_harvest_particles.gravity = Vector2(0, -15)
	_harvest_particles.initial_velocity_min = 30.0
	_harvest_particles.initial_velocity_max = 70.0
	_harvest_particles.scale_amount_min = 2.0
	_harvest_particles.scale_amount_max = 4.5
	_harvest_particles.color = Color(1.0, 0.85, 0.3, 0.9)
	add_child(_harvest_particles)


func _process(delta: float) -> void:
	if is_watered:
		water_duration_remaining -= delta
		if water_duration_remaining <= 0.0:
			is_watered = false
			water_duration_remaining = 0.0
			queue_redraw()

	if state == State.GROWING:
		var data: Dictionary = FlowerData.get_flower(current_flower_id)
		var base_duration: float = float(data.get("base_growth_seconds", 30.0))
		var water_boost: float = 1.6 if is_watered else 1.0
		var rate: float = (1.0 / max(base_duration, 0.5)) * water_boost * growth_speed_multiplier

		growth_progress = min(1.0, growth_progress + rate * delta)
		_update_growth_stage()

		if growth_progress >= 0.60 and growth_progress <= 0.85 and not is_pruned:
			_prune_badge_time += delta * 4.0
			if not _prune_alerted:
				_prune_alerted = true
				prune_window_opened.emit(self)
			queue_redraw()

		if growth_progress >= 1.0:
			state = State.MATURE
			_on_mature_reached()
		queue_redraw()


func _update_growth_stage() -> void:
	if not is_instance_valid(_flower_visual):
		return
	if growth_progress < 0.25:
		_flower_visual.current_stage = FlowerVisual.Stage.SEED
	elif growth_progress < 0.60:
		_flower_visual.current_stage = FlowerVisual.Stage.SPROUT
	elif growth_progress < 1.0:
		_flower_visual.current_stage = FlowerVisual.Stage.VEGETATIVE
	else:
		_flower_visual.current_stage = FlowerVisual.Stage.BLOOMING


func _update_growth_stage_visual() -> void:
	_update_growth_stage()


func _on_mature_reached() -> void:
	if is_mystery_seed and not is_revealed:
		is_revealed = true
		if is_instance_valid(_flower_visual):
			_flower_visual.is_mystery = false
			_flower_visual.is_revealed = true
		emit_signal("flower_revealed", current_flower_id, self)

	# Celebration bounce pop
	if is_inside_tree() and is_instance_valid(_flower_visual):
		var tween := create_tween()
		if tween != null:
			var target_s := 1.7 if is_pruned else 1.2
			tween.tween_property(_flower_visual, "scale", Vector2(target_s, target_s), 0.18).set_trans(Tween.TRANS_BACK)
			tween.tween_property(_flower_visual, "scale", Vector2(1.0, 1.0), 0.14)


func plant(new_flower_id: String, mystery: bool = false, specimen: FlowerSpecimen = null) -> bool:
	if state != State.EMPTY:
		return false

	current_flower_id = new_flower_id
	state = State.GROWING
	growth_progress = 0.0
	is_mystery_seed = mystery
	is_revealed = not mystery
	is_pruned = false
	_prune_alerted = false
	quality = 1

	if specimen != null:
		current_specimen = specimen
	else:
		current_specimen = GeneticsEngine.create_starter_specimen(new_flower_id)

	_flower_visual.flower_id = current_flower_id
	_flower_visual.phenotype = current_specimen.phenotype
	_flower_visual.is_mystery = mystery
	_flower_visual.is_revealed = is_revealed
	_flower_visual.is_pruned = false
	_flower_visual.current_stage = FlowerVisual.Stage.SEED
	_flower_visual.visible = true

	# Particle & Pop
	_plant_particles.restart()
	_plant_particles.emitting = true
	_play_sfx("plant")

	var tween := create_tween()
	scale = Vector2(0.85, 0.85)
	tween.tween_property(self, "scale", Vector2(1.08, 1.08), 0.12).set_trans(Tween.TRANS_BACK)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.08)

	queue_redraw()
	return true


func water() -> bool:
	is_watered = true
	water_duration_remaining = WATER_EFFECT_DURATION * water_duration_multiplier

	# Splash particle & bounce
	_water_particles.restart()
	_water_particles.emitting = true
	_play_sfx("water")

	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(1.05, 0.95), 0.08)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.12).set_trans(Tween.TRANS_ELASTIC)

	queue_redraw()
	return true


func apply_fertilizer() -> bool:
	if state != State.GROWING or is_fertilized:
		return false
	is_fertilized = true
	growth_progress = min(0.99, growth_progress + 0.35)
	_play_sfx("upgrade")
	_spawn_floating_text("🧪 Fertilizer Boost!", Color(0.35, 0.95, 0.55))
	var tween := create_tween()
	if tween:
		tween.tween_property(self, "scale", Vector2(1.10, 1.10), 0.12).set_trans(Tween.TRANS_BACK)
		tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.10)
	queue_redraw()
	return true


func prune() -> bool:
	# Pruning mechanic: Trims side shoots at Stage 2 / Vegetative to focus energy into a Hero Bloom (★★★)
	if state != State.GROWING or is_pruned:
		return false

	is_pruned = true
	_prune_alerted = false
	quality = 3
	if is_instance_valid(_flower_visual):
		_flower_visual.is_pruned = true

	# Snip sparkle & pop
	_harvest_particles.restart()
	_harvest_particles.emitting = true
	_play_sfx("prune")

	var tween := create_tween()
	scale = Vector2(1.12, 1.12)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.15).set_trans(Tween.TRANS_BACK)

	_spawn_floating_text("✂️ Hero Bloom (★★★)!", Color(1.0, 0.88, 0.35))
	queue_redraw()
	return true


func set_highlight(val: bool) -> void:
	set_hovered(val)


func harvest() -> Dictionary:
	if state != State.MATURE:
		return {}

	var harvested_id := current_flower_id
	var harvested_quality := quality
	var harvested_specimen := current_specimen

	state = State.EMPTY
	current_flower_id = ""
	current_specimen = null
	growth_progress = 0.0
	is_pruned = false
	_prune_alerted = false
	is_fertilized = false
	quality = 1
	is_mystery_seed = false
	is_revealed = false

	if is_instance_valid(_flower_visual):
		_flower_visual.visible = false

	# Sparkle celebration
	_harvest_particles.restart()
	_harvest_particles.emitting = true
	_play_sfx("harvest")

	var harvest_count := 2 if harvested_quality >= 3 else 1
	emit_signal("flower_harvested", harvested_id, harvest_count)

	var f_data := FlowerData.get_flower(harvested_id)
	var flower_name: String = f_data.get("display_name", harvested_id)
	_spawn_floating_text("+%d %s" % [harvest_count, flower_name], Color(0.7, 0.95, 0.65))

	queue_redraw()
	return {
		"flower_id": harvested_id,
		"count": harvest_count,
		"quality": harvested_quality,
		"specimen": harvested_specimen
	}


func preserve_specimen_for_breeding() -> FlowerSpecimen:
	if state != State.MATURE or current_specimen == null:
		return null

	var preserved := current_specimen
	state = State.EMPTY
	current_flower_id = ""
	current_specimen = null
	growth_progress = 0.0
	is_pruned = false
	quality = 1
	is_mystery_seed = false
	is_revealed = false

	if is_instance_valid(_flower_visual):
		_flower_visual.visible = false

	_harvest_particles.restart()
	_harvest_particles.emitting = true

	emit_signal("specimen_preserved", preserved, self)
	_spawn_floating_text("Preserved %s to Roster" % preserved.specimen_id, Color(0.95, 0.8, 0.4))

	queue_redraw()
	return preserved


func _reset_plot_state() -> void:
	state = State.EMPTY
	current_flower_id = ""
	current_specimen = null
	growth_progress = 0.0
	is_mystery_seed = false
	is_revealed = false
	is_pruned = false
	quality = 1
	if is_instance_valid(_flower_visual):
		_flower_visual.is_mystery = false
		_flower_visual.is_revealed = false
		_flower_visual.is_pruned = false
		_flower_visual.phenotype = null
		_flower_visual.visible = false

	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(1.12, 1.12), 0.1).set_trans(Tween.TRANS_BACK)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.1)

	queue_redraw()


func _spawn_floating_text(text: String, color: Color) -> void:
	var label := Label.new()
	label.text = text
	label.position = Vector2(-70, -48)
	label.size = Vector2(140, 24)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0.1, 0.08, 0.05, 0.9))
	label.add_theme_constant_override("outline_size", 4)
	label.add_theme_font_size_override("font_size", 14)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)

	var tween := create_tween()
	tween.tween_property(label, "position:y", label.position.y - 32.0, 0.85).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.85).set_ease(Tween.EASE_IN)
	tween.tween_callback(label.queue_free)


func _draw() -> void:
	var center := Vector2.ZERO
	var w := PLOT_WIDTH
	var h := PLOT_HEIGHT

	# 1. Soft Warm Grounding Shadow
	_draw_custom_ellipse(center + Vector2(2, 6), (w * 0.5) + 6.0, (h * 0.5) + 4.0, Color(0.06, 0.11, 0.07, 0.28))

	# 2. Selection / Hover Highlight Ring
	if is_selected:
		_draw_custom_ellipse(center, (w * 0.5) + 8.0, (h * 0.5) + 6.0, Color(1.0, 0.88, 0.35, 0.45))
	elif is_hovered:
		_draw_custom_ellipse(center, (w * 0.5) + 6.0, (h * 0.5) + 5.0, Color(0.65, 0.95, 0.75, 0.30))

	# 3. Outer Wooden Planter Timber Frame
	var wood_dark := Color(0.38, 0.25, 0.14)
	var wood_mid := Color(0.48, 0.32, 0.18)
	var wood_light := Color(0.58, 0.40, 0.24)
	var corner_peg_color := Color(0.62, 0.45, 0.28)

	var frame_rect := Rect2(-w * 0.5 - 2, -h * 0.5 - 2, w + 4, h + 4)
	draw_rect(frame_rect, wood_dark, true)
	draw_rect(Rect2(-w * 0.5, -h * 0.5, w, h), wood_mid, true)

	# 4. Corner Round Wooden Pegs
	draw_circle(Vector2(-w * 0.5, -h * 0.5), 3.5, corner_peg_color)
	draw_circle(Vector2(w * 0.5, -h * 0.5), 3.5, corner_peg_color)
	draw_circle(Vector2(-w * 0.5, h * 0.5), 3.5, corner_peg_color)
	draw_circle(Vector2(w * 0.5, h * 0.5), 3.5, corner_peg_color)

	# 5. Inner Loam Soil Basin
	var base_soil_color := Color(0.24, 0.16, 0.10, 0.98)
	var wet_soil_color := Color(0.12, 0.08, 0.05, 0.99)
	var soil_col: Color = wet_soil_color if is_watered else base_soil_color

	var soil_rect := Rect2(-w * 0.5 + 4, -h * 0.5 + 4, w - 8, h - 8)
	draw_rect(soil_rect, soil_col, true)

	# Rich Soil Texture Details
	var speck_color: Color = Color(0.35, 0.25, 0.16, 0.8) if not is_watered else Color(0.18, 0.13, 0.09, 0.9)
	draw_circle(center + Vector2(-16, -4), 1.8, speck_color)
	draw_circle(center + Vector2(14, 6), 2.2, speck_color)
	draw_circle(center + Vector2(-6, 8), 1.6, speck_color)
	draw_circle(center + Vector2(18, -6), 1.8, speck_color)

	# 6. Moisture Sheen Overlay if Watered
	if is_watered:
		var sheen_color := Color(0.35, 0.70, 1.0, 0.22)
		draw_rect(Rect2(-w * 0.5 + 6, -h * 0.5 + 6, w - 12, h - 12), sheen_color, true)

	# 7. Hero Showcase Pedestal & Placard Stake (Plot #24)
	if is_hero_showcase:
		_draw_custom_ellipse(center, (w * 0.5) + 12.0, (h * 0.5) + 8.0, Color(1.0, 0.85, 0.40, 0.18))
		# Wooden Botanical Placard Stake (bottom right)
		var stake_pos := Vector2(w * 0.5 + 2, h * 0.5 - 2)
		draw_line(stake_pos, stake_pos + Vector2(0, 12), Color(0.35, 0.22, 0.12), 2.5)
		draw_rect(Rect2(stake_pos.x - 4, stake_pos.y - 8, 12, 9), Color(0.85, 0.72, 0.52), true)
		draw_rect(Rect2(stake_pos.x - 4, stake_pos.y - 8, 12, 9), Color(0.40, 0.28, 0.16), false, 1.0)

	# 8. Pruning Window Opportunity Badge (Scissors Icon ✂️ & Timer Ring)
	if state == State.GROWING and growth_progress >= 0.60 and growth_progress <= 0.85 and not is_pruned:
		var p_ratio: float = 1.0 - ((growth_progress - 0.60) / 0.25)
		var badge_y: float = -38.0 + sin(_prune_badge_time) * 3.0
		var badge_center := Vector2(0, badge_y)

		# Outer glowing ring
		draw_circle(badge_center, 14.0, Color(1.0, 0.88, 0.35, 0.40))
		draw_circle(badge_center, 11.0, Color(0.18, 0.14, 0.10, 0.95))
		# Timer progress arc
		var arc_pts := PackedVector2Array([badge_center])
		var segs: int = int(p_ratio * 16.0)
		for s in range(segs + 1):
			var a: float = -PI * 0.5 + (float(s) / 16.0) * TAU
			arc_pts.append(badge_center + Vector2(cos(a) * 9.5, sin(a) * 9.5))
		if arc_pts.size() > 2:
			draw_colored_polygon(arc_pts, Color(1.0, 0.85, 0.30, 0.85))
		# Scissors label symbol
		draw_circle(badge_center + Vector2(-3, 2), 2.0, Color.WHITE)
		draw_circle(badge_center + Vector2(3, 2), 2.0, Color.WHITE)
		draw_line(badge_center + Vector2(-3, 2), badge_center + Vector2(3, -4), Color.WHITE, 1.8)
		draw_line(badge_center + Vector2(3, 2), badge_center + Vector2(-3, -4), Color.WHITE, 1.8)

	# 9. Thirsty Plot Alert (Pulsing Water Droplet Icon)
	if state == State.GROWING and not is_watered:
		var drop_y: float = -h * 0.5 - 6.0 + sin(_thirsty_badge_time) * 2.5
		var drop_pos := Vector2(w * 0.5 - 10, drop_y)
		draw_circle(drop_pos, 7.5, Color(0.18, 0.52, 0.95, 0.90))
		draw_circle(drop_pos, 5.0, Color(0.42, 0.78, 1.0, 0.95))
		draw_circle(drop_pos + Vector2(-1.5, -1.5), 1.5, Color.WHITE)

	# 10. Fertilizer Sparkles
	if is_fertilized and state == State.GROWING:
		draw_circle(center + Vector2(-18, -14), 2.2, Color(0.35, 0.95, 0.55, 0.9))
		draw_circle(center + Vector2(18, -10), 2.0, Color(0.35, 0.95, 0.55, 0.9))


func _draw_custom_ellipse(
	center: Vector2,
	radius_x: float,
	radius_y: float,
	color: Color,
	segments: int = 24
) -> void:
	var points := PackedVector2Array()
	for i in range(segments):
		var angle: float = (float(i) / float(segments)) * TAU
		points.append(center + Vector2(cos(angle) * radius_x, sin(angle) * radius_y))
	draw_colored_polygon(points, color)


func _unhandled_input(_event: InputEvent) -> void:
	pass


func set_hovered(hover: bool) -> void:
	if is_hovered != hover:
		is_hovered = hover
		queue_redraw()
		emit_signal("plot_hovered", self, is_hovered)


func set_selected(selected: bool) -> void:
	if is_selected != selected:
		is_selected = selected
		queue_redraw()


func is_point_inside_plot(local_pos: Vector2) -> bool:
	var rx: float = PLOT_WIDTH * 0.5 + 4.0
	var ry: float = PLOT_HEIGHT * 0.5 + 4.0
	return (local_pos.x * local_pos.x) / (rx * rx) + (local_pos.y * local_pos.y) / (ry * ry) <= 1.0


func _play_sfx(sfx_name: String) -> void:
	if is_inside_tree() and has_node("/root/AudioManager"):
		var am = get_node("/root/AudioManager")
		if am != null and am.has_method("play_sfx"):
			am.play_sfx(sfx_name)


func _is_point_inside_plot(local_pos: Vector2) -> bool:
	return is_point_inside_plot(local_pos)
