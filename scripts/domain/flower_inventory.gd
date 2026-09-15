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
	if requirements.is_empty():
		return true

	for flower_id in requirements:
		var req_val = requirements[flower_id]
		if req_val is int or req_val is float:
			var req_count: int = int(req_val)
			if req_count <= 0:
				continue
			if get_flower_count(flower_id) < req_count:
				return false
		elif req_val is Dictionary:
			var tier_reqs: Dictionary = req_val
			for tier_key in tier_reqs:
				var tier: int = int(tier_key)
				var req_count: int = int(tier_reqs[tier_key])
				if req_count <= 0:
					continue
				if get_flower_count_by_quality(flower_id, tier) < req_count:
					return false
		else:
			return false

	return true


func consume_requirements(requirements: Dictionary, policy = ConsumptionPolicy.LOWEST_QUALITY_FIRST) -> bool:
	## Transactional requirement consumption: validate all first, then commit deductions.
	## If any check fails: zero mutation.
	if not can_consume_requirements(requirements, policy):
		return false

	# Order of tiers depending on policy (LOWEST_QUALITY_FIRST vs HIGHEST_QUALITY_FIRST)
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
		if req_val is int or req_val is float:
			var remaining_needed: int = int(req_val)
			for tier in tier_order:
				if remaining_needed <= 0:
					break
				var avail: int = get_flower_count_by_quality(flower_id, tier)
				if avail <= 0:
					continue
				var to_take: int = mini(avail, remaining_needed)
				remove_flower(flower_id, tier, to_take)
				remaining_needed -= to_take
		elif req_val is Dictionary:
			var tier_reqs: Dictionary = req_val
			for tier_key in tier_reqs:
				var tier: int = int(tier_key)
				var req_count: int = int(tier_reqs[tier_key])
				if req_count > 0:
					remove_flower(flower_id, tier, req_count)

	return true


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
