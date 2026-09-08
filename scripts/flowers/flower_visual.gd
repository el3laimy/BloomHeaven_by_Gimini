class_name FlowerVisual
extends Node2D

## Procedural visual representation for Base and Hybrid flowers with heritable trait genetics (P3).
## Supports dynamic phenotype coloring, distinct petal geometry (Round, Star, Pointed),
## vigor scaling (0.95x to 1.15x), and mature fragrance shimmer particles.

enum Stage {
	SEED = 0,
	SPROUT = 1,
	VEGETATIVE = 2,
	BLOOMING = 3
}

@export var flower_id: String = "rose":
	set(val):
		flower_id = val
		_data = FlowerData.get_flower(flower_id)
		queue_redraw()

@export var current_stage: Stage = Stage.SEED:
	set(val):
		if current_stage != val:
			var prev := current_stage
			current_stage = val
			_on_stage_changed(prev, val)
		queue_redraw()

@export var is_mystery: bool = false:
	set(val):
		is_mystery = val
		queue_redraw()

@export var is_revealed: bool = true:
	set(val):
		is_revealed = val
		queue_redraw()

var phenotype: FlowerPhenotype = null:
	set(val):
		phenotype = val
		queue_redraw()

@export var is_pruned: bool = false:
	set(val):
		is_pruned = val
		queue_redraw()

@export var sway_enabled: bool = true

var _data: Dictionary = {}
var _sway_time: float = 0.0
var _sway_offset: float = 0.0
var _branch_sprite: Sprite2D = null


func _ready() -> void:
	_data = FlowerData.get_flower(flower_id)
	_sway_offset = randf() * 100.0
	_setup_branch_sprite()
	queue_redraw()


func _setup_branch_sprite() -> void:
	if not is_instance_valid(_branch_sprite):
		_branch_sprite = Sprite2D.new()
		_branch_sprite.name = "BranchSprite"
		_branch_sprite.visible = false
		_branch_sprite.centered = true
		add_child(_branch_sprite)


func _process(delta: float) -> void:
	rotation = 0.0
	if sway_enabled and (current_stage == Stage.VEGETATIVE or current_stage == Stage.BLOOMING):
		_sway_time += delta * 1.8
		var sway_skew: float = sin(_sway_time + _sway_offset) * 0.05
		if current_stage == Stage.BLOOMING:
			sway_skew = sin(_sway_time + _sway_offset) * 0.075
		if is_instance_valid(_branch_sprite):
			_branch_sprite.skew = sway_skew
			_branch_sprite.rotation = 0.0
	else:
		if is_instance_valid(_branch_sprite):
			_branch_sprite.skew = 0.0
			_branch_sprite.rotation = 0.0


func _on_stage_changed(_prev: Stage, _next: Stage) -> void:
	var tween := create_tween()
	scale = Vector2(0.6, 0.6)
	tween.tween_property(self, "scale", Vector2(1.15, 1.15), 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.12).set_trans(Tween.TRANS_SINE)


func _draw() -> void:
	if _data.is_empty():
		_data = FlowerData.get_flower(flower_id)

	# If flower has dedicated branching stage textures from BloomHeaven
	if _update_branching_sprite():
		_draw_custom_ellipse(Vector2(0, 4), 16.0, 8.0, Color(0.04, 0.08, 0.05, 0.35))
		if is_pruned and current_stage == Stage.BLOOMING:
			# Golden Shimmer Aura for Pruned Hero Bloom
			_draw_custom_ellipse(Vector2(0, -32), 34.0, 34.0, Color(1.0, 0.88, 0.35, 0.22))
			_draw_custom_ellipse(Vector2(0, -32), 24.0, 24.0, Color(1.0, 0.95, 0.55, 0.25))
			draw_circle(Vector2(-24, -48), 2.5, Color(1.0, 0.95, 0.6, 0.9))
			draw_circle(Vector2(26, -42), 2.2, Color(1.0, 0.95, 0.6, 0.9))
			draw_circle(Vector2(-18, -16), 1.8, Color(1.0, 0.95, 0.6, 0.85))
			draw_circle(Vector2(22, -18), 2.0, Color(1.0, 0.95, 0.6, 0.85))
		return

	var primary_col: Color = _data.get("primary_color", Color.RED)
	var secondary_col: Color = _data.get("secondary_color", Color.DARK_RED)
	var accent_col: Color = _data.get("accent_color", Color.PINK)
	var stem_col: Color = _data.get("stem_color", Color(0.18, 0.44, 0.16))
	var leaf_col: Color = _data.get("leaf_color", Color(0.24, 0.58, 0.22))
	var petal_form: String = "round"
	var vigor_scale: float = 1.0
	var fragrance_rating: int = 1

	if phenotype != null:
		petal_form = phenotype.petal_form
		vigor_scale = phenotype.visual_scale
		fragrance_rating = phenotype.fragrance_rating
		if phenotype.color_tint != Color.WHITE:
			primary_col = phenotype.color_tint
			secondary_col = phenotype.color_tint.darkened(0.25)
			accent_col = phenotype.color_tint.lightened(0.25)

	match current_stage:
		Stage.SEED:
			_draw_seed_stage()
		Stage.SPROUT:
			_draw_sprout_stage(leaf_col, stem_col)
		Stage.VEGETATIVE:
			_draw_vegetative_stage(stem_col, leaf_col, primary_col)
		Stage.BLOOMING:
			_draw_blooming_stage(primary_col, secondary_col, accent_col, stem_col, leaf_col, petal_form, vigor_scale, fragrance_rating)


static var _growth_tex_cache: Dictionary = {}

static func _load_cached_tex(path: String) -> Texture2D:
	if _growth_tex_cache.has(path):
		return _growth_tex_cache[path]
	if ResourceLoader.exists(path):
		var tex := load(path) as Texture2D
		_growth_tex_cache[path] = tex
		return tex
	return null


func _update_branching_sprite() -> bool:
	if not is_instance_valid(_branch_sprite):
		_setup_branch_sprite()

	if current_stage == Stage.SEED:
		if is_instance_valid(_branch_sprite):
			_branch_sprite.visible = false
		return false

	var sp_key := _get_species_key()
	var tex: Texture2D = null

	match current_stage:
		Stage.SPROUT:
			var sprout_sp := sp_key
			if sprout_sp == "sunflower" or sprout_sp.is_empty():
				sprout_sp = "daisy"
			elif sprout_sp in ["roselight", "golden_rose"]:
				sprout_sp = "rose_crimson"
			tex = _load_cached_tex("res://assets/flowers/growth_stages/%s_sprout.png" % sprout_sp)

		Stage.VEGETATIVE:
			var veg_sp := sp_key
			if veg_sp == "sunflower" or veg_sp.is_empty():
				veg_sp = "daisy"
			elif veg_sp in ["roselight", "golden_rose"]:
				veg_sp = "rose_crimson"
			var veg_suffix := "veg_single" if is_pruned else "veg_bush"
			tex = _load_cached_tex("res://assets/flowers/growth_stages/%s_%s.png" % [veg_sp, veg_suffix])
			if tex == null:
				tex = _load_cached_tex("res://assets/flowers/growth_stages/%s_veg_bush.png" % veg_sp)

		Stage.BLOOMING:
			if flower_id == "sunflower":
				tex = _load_cached_tex("res://assets/flowers/master_sunflower.png")
			elif flower_id == "roselight":
				tex = _load_cached_tex("res://assets/flowers/master_roselight.png")
			elif flower_id == "golden_rose":
				tex = _load_cached_tex("res://assets/flowers/master_golden_rose.png")
			elif flower_id == "sunflare_spike":
				tex = _load_cached_tex("res://assets/flowers/master_sunflare_spike.png")
			else:
				var bloom_sp := sp_key if not sp_key.is_empty() else "rose_crimson"
				var bloom_suffix := "bloom_premium" if is_pruned else "bloom_standard"
				tex = _load_cached_tex("res://assets/flowers/growth_stages/%s_%s.png" % [bloom_sp, bloom_suffix])
				if tex == null:
					tex = _load_cached_tex("res://assets/flowers/growth_stages/%s_bloom_standard.png" % bloom_sp)

	if tex != null and is_instance_valid(_branch_sprite):
		_branch_sprite.texture = tex
		_branch_sprite.visible = true

		var target_height: float = 64.0
		if current_stage == Stage.SPROUT:
			target_height = 38.0
		elif current_stage == Stage.VEGETATIVE:
			target_height = 52.0
		elif current_stage == Stage.BLOOMING:
			target_height = 80.0 if is_pruned else 66.0

		var s: float = target_height / float(tex.get_height())
		_branch_sprite.scale = Vector2(s, s)
		_branch_sprite.offset = Vector2(0, -tex.get_height() * 0.5)
		_branch_sprite.position = Vector2(0, 2.0)
		return true

	if is_instance_valid(_branch_sprite):
		_branch_sprite.visible = false
	return false


func _draw_seed_stage() -> void:
	if is_instance_valid(_branch_sprite):
		_branch_sprite.visible = false

	var mound_col := Color(0.24, 0.16, 0.10, 0.95)
	var crumb_col := Color(0.38, 0.26, 0.16, 1.0)
	var seed_marker := Color(0.85, 0.72, 0.45, 0.9) if not is_mystery else Color(0.95, 0.85, 0.35, 1.0)

	_draw_custom_ellipse(Vector2(0, 4), 16.0, 9.0, mound_col)
	draw_circle(Vector2(-6, 3), 2.2, crumb_col)
	draw_circle(Vector2(4, 5), 2.8, crumb_col)
	draw_circle(Vector2(0, 1), 1.8, crumb_col)
	
	# Seed marker
	_draw_custom_ellipse(Vector2(0, 2), 3.2, 2.0, seed_marker)

	# Mystery shimmer aura on unknown seeds
	if is_mystery:
		draw_circle(Vector2(-7, -4), 1.6, Color(1.0, 0.9, 0.5, 0.8))
		draw_circle(Vector2(6, -5), 1.4, Color(1.0, 0.95, 0.6, 0.7))


func _get_species_key() -> String:
	match flower_id:
		"rose":
			return "rose_crimson"
		"rose_cream":
			return "rose_cream"
		"lavender":
			return "lavender"
		"tulip":
			return "tulip"
		"daisy":
			return "daisy"
		"sunflower":
			return "sunflower"
		"roselight":
			return "roselight"
		"golden_rose":
			return "golden_rose"
		"sunflare_spike":
			return "sunflare_spike"
		_:
			return "rose_crimson"


func _get_growth_sprite(stage_suffix: String) -> Texture2D:
	var sp_key := _get_species_key()
	if sp_key != "":
		var p := "res://assets/flowers/growth_stages/%s_%s.png" % [sp_key, stage_suffix]
		if ResourceLoader.exists(p):
			return load(p)
	return null


func _draw_sprout_stage(leaf_col: Color, stem_col: Color) -> void:
	# Soft grounding shadow
	_draw_custom_ellipse(Vector2(1, 4), 10.0, 4.5, Color(0.06, 0.11, 0.07, 0.25))

	if not is_mystery or is_revealed:
		var tex := _get_growth_sprite("sprout")
		if tex != null:
			var spr_w := 34.0
			var spr_h := 48.0
			if is_instance_valid(_branch_sprite):
				_branch_sprite.texture = tex
				_branch_sprite.scale = Vector2(spr_w / float(tex.get_width()), spr_h / float(tex.get_height()))
				_branch_sprite.offset = Vector2(0, -tex.get_height() * 0.5)
				_branch_sprite.position = Vector2(0, 4.0)
				_branch_sprite.visible = true
			return

	if is_instance_valid(_branch_sprite):
		_branch_sprite.visible = false

	# Procedural Sprout Fallback / Mystery Seed Sprout
	draw_line(Vector2(0, 6), Vector2(0, -10), stem_col, 3.0, true)

	var leaf_left := PackedVector2Array([
		Vector2(0, -8),
		Vector2(-9, -14),
		Vector2(-6, -18),
		Vector2(0, -12)
	])
	draw_colored_polygon(leaf_left, leaf_col)

	var leaf_right := PackedVector2Array([
		Vector2(0, -9),
		Vector2(9, -15),
		Vector2(6, -19),
		Vector2(0, -13)
	])
	draw_colored_polygon(leaf_right, leaf_col.lightened(0.12))

	_draw_custom_ellipse(Vector2(0, 6), 11.0, 5.0, Color(0.22, 0.14, 0.08, 0.9))

	if is_mystery:
		draw_circle(Vector2(0, -13), 2.5, Color(1.0, 0.92, 0.45, 0.85))


func _draw_vegetative_stage(stem_col: Color, leaf_col: Color, bud_col: Color) -> void:
	# Soft grounding shadow
	_draw_custom_ellipse(Vector2(2, 4), 12.0, 5.5, Color(0.06, 0.11, 0.07, 0.25))

	if not is_mystery or is_revealed:
		var veg_key := "veg_single" if is_pruned else "veg_bush"
		var tex := _get_growth_sprite(veg_key)
		if tex == null:
			tex = _get_growth_sprite("veg_bush")
		if tex != null:
			var spr_w := 46.0
			var spr_h := 58.0
			if is_instance_valid(_branch_sprite):
				_branch_sprite.texture = tex
				_branch_sprite.scale = Vector2(spr_w / float(tex.get_width()), spr_h / float(tex.get_height()))
				_branch_sprite.offset = Vector2(0, -tex.get_height() * 0.5)
				_branch_sprite.position = Vector2(0, 4.0)
				_branch_sprite.visible = true
			return

	if is_instance_valid(_branch_sprite):
		_branch_sprite.visible = false

	# Procedural Vegetative Fallback / Mystery Seed Bud
	draw_line(Vector2(0, 8), Vector2(0, -22), stem_col, 4.2, true)

	draw_line(Vector2(0, -4), Vector2(-12, -12), stem_col, 3.0, true)
	var leaf1 := PackedVector2Array([
		Vector2(-12, -12),
		Vector2(-19, -18),
		Vector2(-14, -22),
		Vector2(-8, -15)
	])
	draw_colored_polygon(leaf1, leaf_col)

	draw_line(Vector2(0, -10), Vector2(13, -17), stem_col, 3.0, true)
	var leaf2 := PackedVector2Array([
		Vector2(13, -17),
		Vector2(20, -23),
		Vector2(16, -27),
		Vector2(9, -20)
	])
	draw_colored_polygon(leaf2, leaf_col)

	var leaf3 := PackedVector2Array([
		Vector2(0, -1),
		Vector2(-10, -5),
		Vector2(-8, -9),
		Vector2(0, -6)
	])
	draw_colored_polygon(leaf3, leaf_col.darkened(0.15))

	var bud_actual_col := bud_col if not is_mystery else Color(0.9, 0.82, 0.45)
	var bud_accent := bud_actual_col.lightened(0.25)
	
	_draw_custom_ellipse(Vector2(0, -23), 6.5, 8.5, stem_col)
	
	draw_circle(Vector2(-2, -26), 4.0, bud_actual_col)
	draw_circle(Vector2(2, -26), 4.0, bud_actual_col)
	draw_circle(Vector2(0, -28), 3.2, bud_accent)

	if is_mystery:
		draw_circle(Vector2(0, -31), 2.2, Color(1.0, 0.95, 0.6, 0.9))


func _draw_blooming_stage(
	primary_col: Color,
	secondary_col: Color,
	accent_col: Color,
	stem_col: Color,
	leaf_col: Color,
	petal_form: String,
	vigor_scale: float,
	fragrance_rating: int
) -> void:
	if is_pruned:
		vigor_scale = max(vigor_scale, 1.65)
		# Golden Shimmer Aura for Pruned Hero Bloom
		_draw_custom_ellipse(Vector2(0, -32), 34.0, 34.0, Color(1.0, 0.88, 0.35, 0.22))
		_draw_custom_ellipse(Vector2(0, -32), 24.0, 24.0, Color(1.0, 0.95, 0.55, 0.25))
		draw_circle(Vector2(-24, -48), 2.5, Color(1.0, 0.95, 0.6, 0.9))
		draw_circle(Vector2(26, -42), 2.2, Color(1.0, 0.95, 0.6, 0.9))
		draw_circle(Vector2(-18, -16), 1.8, Color(1.0, 0.95, 0.6, 0.85))
		draw_circle(Vector2(22, -18), 2.0, Color(1.0, 0.95, 0.6, 0.85))

	# Soft Warm Grounding Shadow at stem base
	_draw_custom_ellipse(Vector2(2, 4), 14.0 * vigor_scale, 6.0 * vigor_scale, Color(0.06, 0.11, 0.07, 0.25))

	var tex: Texture2D = null

	# 1. Check for Dedicated Master Growth Sheet Stage (Standard vs Premium)
	var bloom_key := "bloom_premium" if (vigor_scale > 1.1 or is_pruned) else "bloom_standard"
	tex = _get_growth_sprite(bloom_key)
	if tex == null and bloom_key == "bloom_premium":
		tex = _get_growth_sprite("bloom_standard")

	# 2. Check for Dedicated Hybrid Specimen Sprites
	if tex == null:
		if flower_id == "roselight":
			match petal_form:
				"star":
					if ResourceLoader.exists("res://assets/flowers/roselight_specimen_b.png"):
						tex = load("res://assets/flowers/roselight_specimen_b.png")
				"pointed":
					if ResourceLoader.exists("res://assets/flowers/roselight_specimen_c.png"):
						tex = load("res://assets/flowers/roselight_specimen_c.png")
				_:
					if ResourceLoader.exists("res://assets/flowers/roselight_specimen_a.png"):
						tex = load("res://assets/flowers/roselight_specimen_a.png")
		elif flower_id == "rose" and vigor_scale > 1.1:
			if ResourceLoader.exists("res://assets/flowers/rose_premium_form.png"):
				tex = load("res://assets/flowers/rose_premium_form.png")
			elif ResourceLoader.exists("res://assets/flowers/master_rose.png"):
				tex = load("res://assets/flowers/master_rose.png")
		elif flower_id == "rose" and ResourceLoader.exists("res://assets/flowers/rose_standard_form.png"):
			tex = load("res://assets/flowers/rose_standard_form.png")
		else:
			var tex_path := "res://assets/flowers/master_%s.png" % flower_id
			if ResourceLoader.exists(tex_path):
				tex = load(tex_path)

	if tex != null:
		var spr_w: float = 52.0 * vigor_scale
		var spr_h: float = 68.0 * vigor_scale
		if is_instance_valid(_branch_sprite):
			_branch_sprite.texture = tex
			_branch_sprite.scale = Vector2(spr_w / float(tex.get_width()), spr_h / float(tex.get_height()))
			_branch_sprite.offset = Vector2(0, -tex.get_height() * 0.5)
			_branch_sprite.position = Vector2(0, 4.0)
			_branch_sprite.visible = true
	else:
		if is_instance_valid(_branch_sprite):
			_branch_sprite.visible = false
		# Fallback to procedural vector rendering
		match flower_id:
			"rose":
				_draw_blooming_rose(primary_col, secondary_col, accent_col, stem_col, leaf_col, petal_form, vigor_scale)
			"lavender":
				_draw_blooming_lavender(primary_col, secondary_col, accent_col, stem_col, leaf_col, petal_form, vigor_scale)
			"sunflower":
				_draw_blooming_sunflower(primary_col, secondary_col, accent_col, stem_col, leaf_col, petal_form, vigor_scale)
			"roselight":
				_draw_blooming_roselight(primary_col, secondary_col, accent_col, stem_col, leaf_col, petal_form, vigor_scale)
			"golden_rose":
				_draw_blooming_golden_rose(primary_col, secondary_col, accent_col, stem_col, leaf_col, petal_form, vigor_scale)
			"sunflare_spike":
				_draw_blooming_sunflare_spike(primary_col, secondary_col, accent_col, stem_col, leaf_col, petal_form, vigor_scale)
			_:
				_draw_blooming_rose(primary_col, secondary_col, accent_col, stem_col, leaf_col, petal_form, vigor_scale)

	# Mature Aroma Shimmer Particles (Fragrance >= 3)
	if fragrance_rating >= 3 and (not is_mystery or is_revealed):
		_draw_fragrance_shimmer(fragrance_rating)


func _draw_fragrance_shimmer(rating: int) -> void:
	var shimmer_col := Color(1.0, 0.95, 0.65, 0.75 if rating >= 4 else 0.5)
	draw_circle(Vector2(-14, -46), 1.8, shimmer_col)
	draw_circle(Vector2(12, -50), 2.2, shimmer_col)
	draw_circle(Vector2(0, -56), 2.6, shimmer_col)
	if rating >= 4:
		draw_circle(Vector2(-6, -62), 1.5, shimmer_col)
		draw_circle(Vector2(8, -64), 1.8, shimmer_col)


func _draw_blooming_rose(
	primary_col: Color,
	secondary_col: Color,
	accent_col: Color,
	stem_col: Color,
	leaf_col: Color,
	petal_form: String,
	vigor_scale: float
) -> void:
	# Stem
	draw_line(Vector2(0, 10), Vector2(0, -26), stem_col, 4.5 * vigor_scale, true)

	# Rose Leaves
	_draw_custom_ellipse(Vector2(-14, -6) * vigor_scale, 10.0 * vigor_scale, 5.0 * vigor_scale, leaf_col)
	_draw_custom_ellipse(Vector2(14, -12) * vigor_scale, 10.0 * vigor_scale, 5.0 * vigor_scale, leaf_col)
	_draw_custom_ellipse(Vector2(-11, -18) * vigor_scale, 8.0 * vigor_scale, 4.0 * vigor_scale, leaf_col.lightened(0.1))

	# Thorn
	draw_line(Vector2(0, 0), Vector2(4, -2) * vigor_scale, stem_col.darkened(0.2), 2.0)

	var center := Vector2(0, -32)

	# Draw Petals according to Petal Form Genotype
	if petal_form == "star":
		# Star Form Petals (6-pointed radial stars)
		var num_points := 6
		for i in range(num_points):
			var angle: float = (float(i) / float(num_points)) * TAU - PI * 0.5
			var dir := Vector2(cos(angle), sin(angle))
			var star_poly := PackedVector2Array([
				center,
				center + dir.rotated(0.3) * (7.0 * vigor_scale),
				center + dir * (14.0 * vigor_scale),
				center + dir.rotated(-0.3) * (7.0 * vigor_scale)
			])
			draw_colored_polygon(star_poly, secondary_col)
		for i in range(num_points):
			var angle: float = (float(i) / float(num_points)) * TAU - PI * 0.25
			var dir := Vector2(cos(angle), sin(angle))
			var inner_poly := PackedVector2Array([
				center,
				center + dir.rotated(0.25) * (5.0 * vigor_scale),
				center + dir * (10.5 * vigor_scale),
				center + dir.rotated(-0.25) * (5.0 * vigor_scale)
			])
			draw_colored_polygon(inner_poly, primary_col)
	elif petal_form == "pointed":
		# Pointed Needle Petals
		var num_petals := 8
		for i in range(num_petals):
			var angle: float = (float(i) / float(num_petals)) * TAU
			var dir := Vector2(cos(angle), sin(angle))
			var pointed_poly := PackedVector2Array([
				center,
				center + dir.rotated(0.4) * (5.5 * vigor_scale),
				center + dir * (13.0 * vigor_scale),
				center + dir.rotated(-0.4) * (5.5 * vigor_scale)
			])
			draw_colored_polygon(pointed_poly, secondary_col if i % 2 == 0 else primary_col)
	else:
		# Classic Round Petals (Smooth overlapping ellipses)
		var num_outer := 5
		for i in range(num_outer):
			var angle: float = (float(i) / float(num_outer)) * TAU - PI * 0.5
			var offset := Vector2(cos(angle), sin(angle)) * (8.0 * vigor_scale)
			_draw_custom_ellipse(center + offset, 8.5 * vigor_scale, 7.5 * vigor_scale, secondary_col)
		for i in range(num_outer):
			var angle: float = (float(i) / float(num_outer)) * TAU - PI * 0.25
			var offset := Vector2(cos(angle), sin(angle)) * (5.0 * vigor_scale)
			_draw_custom_ellipse(center + offset, 7.0 * vigor_scale, 6.0 * vigor_scale, primary_col)

	# Rose Heart & Highlight
	_draw_custom_ellipse(center + Vector2(-1, -1), 4.5 * vigor_scale, 3.5 * vigor_scale, accent_col)
	draw_circle(center, 3.0 * vigor_scale, primary_col.darkened(0.15))
	draw_circle(center + Vector2(1, -1), 1.5 * vigor_scale, accent_col.lightened(0.3))


func _draw_blooming_lavender(
	primary_col: Color,
	secondary_col: Color,
	accent_col: Color,
	stem_col: Color,
	leaf_col: Color,
	petal_form: String,
	vigor_scale: float
) -> void:
	# Tall delicate stalk
	draw_line(Vector2(0, 10), Vector2(0, -42 * vigor_scale), stem_col, 3.2 * vigor_scale, true)

	# Narrow silver-green leaves along stem
	for y in [-4, -12, -20]:
		draw_line(Vector2(0, y * vigor_scale), Vector2(-10, y - 4) * vigor_scale, leaf_col, 2.2, true)
		draw_line(Vector2(0, (y - 3) * vigor_scale), Vector2(10, y - 7) * vigor_scale, leaf_col, 2.2, true)

	var tiers := [-26, -31, -36, -41, -45]
	var tier_widths := [7.0, 6.5, 5.5, 4.5, 3.0]

	for i in range(tiers.size()):
		var y: float = tiers[i] * vigor_scale
		var w: float = tier_widths[i] * vigor_scale
		var col := primary_col if i % 2 == 0 else secondary_col

		if petal_form == "star":
			# Star florets
			draw_circle(Vector2(-w * 0.7, y), 3.5 * vigor_scale, col)
			draw_line(Vector2(-w * 0.7 - 2, y), Vector2(-w * 0.7 + 2, y), accent_col, 1.8)
			draw_line(Vector2(-w * 0.7, y - 2), Vector2(-w * 0.7, y + 2), accent_col, 1.8)

			draw_circle(Vector2(w * 0.7, y), 3.5 * vigor_scale, col)
			draw_line(Vector2(w * 0.7 - 2, y), Vector2(w * 0.7 + 2, y), accent_col, 1.8)
			draw_line(Vector2(w * 0.7, y - 2), Vector2(w * 0.7, y + 2), accent_col, 1.8)
		elif petal_form == "pointed":
			# Pointed spiked florets
			var fl_l := PackedVector2Array([
				Vector2(-w * 0.7, y + 3),
				Vector2(-w * 0.7 - 4, y),
				Vector2(-w * 0.7, y - 3)
			])
			draw_colored_polygon(fl_l, col)
			var fl_r := PackedVector2Array([
				Vector2(w * 0.7, y + 3),
				Vector2(w * 0.7 + 4, y),
				Vector2(w * 0.7, y - 3)
			])
			draw_colored_polygon(fl_r, col)
		else:
			# Round florets
			draw_circle(Vector2(-w * 0.7, y), 3.5 * vigor_scale, col)
			draw_circle(Vector2(-w * 0.7, y - 1), 1.8 * vigor_scale, accent_col)
			draw_circle(Vector2(w * 0.7, y), 3.5 * vigor_scale, col)
			draw_circle(Vector2(w * 0.7, y - 1), 1.8 * vigor_scale, accent_col)

		draw_circle(Vector2(0, y - 2), 3.0 * vigor_scale, accent_col)

	# Tip
	draw_circle(Vector2(0, -48 * vigor_scale), 2.5 * vigor_scale, primary_col.lightened(0.2))


func _draw_blooming_sunflower(
	primary_col: Color,
	secondary_col: Color,
	accent_col: Color,
	stem_col: Color,
	leaf_col: Color,
	petal_form: String,
	vigor_scale: float
) -> void:
	# Sturdy thick stalk
	draw_line(Vector2(0, 10), Vector2(0, -28), stem_col, 5.5 * vigor_scale, true)

	# Large broad heart leaves
	var leaf_l := PackedVector2Array([
		Vector2(0, -6) * vigor_scale,
		Vector2(-18, -14) * vigor_scale,
		Vector2(-22, -8) * vigor_scale,
		Vector2(-6, -1) * vigor_scale
	])
	draw_colored_polygon(leaf_l, leaf_col)

	var leaf_r := PackedVector2Array([
		Vector2(0, -14) * vigor_scale,
		Vector2(19, -22) * vigor_scale,
		Vector2(23, -16) * vigor_scale,
		Vector2(7, -9) * vigor_scale
	])
	draw_colored_polygon(leaf_r, leaf_col)

	var center := Vector2(0, -35)

	# Radiating Ray Petals according to Petal Form
	var num_petals := 12
	for i in range(num_petals):
		var angle: float = (float(i) / float(num_petals)) * TAU
		var dir := Vector2(cos(angle), sin(angle))
		var petal_pos := center + dir * (14.0 * vigor_scale)
		
		if petal_form == "star":
			var star_floret := PackedVector2Array([
				center + dir * (9.0 * vigor_scale),
				petal_pos + dir.rotated(0.3) * (5.0 * vigor_scale),
				center + dir * (20.0 * vigor_scale),
				petal_pos + dir.rotated(-0.3) * (5.0 * vigor_scale)
			])
			draw_colored_polygon(star_floret, primary_col)
		elif petal_form == "pointed":
			var pointed_ray := PackedVector2Array([
				center + dir.rotated(0.2) * (10.0 * vigor_scale),
				center + dir * (20.0 * vigor_scale),
				center + dir.rotated(-0.2) * (10.0 * vigor_scale)
			])
			draw_colored_polygon(pointed_ray, primary_col)
		else:
			_draw_custom_ellipse(petal_pos, 5.5 * vigor_scale, 9.5 * vigor_scale, primary_col)
			draw_line(center, center + dir * (18.0 * vigor_scale), accent_col, 3.2 * vigor_scale, true)

	# Dark Textured Seed Disk Center
	draw_circle(center, 10.5 * vigor_scale, secondary_col)
	draw_circle(center, 8.5 * vigor_scale, secondary_col.darkened(0.25))

	for angle_idx in range(6):
		var ang: float = float(angle_idx) * (TAU / 6.0)
		var dot_pos := center + Vector2(cos(ang), sin(ang)) * (5.0 * vigor_scale)
		draw_circle(dot_pos, 1.4 * vigor_scale, Color(0.65, 0.45, 0.20, 0.9))


func _draw_blooming_roselight(
	primary_col: Color,
	secondary_col: Color,
	accent_col: Color,
	stem_col: Color,
	leaf_col: Color,
	petal_form: String,
	vigor_scale: float
) -> void:
	draw_line(Vector2(0, 10), Vector2(0, -28), stem_col, 4.2 * vigor_scale, true)
	_draw_custom_ellipse(Vector2(-14, -8) * vigor_scale, 10.0 * vigor_scale, 5.0 * vigor_scale, leaf_col)
	_draw_custom_ellipse(Vector2(14, -14) * vigor_scale, 10.0 * vigor_scale, 5.0 * vigor_scale, leaf_col)

	var center := Vector2(0, -34)

	# Glowing Luminescent Halo
	_draw_custom_ellipse(center, 18.0 * vigor_scale, 18.0 * vigor_scale, Color(accent_col.r, accent_col.g, accent_col.b, 0.35))

	# Petal Form Rendering
	if petal_form == "star":
		var num_points := 8
		for i in range(num_points):
			var angle: float = (float(i) / float(num_points)) * TAU
			var dir := Vector2(cos(angle), sin(angle))
			var star_poly := PackedVector2Array([
				center,
				center + dir.rotated(0.3) * (7.0 * vigor_scale),
				center + dir * (16.0 * vigor_scale),
				center + dir.rotated(-0.3) * (7.0 * vigor_scale)
			])
			draw_colored_polygon(star_poly, secondary_col if i % 2 == 0 else primary_col)
	elif petal_form == "pointed":
		var num_petals := 7
		for i in range(num_petals):
			var angle: float = (float(i) / float(num_petals)) * TAU
			var dir := Vector2(cos(angle), sin(angle))
			var pointed_poly := PackedVector2Array([
				center,
				center + dir.rotated(0.35) * (6.0 * vigor_scale),
				center + dir * (15.0 * vigor_scale),
				center + dir.rotated(-0.35) * (6.0 * vigor_scale)
			])
			draw_colored_polygon(pointed_poly, primary_col)
	else:
		var num_petals := 6
		for i in range(num_petals):
			var angle: float = (float(i) / float(num_petals)) * TAU
			var offset := Vector2(cos(angle), sin(angle)) * (8.5 * vigor_scale)
			_draw_custom_ellipse(center + offset, 8.0 * vigor_scale, 7.5 * vigor_scale, secondary_col)
		for i in range(num_petals):
			var angle: float = (float(i) / float(num_petals)) * TAU + PI * 0.15
			var offset := Vector2(cos(angle), sin(angle)) * (5.5 * vigor_scale)
			_draw_custom_ellipse(center + offset, 6.5 * vigor_scale, 6.0 * vigor_scale, primary_col)

	# Radiant Crystal Center
	_draw_custom_ellipse(center, 4.5 * vigor_scale, 4.5 * vigor_scale, accent_col)
	draw_circle(center, 2.5 * vigor_scale, Color(1.0, 1.0, 1.0, 0.95))


func _draw_blooming_golden_rose(
	primary_col: Color,
	secondary_col: Color,
	accent_col: Color,
	stem_col: Color,
	leaf_col: Color,
	petal_form: String,
	vigor_scale: float
) -> void:
	draw_line(Vector2(0, 10), Vector2(0, -27), stem_col, 4.8 * vigor_scale, true)
	_draw_custom_ellipse(Vector2(-14, -8) * vigor_scale, 11.0 * vigor_scale, 6.0 * vigor_scale, leaf_col)
	_draw_custom_ellipse(Vector2(14, -14) * vigor_scale, 11.0 * vigor_scale, 6.0 * vigor_scale, leaf_col)

	var center := Vector2(0, -34)
	_draw_custom_ellipse(center, 19.0 * vigor_scale, 19.0 * vigor_scale, Color(accent_col.r, accent_col.g, accent_col.b, 0.3))

	if petal_form == "star":
		for i in range(6):
			var angle: float = (float(i) / 6.0) * TAU
			var dir := Vector2(cos(angle), sin(angle))
			var poly := PackedVector2Array([
				center,
				center + dir.rotated(0.3) * (7.0 * vigor_scale),
				center + dir * (16.0 * vigor_scale),
				center + dir.rotated(-0.3) * (7.0 * vigor_scale)
			])
			draw_colored_polygon(poly, primary_col)
	elif petal_form == "pointed":
		for i in range(8):
			var angle: float = (float(i) / 8.0) * TAU
			var dir := Vector2(cos(angle), sin(angle))
			var poly := PackedVector2Array([
				center,
				center + dir.rotated(0.3) * (6.0 * vigor_scale),
				center + dir * (15.0 * vigor_scale),
				center + dir.rotated(-0.3) * (6.0 * vigor_scale)
			])
			draw_colored_polygon(poly, primary_col)
	else:
		for i in range(6):
			var angle: float = (float(i) / 6.0) * TAU
			var offset := Vector2(cos(angle), sin(angle)) * (9.0 * vigor_scale)
			_draw_custom_ellipse(center + offset, 8.5 * vigor_scale, 7.5 * vigor_scale, secondary_col)
		for i in range(6):
			var angle: float = (float(i) / 6.0) * TAU + PI * 0.15
			var offset := Vector2(cos(angle), sin(angle)) * (6.0 * vigor_scale)
			_draw_custom_ellipse(center + offset, 7.0 * vigor_scale, 6.0 * vigor_scale, primary_col)

	draw_circle(center, 4.5 * vigor_scale, secondary_col)
	draw_circle(center, 2.5 * vigor_scale, accent_col)


func _draw_blooming_sunflare_spike(
	primary_col: Color,
	secondary_col: Color,
	accent_col: Color,
	stem_col: Color,
	leaf_col: Color,
	petal_form: String,
	vigor_scale: float
) -> void:
	draw_line(Vector2(0, 10), Vector2(0, -45 * vigor_scale), stem_col, 4.0 * vigor_scale, true)

	for y in [-6, -14, -22]:
		draw_line(Vector2(0, y * vigor_scale), Vector2(-12, y - 5) * vigor_scale, leaf_col, 2.8, true)
		draw_line(Vector2(0, (y - 4) * vigor_scale), Vector2(12, y - 9) * vigor_scale, leaf_col, 2.8, true)

	var tiers := [-26, -32, -38, -44, -50]
	var widths := [9.0, 8.0, 6.5, 5.0, 3.5]

	for i in range(tiers.size()):
		var y: float = tiers[i] * vigor_scale
		var w: float = widths[i] * vigor_scale
		var col := primary_col if i % 2 == 0 else secondary_col

		if petal_form == "star" or petal_form == "pointed":
			var fl_l := PackedVector2Array([
				Vector2(-w * 0.8, y + 3),
				Vector2(-w * 0.8 - 5, y),
				Vector2(-w * 0.8, y - 3)
			])
			draw_colored_polygon(fl_l, col)
			var fl_r := PackedVector2Array([
				Vector2(w * 0.8, y + 3),
				Vector2(w * 0.8 + 5, y),
				Vector2(w * 0.8, y - 3)
			])
			draw_colored_polygon(fl_r, col)
		else:
			_draw_custom_ellipse(Vector2(-w * 0.8, y), 4.5 * vigor_scale, 3.5 * vigor_scale, col)
			_draw_custom_ellipse(Vector2(w * 0.8, y), 4.5 * vigor_scale, 3.5 * vigor_scale, col)

		draw_circle(Vector2(0, y - 2), 3.5 * vigor_scale, accent_col)

	draw_circle(Vector2(0, -54 * vigor_scale), 3.0 * vigor_scale, accent_col.lightened(0.3))


func _draw_custom_ellipse(
	center: Vector2,
	radius_x: float,
	radius_y: float,
	color: Color,
	segments: int = 16
) -> void:
	var points := PackedVector2Array()
	for i in range(segments):
		var angle: float = (float(i) / float(segments)) * TAU
		points.append(center + Vector2(cos(angle) * radius_x, sin(angle) * radius_y))
	draw_colored_polygon(points, color)
