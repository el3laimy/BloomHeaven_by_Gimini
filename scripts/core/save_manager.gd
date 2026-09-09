class_name SaveManager
extends RefCounted

## Save & Load Manager V1 for Finest Garden.
## Handles schema versioning, serialization, deserialization, and auto-save.

const SAVE_PATH_V2: String = "user://bloomhaven_save_v2.json"
const SAVE_PATH_V1: String = "user://finest_garden_save_v1.json"
const SAVE_PATH: String = SAVE_PATH_V2
const CURRENT_VERSION: int = 2


static func get_active_save_path() -> String:
	if FileAccess.file_exists(SAVE_PATH_V2):
		return SAVE_PATH_V2
	elif FileAccess.file_exists(SAVE_PATH_V1):
		return SAVE_PATH_V1
	return SAVE_PATH_V2


static func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH_V2) or FileAccess.file_exists(SAVE_PATH_V1)


static func delete_save() -> bool:
	var success: bool = true
	if FileAccess.file_exists(SAVE_PATH_V2):
		var err := DirAccess.remove_absolute(SAVE_PATH_V2)
		if err != OK:
			success = false
	if FileAccess.file_exists(SAVE_PATH_V1):
		var err := DirAccess.remove_absolute(SAVE_PATH_V1)
		if err != OK:
			success = false
	return success


static func save_game(state_data: Dictionary) -> bool:
	var payload: Dictionary = {
		"version": CURRENT_VERSION,
		"timestamp": Time.get_unix_time_from_system(),
		"game_title": "BloomHaven CVP",
		"data": state_data
	}

	var json_str := JSON.stringify(payload, "\t")
	var file := FileAccess.open(SAVE_PATH_V2, FileAccess.WRITE)
	if file == null:
		printerr("SaveManager: Failed to open save file for writing: %s" % SAVE_PATH_V2)
		return false

	file.store_string(json_str)
	file.close()
	print("✓ [SAVE] Game state saved successfully to %s (v%d)." % [SAVE_PATH_V2, CURRENT_VERSION])
	return true


static func load_game() -> Dictionary:
	if not has_save():
		print("[SAVE] No save file found. Starting fresh.")
		return {}

	var load_path := get_active_save_path()
	var file := FileAccess.open(load_path, FileAccess.READ)
	if file == null:
		printerr("SaveManager: Failed to open save file for reading: %s" % load_path)
		return {}

	var text := file.get_as_text()
	file.close()

	var json := JSON.new()
	var parse_result := json.parse(text)
	if parse_result != OK:
		printerr("SaveManager: JSON parse error in save file: %s" % json.get_error_message())
		return {}

	if not (json.data is Dictionary):
		printerr("SaveManager: Corrupted save data (root not a Dictionary).")
		return {}

	var root_dict: Dictionary = json.data
	var version: int = root_dict.get("version", 0)

	if version < 1:
		printerr("SaveManager: Unsupported save version: %d" % version)
		return {}

	var raw_data: Dictionary = root_dict.get("data", {})
	print("✓ [LOAD] Game state loaded successfully (%s - v%d)." % [load_path.get_file(), version])
	return raw_data


## Serializes 12 Garden Plots state into an Array of Dictionaries
static func serialize_plots(plots: Array) -> Array:
	var plots_array: Array = []
	for plot in plots:
		if plot is GardenPlot:
			var p_dict: Dictionary = {
				"index": plot.plot_index,
				"state": int(plot.state),
				"flower_id": plot.current_flower_id,
				"growth_progress": plot.growth_progress,
				"is_watered": plot.is_watered,
				"water_duration_remaining": plot.water_duration_remaining,
				"is_mystery_seed": plot.is_mystery_seed,
				"is_revealed": plot.is_revealed,
				"is_pruned": plot.is_pruned,
				"is_fertilized": plot.is_fertilized,
				"quality": plot.quality
			}
			if plot.current_specimen != null:
				p_dict["specimen"] = plot.current_specimen.serialize()
			plots_array.append(p_dict)
	return plots_array


## Deserializes plot state into GardenPlot instances
static func deserialize_plots(plots_array: Array, plots: Array) -> void:
	for p_data in plots_array:
		if not (p_data is Dictionary):
			continue
		var idx: int = p_data.get("index", -1)
		if idx >= 0 and idx < plots.size():
			var plot: GardenPlot = plots[idx]
			plot.state = p_data.get("state", 0) as GardenPlot.State
			plot.current_flower_id = p_data.get("flower_id", "")
			plot.growth_progress = p_data.get("growth_progress", 0.0)
			plot.is_watered = p_data.get("is_watered", false)
			plot.water_duration_remaining = p_data.get("water_duration_remaining", 0.0)
			plot.is_mystery_seed = p_data.get("is_mystery_seed", false)
			plot.is_revealed = p_data.get("is_revealed", true)
			plot.is_pruned = p_data.get("is_pruned", false)
			plot.is_fertilized = p_data.get("is_fertilized", false)
			plot.quality = p_data.get("quality", 1)

			if p_data.has("specimen") and p_data["specimen"] is Dictionary:
				plot.current_specimen = FlowerSpecimen.deserialize(p_data["specimen"])
			elif not plot.current_flower_id.is_empty():
				plot.current_specimen = GeneticsEngine.create_starter_specimen(plot.current_flower_id)

			# Sync visual
			if is_instance_valid(plot._flower_visual):
				if plot.state != GardenPlot.State.EMPTY and not plot.current_flower_id.is_empty():
					plot._flower_visual.flower_id = plot.current_flower_id
					plot._flower_visual.phenotype = plot.current_specimen.phenotype if plot.current_specimen else null
					plot._flower_visual.is_mystery = plot.is_mystery_seed
					plot._flower_visual.is_revealed = plot.is_revealed
					plot._flower_visual.is_pruned = plot.is_pruned
					plot._flower_visual.visible = true
					plot._update_growth_stage()
				else:
					plot._flower_visual.visible = false
			plot.queue_redraw()
