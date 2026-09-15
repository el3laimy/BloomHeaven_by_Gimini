class_name FlowerData
extends RefCounted

## Flower definitions and deterministic breeding rules for Finest Garden.
## Loads data dynamically from res://data/flowers.json with fallback cache.

static var _cached_flowers: Dictionary = {}
static var _is_initialized: bool = false


static func _ensure_initialized() -> void:
	if _is_initialized and not _cached_flowers.is_empty():
		return
	
	_cached_flowers.clear()
	var path := "res://data/flowers.json"
	if FileAccess.file_exists(path):
		var file := FileAccess.open(path, FileAccess.READ)
		if file != null:
			var json := JSON.new()
			if json.parse(file.get_as_text()) == OK and json.data is Dictionary:
				var raw_dict: Dictionary = json.data.get("flowers", {})
				for f_id in raw_dict:
					var entry: Dictionary = raw_dict[f_id].duplicate()
					# Convert color arrays to Color objects
					for col_key in ["primary_color", "secondary_color", "accent_color", "stem_color", "leaf_color"]:
						if entry.has(col_key) and entry[col_key] is Array:
							var arr: Array = entry[col_key]
							if arr.size() >= 4:
								entry[col_key] = Color(arr[0], arr[1], arr[2], arr[3])
							elif arr.size() == 3:
								entry[col_key] = Color(arr[0], arr[1], arr[2], 1.0)
					_cached_flowers[f_id] = entry
	
	if _cached_flowers.is_empty():
		# Built-in fallback
		_cached_flowers = _get_default_flowers()
	
	_is_initialized = true


static func get_canonical_id(flower_id: String) -> String:
	_ensure_initialized()
	if not _cached_flowers.has(flower_id):
		return ""
	var entry: Dictionary = _cached_flowers[flower_id]
	if entry.get("status") == "alias":
		var target: String = entry.get("alias_of", "")
		if target.is_empty() or target == flower_id:
			return "" # Broken or self-referential alias
		if not _cached_flowers.has(target):
			return "" # Target missing
		var target_entry: Dictionary = _cached_flowers[target]
		if target_entry.get("status") == "alias":
			return "" # Circular or chained alias rejected
		return target
	return flower_id


static func get_flower(flower_id: String) -> Dictionary:
	_ensure_initialized()
	var canon_id := get_canonical_id(flower_id)
	if not canon_id.is_empty() and _cached_flowers.has(canon_id):
		return _cached_flowers[canon_id]
	return {}


static func get_cvp_base_species() -> Array[String]:
	_ensure_initialized()
	var res: Array[String] = []
	for f_id in _cached_flowers:
		var entry: Dictionary = _cached_flowers[f_id]
		if entry.get("status") == "cvp_base":
			res.append(f_id)
	return res


static func get_curated_hybrids() -> Array[String]:
	_ensure_initialized()
	var res: Array[String] = []
	for f_id in _cached_flowers:
		var entry: Dictionary = _cached_flowers[f_id]
		if entry.get("status") == "cvp_hybrid":
			res.append(f_id)
	return res


static func get_legacy_species() -> Array[String]:
	_ensure_initialized()
	var res: Array[String] = []
	for f_id in _cached_flowers:
		var entry: Dictionary = _cached_flowers[f_id]
		if entry.get("status") == "legacy":
			res.append(f_id)
	return res


static func get_base_flower_ids() -> Array[String]:
	_ensure_initialized()
	var res: Array[String] = []
	for f_id in _cached_flowers:
		var entry: Dictionary = _cached_flowers[f_id]
		if entry.get("status") != "alias" and not entry.get("is_hybrid", false):
			res.append(f_id)
	return res


static func get_hybrid_flower_ids() -> Array[String]:
	_ensure_initialized()
	var res: Array[String] = []
	for f_id in _cached_flowers:
		var entry: Dictionary = _cached_flowers[f_id]
		if entry.get("status") != "alias" and entry.get("is_hybrid", false):
			res.append(f_id)
	return res


static func get_all_flower_ids() -> Array[String]:
	_ensure_initialized()
	var res: Array[String] = []
	for f_id in _cached_flowers:
		if _cached_flowers[f_id].get("status") != "alias":
			res.append(f_id)
	return res


## Deterministic breeding cross resolver for CVP Handcrafted Hybrids & Legacy Crosses
static func get_breeding_result(parent_a: String, parent_b: String) -> String:
	_ensure_initialized()
	var canon_a := get_canonical_id(parent_a)
	var canon_b := get_canonical_id(parent_b)
	if canon_a.is_empty() or canon_b.is_empty():
		return ""
	var pair := [canon_a, canon_b]
	pair.sort()

	# CVP Curated 6 Handcrafted Hybrids
	if pair == ["daisy", "rose"]:
		return "blushbell"
	elif pair == ["lavender", "rose"]:
		return "velvet_dusk"
	elif pair == ["lavender", "tulip"]:
		return "twilight_bell"
	elif pair == ["daisy", "tulip"]:
		return "sunburst_daisy"
	elif pair == ["rose", "tulip"]:
		return "crown_petal"
	elif pair == ["daisy", "lavender"]:
		return "meadow_mist"
	# Legacy cross pairs
	elif pair == ["rose", "sunflower"]:
		return "golden_rose"
	elif pair == ["lavender", "sunflower"]:
		return "sunflare_spike"
	elif canon_a == canon_b:
		return canon_a

	return ""


static func _get_default_flowers() -> Dictionary:
	return {
		"rose": {
			"id": "rose",
			"display_name": "Red Rose",
			"is_hybrid": false,
			"parents": [],
			"base_growth_seconds": 6.0,
			"primary_color": Color(0.92, 0.22, 0.28, 1.0),
			"secondary_color": Color(0.72, 0.12, 0.18, 1.0),
			"accent_color": Color(1.0, 0.45, 0.50, 1.0),
			"stem_color": Color(0.24, 0.52, 0.28, 1.0),
			"leaf_color": Color(0.18, 0.44, 0.22, 1.0),
			"bloom_size": 24.0,
			"stages": ["Seed Mounded", "Tiny Sprout", "Rose Bush Bud", "Blooming Rose"],
			"description": "A fragrant, classic crimson rose with velvety petals."
		},
		"lavender": {
			"id": "lavender",
			"display_name": "Lavender",
			"is_hybrid": false,
			"parents": [],
			"base_growth_seconds": 8.0,
			"primary_color": Color(0.68, 0.50, 0.88, 1.0),
			"secondary_color": Color(0.48, 0.32, 0.70, 1.0),
			"accent_color": Color(0.85, 0.75, 0.98, 1.0),
			"stem_color": Color(0.32, 0.56, 0.36, 1.0),
			"leaf_color": Color(0.26, 0.48, 0.30, 1.0),
			"bloom_size": 20.0,
			"stages": ["Seed Mounded", "Silver Sprout", "Tall Stalk", "Flowering Spike"],
			"description": "Calming, aromatic lavender stalks that sway gently in the breeze."
		},
		"sunflower": {
			"id": "sunflower",
			"display_name": "Sunflower",
			"is_hybrid": false,
			"parents": [],
			"base_growth_seconds": 10.0,
			"primary_color": Color(1.0, 0.82, 0.14, 1.0),
			"secondary_color": Color(0.42, 0.25, 0.12, 1.0),
			"accent_color": Color(1.0, 0.94, 0.40, 1.0),
			"stem_color": Color(0.28, 0.58, 0.25, 1.0),
			"leaf_color": Color(0.22, 0.50, 0.20, 1.0),
			"bloom_size": 28.0,
			"stages": ["Seed Mounded", "Heart Sprout", "Broad-Leaf Stalk", "Radiant Sunbloom"],
			"description": "A tall, cheerful sunflower facing the warm morning light."
		}
	}
