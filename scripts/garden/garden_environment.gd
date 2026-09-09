class_name GardenEnvironment
extends Node2D

## Living Garden Environmental Architecture & Ambient Presentation for BloomHaven.
## Assembles the complete 2.5D Isometric Handcrafted Architecture:
## - 2.5D Meadow Island terrain base with natural soil paths & stone borders
## - Layered Cottage (walls + see-through occluded roof on Lily approach)
## - Ancient Oak Tree (Y-sorted trunk + breeze-swayed canopy)
## - Interactive Beehive Landmark with orbiting golden bee motes
## - Modular rustic white/wood fences & open boundary gate
## - Botanical foliage shrubs (flowering, boxwood, low shrub, round, ivy)
## - Foreground leafy canopy vignette framing the top screen
## - Ambient drifting petals, firefly motes, and interactive destination ripples

signal decor_moved(decor_name: String, new_pos: Vector2)

@export var ambient_enabled: bool = true
@export var perspective_mode: int = 1 # 3/4 Angled BloomHaven view

# Master 2.5D Environmental Sprites
const TEX_ISLAND := preload("res://assets/environment/terrain/terrain_island_meadow.png")
const TEX_COTTAGE_BASE := preload("res://assets/environment/cottage/cottage_base.png")
const TEX_COTTAGE_ROOF := preload("res://assets/environment/cottage/cottage_roof.png")
const TEX_OAK_TRUNK := preload("res://assets/environment/trees/oak_trunk.png")
const TEX_OAK_CANOPY := preload("res://assets/environment/trees/oak_canopy.png")
const TEX_VIGNETTE := preload("res://assets/environment/trees/foreground_canopy_vignette.png")
const TEX_BEEHIVE := preload("res://assets/environment/plots/decor_beehive.png")

# Foliage Bushes
const TEX_BUSH_FLOWERING := preload("res://assets/environment/foliage/bush_flowering.png")
const TEX_BUSH_BOXWOOD := preload("res://assets/environment/foliage/bush_boxwood_sphere.png")
const TEX_BUSH_LOW := preload("res://assets/environment/foliage/bush_low_shrub.png")
const TEX_BUSH_ROUND := preload("res://assets/environment/foliage/bush_round_dense.png")
const TEX_BUSH_IVY := preload("res://assets/environment/foliage/bush_ivy_patch.png")

# Fences & Gates
const TEX_FENCE_STRAIGHT := preload("res://assets/environment/fences/fence_straight.png")
const TEX_FENCE_CORNER_LEFT := preload("res://assets/environment/fences/fence_corner_left.png")
const TEX_FENCE_CORNER_RIGHT := preload("res://assets/environment/fences/fence_corner_right.png")
const TEX_GATE_OPEN := preload("res://assets/environment/fences/gate_open.png")

var _anim_time: float = 0.0
var _falling_petals: CPUParticles2D = null
var _firefly_motes: CPUParticles2D = null
var _destination_marker_pos: Vector2 = Vector2.INF
var _destination_marker_alpha: float = 0.0

# 2.5D Node References
var _spr_island: Sprite2D = null
var _cottage_node: Node2D = null
var _cottage_base: Sprite2D = null
var _cottage_roof: Sprite2D = null
var _oak_node: Node2D = null
var _oak_trunk: Sprite2D = null
var _oak_canopy: Sprite2D = null
var _beehive: Sprite2D = null
var _bee_particles: CPUParticles2D = null
var _vignette: Sprite2D = null
var _foliage_container: Node2D = null
var _fence_container: Node2D = null


func _ready() -> void:
	z_index = 0
	z_as_relative = true
	_setup_environment_sprites()
	_setup_ambient_particles()
	queue_redraw()


func _setup_environment_sprites() -> void:
	# 1. Meadow Island Base (Deep background under all plots, paths, and flowers)
	_spr_island = Sprite2D.new()
	_spr_island.name = "MeadowIsland"
	_spr_island.texture = TEX_ISLAND
	_spr_island.centered = true
	_spr_island.position = Vector2(0, 15)
	_spr_island.scale = Vector2(0.90, 0.90)
	_spr_island.z_index = -5
	_spr_island.z_as_relative = false
	add_child(_spr_island)

	# 2. Rustic Fences Container
	_fence_container = Node2D.new()
	_fence_container.name = "Fences"
	_fence_container.z_index = -1
	_fence_container.z_as_relative = false
	add_child(_fence_container)

	_create_sprite(_fence_container, TEX_FENCE_CORNER_LEFT, Vector2(-260, -180), Vector2(0.18, 0.18), Vector2(0, -50))
	_create_sprite(_fence_container, TEX_FENCE_STRAIGHT, Vector2(-160, -185), Vector2(0.18, 0.18), Vector2(0, -50))
	_create_sprite(_fence_container, TEX_GATE_OPEN, Vector2(0, -185), Vector2(0.18, 0.18), Vector2(0, -50))
	_create_sprite(_fence_container, TEX_FENCE_STRAIGHT, Vector2(160, -185), Vector2(0.18, 0.18), Vector2(0, -50))
	_create_sprite(_fence_container, TEX_FENCE_CORNER_RIGHT, Vector2(250, -180), Vector2(0.18, 0.18), Vector2(0, -50))

	# 3. Foliage Bushes Container
	_foliage_container = Node2D.new()
	_foliage_container.name = "Foliage"
	_foliage_container.y_sort_enabled = true
	_foliage_container.z_index = 0
	add_child(_foliage_container)

	_create_sprite(_foliage_container, TEX_BUSH_FLOWERING, Vector2(-360, -20), Vector2(0.16, 0.16), Vector2(0, -80))
	_create_sprite(_foliage_container, TEX_BUSH_BOXWOOD, Vector2(-45, -185), Vector2(0.14, 0.14), Vector2(0, -80))
	_create_sprite(_foliage_container, TEX_BUSH_BOXWOOD, Vector2(45, -185), Vector2(0.14, 0.14), Vector2(0, -80))
	_create_sprite(_foliage_container, TEX_BUSH_LOW, Vector2(-280, 210), Vector2(0.16, 0.16), Vector2(0, -50))
	_create_sprite(_foliage_container, TEX_BUSH_ROUND, Vector2(290, 210), Vector2(0.16, 0.16), Vector2(0, -80))
	_create_sprite(_foliage_container, TEX_BUSH_IVY, Vector2(245, -150), Vector2(0.15, 0.15), Vector2(0, -60))

	# 4. Interactive Beehive Landmark
	_beehive = Sprite2D.new()
	_beehive.name = "Beehive"
	_beehive.texture = TEX_BEEHIVE
	_beehive.centered = true
	_beehive.position = Vector2(320, 60)
	_beehive.offset = Vector2(0, -120)
	_beehive.scale = Vector2(0.16, 0.16)
	_beehive.z_index = 0
	add_child(_beehive)

	_bee_particles = CPUParticles2D.new()
	_bee_particles.name = "BeeParticles"
	_bee_particles.position = Vector2(320, 42)
	_bee_particles.amount = 6
	_bee_particles.lifetime = 1.8
	_bee_particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	_bee_particles.emission_sphere_radius = 16.0
	_bee_particles.direction = Vector2(0, -1)
	_bee_particles.spread = 180.0
	_bee_particles.gravity = Vector2(0, 0)
	_bee_particles.initial_velocity_min = 10.0
	_bee_particles.initial_velocity_max = 22.0
	_bee_particles.damping_min = 15.0
	_bee_particles.damping_max = 25.0
	_bee_particles.scale_amount_min = 2.0
	_bee_particles.scale_amount_max = 3.5
	_bee_particles.color = Color(1.0, 0.88, 0.25, 0.9)
	add_child(_bee_particles)

	# 5. Ancient Oak Tree (Top-Left)
	_oak_node = Node2D.new()
	_oak_node.name = "AncientOakTree"
	_oak_node.position = Vector2(-330, -140)
	_oak_node.y_sort_enabled = true
	add_child(_oak_node)

	_oak_trunk = Sprite2D.new()
	_oak_trunk.name = "OakTrunk"
	_oak_trunk.texture = TEX_OAK_TRUNK
	_oak_trunk.centered = true
	_oak_trunk.offset = Vector2(0, -350)
	_oak_trunk.scale = Vector2(0.22, 0.22)
	_oak_trunk.z_index = 0
	_oak_node.add_child(_oak_trunk)

	_oak_canopy = Sprite2D.new()
	_oak_canopy.name = "OakCanopy"
	_oak_canopy.texture = TEX_OAK_CANOPY
	_oak_canopy.centered = true
	_oak_canopy.offset = Vector2(0, -350)
	_oak_canopy.scale = Vector2(0.22, 0.22)
	_oak_canopy.z_index = 3
	_oak_canopy.z_as_relative = false
	_oak_node.add_child(_oak_canopy)

	# 6. Layered Cottage (Top-Right)
	_cottage_node = Node2D.new()
	_cottage_node.name = "LayeredCottage"
	_cottage_node.position = Vector2(275, -150)
	_cottage_node.y_sort_enabled = true
	add_child(_cottage_node)

	_cottage_base = Sprite2D.new()
	_cottage_base.name = "CottageBase"
	_cottage_base.texture = TEX_COTTAGE_BASE
	_cottage_base.centered = true
	_cottage_base.offset = Vector2(0, -350)
	_cottage_base.scale = Vector2(0.20, 0.20)
	_cottage_base.z_index = 0
	_cottage_node.add_child(_cottage_base)

	_cottage_roof = Sprite2D.new()
	_cottage_roof.name = "CottageRoof"
	_cottage_roof.texture = TEX_COTTAGE_ROOF
	_cottage_roof.centered = true
	_cottage_roof.offset = Vector2(0, -350)
	_cottage_roof.scale = Vector2(0.20, 0.20)
	_cottage_roof.z_index = 2
	_cottage_roof.z_as_relative = false
	_cottage_node.add_child(_cottage_roof)

	# 7. Foreground Canopy Vignette (Screen Framing)
	_vignette = Sprite2D.new()
	_vignette.name = "ForegroundCanopyVignette"
	_vignette.texture = TEX_VIGNETTE
	_vignette.centered = true
	_vignette.position = Vector2(0, -220)
	_vignette.scale = Vector2(0.85, 0.85)
	_vignette.z_index = 10
	_vignette.z_as_relative = false
	_vignette.modulate = Color(1.0, 1.0, 1.0, 0.95)
	add_child(_vignette)


func _create_sprite(parent: Node, tex: Texture2D, pos: Vector2, scl: Vector2, off: Vector2 = Vector2.ZERO) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = tex
	s.centered = true
	s.position = pos
	s.scale = scl
	s.offset = off
	parent.add_child(s)
	return s


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

		# Tree Canopy Breeze Sway
		if is_instance_valid(_oak_canopy):
			_oak_canopy.rotation = sin(_anim_time * 0.9) * 0.02
			_oak_canopy.position = Vector2(sin(_anim_time * 0.7) * 1.5, 0)

		# Layered Cottage Roof See-through Occlusion when Lily approaches
		if is_instance_valid(_cottage_roof) and is_instance_valid(_cottage_node):
			var target_alpha := 1.0
			var parent := get_parent()
			if parent != null:
				var lily := parent.get_node_or_null("GardenerCharacter")
				if lily != null:
					var dist: float = lily.global_position.distance_to(_cottage_node.global_position + Vector2(-30, 40))
					if dist < 150.0:
						target_alpha = 0.35
			_cottage_roof.modulate.a = lerp(_cottage_roof.modulate.a, target_alpha, delta * 4.0)

		queue_redraw()


func _draw() -> void:
	# Fallback to vector terrain only if sprite island was not instantiated
	if not is_instance_valid(_spr_island):
		var y_scale := 0.85 if perspective_mode == 1 else 1.0
		_draw_garden_terrain(y_scale)
		_draw_background_fence_and_trellises(y_scale)
		_draw_oak_tree_and_bench(y_scale)
		_draw_wheelbarrow_and_hydrangeas(y_scale)
		_draw_fence_corner(y_scale)

	# Destination Marker Ripple
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
