class_name ModularFlowerVisual
extends Node2D

## Modular Flower Visual & Art Strategy Comparator for Milestone P4.
## Evaluates:
## - Approach A: Whole-Authored Strategy (Curated standalone species look)
## - Approach B: Full Modular Composition (Unrestricted interchangeable parts)
## - Approach C: Curated Hybrid Pipeline (Master species architecture + modular heritable variations)
## Includes lightweight part compatibility table and trait provenance tracking.

enum Strategy {
	WHOLE_AUTHORED = 0,
	FULL_MODULAR = 1,
	CURATED_HYBRID = 2
}

enum Provenance {
	PARENT_A,
	PARENT_B,
	BLENDED,
	EMERGENT
}

# [PROTOTYPE_ONLY]: Compatibility matrix between Bloom Architectures and Part Families
const COMPATIBILITY_TABLE: Dictionary = {
	"solitary_cup": {
		"compatible_petals": ["round", "star", "pointed", "fluted"],
		"compatible_centers": ["spiral_heart", "crystal_core", "seed_disk"],
		"compatible_foliage": ["serrated_oval", "broad_cordate"]
	},
	"verticillaster_spike": {
		"compatible_petals": ["floret_tier", "star_floret", "pointed_floret"],
		"compatible_centers": ["tubular_throat", "crystal_tip"],
		"compatible_foliage": ["linear_silver", "slender_lance"]
	},
	"radiant_disk": {
		"compatible_petals": ["elongated_ray", "star_ray", "pointed_ray"],
		"compatible_centers": ["geometric_seed_disk", "amber_core"],
		"compatible_foliage": ["broad_cordate", "serrated_oval"]
	}
}

@export var strategy: Strategy = Strategy.CURATED_HYBRID:
	set(val):
		strategy = val
		queue_redraw()

@export var flower_id: String = "roselight":
	set(val):
		flower_id = val
		queue_redraw()

var phenotype: FlowerPhenotype = null:
	set(val):
		phenotype = val
		queue_redraw()

# Modular Part Selections
@export var stem_type: String = "woody_thorn"
@export var foliage_type: String = "serrated_oval"
@export var bloom_architecture: String = "solitary_cup"
@export var petal_variant: String = "star"
@export var center_core: String = "crystal_core"
@export var aura_type: String = "luminescent_halo"
@export var visual_scale: float = 1.0

# Trait Provenance Tracking (for lineage attribution breakdown)
var provenance_data: Dictionary = {
	"stem": { "source": Provenance.PARENT_A, "parent_name": "Rose", "label": "Stem & Thorns" },
	"foliage": { "source": Provenance.PARENT_A, "parent_name": "Rose", "label": "Serrated Foliage" },
	"architecture": { "source": Provenance.PARENT_A, "parent_name": "Rose", "label": "Solitary Bloom Architecture" },
	"petal_form": { "source": Provenance.PARENT_B, "parent_name": "Lavender", "label": "Star Petal Genetics" },
	"color": { "source": Provenance.BLENDED, "parent_name": "Rose × Lavender", "label": "Plum Magenta Blend (Cr × Cp)" },
	"center": { "source": Provenance.EMERGENT, "parent_name": "Emergent Hybrid", "label": "Radiant Crystal Core" },
	"fragrance_aura": { "source": Provenance.PARENT_B, "parent_name": "Lavender", "label": "Aroma Shimmer (4★)" }
}


func _draw() -> void:
	match strategy:
		Strategy.WHOLE_AUTHORED:
			_draw_whole_authored()
		Strategy.FULL_MODULAR:
			_draw_full_modular()
		Strategy.CURATED_HYBRID:
			_draw_curated_hybrid()


func _draw_whole_authored() -> void:
	# Approach A: Hand-curated standalone composition with strong unified artistic silhouette
	var tex_path := "res://assets/flowers/master_%s.png" % flower_id
	if ResourceLoader.exists(tex_path):
		var tex: Texture2D = load(tex_path)
		var spr_w: float = 64.0 * visual_scale
		var spr_h: float = 64.0 * visual_scale
		_draw_custom_ellipse(Vector2(0, 4), 18.0 * visual_scale, 8.0 * visual_scale, Color(0.04, 0.08, 0.05, 0.45))
		draw_texture_rect(tex, Rect2(-spr_w * 0.5, -spr_h + 4.0, spr_w, spr_h), false)
		return

	var data := FlowerData.get_flower(flower_id)
	var p_col: Color = data.get("primary_color", Color.MAGENTA)
	var s_col: Color = data.get("secondary_color", Color.DARK_MAGENTA)
	var a_col: Color = data.get("accent_color", Color.PINK)
	var stem_col: Color = Color(0.24, 0.48, 0.28)
	var leaf_col: Color = Color(0.18, 0.42, 0.22)

	match flower_id:
		"rose":
			# Hand-curated classic Rose
			draw_line(Vector2(0, 10), Vector2(0, -26), stem_col, 4.5, true)
			_draw_custom_ellipse(Vector2(-14, -6), 10.0, 5.0, leaf_col)
			_draw_custom_ellipse(Vector2(14, -12), 10.0, 5.0, leaf_col)
			draw_line(Vector2(0, 0), Vector2(4, -2), stem_col.darkened(0.2), 2.0)
			for i in range(5):
				var ang: float = (float(i) / 5.0) * TAU - PI * 0.5
				_draw_custom_ellipse(Vector2(0, -32) + Vector2(cos(ang), sin(ang)) * 8.0, 8.5, 7.5, s_col)
			for i in range(5):
				var ang: float = (float(i) / 5.0) * TAU - PI * 0.25
				_draw_custom_ellipse(Vector2(0, -32) + Vector2(cos(ang), sin(ang)) * 5.0, 7.0, 6.0, p_col)
			draw_circle(Vector2(0, -32), 3.5, a_col)

		"lavender":
			# Hand-curated tiered Lavender Stalk
			draw_line(Vector2(0, 10), Vector2(0, -44), stem_col, 3.0, true)
			for y in [-6, -14, -22]:
				draw_line(Vector2(0, y), Vector2(-10, y - 4), leaf_col, 2.0, true)
				draw_line(Vector2(0, y - 3), Vector2(10, y - 7), leaf_col, 2.0, true)
			for y in [-26, -32, -38, -44]:
				draw_circle(Vector2(-5, y), 3.5, p_col)
				draw_circle(Vector2(5, y), 3.5, p_col)
				draw_circle(Vector2(0, y - 2), 2.5, a_col)
			draw_circle(Vector2(0, -48), 2.2, a_col.lightened(0.2))

		"sunflower":
			# Hand-curated large radiant Sunflower
			draw_line(Vector2(0, 10), Vector2(0, -28), stem_col, 5.5, true)
			_draw_custom_ellipse(Vector2(-16, -10), 14.0, 8.0, leaf_col)
			_draw_custom_ellipse(Vector2(16, -16), 14.0, 8.0, leaf_col)
			var c := Vector2(0, -35)
			for i in range(12):
				var ang: float = (float(i) / 12.0) * TAU
				var dir := Vector2(cos(ang), sin(ang))
				_draw_custom_ellipse(c + dir * 14.0, 5.5, 9.5, p_col)
			draw_circle(c, 10.5, s_col)
			draw_circle(c, 8.5, s_col.darkened(0.3))

		"roselight":
			# Hand-curated Master Roselight Hybrid
			draw_line(Vector2(0, 10), Vector2(0, -28), stem_col, 4.2, true)
			_draw_custom_ellipse(Vector2(-14, -8), 10.0, 5.0, leaf_col)
			_draw_custom_ellipse(Vector2(14, -14), 10.0, 5.0, leaf_col)
			var c := Vector2(0, -34)
			_draw_custom_ellipse(c, 18.0, 18.0, Color(a_col.r, a_col.g, a_col.b, 0.35))
			for i in range(6):
				var ang: float = (float(i) / 6.0) * TAU
				_draw_custom_ellipse(c + Vector2(cos(ang), sin(ang)) * 8.5, 8.0, 7.5, s_col)
			for i in range(6):
				var ang: float = (float(i) / 6.0) * TAU + PI * 0.15
				_draw_custom_ellipse(c + Vector2(cos(ang), sin(ang)) * 5.5, 6.5, 6.0, p_col)
			_draw_custom_ellipse(c, 4.5, 4.5, a_col)
			draw_circle(c, 2.5, Color.WHITE)

		"golden_rose":
			# Hand-curated Golden Sun Rose
			draw_line(Vector2(0, 10), Vector2(0, -28), stem_col, 4.8, true)
			_draw_custom_ellipse(Vector2(-15, -8), 12.0, 6.0, leaf_col)
			_draw_custom_ellipse(Vector2(15, -14), 12.0, 6.0, leaf_col)
			var c := Vector2(0, -34)
			_draw_custom_ellipse(c, 16.0, 16.0, Color(1.0, 0.85, 0.3, 0.35))
			for i in range(8):
				var ang: float = (float(i) / 8.0) * TAU
				_draw_custom_ellipse(c + Vector2(cos(ang), sin(ang)) * 9.0, 7.0, 8.0, p_col)
			draw_circle(c, 7.0, s_col)
			draw_circle(c, 3.5, a_col)

		"sunflare_spike":
			# Hand-curated Sunflare Spike
			draw_line(Vector2(0, 10), Vector2(0, -46), stem_col, 3.8, true)
			for y in [-6, -14, -22]:
				draw_line(Vector2(0, y), Vector2(-12, y - 5), leaf_col, 2.2, true)
				draw_line(Vector2(0, y - 3), Vector2(12, y - 8), leaf_col, 2.2, true)
			for y in [-26, -32, -38, -44]:
				draw_circle(Vector2(-6, y), 4.2, p_col)
				draw_circle(Vector2(6, y), 4.2, p_col)
				draw_circle(Vector2(0, y - 2), 3.0, a_col)
			draw_circle(Vector2(0, -50), 3.2, Color.WHITE)


func _draw_full_modular() -> void:
	# Approach B: Full unrestricted modular assembly from raw part layers
	var col: Color = phenotype.color_tint if phenotype != null else Color(0.88, 0.35, 0.78)
	var v_scale: float = visual_scale * (phenotype.visual_scale if phenotype != null else 1.0)
	
	_draw_stem_layer(stem_type, v_scale)
	_draw_foliage_layer(foliage_type, v_scale)
	_draw_architecture_base(bloom_architecture, col, v_scale)
	_draw_petal_layer(petal_variant, col, v_scale)
	_draw_center_layer(center_core, col, v_scale)
	_draw_aura_layer(aura_type, col, v_scale)


func _draw_curated_hybrid() -> void:
	# Approach C: Curated Hybrid Pipeline (Master species architecture + modular heritable variation)
	# Ensures the master botanical silhouette is strictly preserved while expressing heritable genes
	var v_scale: float = visual_scale * (phenotype.visual_scale if phenotype != null else 1.0)
	var p_form: String = phenotype.petal_form if phenotype != null else petal_variant
	var frag: int = phenotype.fragrance_rating if phenotype != null else 3

	# Check for Master Curated Sprites
	var tex: Texture2D = null
	if flower_id == "roselight":
		match p_form:
			"star":
				if ResourceLoader.exists("res://assets/flowers/roselight_specimen_b.png"):
					tex = load("res://assets/flowers/roselight_specimen_b.png")
			"pointed":
				if ResourceLoader.exists("res://assets/flowers/roselight_specimen_c.png"):
					tex = load("res://assets/flowers/roselight_specimen_c.png")
			_:
				if ResourceLoader.exists("res://assets/flowers/roselight_specimen_a.png"):
					tex = load("res://assets/flowers/roselight_specimen_a.png")
	else:
		var tex_path := "res://assets/flowers/master_%s.png" % flower_id
		if ResourceLoader.exists(tex_path):
			tex = load(tex_path)

	if tex != null:
		var spr_w: float = 64.0 * v_scale
		var spr_h: float = 64.0 * v_scale
		_draw_custom_ellipse(Vector2(0, 4), 18.0 * v_scale, 8.0 * v_scale, Color(0.04, 0.08, 0.05, 0.45))
		draw_texture_rect(tex, Rect2(-spr_w * 0.5, -spr_h + 4.0, spr_w, spr_h), false)
		if frag >= 3:
			draw_circle(Vector2(-16 * v_scale, -48 * v_scale), 2.2, Color(1.0, 0.95, 0.65, 0.8))
			draw_circle(Vector2(14 * v_scale, -52 * v_scale), 2.6, Color(1.0, 0.95, 0.65, 0.8))
			draw_circle(Vector2(0, -60 * v_scale), 3.0, Color(1.0, 0.95, 0.65, 0.9))
		return

	var col: Color = phenotype.color_tint if phenotype != null else Color(0.88, 0.35, 0.78)
	# 1. Master species structure (guardrail preserves identity)
	var stem_col := Color(0.24, 0.48, 0.28)
	var leaf_col := Color(0.18, 0.44, 0.22)
	draw_line(Vector2(0, 10), Vector2(0, -28 * v_scale), stem_col, 4.2 * v_scale, true)
	_draw_custom_ellipse(Vector2(-14, -8) * v_scale, 10.0 * v_scale, 5.0 * v_scale, leaf_col)
	_draw_custom_ellipse(Vector2(14, -14) * v_scale, 10.0 * v_scale, 5.0 * v_scale, leaf_col)

	var center := Vector2(0, -34 * v_scale)

	# 2. Emergent hybrid halo
	_draw_custom_ellipse(center, 18.0 * v_scale, 18.0 * v_scale, Color(col.r, col.g, col.b, 0.32))

	# 3. Heritable modular petal expression
	if p_form == "star":
		for i in range(8):
			var ang: float = (float(i) / 8.0) * TAU
			var dir := Vector2(cos(ang), sin(ang))
			var poly := PackedVector2Array([
				center,
				center + dir.rotated(0.3) * (7.0 * v_scale),
				center + dir * (16.0 * v_scale),
				center + dir.rotated(-0.3) * (7.0 * v_scale)
			])
			draw_colored_polygon(poly, col.darkened(0.2) if i % 2 == 0 else col)
	elif p_form == "pointed":
		for i in range(8):
			var ang: float = (float(i) / 8.0) * TAU
			var dir := Vector2(cos(ang), sin(ang))
			var poly := PackedVector2Array([
				center,
				center + dir.rotated(0.35) * (6.0 * v_scale),
				center + dir * (15.0 * v_scale),
				center + dir.rotated(-0.35) * (6.0 * v_scale)
			])
			draw_colored_polygon(poly, col)
	else:
		# Round petals
		for i in range(6):
			var ang: float = (float(i) / 6.0) * TAU
			var offset := Vector2(cos(ang), sin(ang)) * (8.5 * v_scale)
			_draw_custom_ellipse(center + offset, 8.0 * v_scale, 7.5 * v_scale, col.darkened(0.2))
		for i in range(6):
			var ang: float = (float(i) / 6.0) * TAU + PI * 0.15
			var offset := Vector2(cos(ang), sin(ang)) * (5.5 * v_scale)
			_draw_custom_ellipse(center + offset, 6.5 * v_scale, 6.0 * v_scale, col)

	# 4. Emergent crystal center core
	_draw_custom_ellipse(center, 4.5 * v_scale, 4.5 * v_scale, col.lightened(0.4))
	draw_circle(center, 2.5 * v_scale, Color.WHITE)

	# 5. Heritable aroma particles
	if frag >= 3:
		_draw_shimmer_particles(frag, center)


func _draw_stem_layer(s_type: String, v_scale: float) -> void:
	var col := Color(0.24, 0.48, 0.28)
	match s_type:
		"woody_thorn":
			draw_line(Vector2(0, 10), Vector2(0, -28 * v_scale), col, 4.5 * v_scale, true)
			draw_line(Vector2(0, 0), Vector2(4, -2) * v_scale, col.darkened(0.25), 2.0)
		"slender_stalk":
			draw_line(Vector2(0, 10), Vector2(0, -42 * v_scale), col, 3.0 * v_scale, true)
		"thick_robust":
			draw_line(Vector2(0, 10), Vector2(0, -28 * v_scale), col, 5.5 * v_scale, true)
		_:
			draw_line(Vector2(0, 10), Vector2(0, -28 * v_scale), col, 4.0 * v_scale, true)


func _draw_foliage_layer(f_type: String, v_scale: float) -> void:
	var col := Color(0.18, 0.44, 0.22)
	match f_type:
		"serrated_oval":
			_draw_custom_ellipse(Vector2(-14, -8) * v_scale, 10.0 * v_scale, 5.0 * v_scale, col)
			_draw_custom_ellipse(Vector2(14, -14) * v_scale, 10.0 * v_scale, 5.0 * v_scale, col)
		"linear_silver":
			for y in [-6, -14, -22]:
				draw_line(Vector2(0, y * v_scale), Vector2(-10, y - 4) * v_scale, col, 2.0, true)
				draw_line(Vector2(0, (y - 3) * v_scale), Vector2(10, y - 7) * v_scale, col, 2.0, true)
		"broad_cordate":
			_draw_custom_ellipse(Vector2(-16, -10) * v_scale, 14.0 * v_scale, 8.0 * v_scale, col)
			_draw_custom_ellipse(Vector2(16, -16) * v_scale, 14.0 * v_scale, 8.0 * v_scale, col)


func _draw_architecture_base(arch_type: String, col: Color, v_scale: float) -> void:
	var center := Vector2(0, -34 * v_scale)
	match arch_type:
		"solitary_cup":
			_draw_custom_ellipse(center, 12.0 * v_scale, 12.0 * v_scale, col.darkened(0.3))
		"verticillaster_spike":
			for y in [-26, -32, -38, -44]:
				draw_circle(Vector2(0, y * v_scale), 5.0 * v_scale, col.darkened(0.2))
		"radiant_disk":
			draw_circle(center, 12.0 * v_scale, col.darkened(0.4))


func _draw_petal_layer(p_type: String, col: Color, v_scale: float) -> void:
	var center := Vector2(0, -34 * v_scale)
	if p_type == "star" or p_type == "delicate_star":
		for i in range(8):
			var ang: float = (float(i) / 8.0) * TAU
			var dir := Vector2(cos(ang), sin(ang))
			var poly := PackedVector2Array([
				center,
				center + dir.rotated(0.3) * (7.0 * v_scale),
				center + dir * (15.0 * v_scale),
				center + dir.rotated(-0.3) * (7.0 * v_scale)
			])
			draw_colored_polygon(poly, col)
	elif p_type == "pointed" or p_type == "pointed_needle":
		for i in range(8):
			var ang: float = (float(i) / 8.0) * TAU
			var dir := Vector2(cos(ang), sin(ang))
			var poly := PackedVector2Array([
				center,
				center + dir.rotated(0.35) * (6.0 * v_scale),
				center + dir * (14.0 * v_scale),
				center + dir.rotated(-0.35) * (6.0 * v_scale)
			])
			draw_colored_polygon(poly, col)
	else:
		# Round petals
		for i in range(6):
			var ang: float = (float(i) / 6.0) * TAU
			var offset := Vector2(cos(ang), sin(ang)) * (7.5 * v_scale)
			_draw_custom_ellipse(center + offset, 7.5 * v_scale, 6.5 * v_scale, col)


func _draw_center_layer(c_type: String, col: Color, v_scale: float) -> void:
	var center := Vector2(0, -34 * v_scale)
	match c_type:
		"spiral_heart":
			draw_circle(center, 4.0 * v_scale, col.darkened(0.3))
			draw_circle(center + Vector2(1, -1), 2.0 * v_scale, col.lightened(0.4))
		"tubular_throat":
			draw_circle(center, 3.0 * v_scale, col.darkened(0.4))
		"seed_disk":
			draw_circle(center, 6.5 * v_scale, Color(0.35, 0.22, 0.12))
		"crystal_core":
			_draw_custom_ellipse(center, 4.0 * v_scale, 4.0 * v_scale, col.lightened(0.4))
			draw_circle(center, 2.0 * v_scale, Color.WHITE)


func _draw_aura_layer(a_type: String, col: Color, v_scale: float) -> void:
	var center := Vector2(0, -34 * v_scale)
	if a_type == "luminescent_halo":
		_draw_custom_ellipse(center, 18.0 * v_scale, 18.0 * v_scale, Color(col.r, col.g, col.b, 0.28))


func _draw_shimmer_particles(rating: int, center: Vector2) -> void:
	var shimmer_col := Color(1.0, 0.95, 0.65, 0.75 if rating >= 4 else 0.5)
	draw_circle(center + Vector2(-12, -14), 1.8, shimmer_col)
	draw_circle(center + Vector2(10, -18), 2.2, shimmer_col)
	draw_circle(center + Vector2(0, -24), 2.6, shimmer_col)


func _draw_custom_ellipse(center: Vector2, rx: float, ry: float, color: Color, segments: int = 16) -> void:
	var points := PackedVector2Array()
	for i in range(segments):
		var ang := (float(i) / float(segments)) * TAU
		points.append(center + Vector2(cos(ang) * rx, sin(ang) * ry))
	draw_colored_polygon(points, color)


static func get_trait_provenance_breakdown(hybrid_id: String) -> Array[Dictionary]:
	match hybrid_id:
		"roselight":
			return [
				{ "part": "Stem & Thorns", "source": "Inherited from Parent A (Rose)", "type": Provenance.PARENT_A, "color": Color(0.9, 0.4, 0.4) },
				{ "part": "Star Petal Genetics", "source": "Inherited from Parent B (Lavender)", "type": Provenance.PARENT_B, "color": Color(0.7, 0.5, 0.9) },
				{ "part": "Plum Magenta Hue", "source": "Blended from both (Cr × Cp)", "type": Provenance.BLENDED, "color": Color(0.9, 0.5, 0.8) },
				{ "part": "Radiant Crystal Core", "source": "Emergent Hybrid Feature", "type": Provenance.EMERGENT, "color": Color(1.0, 0.88, 0.35) },
				{ "part": "Luminescent Aura", "source": "Emergent Hybrid Feature", "type": Provenance.EMERGENT, "color": Color(1.0, 0.88, 0.35) }
			]
		"golden_rose":
			return [
				{ "part": "Velvety Cup Silhouette", "source": "Inherited from Parent A (Rose)", "type": Provenance.PARENT_A, "color": Color(0.9, 0.4, 0.4) },
				{ "part": "Golden Sun Petals", "source": "Inherited from Parent B (Sunflower)", "type": Provenance.PARENT_B, "color": Color(1.0, 0.82, 0.2) },
				{ "part": "Amber Flame Blend", "source": "Blended from both (Cr × Cy)", "type": Provenance.BLENDED, "color": Color(0.95, 0.6, 0.2) },
				{ "part": "Golden Sparkle Disk", "source": "Emergent Hybrid Feature", "type": Provenance.EMERGENT, "color": Color(1.0, 0.88, 0.35) }
			]
		"sunflare_spike":
			return [
				{ "part": "Verticillaster Tiered Spike", "source": "Inherited from Parent A (Lavender)", "type": Provenance.PARENT_A, "color": Color(0.7, 0.5, 0.9) },
				{ "part": "Radiant Sun Ray Petals", "source": "Inherited from Parent B (Sunflower)", "type": Provenance.PARENT_B, "color": Color(1.0, 0.82, 0.2) },
				{ "part": "Sunset Orchid Blend", "source": "Blended from both (Cp × Cy)", "type": Provenance.BLENDED, "color": Color(0.85, 0.45, 0.7) },
				{ "part": "Sunflare Spire Core", "source": "Emergent Hybrid Feature", "type": Provenance.EMERGENT, "color": Color(1.0, 0.88, 0.35) }
			]
		_:
			return []
