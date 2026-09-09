class_name GeneticsEngine
extends RefCounted

## Mendelian genetics engine for Milestone P3.
## Handles species cross compatibility, diploid allele segregation with deterministic RNG,
## starter specimen templates, and full phenotype resolution.
## [PROTOTYPE_ONLY]: 4-locus Mendelian rules, dominance hierarchy (Ps > Pr > Pp), and starter templates.

const STARTER_GENOTYPES: Dictionary = {
	"rose": {
		"color": ["Cr", "Cr"],
		"petal": ["Pr", "Pp"],     # Round (carries Pointed)
		"fragrance": ["F+", "f-"], # Fragrant (3★)
		"vigor": ["V+", "v-"]      # Robust (Tier 2)
	},
	"lavender": {
		"color": ["Cp", "Cp"],
		"petal": ["Ps", "Pr"],     # Star (carries Round)
		"fragrance": ["F+", "F+"], # Intense (4★)
		"vigor": ["v-", "v-"]      # Standard (Tier 1)
	},
	"sunflower": {
		"color": ["Cy", "Cy"],
		"petal": ["Pr", "Pr"],     # Round (pure)
		"fragrance": ["f-", "f-"], # Mild (1★)
		"vigor": ["V+", "V+"]      # Exceptional (Tier 3)
	},
	"tulip": {
		"color": ["Cy", "Cr"],     # Orange Flame
		"petal": ["Pr", "Pr"],     # Cupped / Round
		"fragrance": ["F+", "f-"], # Fragrant (3★)
		"vigor": ["v-", "v-"]      # Standard (Tier 1)
	},
	"daisy": {
		"color": ["Cp", "Cy"],     # Bright Ray / Sunny Disc
		"petal": ["Ps", "Ps"],     # Star / Ray Petals
		"fragrance": ["f-", "f-"], # Mild (1★)
		"vigor": ["v-", "v-"]      # Standard (Tier 1)
	},
	"rose_cream": {
		"color": ["Cp", "Cp"],     # Porcelain Cream / White
		"petal": ["Pr", "Pp"],     # Round Rosette
		"fragrance": ["F+", "F+"], # Intense Tea Scent (4★)
		"vigor": ["V+", "v-"]      # Robust (Tier 2)
	}
}

static var _specimen_counter: int = 100


static func resolve_species(species_a: String, species_b: String) -> String:
	return FlowerData.get_breeding_result(species_a, species_b)


static func resolve_phenotype(genotype: FlowerGenotype, species_id: String) -> FlowerPhenotype:
	var p := FlowerPhenotype.new()
	var val_res := genotype.validate()
	if not val_res.get("valid", false):
		p.color_name = "Genetic Anomaly"
		p.petal_form = "round"
		p.petal_form_name = "Irregular Petals"
		p.fragrance_rating = 1
		p.fragrance_name = "Faint Fragrance"
		p.vigor_tier = 1
		p.vigor_name = "Fragile Vigor"
		p.visual_scale = 0.9
		return p

	# 1. Color Locus (Incomplete Dominance)
	var c: Array[String] = genotype.color_alleles.duplicate()
	c.sort()
	var c_key := "%s%s" % [c[0], c[1]]
	match c_key:
		"CrCr":
			p.color_tint = Color(0.92, 0.22, 0.28, 1.0)
			p.color_name = "Crimson Red"
		"CpCp":
			p.color_tint = Color(0.68, 0.50, 0.88, 1.0)
			p.color_name = "Soft Lavender"
		"CyCy":
			p.color_tint = Color(1.0, 0.82, 0.14, 1.0)
			p.color_name = "Golden Yellow"
		"CpCr":
			p.color_tint = Color(0.88, 0.35, 0.78, 1.0)
			p.color_name = "Plum Magenta"
		"CrCy":
			p.color_tint = Color(0.98, 0.55, 0.15, 1.0)
			p.color_name = "Amber Flame"
		"CpCy":
			p.color_tint = Color(0.85, 0.45, 0.70, 1.0)
			p.color_name = "Sunset Orchid"
		_:
			p.color_tint = Color.WHITE
			p.color_name = "Natural"

	# 2. Petal Form Locus (Hierarchy: Ps > Pr > Pp)
	var p1: String = genotype.petal_alleles[0]
	var p2: String = genotype.petal_alleles[1]
	if p1 == "Ps" or p2 == "Ps":
		p.petal_form = "star"
		p.petal_form_name = "Star Petals"
	elif p1 == "Pr" or p2 == "Pr":
		p.petal_form = "round"
		p.petal_form_name = "Round Petals"
	elif p1 == "Pp" and p2 == "Pp":
		p.petal_form = "pointed"
		p.petal_form_name = "Pointed Petals"
	else:
		p.petal_form = "round"
		p.petal_form_name = "Round Petals"

	# 3. Fragrance Locus (Additive Dosage)
	var f: Array[String] = genotype.fragrance_alleles.duplicate()
	f.sort()
	var f_key := "%s%s" % [f[0], f[1]]
	match f_key:
		"f-f-":
			p.fragrance_rating = 1
			p.fragrance_name = "Mild Fragrance"
		"F+f-":
			p.fragrance_rating = 3
			p.fragrance_name = "Fragrant"
		"F+F+":
			p.fragrance_rating = 4
			p.fragrance_name = "Intense Fragrance"
		_:
			p.fragrance_rating = 2
			p.fragrance_name = "Sweet Fragrance"

	# 4. Vigor Locus (Additive Dosage & Scale Multiplier)
	var v: Array[String] = genotype.vigor_alleles.duplicate()
	v.sort()
	var v_key := "%s%s" % [v[0], v[1]]
	match v_key:
		"v-v-":
			p.vigor_tier = 1
			p.vigor_name = "Standard Vigor"
			p.visual_scale = 0.95
		"V+v-":
			p.vigor_tier = 2
			p.vigor_name = "Robust Vigor"
			p.visual_scale = 1.05
		"V+V+":
			p.vigor_tier = 3
			p.vigor_name = "Exceptional Vigor"
			p.visual_scale = 1.15
		_:
			p.vigor_tier = 1
			p.vigor_name = "Standard Vigor"
			p.visual_scale = 1.0

	return p


static func create_starter_specimen(species_id: String, custom_id: String = "") -> FlowerSpecimen:
	var tpl: Dictionary = STARTER_GENOTYPES.get(species_id, STARTER_GENOTYPES["rose"])
	var c_arr: Array[String] = [String(tpl["color"][0]), String(tpl["color"][1])]
	var p_arr: Array[String] = [String(tpl["petal"][0]), String(tpl["petal"][1])]
	var f_arr: Array[String] = [String(tpl["fragrance"][0]), String(tpl["fragrance"][1])]
	var v_arr: Array[String] = [String(tpl["vigor"][0]), String(tpl["vigor"][1])]
	var genotype := FlowerGenotype.new(c_arr, p_arr, f_arr, v_arr)
	var phenotype := resolve_phenotype(genotype, species_id)
	
	var s_id := custom_id
	if s_id.is_empty():
		_specimen_counter += 1
		var prefix: String = species_id.substr(0, 1).to_upper()
		s_id = "%s-%03d" % [prefix, _specimen_counter]

	var specimen := FlowerSpecimen.new(s_id, species_id, 0, genotype, phenotype)
	return specimen


static func cross_specimens(
	parent_a: FlowerSpecimen,
	parent_b: FlowerSpecimen,
	rng_seed: int
) -> Dictionary:
	# Returns { "success": bool, "error": String, "specimen": FlowerSpecimen, "species_id": String }
	if parent_a == null or parent_b == null:
		return {"success": false, "error": "Invalid parent specimens provided."}

	var child_species := resolve_species(parent_a.species_id, parent_b.species_id)
	if child_species.is_empty():
		return {
			"success": false,
			"error": "Undefined hybrid combination: %s × %s cannot be crossed." % [
				parent_a.species_id.capitalize(),
				parent_b.species_id.capitalize()
			]
		}

	var rng := RandomNumberGenerator.new()
	rng.seed = rng_seed

	# Allele Segregation (1 allele randomly inherited from each parent per locus)
	var child_color: Array[String] = [
		parent_a.genotype.color_alleles[rng.randi_range(0, 1)],
		parent_b.genotype.color_alleles[rng.randi_range(0, 1)]
	]
	var child_petal: Array[String] = [
		parent_a.genotype.petal_alleles[rng.randi_range(0, 1)],
		parent_b.genotype.petal_alleles[rng.randi_range(0, 1)]
	]
	var child_fragrance: Array[String] = [
		parent_a.genotype.fragrance_alleles[rng.randi_range(0, 1)],
		parent_b.genotype.fragrance_alleles[rng.randi_range(0, 1)]
	]
	var child_vigor: Array[String] = [
		parent_a.genotype.vigor_alleles[rng.randi_range(0, 1)],
		parent_b.genotype.vigor_alleles[rng.randi_range(0, 1)]
	]

	var child_genotype := FlowerGenotype.new(child_color, child_petal, child_fragrance, child_vigor)
	var child_phenotype := resolve_phenotype(child_genotype, child_species)
	var child_gen: int = max(parent_a.generation, parent_b.generation) + 1

	_specimen_counter += 1
	var prefix: String = "H" if FlowerData.get_flower(child_species).get("is_hybrid", false) else child_species.substr(0, 1).to_upper()
	var child_id := "%s-%03d" % [prefix, _specimen_counter]

	var offspring := FlowerSpecimen.new(child_id, child_species, child_gen, child_genotype, child_phenotype)
	offspring.parent_a_id = parent_a.specimen_id
	offspring.parent_b_id = parent_b.specimen_id
	offspring.origin_seed = rng_seed

	return {
		"success": true,
		"error": "",
		"specimen": offspring,
		"species": child_species,
		"species_id": child_species
	}
