class_name UpgradeManager
extends RefCounted

## Fiona Finch Tool & Garden Upgrades Manager.
## Handles loading upgrades, tracking unlock status, validating purchasing, and applying game effects.

signal upgrade_applied(upgrade_id: String)

var active_upgrades: Dictionary = {
	"swift_boots": false,
	"double_sprinkler": false,
	"enriched_soil": false,
	"fertilizer_box": false,
	"expanded_satchel": false
}

var _cached_definitions: Array = []


func _init() -> void:
	_load_definitions()


func _load_definitions() -> void:
	var path := "res://data/upgrades.json"
	if not FileAccess.file_exists(path):
		return
	var file := FileAccess.open(path, FileAccess.READ)
	if file != null:
		var json := JSON.new()
		if json.parse(file.get_as_text()) == OK and json.data is Dictionary:
			_cached_definitions = json.data.get("upgrades", [])


func get_all_upgrades() -> Array:
	if _cached_definitions.is_empty():
		_load_definitions()
	return _cached_definitions


func get_upgrade(upgrade_id: String) -> Dictionary:
	for up in get_all_upgrades():
		if up.get("id") == upgrade_id:
			return up
	return {}


func is_unlocked(upgrade_id: String) -> bool:
	return active_upgrades.get(upgrade_id, false)


func can_purchase(upgrade_id: String, current_coins: int) -> Dictionary:
	var up := get_upgrade(upgrade_id)
	if up.is_empty():
		return {"can_buy": false, "reason": "Upgrade not found."}
	if is_unlocked(upgrade_id):
		return {"can_buy": false, "reason": "Already purchased."}
	var cost: int = int(up.get("cost", 100))
	if current_coins < cost:
		return {"can_buy": false, "reason": "Not enough coins."}
	return {"can_buy": true, "cost": cost, "upgrade": up}


func purchase(upgrade_id: String, current_coins: int) -> Dictionary:
	var check := can_purchase(upgrade_id, current_coins)
	if not check.get("can_buy", false):
		return {
			"success": false,
			"error": check.get("reason", "Cannot purchase.")
		}
	var cost: int = check["cost"]
	active_upgrades[upgrade_id] = true
	return {
		"success": true,
		"cost": cost,
		"upgrade_id": upgrade_id,
		"upgrade_data": check["upgrade"]
	}


func apply_upgrade_effect(upgrade_id: String, character: CharacterBody2D, garden_grid: GardenGrid, inventory: Dictionary) -> void:
	match upgrade_id:
		"swift_boots":
			if is_instance_valid(character):
				character.move_speed = 240.0
		"enriched_soil":
			if is_instance_valid(garden_grid):
				for p in garden_grid.plots:
					if p is GardenPlot:
						p.water_duration_multiplier = 2.0
		"double_sprinkler":
			# Handled dynamically during watering action in MainGame
			pass
		"fertilizer_box":
			# Handled dynamically to permit fertilizer tool usage in MainGame
			pass
		"expanded_satchel":
			# Bonus items are awarded once upon purchase in MainGame, not repeated on load.
			pass
	upgrade_applied.emit(upgrade_id)


func apply_all_active_upgrades(character: CharacterBody2D, garden_grid: GardenGrid, inventory: Dictionary) -> void:
	for up_id in active_upgrades:
		if active_upgrades[up_id]:
			apply_upgrade_effect(up_id, character, garden_grid, inventory)


func serialize() -> Dictionary:
	return active_upgrades.duplicate()


func deserialize(data: Dictionary) -> void:
	for k in data:
		if active_upgrades.has(k):
			active_upgrades[k] = bool(data[k])
