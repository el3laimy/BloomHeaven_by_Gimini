class_name SaveManager
extends RefCounted

## Save & Load Manager V3 for BloomHaven.
## Handles schema versioning, formal migrations (V1->V2->V3), atomic saves (.tmp),
## safe backup rotation (.bak), and robust multi-tier fallback recovery.

const SAVE_PATH_V3: String = "user://bloomhaven_save_v3.json"
const SAVE_PATH_V3_BAK: String = "user://bloomhaven_save_v3.bak"
const SAVE_PATH_V3_TMP: String = "user://bloomhaven_save_v3.tmp"
const SAVE_PATH_V2: String = "user://bloomhaven_save_v2.json"
const SAVE_PATH_V2_BAK: String = "user://bloomhaven_save_v2.bak"
const SAVE_PATH_V1: String = "user://finest_garden_save_v1.json"

const SAVE_PATH: String = SAVE_PATH_V3
const CURRENT_VERSION: int = 3
const SAVE_SCHEMA_VERSION: int = 3


static func get_active_save_path() -> String:
	if FileAccess.file_exists(SAVE_PATH_V3):
		return SAVE_PATH_V3
	elif FileAccess.file_exists(SAVE_PATH_V3_BAK):
		return SAVE_PATH_V3_BAK
	elif FileAccess.file_exists(SAVE_PATH_V2):
		return SAVE_PATH_V2
	elif FileAccess.file_exists(SAVE_PATH_V2_BAK):
		return SAVE_PATH_V2_BAK
	elif FileAccess.file_exists(SAVE_PATH_V1):
		return SAVE_PATH_V1
	return SAVE_PATH_V3


static func has_save(target_path: String = SAVE_PATH_V3) -> bool:
	var bak_path := target_path.get_basename() + ".bak"
	if target_path == SAVE_PATH_V3:
		return FileAccess.file_exists(target_path) \
			or FileAccess.file_exists(bak_path) \
			or FileAccess.file_exists(SAVE_PATH_V2) \
			or FileAccess.file_exists(SAVE_PATH_V2_BAK) \
			or FileAccess.file_exists(SAVE_PATH_V1)
	return FileAccess.file_exists(target_path) or FileAccess.file_exists(bak_path)


static func delete_save(target_path: String = SAVE_PATH_V3) -> bool:
	var success: bool = true
	var bak_path := target_path.get_basename() + ".bak"
	var tmp_path := target_path + ".tmp"
	var files_to_delete: Array[String] = [
		target_path,
		bak_path,
		tmp_path
	]
	if target_path == SAVE_PATH_V3:
		files_to_delete.append(SAVE_PATH_V2)
		files_to_delete.append(SAVE_PATH_V2_BAK)
		files_to_delete.append(SAVE_PATH_V1)

	for f in files_to_delete:
		if FileAccess.file_exists(f):
			var err := DirAccess.remove_absolute(f)
			if err != OK:
				success = false
	return success


## Validates V3 root schema. Strictly validates only; never clamps or modifies data.
static func validate_schema(root_dict: Dictionary) -> Dictionary:
	if root_dict == null or not (root_dict is Dictionary):
		return {"valid": false, "error": "Root payload must be a Dictionary"}

	var ver = root_dict.get("version", null)
	if ver == null or not (ver is int or ver is float) or int(ver) != SAVE_SCHEMA_VERSION:
		return {"valid": false, "error": "Invalid or unsupported version: %s (expected %d)" % [str(ver), SAVE_SCHEMA_VERSION]}

	if not root_dict.has("data") or not (root_dict["data"] is Dictionary):
		return {"valid": false, "error": "Missing or invalid 'data' dictionary"}

	var data: Dictionary = root_dict["data"]

	if not data.has("coins") or not (data["coins"] is int or data["coins"] is float) or data["coins"] < 0:
		return {"valid": false, "error": "Invalid or missing 'coins' (must be non-negative number)"}

	if not data.has("specimen_counter") or not (data["specimen_counter"] is int or data["specimen_counter"] is float) or data["specimen_counter"] < 0:
		return {"valid": false, "error": "Invalid or missing 'specimen_counter'"}

	if not data.has("flower_inventory_storage") or not (data["flower_inventory_storage"] is Dictionary):
		return {"valid": false, "error": "Missing or invalid 'flower_inventory_storage'"}

	if not data.has("seed_inventory") or not (data["seed_inventory"] is Dictionary):
		return {"valid": false, "error": "Missing or invalid 'seed_inventory'"}

	for s_key in data["seed_inventory"]:
		var s_val = data["seed_inventory"][s_key]
		if not (s_val is int or s_val is float) or s_val < 0:
			return {"valid": false, "error": "Invalid seed count for '%s': %s" % [str(s_key), str(s_val)]}

	if not data.has("plots") or not (data["plots"] is Array):
		return {"valid": false, "error": "Missing or invalid 'plots' array"}

	if not data.has("breeding_roster") or not (data["breeding_roster"] is Array):
		return {"valid": false, "error": "Missing or invalid 'breeding_roster' array"}

	if not data.has("pending_hybrid_seeds") or not (data["pending_hybrid_seeds"] is Array):
		return {"valid": false, "error": "Missing or invalid 'pending_hybrid_seeds' array"}

	if not data.has("bouquet_inventory") or not (data["bouquet_inventory"] is Dictionary):
		return {"valid": false, "error": "Missing or invalid 'bouquet_inventory'"}

	if not data.has("order_runtime") or not (data["order_runtime"] is Dictionary):
		return {"valid": false, "error": "Missing or invalid 'order_runtime'"}

	for o_id in data["order_runtime"]:
		var o_entry = data["order_runtime"][o_id]
		if not (o_entry is Dictionary):
			return {"valid": false, "error": "Invalid order_runtime entry for '%s' (must be Dictionary)" % str(o_id)}
		if not o_entry.has("completed") or not (o_entry["completed"] is bool):
			return {"valid": false, "error": "Missing or non-bool 'completed' in order_runtime['%s']" % str(o_id)}
		if not o_entry.has("remaining_patience") or not (o_entry["remaining_patience"] is int or o_entry["remaining_patience"] is float):
			return {"valid": false, "error": "Missing or non-numeric 'remaining_patience' in order_runtime['%s']" % str(o_id)}
		if not o_entry.has("max_patience") or not (o_entry["max_patience"] is int or o_entry["max_patience"] is float):
			return {"valid": false, "error": "Missing or non-numeric 'max_patience' in order_runtime['%s']" % str(o_id)}

	return {"valid": true, "error": ""}


static func migrate_v1_to_v2(raw_v1: Dictionary) -> Dictionary:
	var out: Dictionary = raw_v1.duplicate(true)
	out["version"] = 2
	out["game_title"] = "BloomHaven CVP"
	if not out.has("timestamp"):
		out["timestamp"] = Time.get_unix_time_from_system()
	if not out.has("data") or not (out["data"] is Dictionary):
		out["data"] = {}
	var d: Dictionary = out["data"]
	if d.has("bouquet_inventory") and d["bouquet_inventory"] is Dictionary:
		for k in d["bouquet_inventory"]:
			d["bouquet_inventory"][k] = int(round(float(d["bouquet_inventory"][k])))
	return out


static func migrate_v2_to_v3(raw_v2: Dictionary) -> Dictionary:
	var out: Dictionary = raw_v2.duplicate(true)
	out["version"] = 3
	out["game_title"] = "BloomHaven CVP"
	if not out.has("timestamp"):
		out["timestamp"] = Time.get_unix_time_from_system()
	if not out.has("data") or not (out["data"] is Dictionary):
		out["data"] = {}
	var d: Dictionary = out["data"]

	# 1. Flower Inventory: Convert flat { flower_id: count } -> { flower_id: { "1": count } } (Normal tier)
	if not d.has("flower_inventory_storage") or not (d["flower_inventory_storage"] is Dictionary):
		var converted_storage: Dictionary = {}
		if d.has("inventory") and d["inventory"] is Dictionary:
			for f_id in d["inventory"]:
				var count: int = int(d["inventory"][f_id])
				if count > 0:
					converted_storage[f_id] = { str(FlowerQuality.Tier.NORMAL): count }
		d["flower_inventory_storage"] = converted_storage

	# 2. Seed Inventory: Deterministic migration policy for legacy saves lacking SeedInventory
	if not d.has("seed_inventory") or not (d["seed_inventory"] is Dictionary) or d["seed_inventory"].is_empty():
		d["seed_inventory"] = {
			"rose": 5,
			"tulip": 5,
			"daisy": 5,
			"lavender": 5
		}

	# 3. Pending Hybrids: Deterministic legacy reconstruction for historical string arrays
	# Legacy V1/V2 only stored string IDs (unknown_hybrid_seeds: ["species_id"]).
	# Historical genotype, phenotype, parents, and generation were not tracked in legacy schemas.
	# We perform deterministic legacy reconstruction (preserving species_id with valid starter genetics),
	# explicitly recording "legacy_reconstructed" for lineage, while lossless preservation is guaranteed for V3 serialized specimens.
	if not d.has("pending_hybrid_seeds") or not (d["pending_hybrid_seeds"] is Array):
		var pending: Array = []
		if d.has("unknown_hybrid_seeds") and d["unknown_hybrid_seeds"] is Array:
			for item in d["unknown_hybrid_seeds"]:
				if item is String and not item.is_empty():
					var starter_sp := GeneticsEngine.create_starter_specimen(item)
					starter_sp.parent_a_id = "legacy_reconstructed"
					starter_sp.parent_b_id = "legacy_reconstructed"
					starter_sp.generation = 1
					pending.append(starter_sp.serialize())
				elif item is Dictionary:
					pending.append(item)
		d["pending_hybrid_seeds"] = pending

	# 4. Order Runtime: Merge completed_requests + live_orders_patience into canonical per-order records
	if not d.has("order_runtime") or not (d["order_runtime"] is Dictionary) or d["order_runtime"].is_empty():
		var order_rt: Dictionary = {}
		var comp_reqs: Dictionary = d.get("completed_requests", {})
		var live_pat: Dictionary = d.get("live_orders_patience", {})
		var all_order_ids: Array = ["order_1", "order_2", "order_3", "order_4", "order_5", "order_6"]
		for k in comp_reqs:
			if not all_order_ids.has(k):
				all_order_ids.append(k)
		for k in live_pat:
			if not all_order_ids.has(k):
				all_order_ids.append(k)

		for o_id in all_order_ids:
			var req_data := FloristRequestData.get_request(o_id)
			var max_p: float = float(req_data.get("patience_max_seconds", 75.0)) if not req_data.is_empty() else 75.0
			var is_comp: bool = bool(comp_reqs.get(o_id, false))
			var rem_p: float = float(live_pat.get(o_id, 0.0 if is_comp else max_p))
			order_rt[o_id] = {
				"completed": is_comp,
				"remaining_patience": rem_p,
				"max_patience": max_p
			}
		d["order_runtime"] = order_rt
	else:
		# Ensure every entry in existing order_runtime satisfies the canonical structure
		for o_id in d["order_runtime"]:
			var entry = d["order_runtime"][o_id]
			if entry is Dictionary:
				if not entry.has("completed"):
					entry["completed"] = false
				if not entry.has("max_patience"):
					entry["max_patience"] = 75.0
				if not entry.has("remaining_patience"):
					entry["remaining_patience"] = float(entry.get("max_patience", 75.0))

	# 5. Specimen Counter: Scan all existing specimen IDs
	var scanned_max: int = _scan_max_specimen_id(d)
	var existing_counter: int = int(d.get("specimen_counter", 100))
	d["specimen_counter"] = maxi(existing_counter, scanned_max)

	# 6. Ensure other standard CVP fields exist
	if not d.has("coins"): d["coins"] = 0
	if not d.has("plots"): d["plots"] = []
	if not d.has("breeding_roster"): d["breeding_roster"] = []
	if not d.has("bouquet_inventory"): d["bouquet_inventory"] = {}
	if not d.has("perfume_inventory"): d["perfume_inventory"] = {}
	if not d.has("discovered_flowers"): d["discovered_flowers"] = {}
	if not d.has("active_upgrades"): d["active_upgrades"] = {}
	if not d.has("tutorial_completed"): d["tutorial_completed"] = false

	return out


static func migrate_to_latest(root_dict: Dictionary) -> Dictionary:
	var ver: int = int(root_dict.get("version", 1))
	var current: Dictionary = root_dict
	if ver == 1:
		current = migrate_v1_to_v2(current)
		ver = 2
	if ver == 2:
		current = migrate_v2_to_v3(current)
		ver = 3

	# Requirement 5: Migrated payload must pass validate_schema
	var val_res := validate_schema(current)
	if not val_res.get("valid", false):
		push_error("SaveManager: Migrated payload failed schema validation: %s" % str(val_res.get("error", "")))
		return {}
	return current


## Atomic save with .tmp write, read-back verification, and safe .bak rotation
static func save_game(state_data: Dictionary, target_path: String = SAVE_PATH_V3) -> bool:
	var canonical_data := _ensure_canonical_data_shape(state_data)
	var payload: Dictionary = {
		"version": SAVE_SCHEMA_VERSION,
		"timestamp": Time.get_unix_time_from_system(),
		"game_title": "BloomHaven CVP",
		"data": canonical_data
	}

	# 1. Pre-validation in memory
	var pre_val := validate_schema(payload)
	if not pre_val.get("valid", false):
		printerr("SaveManager: In-memory save state failed schema validation: %s" % pre_val.get("error", ""))
		return false

	var tmp_path := target_path + ".tmp"
	var bak_path := target_path.get_basename() + ".bak"

	# 2. Write to temporary file (.tmp)
	var json_str := JSON.stringify(payload, "\t")
	var file := FileAccess.open(tmp_path, FileAccess.WRITE)
	if file == null:
		printerr("SaveManager: Failed to open temp save file for writing: %s" % tmp_path)
		return false
	file.store_string(json_str)
	file.close()

	# 3. Read back from disk to verify write integrity
	var read_back := FileAccess.open(tmp_path, FileAccess.READ)
	if read_back == null:
		printerr("SaveManager: Failed to read back temp file: %s" % tmp_path)
		if FileAccess.file_exists(tmp_path): DirAccess.remove_absolute(tmp_path)
		return false
	var read_text := read_back.get_as_text()
	read_back.close()

	var json := JSON.new()
	if json.parse(read_text) != OK or not (json.data is Dictionary):
		printerr("SaveManager: Written temp file is corrupt/invalid JSON: %s" % json.get_error_message())
		if FileAccess.file_exists(tmp_path): DirAccess.remove_absolute(tmp_path)
		return false

	# 4. Strict schema validation on disk read-back
	var disk_val := validate_schema(json.data)
	if not disk_val.get("valid", false):
		printerr("SaveManager: Written temp file failed schema validation: %s" % disk_val.get("error", ""))
		if FileAccess.file_exists(tmp_path): DirAccess.remove_absolute(tmp_path)
		return false

	# 5. Safe .bak rotation: Never overwrite a valid backup with a corrupt primary!
	if FileAccess.file_exists(target_path):
		if _is_file_valid_v3(target_path):
			_copy_file(target_path, bak_path)
		else:
			push_warning("SaveManager: Current primary %s is corrupt. Preserving existing backup and skipping backup rotation." % target_path)

	# 6. Promote temp file to primary
	var promote_ok := _copy_file(tmp_path, target_path)
	if FileAccess.file_exists(tmp_path):
		DirAccess.remove_absolute(tmp_path)

	if not promote_ok:
		printerr("SaveManager: Failed to promote temp save to primary: %s" % target_path)
		return false

	print("✓ [SAVE] Game state saved successfully to %s (v%d)." % [target_path, SAVE_SCHEMA_VERSION])
	return true


## Loads game state using the strict 6-tier recovery order:
## 1. V3 primary -> 2. V3 backup -> 3. V2 primary + migration -> 4. V2 backup + migration -> 5. V1 primary + migration -> 6. Clean failure
static func load_game(target_path: String = SAVE_PATH_V3) -> Dictionary:
	var bak_path := target_path.get_basename() + ".bak"

	# 1. Primary V3
	if FileAccess.file_exists(target_path):
		var data_v3 := _try_read_and_validate_v3(target_path)
		if not data_v3.is_empty():
			print("✓ [LOAD] Game state loaded successfully (%s - v3 primary)." % target_path.get_file())
			return data_v3
		var migrated_target := _try_read_and_migrate_legacy(target_path, -1)
		if not migrated_target.is_empty():
			print("✓ [LOAD] Migrated legacy save at %s -> v3." % target_path.get_file())
			return migrated_target
		else:
			push_warning("SaveManager: Primary save %s is corrupt or invalid schema. Attempting recovery..." % target_path)

	# 2. Backup V3
	if FileAccess.file_exists(bak_path):
		var data_bak := _try_read_and_validate_v3(bak_path)
		if not data_bak.is_empty():
			print("✓ [LOAD] Game state recovered from backup (%s - v3 backup)." % bak_path.get_file())
			return data_bak
		else:
			push_warning("SaveManager: Backup save %s is corrupt or invalid schema. Attempting legacy recovery..." % bak_path)

	# Global legacy fallthrough applies when loading default canonical save path
	if target_path == SAVE_PATH_V3:
		# 3. Primary V2 + Migration
		if FileAccess.file_exists(SAVE_PATH_V2):
			var data_v2 := _try_read_and_migrate_legacy(SAVE_PATH_V2, 2)
			if not data_v2.is_empty():
				print("✓ [LOAD] Migrated V2 primary save (%s -> v3)." % SAVE_PATH_V2.get_file())
				return data_v2

		# 4. Backup V2 + Migration
		if FileAccess.file_exists(SAVE_PATH_V2_BAK):
			var data_v2_bak := _try_read_and_migrate_legacy(SAVE_PATH_V2_BAK, 2)
			if not data_v2_bak.is_empty():
				print("✓ [LOAD] Migrated V2 backup save (%s -> v3)." % SAVE_PATH_V2_BAK.get_file())
				return data_v2_bak

		# 5. Primary V1 + Migration
		if FileAccess.file_exists(SAVE_PATH_V1):
			var data_v1 := _try_read_and_migrate_legacy(SAVE_PATH_V1, 1)
			if not data_v1.is_empty():
				print("✓ [LOAD] Migrated V1 primary save (%s -> v3)." % SAVE_PATH_V1.get_file())
				return data_v1

	# 6. Clean failure
	print("[SAVE] No valid or recoverable save file found. Clean failure.")
	return {}


## Serializes Garden Plots state into an Array of Dictionaries
static func serialize_plots(plots: Array) -> Array:
	var plots_array: Array = []
	for plot in plots:
		if plot is GardenPlot:
			plots_array.append(plot.to_dictionary())
		elif plot is Dictionary:
			plots_array.append(plot)
	return plots_array


## Deserializes plot state into GardenPlot instances
static func deserialize_plots(plots_array: Array, plots: Array) -> void:
	for p_data in plots_array:
		if not (p_data is Dictionary):
			continue
		var idx: int = int(p_data.get("index", -1))
		if idx >= 0 and idx < plots.size():
			var plot: GardenPlot = plots[idx] as GardenPlot
			if plot != null:
				plot.from_dictionary(p_data)


static func _scan_max_specimen_id(data: Dictionary) -> int:
	var max_num: int = 100
	var collections: Array = [
		data.get("breeding_roster", []),
		data.get("pending_hybrid_seeds", [])
	]
	for col in collections:
		if col is Array:
			for item in col:
				var s_id: String = ""
				if item is Dictionary:
					s_id = str(item.get("specimen_id", ""))
				elif item is FlowerSpecimen:
					s_id = item.specimen_id
				if not s_id.is_empty():
					var parts := s_id.split("-")
					if parts.size() >= 2:
						var last_part: String = parts[parts.size() - 1]
						if last_part.is_valid_int():
							var num := last_part.to_int()
							if num > max_num:
								max_num = num

	var plots_arr = data.get("plots", [])
	if plots_arr is Array:
		for p in plots_arr:
			var spec_obj: Variant = null
			if p is Dictionary:
				spec_obj = p.get("current_specimen", p.get("specimen", null))
			elif p is GardenPlot:
				spec_obj = p.current_specimen

			var s_id: String = ""
			if spec_obj is Dictionary:
				s_id = str(spec_obj.get("specimen_id", ""))
			elif spec_obj is FlowerSpecimen:
				s_id = spec_obj.specimen_id

			if not s_id.is_empty():
				var parts := s_id.split("-")
				if parts.size() >= 2:
					var last_part: String = parts[parts.size() - 1]
					if last_part.is_valid_int():
						var num := last_part.to_int()
						if num > max_num:
							max_num = num
	return max_num


static func _ensure_canonical_data_shape(state_data: Dictionary) -> Dictionary:
	var d := state_data.duplicate(true)
	if not d.has("coins"):
		d["coins"] = 0
	if not d.has("specimen_counter"):
		d["specimen_counter"] = _scan_max_specimen_id(d)
	if not d.has("flower_inventory_storage"):
		var converted_storage: Dictionary = {}
		if d.has("inventory") and d["inventory"] is Dictionary:
			for f_id in d["inventory"]:
				converted_storage[f_id] = { str(FlowerQuality.Tier.NORMAL): int(d["inventory"][f_id]) }
		d["flower_inventory_storage"] = converted_storage
	if not d.has("seed_inventory"):
		d["seed_inventory"] = {}
	if not d.has("plots"):
		d["plots"] = []
	if not d.has("breeding_roster"):
		d["breeding_roster"] = []
	if not d.has("pending_hybrid_seeds"):
		d["pending_hybrid_seeds"] = []
	if not d.has("bouquet_inventory"):
		d["bouquet_inventory"] = {}
	if not d.has("perfume_inventory"):
		d["perfume_inventory"] = {}
	if not d.has("discovered_flowers"):
		d["discovered_flowers"] = {}
	if not d.has("active_upgrades"):
		d["active_upgrades"] = {}
	if not d.has("tutorial_completed"):
		d["tutorial_completed"] = false
	if not d.has("order_runtime"):
		d["order_runtime"] = {}
	return d


static func _copy_file(src: String, dst: String) -> bool:
	var rf := FileAccess.open(src, FileAccess.READ)
	if rf == null:
		return false
	var content := rf.get_as_text()
	rf.close()
	var wf := FileAccess.open(dst, FileAccess.WRITE)
	if wf == null:
		return false
	wf.store_string(content)
	wf.close()
	return true


static func _is_file_valid_v3(path: String) -> bool:
	if not FileAccess.file_exists(path):
		return false
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return false
	var text := f.get_as_text()
	f.close()
	var json := JSON.new()
	if json.parse(text) != OK or not (json.data is Dictionary):
		return false
	var val_res := validate_schema(json.data)
	return bool(val_res.get("valid", false))


static func _try_read_and_validate_v3(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	var text := f.get_as_text()
	f.close()
	var json := JSON.new()
	if json.parse(text) != OK or not (json.data is Dictionary):
		return {}
	var val_res := validate_schema(json.data)
	if not val_res.get("valid", false):
		return {}
	return json.data.get("data", {})


static func _try_read_and_migrate_legacy(path: String, expected_ver: int) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	var text := f.get_as_text()
	f.close()
	var json := JSON.new()
	if json.parse(text) != OK or not (json.data is Dictionary):
		return {}
	var root_dict: Dictionary = json.data
	var ver: int = int(root_dict.get("version", 0))
	if expected_ver > 0 and ver != expected_ver:
		return {}
	if ver >= SAVE_SCHEMA_VERSION:
		return {}
	var migrated := migrate_to_latest(root_dict)
	if migrated.is_empty():
		return {}
	var val_res := validate_schema(migrated)
	if not val_res.get("valid", false):
		return {}
	return migrated.get("data", {})
