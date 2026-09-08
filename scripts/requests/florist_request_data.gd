class_name FloristRequestData
extends RefCounted

## Customer Orders & Florist Requests for Finest Garden.
## Loads data dynamically from res://data/requests.json.

static var _cached_requests: Dictionary = {}
static var _is_initialized: bool = false


static func _ensure_initialized() -> void:
	if _is_initialized and not _cached_requests.is_empty():
		return
	
	_cached_requests.clear()
	var path := "res://data/requests.json"
	if FileAccess.file_exists(path):
		var file := FileAccess.open(path, FileAccess.READ)
		if file != null:
			var json := JSON.new()
			if json.parse(file.get_as_text()) == OK and json.data is Dictionary:
				var raw_dict: Dictionary = json.data.get("requests", {})
				for r_id in raw_dict:
					var entry: Dictionary = raw_dict[r_id].duplicate()
					if entry.has("avatar_color") and entry["avatar_color"] is Array:
						var arr: Array = entry["avatar_color"]
						if arr.size() >= 4:
							entry["avatar_color"] = Color(arr[0], arr[1], arr[2], arr[3])
						elif arr.size() == 3:
							entry["avatar_color"] = Color(arr[0], arr[1], arr[2], 1.0)
					_cached_requests[r_id] = entry
	
	if _cached_requests.is_empty():
		_cached_requests = {
			"order_1": {
				"id": "order_1",
				"customer_name": "Maya",
				"customer_title": "Wedding Stylist",
				"avatar_color": Color(0.85, 0.45, 0.65, 1.0),
				"avatar_badge": "M",
				"type": "flowers",
				"required_items": {"lavender": 2, "sunflower": 1},
				"dialogue": "I'm styling an outdoor wedding altar. I need fragrant lavender and sunflowers!",
				"coin_reward": 25
			}
		}
	
	_is_initialized = true


static func get_request(order_id: String) -> Dictionary:
	_ensure_initialized()
	if _cached_requests.has(order_id):
		var req: Dictionary = _cached_requests[order_id].duplicate()
		if not req.has("patience_max_seconds"):
			req["patience_max_seconds"] = 75.0
		return req
	var fallback: Dictionary = _cached_requests.get("order_1", {}).duplicate()
	if not fallback.has("patience_max_seconds"):
		fallback["patience_max_seconds"] = 75.0
	return fallback


static func get_all_request_ids() -> Array[String]:
	_ensure_initialized()
	var res: Array[String] = []
	for r_id in _cached_requests:
		res.append(r_id)
	return res


## Calculate coins reward including speed tip & combo multiplier
static func calculate_reward(order_id: String, patience_ratio: float, combo_multiplier: float = 1.0) -> Dictionary:
	var req := get_request(order_id)
	var base_coins: int = int(req.get("coin_reward", 25))
	var base_rep: int = int(req.get("reputation_reward", 10))

	var tip_percent: float = 0.0
	var rating_stars: int = 1
	var satisfaction_tier := "bronze"

	if patience_ratio >= 0.70:
		tip_percent = 0.50 # +50% Tip for Gold Zone
		rating_stars = 5
		satisfaction_tier = "gold"
	elif patience_ratio >= 0.40:
		tip_percent = 0.25 # +25% Tip for Silver Zone
		rating_stars = 3
		satisfaction_tier = "silver"
	else:
		tip_percent = 0.0
		rating_stars = 2
		satisfaction_tier = "bronze"

	var tip_coins: int = int(float(base_coins) * tip_percent)
	var total_coins: int = int(float(base_coins + tip_coins) * combo_multiplier)
	var total_rep: int = int(float(base_rep) * combo_multiplier)

	return {
		"base_coins": base_coins,
		"tip_coins": tip_coins,
		"total_coins": total_coins,
		"total_reputation": total_rep,
		"rating_stars": rating_stars,
		"satisfaction_tier": satisfaction_tier
	}


## Checks if the player has all required items in inventory to fulfill the request.
## Returns Dictionary with "can_fulfill": bool, "status_text": String
static func check_fulfillment(order_id: String, flower_inventory: Dictionary, bouquet_inventory: Dictionary) -> Dictionary:
	var req := get_request(order_id)
	var req_type: String = req.get("type", "flowers")
	var items: Dictionary = req.get("required_items", {})
	var can_fulfill := true
	var status_parts: Array[String] = []

	if req_type == "flowers":
		for flower_id in items:
			var needed: int = int(items[flower_id])
			var have: int = int(flower_inventory.get(flower_id, 0))
			var name: String = FlowerData.get_flower(flower_id).get("display_name", flower_id)
			status_parts.append("%s (%d/%d)" % [name, have, needed])
			if have < needed:
				can_fulfill = false
	elif req_type == "bouquet":
		for bouquet_id in items:
			var needed: int = int(items[bouquet_id])
			var have: int = int(bouquet_inventory.get(bouquet_id, 0))
			var name: String = BouquetData.get_bouquet(bouquet_id).get("display_name", bouquet_id)
			status_parts.append("%s (%d/%d)" % [name, have, needed])
			if have < needed:
				can_fulfill = false

	var status_text := ""
	if can_fulfill:
		status_text = "Ready to Fulfill!"
	else:
		status_text = "Missing: " + ", ".join(status_parts)

	return {
		"can_fulfill": can_fulfill,
		"status_text": status_text
	}
