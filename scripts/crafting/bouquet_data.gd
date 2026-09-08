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
	return _cached_bouquets.get("garden_harmony", {})


static func get_all_bouquet_ids() -> Array[String]:
	_ensure_initialized()
	var res: Array[String] = []
	for b_id in _cached_bouquets:
		res.append(b_id)
	return res


## Returns a Dictionary with "can_craft": bool and "missing": Array[String]
static func check_ingredients(bouquet_id: String, inventory: Dictionary) -> Dictionary:
	var b_data := get_bouquet(bouquet_id)
	var ingredients: Dictionary = b_data.get("ingredients", {})
	var can_craft := true
	var missing: Array[String] = []

	for flower_id in ingredients:
		var needed: int = int(ingredients[flower_id])
		var have: int = int(inventory.get(flower_id, 0))
		if have < needed:
			can_craft = false
			var flower_name: String = FlowerData.get_flower(flower_id).get("display_name", flower_id)
			missing.append("%s (need %d, have %d)" % [flower_name, needed, have])

	return {
		"can_craft": can_craft,
		"missing": missing
	}
