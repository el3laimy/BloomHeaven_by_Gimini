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


static func _validate_specimen_dict(spec: Dictionary) -> Dictionary:
	if not (spec is Dictionary):
		return {"valid": false, "error": "Specimen must be a Dictionary"}
	if not spec.has("specimen_id") or not (spec["specimen_id"] is String) or (spec["specimen_id"] as String).is_empty():
		return {"valid": false, "error": "Specimen missing or empty 'specimen_id'"}
	if not spec.has("species_id") or not (spec["species_id"] is String) or (spec["species_id"] as String).is_empty():
		return {"valid": false, "error": "Specimen missing or empty 'species_id'"}
	var sp_id: String = spec["species_id"]
	if FlowerData.get_flower(sp_id).is_empty():
		return {"valid": false, "error": "Specimen '%s' has unknown species_id '%s'" % [spec["specimen_id"], sp_id]}
	if spec.has("generation") and (not (spec["generation"] is int or spec["generation"] is float) or int(spec["generation"]) < 0):
		return {"valid": false, "error": "Specimen '%s' has invalid generation: %s" % [spec["specimen_id"], str(spec.get("generation"))]}
	if spec.has("quality_tier"):
		var q = int(spec["quality_tier"])
		if not FlowerQuality.is_valid(q):
			return {"valid": false, "error": "Specimen '%s' has invalid quality_tier: %s" % [spec["specimen_id"], str(spec.get("quality_tier"))]}
	if not spec.has("genotype") or not (spec["genotype"] is Dictionary):
		return {"valid": false, "error": "Specimen '%s' missing or invalid genotype" % spec["specimen_id"]}
	var geno: Dictionary = spec["genotype"]
	var required_loci: Dictionary = {
		"color": FlowerGenotype.VALID_COLOR_ALLELES,
		"petal": FlowerGenotype.VALID_PETAL_ALLELES,
		"fragrance": FlowerGenotype.VALID_FRAGRANCE_ALLELES,
		"vigor": FlowerGenotype.VALID_VIGOR_ALLELES
	}
	for locus in required_loci:
		if not geno.has(locus) or not (geno[locus] is Array):
			return {"valid": false, "error": "Specimen '%s' genotype missing locus '%s'" % [spec["specimen_id"], locus]}
		var arr: Array = geno[locus]
		if arr.size() != 2:
			return {"valid": false, "error": "Specimen '%s' locus '%s' allele count is %d (expected 2)" % [spec["specimen_id"], locus, arr.size()]}
		var valid_alleles: Array[String] = required_loci[locus]
		for a in arr:
			if not (a is String) or not valid_alleles.has(a):
				return {"valid": false, "error": "Specimen '%s' locus '%s' contains invalid allele '%s'" % [spec["specimen_id"], locus, str(a)]}
	return {"valid": true, "error": ""}


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

	for f_id in data["flower_inventory_storage"]:
		if not (f_id is String) or FlowerData.get_flower(f_id).is_empty():
			return {"valid": false, "error": "flower_inventory_storage contains unknown flower_id '%s'" % str(f_id)}
		var tiers = data["flower_inventory_storage"][f_id]
		if not (tiers is Dictionary):
			return {"valid": false, "error": "flower_inventory_storage['%s'] must be a Dictionary" % str(f_id)}
		for q_key in tiers:
			var q_int := int(str(q_key))
			if not FlowerQuality.is_valid(q_int):
				return {"valid": false, "error": "flower_inventory_storage['%s'] invalid quality tier '%s'" % [str(f_id), str(q_key)]}
			var cnt = tiers[q_key]
			if not (cnt is int or cnt is float) or cnt < 0:
				return {"valid": false, "error": "flower_inventory_storage['%s']['%s'] count must be non-negative" % [str(f_id), str(q_key)]}

	if not data.has("seed_inventory") or not (data["seed_inventory"] is Dictionary):
		return {"valid": false, "error": "Missing or invalid 'seed_inventory'"}

	for s_key in data["seed_inventory"]:
		if not (s_key is String) or FlowerData.get_flower(s_key).is_empty():
			return {"valid": false, "error": "seed_inventory contains unknown flower_id '%s'" % str(s_key)}
		var s_val = data["seed_inventory"][s_key]
		if not (s_val is int or s_val is float) or s_val < 0:
			return {"valid": false, "error": "Invalid seed count for '%s': %s" % [str(s_key), str(s_val)]}

	if not data.has("bouquet_inventory") or not (data["bouquet_inventory"] is Dictionary):
		return {"valid": false, "error": "Missing or invalid 'bouquet_inventory'"}

	for b_id in data["bouquet_inventory"]:
		if not (b_id is String) or not BouquetData.get_all_bouquet_ids().has(b_id):
			return {"valid": false, "error": "bouquet_inventory contains unknown bouquet_id '%s'" % str(b_id)}
		var b_val = data["bouquet_inventory"][b_id]
		if not (b_val is int or b_val is float) or b_val < 0:
			return {"valid": false, "error": "Invalid bouquet count for '%s': %s" % [str(b_id), str(b_val)]}

	if data.has("perfume_inventory") and (data["perfume_inventory"] is Dictionary):
		for p_id in data["perfume_inventory"]:
			if not (p_id is String) or not PerfumeData.get_all_perfume_ids().has(p_id):
				return {"valid": false, "error": "perfume_inventory contains unknown perfume_id '%s'" % str(p_id)}
			var p_val = data["perfume_inventory"][p_id]
			if not (p_val is int or p_val is float) or p_val < 0:
				return {"valid": false, "error": "Invalid perfume count for '%s': %s" % [str(p_id), str(p_val)]}

	if data.has("discovered_flowers") and (data["discovered_flowers"] is Dictionary):
		for df_id in data["discovered_flowers"]:
			if not (df_id is String) or FlowerData.get_flower(df_id).is_empty():
				return {"valid": false, "error": "discovered_flowers contains unknown flower_id '%s'" % str(df_id)}
			if not (data["discovered_flowers"][df_id] is bool):
				return {"valid": false, "error": "discovered_flowers['%s'] must be boolean" % str(df_id)}

	if data.has("active_upgrades") and (data["active_upgrades"] is Dictionary):
		var valid_upgrades: Array[String] = ["swift_boots", "double_sprinkler", "enriched_soil", "fertilizer_box", "expanded_satchel"]
		for u_id in data["active_upgrades"]:
			if not (u_id is String) or not valid_upgrades.has(u_id):
				return {"valid": false, "error": "active_upgrades contains unknown upgrade_id '%s'" % str(u_id)}
			if not (data["active_upgrades"][u_id] is bool):
				return {"valid": false, "error": "active_upgrades['%s'] must be boolean" % str(u_id)}

	if not data.has("plots") or not (data["plots"] is Array):
		return {"valid": false, "error": "Missing or invalid 'plots' array"}

	for idx in range(data["plots"].size()):
		var p = data["plots"][idx]
		if not (p is Dictionary):
			return {"valid": false, "error": "Plot at index %d is not a Dictionary" % idx}
		if not p.has("state") or not (p["state"] is int or p["state"] is float):
			return {"valid": false, "error": "Plot at index %d missing or non-numeric 'state'" % idx}
		var st: int = int(p["state"])
		if st < 0 or st > 2:
			return {"valid": false, "error": "Plot at index %d has invalid state %d (expected 0..2)" % [idx, st]}
		var fid: String = str(p.get("current_flower_id", p.get("flower_id", "")))
		if st == 0:
			# Empty plot: flower_id may be empty or null
			pass
		else:
			# Growing (1) or Mature (2): must have valid flower_id
			if fid.is_empty() or FlowerData.get_flower(fid).is_empty():
				return {"valid": false, "error": "Plot at index %d (state %d) missing or invalid flower_id '%s'" % [idx, st, fid]}
		if p.has("current_specimen") and p["current_specimen"] != null:
			if not (p["current_specimen"] is Dictionary):
				return {"valid": false, "error": "Plot at index %d has non-dictionary current_specimen" % idx}
			var spec_res := _validate_specimen_dict(p["current_specimen"])
			if not spec_res.get("valid", false):
				return spec_res
		if p.has("quality"):
			var q: int = int(p["quality"])
			if not FlowerQuality.is_valid(q):
				return {"valid": false, "error": "Plot at index %d has invalid quality %d" % [idx, q]}

	if not data.has("breeding_roster") or not (data["breeding_roster"] is Array):
		return {"valid": false, "error": "Missing or invalid 'breeding_roster' array"}

	for idx in range(data["breeding_roster"].size()):
		var item = data["breeding_roster"][idx]
		if not (item is Dictionary):
			return {"valid": false, "error": "breeding_roster[%d] must be a Dictionary" % idx}
		var spec_res := _validate_specimen_dict(item)
		if not spec_res.get("valid", false):
			return spec_res

	if not data.has("pending_hybrid_seeds") or not (data["pending_hybrid_seeds"] is Array):
		return {"valid": false, "error": "Missing or invalid 'pending_hybrid_seeds' array"}

	for idx in range(data["pending_hybrid_seeds"].size()):
		var item = data["pending_hybrid_seeds"][idx]
		if not (item is Dictionary):
			return {"valid": false, "error": "pending_hybrid_seeds[%d] must be a Dictionary" % idx}
		var spec_res := _validate_specimen_dict(item)
		if not spec_res.get("valid", false):
			return spec_res

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
		var rem_p: float = float(o_entry["remaining_patience"])
		var max_p: float = float(o_entry["max_patience"])
		if max_p < 0.0:
			return {"valid": false, "error": "order_runtime['%s'] has negative max_patience: %s" % [str(o_id), str(max_p)]}
		if rem_p < -0.001 or rem_p > max_p + 0.001:
			return {"valid": false, "error": "Invalid patience range for order '%s': remaining %s not in [0, %s]" % [str(o_id), str(rem_p), str(max_p)]}

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
				if not (f_id is String) or FlowerData.get_flower(f_id).is_empty():
					push_error("SaveManager: Cannot migrate legacy save with unknown flower species in inventory: '%s'." % str(f_id))
					return {}
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
	# explicitly recording "legacy_reconstructed" for lineage and stable IDs derived from species & index.
	# If any unknown or unsupported hybrid species is found, migration aborts completely.
	if not d.has("pending_hybrid_seeds") or not (d["pending_hybrid_seeds"] is Array):
		var pending: Array = []
		if d.has("unknown_hybrid_seeds") and d["unknown_hybrid_seeds"] is Array:
			var legacy_list: Array = d["unknown_hybrid_seeds"]
			for idx in range(legacy_list.size()):
				var item = legacy_list[idx]
				if item is String and not item.is_empty():
					var stable_id: String = "LEGACY-%s-%03d" % [item.to_upper(), idx + 1]
					var starter_sp := GeneticsEngine.create_reconstructed_legacy_specimen(item, stable_id)
					if starter_sp != null:
						pending.append(starter_sp.serialize())
					else:
						push_error("SaveManager: Cannot migrate legacy save with unknown or unsupported hybrid species '%s'." % item)
						return {}
				elif item is Dictionary:
					var spec_val := _validate_specimen_dict(item)
					if not spec_val.get("valid", false):
						push_error("SaveManager: Cannot migrate legacy save with invalid hybrid specimen: %s" % spec_val.get("error", ""))
						return {}
					pending.append(item)
		d["pending_hybrid_seeds"] = pending

	# 4. Order Runtime: Merge completed_requests + live_orders_patience into canonical per-order records
	if not d.has("order_runtime") or not (d["order_runtime"] is Dictionary) or d["order_runtime"].is_empty():
		var order_rt: Dictionary = {}
		var comp_reqs: Dictionary = d.get("completed_requests", {})
		var live_pat: Dictionary = d.get("live_orders_patience", {})
		var all_order_ids: Array = FloristRequestData.get_all_request_ids()
		for k in comp_reqs:
			if not all_order_ids.has(k):
				all_order_ids.append(k)
		for k in live_pat:
			if not all_order_ids.has(k):
				all_order_ids.append(k)

		for o_id in all_order_ids:
			var req_data := FloristRequestData.get_request(o_id)
			var max_p: float = 0.0
			if req_data.has("patience_max_seconds"):
				max_p = float(req_data["patience_max_seconds"])
			else:
				push_warning("SaveManager: Request '%s' missing canonical 'patience_max_seconds' during migration." % o_id)
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
					var req_def := FloristRequestData.get_request(o_id)
					entry["max_patience"] = float(req_def.get("patience_max_seconds", 0.0))
				if not entry.has("remaining_patience"):
					entry["remaining_patience"] = float(entry.get("max_patience", 0.0))

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

	# 7. Strip all legacy aliases from root payload so migrated V3 contains only canonical keys
	d.erase("inventory")
	d.erase("unknown_hybrid_seeds")
	d.erase("completed_requests")
	d.erase("live_orders_patience")

	# 8. Clean up plot duplicate aliases (flower_id -> current_flower_id, specimen -> current_specimen)
	if d.has("plots") and d["plots"] is Array:
		for p in d["plots"]:
			if p is Dictionary:
				if not p.has("current_flower_id") and p.has("flower_id"):
					p["current_flower_id"] = p["flower_id"]
				p.erase("flower_id")
				if not p.has("current_specimen") and p.has("specimen"):
					p["current_specimen"] = p["specimen"]
				p.erase("specimen")

	return out


static func migrate_to_latest(root_dict: Dictionary) -> Dictionary:
	var ver: int = int(root_dict.get("version", 1))
	var current: Dictionary = root_dict
	if ver == 1:
		current = migrate_v1_to_v2(current)
		if current.is_empty():
			return {}
		ver = 2
	if ver == 2:
		current = migrate_v2_to_v3(current)
		if current.is_empty():
			return {}
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

	# 6. Promote temp file to primary atomically
	var promote_ok := _promote_temp_to_primary(tmp_path, target_path, bak_path)
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

	# Strip all legacy aliases so canonical V3 payload contains only single source of truth
	d.erase("inventory")
	d.erase("unknown_hybrid_seeds")
	d.erase("completed_requests")
	d.erase("live_orders_patience")

	if d.has("plots") and d["plots"] is Array:
		for p in d["plots"]:
			if p is Dictionary:
				if not p.has("current_flower_id") and p.has("flower_id"):
					p["current_flower_id"] = p["flower_id"]
				p.erase("flower_id")
				if not p.has("current_specimen") and p.has("specimen"):
					p["current_specimen"] = p["specimen"]
				p.erase("specimen")

	return d


# Test seams for failure injection during atomic promotion verification
static var _test_inject_first_rename_failure: bool = false
static var _test_inject_second_rename_failure: bool = false

static func _promote_temp_to_primary(tmp_path: String, target_path: String, bak_path: String) -> bool:
	if not FileAccess.file_exists(tmp_path):
		printerr("SaveManager: Temp file %s does not exist for promotion." % tmp_path)
		return false

	# 1. Try atomic rename directly
	var err := DirAccess.rename_absolute(tmp_path, target_path)
	if _test_inject_first_rename_failure:
		err = FAILED
	if err == OK:
		return true

	# 2. If direct rename failed, target may exist and OS does not overwrite on rename
	if FileAccess.file_exists(target_path):
		var remove_err := DirAccess.remove_absolute(target_path)
		if remove_err == OK:
			err = DirAccess.rename_absolute(tmp_path, target_path)
			if _test_inject_second_rename_failure:
				err = FAILED
			if err == OK:
				return true
			# Promotion failed after removing target: restore from backup if available
			push_error("SaveManager: Rename failed after target removal (code %d). Restoring target from backup %s..." % [err, bak_path])
			if FileAccess.file_exists(bak_path):
				_copy_file(bak_path, target_path)
		else:
			push_error("SaveManager: Failed to remove existing target %s for promotion (code %d)." % [target_path, remove_err])

	# 3. Clean up tmp file on failure if still present
	if FileAccess.file_exists(tmp_path):
		DirAccess.remove_absolute(tmp_path)

	return false


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
