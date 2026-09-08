class_name PerfumeData
extends RefCounted

## Perfume formulas and distillation rules for Finest Garden.
## Loads data dynamically from res://data/perfumes.json.

static var _cached_perfumes: Dictionary = {}
static var _is_initialized: bool = false


static func _ensure_initialized() -> void:
	if _is_initialized and not _cached_perfumes.is_empty():
		return
	
	_cached_perfumes.clear()
	var path := "res://data/perfumes.json"
	if FileAccess.file_exists(path):
		var file := FileAccess.open(path, FileAccess.READ)
		if file != null:
			var json := JSON.new()
			if json.parse(file.get_as_text()) == OK and json.data is Dictionary:
				var raw_dict: Dictionary = json.data.get("perfumes", {})
				for p_id in raw_dict:
					var entry: Dictionary = raw_dict[p_id].duplicate()
					if entry.has("primary_color") and entry["primary_color"] is Array:
						var arr: Array = entry["primary_color"]
						if arr.size() >= 4:
							entry["primary_color"] = Color(arr[0], arr[1], arr[2], arr[3])
						elif arr.size() == 3:
							entry["primary_color"] = Color(arr[0], arr[1], arr[2], 1.0)
					_cached_perfumes[p_id] = entry
	
	_is_initialized = true


static func get_perfume(perfume_id: String) -> Dictionary:
	_ensure_initialized()
	if _cached_perfumes.has(perfume_id):
		return _cached_perfumes[perfume_id]
	return _cached_perfumes.get("lavender_mist", {})


static func get_all_perfume_ids() -> Array[String]:
	_ensure_initialized()
	var res: Array[String] = []
	for p_id in _cached_perfumes:
		res.append(p_id)
	return res


static func check_ingredients(perfume_id: String, flower_inventory: Dictionary) -> Dictionary:
	var p_data := get_perfume(perfume_id)
	var ingredients: Dictionary = p_data.get("ingredients", {})
	var can_craft := true
	var missing: Array[String] = []

	for flower_id in ingredients:
		var needed: int = int(ingredients[flower_id])
		var have: int = int(flower_inventory.get(flower_id, 0))
		if have < needed:
			can_craft = false
			var flower_name: String = FlowerData.get_flower(flower_id).get("display_name", flower_id)
			missing.append("%s (need %d, have %d)" % [flower_name, needed, have])

	return {
		"can_craft": can_craft,
		"missing": missing
	}
