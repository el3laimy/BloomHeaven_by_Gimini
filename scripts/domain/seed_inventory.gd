class_name SeedInventory
extends RefCounted

## Canonical Single Source of Truth for standard seed inventory.
## Internal storage structure: _seeds[seed_id: String] = count: int

signal seed_inventory_changed()
signal seed_added(seed_id: String, count: int)
signal seed_consumed(seed_id: String, count: int)

var _seeds: Dictionary = {}


func get_seed_count(seed_id: String) -> int:
	return int(_seeds.get(seed_id, 0))


func has_seed(seed_id: String, count: int = 1) -> bool:
	if seed_id.is_empty() or count <= 0:
		return false
	return get_seed_count(seed_id) >= count


func can_consume(seed_id: String, count: int = 1) -> bool:
	return has_seed(seed_id, count)


func add_seeds(seed_id: String, count: int = 1) -> void:
	if seed_id.is_empty() or count <= 0:
		return
	var current: int = int(_seeds.get(seed_id, 0))
	_seeds[seed_id] = current + count
	seed_added.emit(seed_id, count)
	seed_inventory_changed.emit()


func consume_seed(seed_id: String) -> bool:
	return remove_seeds(seed_id, 1)


func remove_seeds(seed_id: String, count: int = 1) -> bool:
	if not can_consume(seed_id, count):
		return false

	var current: int = int(_seeds.get(seed_id, 0))
	var remaining: int = current - count
	if remaining > 0:
		_seeds[seed_id] = remaining
	else:
		_seeds.erase(seed_id)

	seed_consumed.emit(seed_id, count)
	seed_inventory_changed.emit()
	return true


func get_all_seeds() -> Dictionary:
	return _seeds.duplicate()


func clear() -> void:
	_seeds.clear()
	seed_inventory_changed.emit()


func serialize() -> Dictionary:
	return _seeds.duplicate()


func deserialize(data: Dictionary) -> void:
	_seeds.clear()
	for seed_id in data:
		var count: int = int(data[seed_id])
		if count > 0:
			_seeds[str(seed_id)] = count
	seed_inventory_changed.emit()
