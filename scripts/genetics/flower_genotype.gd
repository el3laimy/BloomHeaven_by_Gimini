class_name FlowerGenotype
extends RefCounted

## Diploid representation of 4 genetic loci for Milestone P3.
## [PROTOTYPE_ONLY]: 4-locus model with 3 color, 3 petal, 2 fragrance, and 2 vigor alleles.

const VALID_COLOR_ALLELES: Array[String] = ["Cr", "Cp", "Cy"]
const VALID_PETAL_ALLELES: Array[String] = ["Pr", "Ps", "Pp"]
const VALID_FRAGRANCE_ALLELES: Array[String] = ["F+", "f-"]
const VALID_VIGOR_ALLELES: Array[String] = ["V+", "v-"]

var color_alleles: Array[String] = ["Cr", "Cr"]
var petal_alleles: Array[String] = ["Pr", "Pr"]
var fragrance_alleles: Array[String] = ["F+", "f-"]
var vigor_alleles: Array[String] = ["V+", "v-"]


func _init(
	p_color: Array[String] = ["Cr", "Cr"],
	p_petal: Array[String] = ["Pr", "Pr"],
	p_fragrance: Array[String] = ["F+", "f-"],
	p_vigor: Array[String] = ["V+", "v-"]
) -> void:
	color_alleles = p_color.duplicate()
	petal_alleles = p_petal.duplicate()
	fragrance_alleles = p_fragrance.duplicate()
	vigor_alleles = p_vigor.duplicate()


func validate() -> Dictionary:
	# Returns { "valid": bool, "error": String }
	if color_alleles.size() != 2:
		return {"valid": false, "error": "Color locus must contain exactly 2 alleles."}
	for a in color_alleles:
		if not VALID_COLOR_ALLELES.has(a):
			return {"valid": false, "error": "Invalid color allele: '%s'" % a}

	if petal_alleles.size() != 2:
		return {"valid": false, "error": "Petal locus must contain exactly 2 alleles."}
	for a in petal_alleles:
		if not VALID_PETAL_ALLELES.has(a):
			return {"valid": false, "error": "Invalid petal allele: '%s'" % a}

	if fragrance_alleles.size() != 2:
		return {"valid": false, "error": "Fragrance locus must contain exactly 2 alleles."}
	for a in fragrance_alleles:
		if not VALID_FRAGRANCE_ALLELES.has(a):
			return {"valid": false, "error": "Invalid fragrance allele: '%s'" % a}

	if vigor_alleles.size() != 2:
		return {"valid": false, "error": "Vigor locus must contain exactly 2 alleles."}
	for a in vigor_alleles:
		if not VALID_VIGOR_ALLELES.has(a):
			return {"valid": false, "error": "Invalid vigor allele: '%s'" % a}

	return {"valid": true, "error": ""}


func clone() -> FlowerGenotype:
	var copy := FlowerGenotype.new(
		color_alleles.duplicate(),
		petal_alleles.duplicate(),
		fragrance_alleles.duplicate(),
		vigor_alleles.duplicate()
	)
	return copy


func serialize() -> Dictionary:
	return {
		"color": color_alleles.duplicate(),
		"petal": petal_alleles.duplicate(),
		"fragrance": fragrance_alleles.duplicate(),
		"vigor": vigor_alleles.duplicate()
	}


static func deserialize(data: Dictionary) -> FlowerGenotype:
	var g := FlowerGenotype.new()
	if data.has("color"):
		var c_arr: Array = data["color"]
		g.color_alleles = [String(c_arr[0]), String(c_arr[1])]
	if data.has("petal"):
		var p_arr: Array = data["petal"]
		g.petal_alleles = [String(p_arr[0]), String(p_arr[1])]
	if data.has("fragrance"):
		var f_arr: Array = data["fragrance"]
		g.fragrance_alleles = [String(f_arr[0]), String(f_arr[1])]
	if data.has("vigor"):
		var v_arr: Array = data["vigor"]
		g.vigor_alleles = [String(v_arr[0]), String(v_arr[1])]
	return g
