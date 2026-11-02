class_name FlowerInventory
extends RefCounted

## Canonical Single Source of Truth for harvested flower storage.
## Internal storage structure: _storage[flower_id][tier: int] = count: int

signal inventory_changed()
signal flower_added(flower_id: String, quality: int, count: int)
signal flower_removed(flower_id: String, quality: int, count: int)

enum ConsumptionPolicy {
	LOWEST_QUALITY_FIRST = 1,
	HIGHEST_QUALITY_FIRST = 2,
}

const LOWEST_QUALITY_FIRST: int = ConsumptionPolicy.LOWEST_QUALITY_FIRST
const HIGHEST_QUALITY_FIRST: int = ConsumptionPolicy.HIGHEST_QUALITY_FIRST

var _storage: Dictionary = {}



func add_flower(flower_id: String, quality: int = FlowerQuality.Tier.NORMAL, count: int = 1) -> void:
	if flower_id.is_empty() or count <= 0:
		return

	var tier: int = quality if FlowerQuality.is_valid(quality) else FlowerQuality.Tier.NORMAL

	if not _storage.has(flower_id):
		_storage[flower_id] = {}

	var current: int = int(_storage[flower_id].get(tier, 0))
	_storage[flower_id][tier] = current + count

	flower_added.emit(flower_id, tier, count)
	inventory_changed.emit()


func remove_flower(flower_id: String, quality: int = FlowerQuality.Tier.NORMAL, count: int = 1) -> bool:
	if flower_id.is_empty() or count <= 0:
		return false

	var tier: int = quality if FlowerQuality.is_valid(quality) else FlowerQuality.Tier.NORMAL

	if not _storage.has(flower_id):
		return false

	var current: int = int(_storage[flower_id].get(tier, 0))
	if current < count:
		return false

	var remaining: int = current - count
	if remaining > 0:
		_storage[flower_id][tier] = remaining
	else:
		_storage[flower_id].erase(tier)
		if _storage[flower_id].is_empty():
			_storage.erase(flower_id)

	flower_removed.emit(flower_id, tier, count)
	inventory_changed.emit()
	return true


func get_flower_count(flower_id: String) -> int:
	if not _storage.has(flower_id):
		return 0

	var total: int = 0
	for tier_key in _storage[flower_id]:
		total += int(_storage[flower_id][tier_key])
	return total


func get_flower_count_by_quality(flower_id: String, quality: int) -> int:
	if not _storage.has(flower_id):
		return 0
	return int(_storage[flower_id].get(quality, 0))


func get_total_flower_count() -> int:
	var total: int = 0
	for flower_id in _storage:
		for tier_key in _storage[flower_id]:
			total += int(_storage[flower_id][tier_key])
	return total


func get_quality_breakdown(flower_id: String) -> Dictionary:
	if not _storage.has(flower_id):
		return {}
	return _storage[flower_id].duplicate()


func get_legacy_view() -> Dictionary:
	## Returns an isolated read-only snapshot: { flower_id: total_count }
	var snapshot: Dictionary = {}
	for flower_id in _storage:
		var total: int = 0
		for tier_key in _storage[flower_id]:
			total += int(_storage[flower_id][tier_key])
		if total > 0:
			snapshot[flower_id] = total
	return snapshot


func get_all_flowers() -> Dictionary:
	var copy: Dictionary = {}
	for flower_id in _storage:
		copy[flower_id] = _storage[flower_id].duplicate()
	return copy


func can_consume_requirements(requirements: Dictionary, policy = ConsumptionPolicy.LOWEST_QUALITY_FIRST) -> bool:
	## Requirements can be { flower_id: count } or { flower_id: { tier: count } }
	return _build_consumption_plan(requirements, policy).get("valid", false)


func consume_requirements(requirements: Dictionary, policy = ConsumptionPolicy.LOWEST_QUALITY_FIRST) -> bool:
	## Commit every deduction before notifying synchronous signal listeners.
	var plan := _build_consumption_plan(requirements, policy)
	if not plan.get("valid", false):
		return false
	var deductions: Array = plan["deductions"]
	for deduction in deductions:
		var flower_id: String = deduction["flower_id"]
		var tier: int = deduction["tier"]
		var remaining: int = int(_storage[flower_id][tier]) - int(deduction["count"])
		if remaining > 0:
			_storage[flower_id][tier] = remaining
		else:
			_storage[flower_id].erase(tier)
			if _storage[flower_id].is_empty():
				_storage.erase(flower_id)

	for deduction in deductions:
		flower_removed.emit(deduction["flower_id"], deduction["tier"], deduction["count"])
	if not deductions.is_empty():
		inventory_changed.emit()
	return true


func _build_consumption_plan(requirements: Dictionary, policy) -> Dictionary:
	var deductions: Array[Dictionary] = []

	var tier_order: Array[int] = [
		FlowerQuality.Tier.NORMAL,
		FlowerQuality.Tier.FINE,
		FlowerQuality.Tier.PERFECT,
		FlowerQuality.Tier.HERO
	]
	if policy == ConsumptionPolicy.HIGHEST_QUALITY_FIRST or str(policy) == "highest_first":
		tier_order.reverse()

	for flower_id in requirements:
		var req_val = requirements[flower_id]
		if not (flower_id is String) or flower_id.is_empty():
			return {"valid": false}
		if req_val is int or req_val is float:
			if not _is_valid_requirement_count(req_val) or req_val > get_flower_count(flower_id):
				return {"valid": false}
			var remaining_needed: int = int(req_val)
			for tier in tier_order:
				if remaining_needed <= 0:
					break
				var avail: int = get_flower_count_by_quality(flower_id, tier)
				if avail <= 0:
					continue
				var to_take: int = mini(avail, remaining_needed)
				deductions.append({"flower_id": flower_id, "tier": tier, "count": to_take})
				remaining_needed -= to_take
		elif req_val is Dictionary:
			var normalized: Dictionary = {}
			for tier_key in req_val:
				if not (tier_key is int or (tier_key is String and tier_key.is_valid_int())):
					return {"valid": false}
				var tier := int(tier_key)
				var count = req_val[tier_key]
				if not FlowerQuality.is_valid(tier) or not _is_valid_requirement_count(count):
					return {"valid": false}
				# JSON string keys and integer keys may address the same tier.
				var planned: int = normalized.get(tier, 0)
				if count > get_flower_count_by_quality(flower_id, tier) - planned:
					return {"valid": false}
				normalized[tier] = planned + int(count)
			for tier in normalized:
				if normalized[tier] > 0:
					deductions.append({"flower_id": flower_id, "tier": tier, "count": normalized[tier]})
		else:
			return {"valid": false}

	return {"valid": true, "deductions": deductions}


func _is_valid_requirement_count(value) -> bool:
	if value is int:
		return value >= 0
	return value is float and is_finite(value) and value >= 0.0 and value == floor(value)


func clear() -> void:
	_storage.clear()
	inventory_changed.emit()


func serialize() -> Dictionary:
	var out: Dictionary = {}
	for flower_id in _storage:
		var tiers_dict: Dictionary = {}
		for tier_key in _storage[flower_id]:
			tiers_dict[str(tier_key)] = int(_storage[flower_id][tier_key])
		out[flower_id] = tiers_dict
	return out


func deserialize(data: Dictionary) -> void:
	_storage.clear()
	for flower_id in data:
		var val = data[flower_id]
		if val is Dictionary:
			# Nested format: { flower_id: { "1": count, ... } }
			_storage[flower_id] = {}
			for tier_key in val:
				var tier_int: int = int(tier_key)
				var count: int = int(val[tier_key])
				if count > 0 and FlowerQuality.is_valid(tier_int):
					_storage[flower_id][tier_int] = count
		elif val is int:
			# Flat legacy format: { flower_id: count } -> Map to NORMAL tier
			var count: int = int(val)
			if count > 0:
				if not _storage.has(flower_id):
					_storage[flower_id] = {}
				_storage[flower_id][FlowerQuality.Tier.NORMAL] = count
	inventory_changed.emit()
