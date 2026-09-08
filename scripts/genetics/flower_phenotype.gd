class_name FlowerPhenotype
extends RefCounted

## Player-facing expressed traits resolved from FlowerGenotype for Milestone P3.
## [PROTOTYPE_ONLY]: Natural language trait labels, colors, and visual multipliers.

var color_tint: Color = Color.WHITE
var color_name: String = "Natural"
var petal_form: String = "round" # "round", "star", "pointed"
var petal_form_name: String = "Round Petals"
var fragrance_rating: int = 2 # 1 to 4 stars
var fragrance_name: String = "Sweet Fragrance"
var vigor_tier: int = 1 # 1 to 3
var vigor_name: String = "Standard Vigor"
var visual_scale: float = 1.0


func serialize() -> Dictionary:
	return {
		"color_tint": color_tint.to_html(),
		"color_name": color_name,
		"petal_form": petal_form,
		"petal_form_name": petal_form_name,
		"fragrance_rating": fragrance_rating,
		"fragrance_name": fragrance_name,
		"vigor_tier": vigor_tier,
		"vigor_name": vigor_name,
		"visual_scale": visual_scale
	}


static func deserialize(data: Dictionary) -> FlowerPhenotype:
	var p := FlowerPhenotype.new()
	p.color_tint = Color.from_string(data.get("color_tint", "#ffffff"), Color.WHITE)
	p.color_name = String(data.get("color_name", "Natural"))
	p.petal_form = String(data.get("petal_form", "round"))
	p.petal_form_name = String(data.get("petal_form_name", "Round Petals"))
	p.fragrance_rating = int(data.get("fragrance_rating", 2))
	p.fragrance_name = String(data.get("fragrance_name", "Sweet Fragrance"))
	p.vigor_tier = int(data.get("vigor_tier", 1))
	p.vigor_name = String(data.get("vigor_name", "Standard Vigor"))
	p.visual_scale = float(data.get("visual_scale", 1.0))
	return p
