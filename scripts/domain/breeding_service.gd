class_name BreedingService
extends RefCounted

## Domain-level validator and service for breeding pairs and genetics operations.
## Single source of truth for breeding compatibility and requirement checks.

static func validate_pair(
	parent_a_id: String,
	parent_b_id: String,
	specimen_a: FlowerSpecimen = null,
	specimen_b: FlowerSpecimen = null,
	flower_inventory = null, # FlowerInventory or Dictionary
	breeding_roster: Array = [] # Array[FlowerSpecimen]
) -> Dictionary:
	if parent_a_id.is_empty() or parent_b_id.is_empty():
		return {
			"valid": false,
			"error": "Select two parent specimens to breed.",
			"result_species": "",
			"is_purebred": false
		}

	# 1. If specimen objects not explicitly passed, try to resolve from breeding_roster by ID
	if specimen_a == null and not breeding_roster.is_empty():
		for spec in breeding_roster:
			if is_instance_valid(spec) and spec.specimen_id == parent_a_id:
				specimen_a = spec
				break

	if specimen_b == null and not breeding_roster.is_empty():
		for spec in breeding_roster:
			if is_instance_valid(spec) and spec.specimen_id == parent_b_id:
				specimen_b = spec
				break

	# 2. Specimen Identity Validation
	if specimen_a != null and specimen_b != null:
		if specimen_a == specimen_b:
			return {
				"valid": false,
				"error": "Cannot breed a specimen with itself.",
				"result_species": "",
				"is_purebred": false
			}
		if not specimen_a.specimen_id.is_empty() and specimen_a.specimen_id == specimen_b.specimen_id:
			return {
				"valid": false,
				"error": "Cannot breed a specimen with itself.",
				"result_species": "",
				"is_purebred": false
			}

	# 3. Roster Ownership Validation (if specimen is used and roster is non-empty)
	if not breeding_roster.is_empty():
		if specimen_a != null:
			var found_a := false
			for s in breeding_roster:
				if is_instance_valid(s) and (s == specimen_a or (not s.specimen_id.is_empty() and s.specimen_id == specimen_a.specimen_id)):
					found_a = true
					break
			if not found_a:
				return {
					"valid": false,
					"error": "Parent A is not in breeding stock.",
					"result_species": "",
					"is_purebred": false
				}

		if specimen_b != null:
			var found_b := false
			for s in breeding_roster:
				if is_instance_valid(s) and (s == specimen_b or (not s.specimen_id.is_empty() and s.specimen_id == specimen_b.specimen_id)):
					found_b = true
					break
			if not found_b:
				return {
					"valid": false,
					"error": "Parent B is not in breeding stock.",
					"result_species": "",
					"is_purebred": false
				}

	# Determine species for each parent
	var species_a: String = specimen_a.species_id if specimen_a != null else parent_a_id
	var species_b: String = specimen_b.species_id if specimen_b != null else parent_b_id

	# 4. Inventory Flower Quantity Validation (if using harvested garden flowers)
	if flower_inventory != null:
		var count_a: int = 0
		var count_b: int = 0
		if flower_inventory is FlowerInventory:
			count_a = flower_inventory.get_flower_count(species_a)
			count_b = flower_inventory.get_flower_count(species_b)
		elif flower_inventory is Dictionary:
			count_a = flower_inventory.get(species_a, 0)
			count_b = flower_inventory.get(species_b, 0)

		var needed_a: int = 1 if specimen_a == null else 0
		var needed_b: int = 1 if specimen_b == null else 0

		if needed_a > 0 and needed_b > 0 and species_a == species_b:
			if count_a < 2:
				return {
					"valid": false,
					"error": "Need at least 2 flowers of this species in inventory.",
					"result_species": "",
					"is_purebred": true
				}
		else:
			if needed_a > 0 and count_a < 1:
				return {
					"valid": false,
					"error": "Insufficient flowers for Slot A in inventory.",
					"result_species": "",
					"is_purebred": false
				}
			if needed_b > 0 and count_b < 1:
				return {
					"valid": false,
					"error": "Insufficient flowers for Slot B in inventory.",
					"result_species": "",
					"is_purebred": false
				}

	# 5. Cross Compatibility Resolution
	var resolved_hybrid := GeneticsEngine.resolve_species(species_a, species_b)
	if resolved_hybrid.is_empty():
		return {
			"valid": false,
			"error": "These species cannot pollinate together.",
			"result_species": "",
			"is_purebred": false
		}

	var is_purebred := (species_a == species_b)
	return {
		"valid": true,
		"error": "",
		"result_species": resolved_hybrid,
		"is_purebred": is_purebred
	}
