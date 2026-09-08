extends SceneTree

## Headless Data Validator for Finest Garden.
## Validates data/flowers.json, data/bouquets.json, data/perfumes.json, data/requests.json.

func _init() -> void:
	print("==================================================")
	print("FINEST GARDEN — HEADLESS DATA VALIDATOR")
	print("==================================================")

	var errors: Array[String] = []

	# 1. Validate flowers.json
	var flowers_path := "res://data/flowers.json"
	var flowers_data := _load_json(flowers_path, errors)
	var valid_flower_ids: Array[String] = []

	if flowers_data.has("flowers") and flowers_data["flowers"] is Dictionary:
		var flowers_dict: Dictionary = flowers_data["flowers"]
		for f_id in flowers_dict:
			valid_flower_ids.append(f_id)
			var flower: Dictionary = flowers_dict[f_id]
			if not flower.has("display_name"):
				errors.append("Flower '%s' missing 'display_name'" % f_id)
			if not flower.has("base_growth_seconds"):
				errors.append("Flower '%s' missing 'base_growth_seconds'" % f_id)
			
			# Check sprite paths if defined
			if flower.has("master_sprite"):
				var spr: String = flower["master_sprite"]
				if not ResourceLoader.exists(spr) and not FileAccess.file_exists(spr):
					errors.append("Flower '%s' master_sprite not found: %s" % [f_id, spr])
			
			if flower.has("branching_stages"):
				var b_stages: Dictionary = flower["branching_stages"]
				for stage_name in b_stages:
					var stage_path: String = b_stages[stage_name]
					if not ResourceLoader.exists(stage_path) and not FileAccess.file_exists(stage_path):
						errors.append("Flower '%s' branching stage '%s' sprite not found: %s" % [f_id, stage_name, stage_path])
	else:
		errors.append("flowers.json missing 'flowers' dictionary.")

	print("✓ [DATA] Flowers validated (%d species registered)." % valid_flower_ids.size())

	# 2. Validate bouquets.json
	var bouquets_path := "res://data/bouquets.json"
	var bouquets_data := _load_json(bouquets_path, errors)
	var valid_bouquet_ids: Array[String] = []

	if bouquets_data.has("bouquets") and bouquets_data["bouquets"] is Dictionary:
		var b_dict: Dictionary = bouquets_data["bouquets"]
		for b_id in b_dict:
			valid_bouquet_ids.append(b_id)
			var bq: Dictionary = b_dict[b_id]
			var ings: Dictionary = bq.get("ingredients", {})
			for ing_id in ings:
				if not valid_flower_ids.has(ing_id):
					errors.append("Bouquet '%s' references unknown ingredient flower '%s'" % [b_id, ing_id])
	else:
		errors.append("bouquets.json missing 'bouquets' dictionary.")

	print("✓ [DATA] Bouquets validated (%d recipes registered)." % valid_bouquet_ids.size())

	# 3. Validate perfumes.json
	var perfumes_path := "res://data/perfumes.json"
	var perfumes_data := _load_json(perfumes_path, errors)
	var valid_perfume_ids: Array[String] = []

	if perfumes_data.has("perfumes") and perfumes_data["perfumes"] is Dictionary:
		var p_dict: Dictionary = perfumes_data["perfumes"]
		for p_id in p_dict:
			valid_perfume_ids.append(p_id)
			var pf: Dictionary = p_dict[p_id]
			var p_ings: Dictionary = pf.get("ingredients", {})
			for ing_id in p_ings:
				if not valid_flower_ids.has(ing_id):
					errors.append("Perfume '%s' references unknown ingredient flower '%s'" % [p_id, ing_id])
	else:
		errors.append("perfumes.json missing 'perfumes' dictionary.")

	print("✓ [DATA] Perfumes validated (%d formulas registered)." % valid_perfume_ids.size())

	# 4. Validate requests.json
	var requests_path := "res://data/requests.json"
	var requests_data := _load_json(requests_path, errors)

	if requests_data.has("requests") and requests_data["requests"] is Dictionary:
		var r_dict: Dictionary = requests_data["requests"]
		for r_id in r_dict:
			var req: Dictionary = r_dict[r_id]
			var r_type: String = req.get("type", "")
			var r_items: Dictionary = req.get("required_items", {})
			if r_type == "flowers":
				for f_id in r_items:
					if not valid_flower_ids.has(f_id):
						errors.append("Request '%s' references unknown flower '%s'" % [r_id, f_id])
			elif r_type == "bouquet":
				for b_id in r_items:
					if not valid_bouquet_ids.has(b_id):
						errors.append("Request '%s' references unknown bouquet '%s'" % [r_id, b_id])
			elif r_type == "perfume":
				for p_id in r_items:
					if not valid_perfume_ids.has(p_id):
						errors.append("Request '%s' references unknown perfume '%s'" % [r_id, p_id])
	else:
		errors.append("requests.json missing 'requests' dictionary.")

	print("✓ [DATA] Requests validated.")

	# Summary
	if not errors.is_empty():
		print("\n❌ DATA VALIDATION FAILED WITH %d ERRORS:" % errors.size())
		for err in errors:
			printerr("  - " + err)
		quit(1)
	else:
		print("\n==================================================")
		print("✅ ALL DATA SCHEMAS AND ASSET REFERENCES ARE VALID")
		print("==================================================")
		quit(0)


func _load_json(file_path: String, errors: Array[String]) -> Dictionary:
	if not FileAccess.file_exists(file_path):
		errors.append("File not found: %s" % file_path)
		return {}
	
	var file := FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		errors.append("Could not open file: %s" % file_path)
		return {}

	var text := file.get_as_text()
	var json := JSON.new()
	var parse_result := json.parse(text)
	if parse_result != OK:
		errors.append("JSON parse error in %s: %s (Line %d)" % [file_path, json.get_error_message(), json.get_error_line()])
		return {}

	if json.data is Dictionary:
		return json.data as Dictionary
	else:
		errors.append("Root of JSON in %s is not a Dictionary." % file_path)
		return {}
