class_name OrderManager
extends RefCounted

## Fiona Finch Customer Orders, Patience, and Combo Rush Controller.
## Coordinates customer patience timers, satisfaction tiers, speed tips, and combo streak multipliers.
## Uses order_runtime as the unified single source of truth for runtime order state.

signal order_fulfilled(order_id: String, reward_data: Dictionary)
signal combo_updated(new_combo: int, time_remaining: float)
signal combo_expired()

const COMBO_WINDOW_SECONDS: float = 18.0
const COMBO_MULTIPLIER_STEP: float = 0.25

## Canonical runtime state: order_runtime[order_id] = { "completed": bool, "remaining_patience": float, "max_patience": float }
var order_runtime: Dictionary = {}

var combo_count: int = 0
var combo_timer: float = 0.0

## Backwards-compatibility view properties mapping to order_runtime
var live_orders_patience: Dictionary:
	get:
		var res: Dictionary = {}
		for o_id in order_runtime:
			res[o_id] = float(order_runtime[o_id].get("remaining_patience", 0.0))
		return res
	set(val):
		for o_id in val:
			_ensure_order_in_runtime(o_id)
			order_runtime[o_id]["remaining_patience"] = float(val[o_id])

var completed_requests: Dictionary:
	get:
		var res: Dictionary = {}
		for o_id in order_runtime:
			res[o_id] = bool(order_runtime[o_id].get("completed", false))
		return res
	set(val):
		for o_id in val:
			_ensure_order_in_runtime(o_id)
			order_runtime[o_id]["completed"] = bool(val[o_id])


func _init() -> void:
	_init_runtime()


func _init_runtime() -> void:
	order_runtime.clear()
	for o_id in FloristRequestData.get_all_request_ids():
		_ensure_order_in_runtime(o_id)


func _ensure_order_in_runtime(order_id: String) -> void:
	if not order_runtime.has(order_id):
		var req := FloristRequestData.get_request(order_id)
		var max_pat: float = float(req.get("patience_max_seconds", 75.0))
		order_runtime[order_id] = {
			"completed": false,
			"remaining_patience": max_pat,
			"max_patience": max_pat
		}


func tick(delta: float) -> void:
	# 1. Decay Combo Rush timer
	if combo_timer > 0.0:
		combo_timer -= delta
		if combo_timer <= 0.0:
			combo_count = 0
			combo_timer = 0.0
			combo_expired.emit()

	# 2. Decay Customer Patience for active orders
	for o_id in order_runtime:
		var entry: Dictionary = order_runtime[o_id]
		if not entry.get("completed", false):
			var rem: float = float(entry.get("remaining_patience", 75.0))
			entry["remaining_patience"] = max(0.0, rem - delta)


func can_fulfill(order_id: String, flower_inventory, bouquet_inventory: Dictionary) -> Dictionary:
	if not order_runtime.has(order_id):
		return {"can_fulfill": false, "status_text": "Order not found."}
	return FloristRequestData.check_fulfillment(order_id, flower_inventory, bouquet_inventory)


func fulfill_order(order_id: String, flower_inventory, bouquet_inventory: Dictionary) -> Dictionary:
	# 1. Validate order ID
	if order_id.is_empty():
		return {"success": false, "error": "Invalid order ID."}

	# 2. Validate runtime exists
	if not order_runtime.has(order_id):
		return {"success": false, "error": "Order runtime not found."}

	var runtime_entry: Dictionary = order_runtime[order_id]

	# 3. Validate not completed
	if runtime_entry.get("completed", false):
		return {"success": false, "error": "Order already completed."}

	# 4. Validate request data and type
	var req := FloristRequestData.get_request(order_id)
	if req.is_empty():
		return {"success": false, "error": "Order data not found."}

	var req_type: String = req.get("type", "")
	if req_type != "flowers" and req_type != "bouquet":
		return {"success": false, "error": "Unsupported request type: " + req_type}

	var items: Dictionary = req.get("required_items", {})
	if items.is_empty():
		return {"success": false, "error": "Order has no required items."}

	# 5 & 6. Verify ALL requirements before any mutation (zero mutation on failure)
	if req_type == "flowers":
		if flower_inventory is FlowerInventory:
			if not flower_inventory.can_consume_requirements(items, FlowerInventory.ConsumptionPolicy.LOWEST_QUALITY_FIRST):
				return {"success": false, "error": "Missing required flowers."}
		elif flower_inventory is Dictionary:
			for f_id in items:
				if int(flower_inventory.get(f_id, 0)) < int(items[f_id]):
					return {"success": false, "error": "Missing required flowers."}
		else:
			return {"success": false, "error": "Invalid flower inventory type."}
	elif req_type == "bouquet":
		for b_id in items:
			if int(bouquet_inventory.get(b_id, 0)) < int(items[b_id]):
				return {"success": false, "error": "Missing required bouquets."}

	# 7. Calculate reward
	var max_pat: float = float(runtime_entry.get("max_patience", req.get("patience_max_seconds", 75.0)))
	var cur_pat: float = float(runtime_entry.get("remaining_patience", max_pat))
	var pat_ratio: float = clamp(cur_pat / max(max_pat, 0.001), 0.0, 1.0)
	var combo_mult: float = 1.0 + (float(combo_count) * COMBO_MULTIPLIER_STEP)

	var reward_calc: Dictionary = FloristRequestData.calculate_reward(order_id, pat_ratio, combo_mult)
	var total_earned: int = int(reward_calc.get("total_coins", 25))
	var tip_earned: int = int(reward_calc.get("tip_coins", 0))

	# 8. Commit deductions atomically (point of no return)
	if req_type == "flowers":
		if flower_inventory is FlowerInventory:
			var success: bool = bool(flower_inventory.consume_requirements(items, FlowerInventory.ConsumptionPolicy.LOWEST_QUALITY_FIRST))
			if not success:
				return {"success": false, "error": "Flower deduction failed."}
		elif flower_inventory is Dictionary:
			for f_id in items:
				flower_inventory[f_id] = int(flower_inventory[f_id]) - int(items[f_id])
	elif req_type == "bouquet":
		for b_id in items:
			bouquet_inventory[b_id] = int(bouquet_inventory[b_id]) - int(items[b_id])

	# 9. Mark order completed in canonical runtime
	runtime_entry["completed"] = true
	runtime_entry["remaining_patience"] = max_pat

	# 10 & 11. Update combo streak
	combo_count += 1
	combo_timer = COMBO_WINDOW_SECONDS

	# 12. Emit signals and return result
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
	if not order_runtime.has(order_id):
		return 0.0
	return float(order_runtime[order_id].get("remaining_patience", 0.0))


func get_patience_ratio(order_id: String) -> float:
	if not order_runtime.has(order_id):
		return 0.0
	var entry: Dictionary = order_runtime[order_id]
	var max_pat: float = float(entry.get("max_patience", 75.0))
	var cur_pat: float = float(entry.get("remaining_patience", max_pat))
	return clamp(cur_pat / max(max_pat, 0.001), 0.0, 1.0)


func reset_all_patience() -> void:
	for o_id in order_runtime:
		var req := FloristRequestData.get_request(o_id)
		var max_pat: float = float(req.get("patience_max_seconds", 75.0))
		order_runtime[o_id]["remaining_patience"] = max_pat
		order_runtime[o_id]["max_patience"] = max_pat


func reset_order(order_id: String) -> void:
	_ensure_order_in_runtime(order_id)
	var req := FloristRequestData.get_request(order_id)
	var max_pat: float = float(req.get("patience_max_seconds", 75.0))
	order_runtime[order_id]["completed"] = false
	order_runtime[order_id]["remaining_patience"] = max_pat
	order_runtime[order_id]["max_patience"] = max_pat


func reset_all_orders() -> void:
	for o_id in order_runtime:
		var req := FloristRequestData.get_request(o_id)
		var max_pat: float = float(req.get("patience_max_seconds", 75.0))
		order_runtime[o_id]["completed"] = false
		order_runtime[o_id]["remaining_patience"] = max_pat
		order_runtime[o_id]["max_patience"] = max_pat


func serialize() -> Dictionary:
	return {
		"order_runtime": order_runtime.duplicate(true),
		"completed_requests": completed_requests,
		"live_orders_patience": live_orders_patience,
		"combo_count": combo_count
	}


func deserialize(data: Dictionary) -> void:
	if data.has("order_runtime") and data["order_runtime"] is Dictionary:
		order_runtime = data["order_runtime"].duplicate(true)
	else:
		_init_runtime()
		if data.has("completed_requests") and data["completed_requests"] is Dictionary:
			for o_id in data["completed_requests"]:
				_ensure_order_in_runtime(o_id)
				order_runtime[o_id]["completed"] = bool(data["completed_requests"][o_id])
		if data.has("live_orders_patience") and data["live_orders_patience"] is Dictionary:
			for o_id in data["live_orders_patience"]:
				_ensure_order_in_runtime(o_id)
				order_runtime[o_id]["remaining_patience"] = float(data["live_orders_patience"][o_id])

	if data.has("combo_count"):
		combo_count = int(data["combo_count"])
