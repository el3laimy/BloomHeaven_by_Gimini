class_name BouquetData
extends RefCounted

## Bouquet Recipes for Finest Garden.
## Loads data dynamically from res://data/bouquets.json.

static var _cached_bouquets: Dictionary = {}
static var _is_initialized: bool = false


static func _ensure_initialized() -> void:
	if _is_initialized and not _cached_bouquets.is_empty():
		return
	
	_cached_bouquets.clear()
	var path := "res://data/bouquets.json"
	if FileAccess.file_exists(path):
		var file := FileAccess.open(path, FileAccess.READ)
		if file != null:
			var json := JSON.new()
			if json.parse(file.get_as_text()) == OK and json.data is Dictionary:
				var raw_dict: Dictionary = json.data.get("bouquets", {})
				for b_id in raw_dict:
					var entry: Dictionary = raw_dict[b_id].duplicate()
					if entry.has("primary_color") and entry["primary_color"] is Array:
						var arr: Array = entry["primary_color"]
						if arr.size() >= 4:
							entry["primary_color"] = Color(arr[0], arr[1], arr[2], arr[3])
						elif arr.size() == 3:
							entry["primary_color"] = Color(arr[0], arr[1], arr[2], 1.0)
					_cached_bouquets[b_id] = entry
	
	if _cached_bouquets.is_empty():
		_cached_bouquets = {
			"garden_harmony": {
				"id": "garden_harmony",
				"display_name": "Garden Harmony",
				"ingredients": {"rose": 1, "lavender": 1, "sunflower": 1},
				"is_hybrid": false,
				"primary_color": Color(0.90, 0.78, 0.35, 1.0),
				"description": "A balanced arrangement uniting red rose, lavender, and sunflower."
			},
			"crimson_romance": {
				"id": "crimson_romance",
				"display_name": "Crimson Romance",
				"ingredients": {"rose": 2, "lavender": 1},
				"is_hybrid": false,
				"primary_color": Color(0.92, 0.28, 0.42, 1.0),
				"description": "A classic romantic bouquet featuring velvety crimson roses."
			},
			"ethereal_lumina": {
				"id": "ethereal_lumina",
				"display_name": "Ethereal Lumina",
				"ingredients": {"roselight": 1, "rose": 1},
				"is_hybrid": true,
				"primary_color": Color(0.92, 0.45, 0.88, 1.0),
				"description": "A showcase bouquet pairing rose with glowing Roselight petals."
			}
		}
	
	_is_initialized = true


static func get_bouquet(bouquet_id: String) -> Dictionary:
	_ensure_initialized()
	if _cached_bouquets.has(bouquet_id):
		return _cached_bouquets[bouquet_id]
	return {}


static func get_all_bouquet_ids() -> Array[String]:
	_ensure_initialized()
	var res: Array[String] = []
	for b_id in _cached_bouquets:
		res.append(b_id)
	return res


## Returns a Dictionary with "can_craft": bool and "missing": Array[String]
static func check_ingredients(bouquet_id: String, inventory) -> Dictionary:
	var b_data := get_bouquet(bouquet_id)
	if b_data.is_empty():
		return {
			"can_craft": false,
			"missing": ["Unknown bouquet recipe."]
		}

	var ingredients: Dictionary = b_data.get("ingredients", {})
	var can_craft := true
	var missing: Array[String] = []

	for flower_id in ingredients:
		var needed: int = int(ingredients[flower_id])
		var have: int = 0
		if inventory is FlowerInventory:
			have = inventory.get_flower_count(flower_id)
		elif inventory is Dictionary:
			have = int(inventory.get(flower_id, 0))
		if have < needed:
			can_craft = false
			var flower_name: String = FlowerData.get_flower(flower_id).get("display_name", flower_id)
			missing.append("%s (need %d, have %d)" % [flower_name, needed, have])

	return {
		"can_craft": can_craft,
		"missing": missing
	}


## Atomically crafts a bouquet if all ingredients are available.
## Supports FlowerInventory (canonical) or legacy Dictionary for flower_inventory.
## Returns a Dictionary with:
##   "success": bool
##   "bouquet_id": String
##   "display_name": String (if success)
##   "error": String (if failure)
static func craft_bouquet(bouquet_id: String, flower_inventory, bouquet_inventory: Dictionary) -> Dictionary:
	# 1. Validate bouquet ID
	if bouquet_id.is_empty():
		return {"success": false, "error": "Bouquet ID cannot be empty."}

	# 2. Load canonical recipe
	var b_data := get_bouquet(bouquet_id)
	if b_data.is_empty():
		return {"success": false, "error": "Unknown bouquet recipe: %s" % bouquet_id}

	# 3. Build requirement plan
	var ingredients: Dictionary = b_data.get("ingredients", {})
	if ingredients.is_empty():
		return {"success": false, "error": "Bouquet recipe has no ingredients."}

	# 4. Validate ALL ingredients before any deduction (zero mutation on failure)
	if flower_inventory is FlowerInventory:
		if not flower_inventory.can_consume_requirements(ingredients, "lowest_first"):
			return {"success": false, "error": "Missing ingredients for %s!" % b_data.get("display_name", bouquet_id)}
	elif flower_inventory is Dictionary:
		for flower_id in ingredients:
			var needed: int = int(ingredients[flower_id])
			if int(flower_inventory.get(flower_id, 0)) < needed:
				return {"success": false, "error": "Missing ingredients for %s!" % b_data.get("display_name", bouquet_id)}
	else:
		return {"success": false, "error": "Invalid flower inventory type."}

	# 5. Commit deductions atomically
	if flower_inventory is FlowerInventory:
		var consumed: bool = flower_inventory.consume_requirements(ingredients, "lowest_first")
		if not consumed:
			return {"success": false, "error": "Failed to consume ingredients for %s!" % b_data.get("display_name", bouquet_id)}
	elif flower_inventory is Dictionary:
		for flower_id in ingredients:
			flower_inventory[flower_id] = int(flower_inventory[flower_id]) - int(ingredients[flower_id])

	# 6. Add bouquet to bouquet_inventory
	bouquet_inventory[bouquet_id] = int(bouquet_inventory.get(bouquet_id, 0)) + 1

	return {
		"success": true,
		"bouquet_id": bouquet_id,
		"display_name": b_data.get("display_name", bouquet_id)
	}
