class_name FlowerSpecimen
extends RefCounted

## Individual flower specimen entity carrying unique ID, species, generation pedigree,
## genotype, and resolved phenotype for Milestone P3.
## [PROTOTYPE_ONLY]: Unique specimen representation for preserved breeding stock.

var specimen_id: String = ""
var species_id: String = "rose"
var nickname: String = ""
var generation: int = 0
var parent_a_id: String = ""
var parent_b_id: String = ""
var origin_seed: int = 0

var genotype: FlowerGenotype = null
var phenotype: FlowerPhenotype = null


func _init(
	p_id: String = "",
	p_species: String = "rose",
	p_gen: int = 0,
	p_genotype: FlowerGenotype = null,
	p_phenotype: FlowerPhenotype = null
) -> void:
	specimen_id = p_id
	species_id = p_species
	generation = p_gen
	genotype = p_genotype if p_genotype != null else FlowerGenotype.new()
	phenotype = p_phenotype if p_phenotype != null else FlowerPhenotype.new()
	if nickname.is_empty():
		nickname = "%s #%s" % [species_id.capitalize(), specimen_id]


func get_generation_label() -> String:
	return "G%d" % generation


func get_display_title() -> String:
	if not nickname.is_empty():
		return nickname
	return "%s #%s" % [species_id.capitalize(), specimen_id]


func clone() -> FlowerSpecimen:
	var copy := FlowerSpecimen.new(
		specimen_id,
		species_id,
		generation,
		genotype.clone(),
		FlowerPhenotype.deserialize(phenotype.serialize())
	)
	copy.nickname = nickname
	copy.parent_a_id = parent_a_id
	copy.parent_b_id = parent_b_id
	copy.origin_seed = origin_seed
	return copy


func serialize() -> Dictionary:
	return {
		"specimen_id": specimen_id,
		"species_id": species_id,
		"nickname": nickname,
		"generation": generation,
		"parent_a_id": parent_a_id,
		"parent_b_id": parent_b_id,
		"origin_seed": origin_seed,
		"genotype": genotype.serialize() if genotype != null else {},
		"phenotype": phenotype.serialize() if phenotype != null else {}
	}


static func deserialize(data: Dictionary) -> FlowerSpecimen:
	var s := FlowerSpecimen.new()
	s.specimen_id = String(data.get("specimen_id", ""))
	s.species_id = String(data.get("species_id", "rose"))
	s.nickname = String(data.get("nickname", ""))
	s.generation = int(data.get("generation", 0))
	s.parent_a_id = String(data.get("parent_a_id", ""))
	s.parent_b_id = String(data.get("parent_b_id", ""))
	s.origin_seed = int(data.get("origin_seed", 0))
	
	if data.has("genotype") and typeof(data["genotype"]) == TYPE_DICTIONARY:
		s.genotype = FlowerGenotype.deserialize(data["genotype"])
	else:
		s.genotype = FlowerGenotype.new()

	if data.has("phenotype") and typeof(data["phenotype"]) == TYPE_DICTIONARY:
		s.phenotype = FlowerPhenotype.deserialize(data["phenotype"])
	else:
		s.phenotype = FlowerPhenotype.new()

	return s
