class_name GardenEnvironment
extends Node2D

## Living Garden Environmental Architecture & Ambient Presentation for BloomHaven.
## Recreates the complete Hero Style Frame:
## - Ancient Oak Tree with birdhouse, warm lantern, and roots (Top-Left)
## - Outdoor Potting Workbench with terracotta pots, clay jars, and seedlings (Top-Left)
## - Rustic White Picket Fence with Climbing Rose Trellises & Birdhouses (Background)
## - Wooden Wheelbarrow with watering can and blooming blue hydrangeas (Bottom-Right)
## - Golden-brown earthen walking paths separating the 4 raised beds and encircling the Hero Plot
## - Ambient drifting petals, pollen motes, and interactive destination click ripples

signal decor_moved(decor_name: String, new_pos: Vector2)

@export var ambient_enabled: bool = true
@export var perspective_mode: int = 1 # 3/4 Angled BloomHaven view

var _anim_time: float = 0.0
var _falling_petals: CPUParticles2D = null
var _firefly_motes: CPUParticles2D = null
var _destination_marker_pos: Vector2 = Vector2.INF
var _destination_marker_alpha: float = 0.0


func _ready() -> void:
	z_index = -2
	z_as_relative = true
	_setup_ambient_particles()
	queue_redraw()


func _setup_ambient_particles() -> void:
	_falling_petals = CPUParticles2D.new()
	_falling_petals.name = "FallingPetals"
	_falling_petals.position = Vector2(0, -320)
	_falling_petals.amount = 20
	_falling_petals.lifetime = 7.0
	_falling_petals.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_falling_petals.emission_rect_extents = Vector2(540, 15)
	_falling_petals.direction = Vector2(0.45, 1.0)
	_falling_petals.spread = 25.0
	_falling_petals.gravity = Vector2(12, 16)
	_falling_petals.initial_velocity_min = 22.0
	_falling_petals.initial_velocity_max = 50.0
	_falling_petals.scale_amount_min = 2.5
	_falling_petals.scale_amount_max = 4.5
	_falling_petals.color = Color(1.0, 0.78, 0.85, 0.75)
	add_child(_falling_petals)

	_firefly_motes = CPUParticles2D.new()
	_firefly_motes.name = "FireflyMotes"
	_firefly_motes.position = Vector2(0, 0)
	_firefly_motes.amount = 14
	_firefly_motes.lifetime = 4.5
	_firefly_motes.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_firefly_motes.emission_rect_extents = Vector2(450, 260)
	_firefly_motes.gravity = Vector2(0, -6)
	_firefly_motes.initial_velocity_min = 5.0
	_firefly_motes.initial_velocity_max = 14.0
	_firefly_motes.scale_amount_min = 2.0
	_firefly_motes.scale_amount_max = 3.5
	_firefly_motes.color = Color(1.0, 0.95, 0.60, 0.65)
	add_child(_firefly_motes)


func show_destination_marker(pos: Vector2) -> void:
	_destination_marker_pos = pos
	_destination_marker_alpha = 1.0


func _process(delta: float) -> void:
	if ambient_enabled:
		_anim_time += delta * 1.5
		if _destination_marker_alpha > 0.0:
			_destination_marker_alpha = max(0.0, _destination_marker_alpha - delta * 2.0)
		queue_redraw()


func _draw() -> void:
	var y_scale := 0.85 if perspective_mode == 1 else 1.0

	# 1. Base Garden Meadow & Earthen Paths
	_draw_garden_terrain(y_scale)

	# 2. Background White Picket Fence & Climbing Trellises
	_draw_background_fence_and_trellises(y_scale)

	# 3. Ancient Oak Tree & Potting Workbench (Top-Left)
	_draw_oak_tree_and_bench(y_scale)

	# 4. Wheelbarrow & Blue Hydrangeas (Bottom-Right)
	_draw_wheelbarrow_and_hydrangeas(y_scale)

	# 5. Picket Fence Corner (Bottom-Left)
	_draw_fence_corner(y_scale)

	# 6. Destination Marker Ripple
	if _destination_marker_alpha > 0.0 and _destination_marker_pos != Vector2.INF:
		var progress: float = 1.0 - _destination_marker_alpha
		var outer_rad: float = 12.0 + progress * 22.0
		var inner_rad: float = 6.0 + progress * 10.0
		# Outer soft gold glow
		_draw_ellipse(_destination_marker_pos, outer_rad + 4.0, (outer_rad + 4.0) * 0.55, Color(1.0, 0.88, 0.35, _destination_marker_alpha * 0.40))
		# Main expanding golden ring
		_draw_ellipse(_destination_marker_pos, outer_rad, outer_rad * 0.55, Color(1.0, 0.85, 0.25, _destination_marker_alpha * 0.70))
		# Inner core
		_draw_ellipse(_destination_marker_pos, inner_rad, inner_rad * 0.55, Color(1.0, 0.96, 0.75, _destination_marker_alpha * 0.90))
		# Tiny four-leaf sparkle motes
		for i in range(4):
			var angle: float = (float(i) / 4.0) * TAU + progress * 1.5
			var mote_offset := Vector2(cos(angle) * outer_rad * 0.85, sin(angle) * outer_rad * 0.50)
			draw_circle(_destination_marker_pos + mote_offset, 2.2 * _destination_marker_alpha, Color(1.0, 0.95, 0.65, _destination_marker_alpha * 0.85))


func _draw_garden_terrain(y_scale: float) -> void:
	# Solid deep lush meadow base
	var meadow_rect := Rect2(-650, -420 * y_scale, 1300, 840 * y_scale)
	draw_rect(meadow_rect, Color(0.18, 0.32, 0.19), true)

	# Natural grass tones & dappled tree shadows
	_draw_ellipse(Vector2(-240, -100 * y_scale), 340.0, 180.0 * y_scale, Color(0.14, 0.26, 0.15, 0.55))
	_draw_ellipse(Vector2(220, 80 * y_scale), 320.0, 160.0 * y_scale, Color(0.22, 0.36, 0.22, 0.45))
	_draw_ellipse(Vector2(0, -150 * y_scale), 380.0, 140.0 * y_scale, Color(0.15, 0.28, 0.16, 0.5))

	# Golden-Brown Earthen Paths separating the 4 raised beds
	var path_base := Color(0.64, 0.50, 0.32, 0.95)
	var path_shadow := Color(0.46, 0.34, 0.20, 0.85)
	var path_light := Color(0.74, 0.60, 0.40, 0.9)

	# Central Vertical Path
	var v_rect := Rect2(-60, -220 * y_scale, 120, 440 * y_scale)
	draw_rect(v_rect, path_base, true)
	_draw_ellipse(Vector2(0, -220 * y_scale), 60.0, 24.0 * y_scale, path_base)
	_draw_ellipse(Vector2(0, 220 * y_scale), 60.0, 24.0 * y_scale, path_base)

	# Central Horizontal Path
	var h_rect := Rect2(-340, -22 * y_scale, 680, 44 * y_scale)
	draw_rect(h_rect, path_base, true)

	# Hero Showcase Circle Surrounding Plot #24
	_draw_ellipse(Vector2(0, 140 * y_scale), 58.0, 42.0 * y_scale, path_base)
	_draw_ellipse(Vector2(0, 140 * y_scale), 52.0, 36.0 * y_scale, path_light)

	# Stepping stones & pebble details along paths
	var pebbles := [
		Vector2(-15, -160 * y_scale), Vector2(18, -110 * y_scale), Vector2(-12, -40 * y_scale),
		Vector2(14, 20 * y_scale),    Vector2(-18, 80 * y_scale),  Vector2(16, 190 * y_scale),
		Vector2(-180, 0),             Vector2(-100, 0),            Vector2(100, 0), Vector2(180, 0)
	]
	for p in pebbles:
		_draw_ellipse(p, 6.0, 4.0 * y_scale, path_shadow)
		_draw_ellipse(p + Vector2(-1, -1), 4.5, 3.0 * y_scale, path_light)


func _draw_background_fence_and_trellises(y_scale: float) -> void:
	var fence_y: float = -205.0 * y_scale
	var fence_col := Color(0.90, 0.88, 0.82)
	var fence_shadow := Color(0.72, 0.70, 0.65)
	var wood_beam := Color(0.78, 0.75, 0.70)

	# Horizontal Rails
	draw_rect(Rect2(-420, fence_y + 12, 840, 6), wood_beam, true)
	draw_rect(Rect2(-420, fence_y + 32, 840, 6), wood_beam, true)

	# Vertical Pickets
	for x in range(-400, 405, 24):
		var picket_h := 46.0
		var top_pts := PackedVector2Array([
			Vector2(x - 6, fence_y + 8),
			Vector2(x, fence_y),
			Vector2(x + 6, fence_y + 8),
			Vector2(x + 6, fence_y + picket_h),
			Vector2(x - 6, fence_y + picket_h)
		])
		draw_colored_polygon(top_pts, fence_shadow)
		var front_pts := PackedVector2Array([
			Vector2(x - 5, fence_y + 9),
			Vector2(x, fence_y + 2),
			Vector2(x + 5, fence_y + 9),
			Vector2(x + 5, fence_y + picket_h - 1),
			Vector2(x - 5, fence_y + picket_h - 1)
		])
		draw_colored_polygon(front_pts, fence_col)

	# Climbing Rose Trellises
	var trellis_x_list := [-180, 180]
	for tx in trellis_x_list:
		var tr_rect := Rect2(tx - 36, fence_y - 30, 72, 65)
		draw_rect(tr_rect, Color(0.38, 0.28, 0.16, 0.85), false, 2.5)
		for lx in range(tx - 30, tx + 35, 12):
			draw_line(Vector2(lx, fence_y - 30), Vector2(lx, fence_y + 35), Color(0.38, 0.28, 0.16, 0.7), 1.5)
		for ly in range(int(fence_y - 25), int(fence_y + 35), 12):
			draw_line(Vector2(tx - 36, ly), Vector2(tx + 36, ly), Color(0.38, 0.28, 0.16, 0.7), 1.5)
		# Climbing Foliage & Pink/Red Roses
		_draw_ellipse(Vector2(tx, fence_y - 5), 32.0, 22.0, Color(0.20, 0.42, 0.22, 0.9))
		_draw_ellipse(Vector2(tx - 12, fence_y - 18), 20.0, 16.0, Color(0.26, 0.50, 0.26, 0.9))
		_draw_ellipse(Vector2(tx + 14, fence_y - 12), 22.0, 18.0, Color(0.24, 0.46, 0.24, 0.9))
		# Rose Blooms on Trellis
		draw_circle(Vector2(tx - 16, fence_y - 10), 4.5, Color(0.92, 0.25, 0.35))
		draw_circle(Vector2(tx + 8, fence_y - 20), 5.0, Color(0.96, 0.45, 0.65))
		draw_circle(Vector2(tx + 18, fence_y), 4.2, Color(0.92, 0.25, 0.35))
		draw_circle(Vector2(tx - 6, fence_y + 12), 4.0, Color(0.96, 0.45, 0.65))

	# Wooden Birdhouse on Post (Right)
	var bh_pos := Vector2(320, fence_y - 20)
	draw_line(bh_pos + Vector2(0, 15), bh_pos + Vector2(0, 40), Color(0.40, 0.28, 0.16), 4.0)
	var house_pts := PackedVector2Array([
		bh_pos + Vector2(-12, 15),
		bh_pos + Vector2(12, 15),
		bh_pos + Vector2(12, -4),
		bh_pos + Vector2(0, -18),
		bh_pos + Vector2(-12, -4)
	])
	draw_colored_polygon(house_pts, Color(0.78, 0.65, 0.48))
	draw_circle(bh_pos + Vector2(0, 2), 3.5, Color(0.18, 0.12, 0.08))


func _draw_oak_tree_and_bench(y_scale: float) -> void:
	var tree_x: float = -340.0
	var tree_y: float = -180.0 * y_scale

	# Trunk & Roots
	var trunk_dark := Color(0.28, 0.18, 0.10)
	var trunk_mid := Color(0.38, 0.26, 0.16)
	var trunk_light := Color(0.48, 0.35, 0.22)

	# Roots spreading into meadow
	draw_line(Vector2(tree_x, tree_y + 40), Vector2(tree_x - 45, tree_y + 75), trunk_dark, 14.0, true)
	draw_line(Vector2(tree_x + 10, tree_y + 40), Vector2(tree_x + 35, tree_y + 70), trunk_dark, 12.0, true)
	draw_line(Vector2(tree_x - 10, tree_y + 20), Vector2(tree_x - 20, tree_y + 80), trunk_mid, 16.0, true)

	# Main Trunk
	var trunk_rect := Rect2(tree_x - 30, tree_y - 80, 60, 130)
	draw_rect(trunk_rect, trunk_mid, true)
	draw_line(Vector2(tree_x - 15, tree_y - 70), Vector2(tree_x - 15, tree_y + 40), trunk_light, 4.0)
	draw_line(Vector2(tree_x + 10, tree_y - 65), Vector2(tree_x + 10, tree_y + 40), trunk_dark, 4.0)

	# Massive Leafy Canopy
	var canopy_dark := Color(0.12, 0.24, 0.14)
	var canopy_mid := Color(0.18, 0.36, 0.20)
	var canopy_light := Color(0.28, 0.50, 0.26)

	_draw_ellipse(Vector2(tree_x - 20, tree_y - 120), 110.0, 75.0, canopy_dark)
	_draw_ellipse(Vector2(tree_x + 30, tree_y - 100), 95.0, 70.0, canopy_dark)
	_draw_ellipse(Vector2(tree_x - 10, tree_y - 110), 95.0, 65.0, canopy_mid)
	_draw_ellipse(Vector2(tree_x + 20, tree_y - 90), 85.0, 60.0, canopy_mid)
	_draw_ellipse(Vector2(tree_x - 5, tree_y - 100), 75.0, 50.0, canopy_light)

	# Wooden Birdhouse on Tree Trunk
	var tb_pos := Vector2(tree_x + 12, tree_y - 15)
	draw_rect(Rect2(tb_pos.x - 8, tb_pos.y - 10, 16, 20), Color(0.70, 0.55, 0.38), true)
	draw_circle(tb_pos + Vector2(0, 0), 2.8, Color(0.15, 0.10, 0.06))

	# Warm Hanging Lantern
	var lan_pos := Vector2(tree_x + 45, tree_y - 45)
	draw_line(lan_pos + Vector2(0, -15), lan_pos, Color(0.2, 0.2, 0.2), 2.0)
	_draw_ellipse(lan_pos + Vector2(0, 6), 22.0, 22.0, Color(1.0, 0.88, 0.45, 0.25))
	draw_rect(Rect2(lan_pos.x - 5, lan_pos.y, 10, 13), Color(0.98, 0.85, 0.40), true)
	draw_rect(Rect2(lan_pos.x - 6, lan_pos.y - 2, 12, 17), Color(0.25, 0.20, 0.15), false, 1.5)

	# Outdoor Potting Workbench (Top-Left)
	var bench_x: float = -285.0
	var bench_y: float = -140.0 * y_scale

	# Bench Legs & Tabletop
	draw_rect(Rect2(bench_x - 38, bench_y + 10, 6, 26), Color(0.35, 0.24, 0.14), true)
	draw_rect(Rect2(bench_x + 32, bench_y + 10, 6, 26), Color(0.35, 0.24, 0.14), true)
	draw_rect(Rect2(bench_x - 42, bench_y, 84, 12), Color(0.52, 0.36, 0.22), true)
	draw_rect(Rect2(bench_x - 42, bench_y, 84, 12), Color(0.35, 0.24, 0.14), false, 1.2)

	# Terracotta Pots & Plants on Bench
	draw_rect(Rect2(bench_x - 30, bench_y - 12, 12, 12), Color(0.78, 0.42, 0.25), true) # Clay pot
	draw_circle(Vector2(bench_x - 24, bench_y - 15), 6.0, Color(0.28, 0.52, 0.26)) # Plant
	draw_rect(Rect2(bench_x - 10, bench_y - 14, 14, 14), Color(0.72, 0.38, 0.22), true) # Clay pot
	draw_circle(Vector2(bench_x - 3, bench_y - 18), 7.0, Color(0.24, 0.48, 0.22)) # Plant
	# Small Blackboard Sign
	draw_rect(Rect2(bench_x + 14, bench_y - 16, 18, 16), Color(0.22, 0.24, 0.22), true)
	draw_rect(Rect2(bench_x + 13, bench_y - 17, 20, 18), Color(0.48, 0.35, 0.20), false, 1.5)


func _draw_wheelbarrow_and_hydrangeas(y_scale: float) -> void:
	var wb_pos := Vector2(275, 170 * y_scale)

	# Wheelbarrow Shadow
	_draw_custom_ellipse(wb_pos + Vector2(0, 18), 34.0, 16.0, Color(0.06, 0.11, 0.07, 0.25))

	# Wooden Wheelbarrow Body
	var wb_pts := PackedVector2Array([
		wb_pos + Vector2(-28, 8),
		wb_pos + Vector2(22, 0),
		wb_pos + Vector2(16, 18),
		wb_pos + Vector2(-22, 22)
	])
	draw_colored_polygon(wb_pts, Color(0.55, 0.38, 0.24))
	draw_line(wb_pos + Vector2(22, 0), wb_pos + Vector2(36, -6), Color(0.40, 0.28, 0.16), 3.5) # Handle
	# Wheel (Front)
	draw_circle(wb_pos + Vector2(-28, 16), 10.0, Color(0.25, 0.25, 0.25))
	draw_circle(wb_pos + Vector2(-28, 16), 7.0, Color(0.45, 0.45, 0.45))
	draw_circle(wb_pos + Vector2(-28, 16), 2.5, Color(0.15, 0.15, 0.15))
	# Watering Can inside Wheelbarrow
	draw_rect(Rect2(wb_pos.x - 8, wb_pos.y - 6, 14, 12), Color(0.82, 0.80, 0.74), true)
	draw_line(wb_pos + Vector2(-8, 0), wb_pos + Vector2(-16, -6), Color(0.82, 0.80, 0.74), 2.5) # Spout

	# Blooming Blue Hydrangea Bush (Next to Wheelbarrow)
	var hyd_pos := Vector2(325, 185 * y_scale)
	_draw_custom_ellipse(hyd_pos + Vector2(0, 16), 28.0, 14.0, Color(0.06, 0.11, 0.07, 0.25)) # Shadow
	# Terracotta Pot
	var pot_pts := PackedVector2Array([
		hyd_pos + Vector2(-16, 6),
		hyd_pos + Vector2(16, 6),
		hyd_pos + Vector2(12, 24),
		hyd_pos + Vector2(-12, 24)
	])
	draw_colored_polygon(pot_pts, Color(0.78, 0.44, 0.26))
	# Hydrangea Foliage
	_draw_ellipse(hyd_pos + Vector2(0, -6), 28.0, 20.0, Color(0.18, 0.40, 0.22))
	# Blue Mophead Flower Clusters
	_draw_ellipse(hyd_pos + Vector2(-10, -12), 16.0, 14.0, Color(0.38, 0.62, 0.95))
	_draw_ellipse(hyd_pos + Vector2(10, -10), 16.0, 14.0, Color(0.48, 0.70, 0.98))
	_draw_ellipse(hyd_pos + Vector2(0, -18), 18.0, 15.0, Color(0.32, 0.55, 0.92))
	# Florets highlights
	draw_circle(hyd_pos + Vector2(-10, -12), 3.0, Color(0.75, 0.88, 1.0))
	draw_circle(hyd_pos + Vector2(10, -10), 3.0, Color(0.75, 0.88, 1.0))
	draw_circle(hyd_pos + Vector2(0, -18), 3.2, Color(0.80, 0.92, 1.0))


func _draw_fence_corner(y_scale: float) -> void:
	var fc_pos := Vector2(-330, 185 * y_scale)
	_draw_custom_ellipse(fc_pos + Vector2(0, 14), 22.0, 10.0, Color(0.06, 0.11, 0.07, 0.25))
	# Picket corner post
	draw_rect(Rect2(fc_pos.x - 6, fc_pos.y - 20, 12, 34), Color(0.88, 0.85, 0.80), true)
	draw_rect(Rect2(fc_pos.x - 8, fc_pos.y - 24, 16, 6), Color(0.95, 0.92, 0.88), true)
	# Little stone birdhouse atop
	draw_rect(Rect2(fc_pos.x - 7, fc_pos.y - 38, 14, 14), Color(0.65, 0.62, 0.58), true)
	draw_circle(fc_pos + Vector2(0, -31), 2.5, Color(0.18, 0.15, 0.12))


func _draw_ellipse(center: Vector2, rx: float, ry: float, col: Color, segments: int = 24) -> void:
	var points := PackedVector2Array()
	for i in range(segments):
		var angle: float = (float(i) / float(segments)) * TAU
		points.append(center + Vector2(cos(angle) * rx, sin(angle) * ry))
	draw_colored_polygon(points, col)


func _draw_custom_ellipse(center: Vector2, rx: float, ry: float, col: Color, segments: int = 24) -> void:
	_draw_ellipse(center, rx, ry, col, segments)
