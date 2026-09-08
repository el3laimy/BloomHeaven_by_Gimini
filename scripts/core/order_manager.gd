class_name OrderManager
extends RefCounted

## Fiona Finch Customer Orders, Patience, and Combo Rush Controller.
## Coordinates customer patience timers, satisfaction tiers, speed tips, and combo streak multipliers.

signal order_fulfilled(order_id: String, reward_data: Dictionary)
signal combo_updated(new_combo: int, time_remaining: float)
signal combo_expired()

const COMBO_WINDOW_SECONDS: float = 18.0
const COMBO_MULTIPLIER_STEP: float = 0.25

var live_orders_patience: Dictionary = {
	"order_1": 75.0,
	"order_2": 80.0,
	"order_3": 85.0,
	"order_4": 90.0,
	"order_5": 80.0,
	"order_6": 95.0
}

var completed_requests: Dictionary = {
	"order_1": false,
	"order_2": false,
	"order_3": false,
	"order_4": false,
	"order_5": false,
	"order_6": false
}

var combo_count: int = 0
var combo_timer: float = 0.0


func tick(delta: float) -> void:
	# 1. Decay Combo Rush timer
	if combo_timer > 0.0:
		combo_timer -= delta
		if combo_timer <= 0.0:
			combo_count = 0
			combo_timer = 0.0
			combo_expired.emit()

	# 2. Decay Customer Patience for active orders
	for o_id in live_orders_patience:
		if not completed_requests.get(o_id, false):
			live_orders_patience[o_id] = max(0.0, live_orders_patience[o_id] - delta)


func can_fulfill(order_id: String, flower_inventory: Dictionary, bouquet_inventory: Dictionary) -> Dictionary:
	return FloristRequestData.check_fulfillment(order_id, flower_inventory, bouquet_inventory)


func fulfill_order(order_id: String, flower_inventory: Dictionary, bouquet_inventory: Dictionary) -> Dictionary:
	var check := can_fulfill(order_id, flower_inventory, bouquet_inventory)
	if not check.get("can_fulfill", false):
		return {
			"success": false,
			"error": "Missing required items."
		}

	var req := FloristRequestData.get_request(order_id)
	var req_type: String = req.get("type", "flowers")
	var items: Dictionary = req.get("required_items", {})

	# Calculate patience ratio and combo multiplier
	var max_pat: float = float(req.get("patience_max_seconds", 75.0))
	var cur_pat: float = float(live_orders_patience.get(order_id, max_pat))
	var pat_ratio: float = clamp(cur_pat / max_pat, 0.0, 1.0)
	var combo_mult: float = 1.0 + (float(combo_count) * COMBO_MULTIPLIER_STEP)

	var reward_calc: Dictionary = FloristRequestData.calculate_reward(order_id, pat_ratio, combo_mult)
	var total_earned: int = int(reward_calc.get("total_coins", 25))
	var tip_earned: int = int(reward_calc.get("tip_coins", 0))

	# Deduct required inventory items
	if req_type == "flowers":
		for flower_id in items:
			flower_inventory[flower_id] -= int(items[flower_id])
	elif req_type == "bouquet":
		for bouquet_id in items:
			bouquet_inventory[bouquet_id] -= int(items[bouquet_id])

	# Update order completion and combo rush streak
	completed_requests[order_id] = true
	combo_count += 1
	combo_timer = COMBO_WINDOW_SECONDS
	live_orders_patience[order_id] = max_pat

	var result := {
		"success": true,
		"order_id": order_id,
		"total_coins": total_earned,
		"tip_coins": tip_earned,
		"combo_count": combo_count,
		"customer_name": req.get("customer_name", "Customer"),
		"satisfaction_tier": reward_calc.get("satisfaction_tier", "bronze"),
		"rating_stars": reward_calc.get("rating_stars", 3)
	}

	order_fulfilled.emit(order_id, result)
	combo_updated.emit(combo_count, combo_timer)
	return result


func get_patience(order_id: String) -> float:
	return float(live_orders_patience.get(order_id, 0.0))


func get_patience_ratio(order_id: String) -> float:
	var req := FloristRequestData.get_request(order_id)
	var max_pat: float = float(req.get("patience_max_seconds", 75.0))
	var cur_pat: float = float(live_orders_patience.get(order_id, max_pat))
	return clamp(cur_pat / max_pat, 0.0, 1.0)


func reset_all_patience() -> void:
	for o_id in live_orders_patience:
		var req := FloristRequestData.get_request(o_id)
		live_orders_patience[o_id] = float(req.get("patience_max_seconds", 75.0))


func serialize() -> Dictionary:
	return {
		"completed_requests": completed_requests.duplicate(),
		"live_orders_patience": live_orders_patience.duplicate(),
		"combo_count": combo_count
	}


func deserialize(data: Dictionary) -> void:
	if data.has("completed_requests") and data["completed_requests"] is Dictionary:
		completed_requests = data["completed_requests"].duplicate()
	if data.has("live_orders_patience") and data["live_orders_patience"] is Dictionary:
		live_orders_patience = data["live_orders_patience"].duplicate()
	if data.has("combo_count"):
		combo_count = int(data["combo_count"])
