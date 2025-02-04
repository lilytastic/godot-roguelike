class_name InventoryProps

var items: Array = []
var max_items = 25

signal items_changed


func _init(opts := {}):
	items = opts.get('items', [])
	max_items = opts.get('max_items', 30)
	items_changed.emit()

func add(stack: Dictionary) -> bool:
	var slot = items.find(func(_slot): return _slot != null)
	if slot != -1:
		slot = stack
		items_changed.emit()
		return true
	if items.size() < max_items:
		items.append(stack)
		items_changed.emit()
		return true
	return false
	
func remove(uuid: String) -> bool:
	var index = -1
	for item in items:
		index += 1
		if item.has('entity') and item.entity == uuid:
			items.remove_at(index)
			items_changed.emit()
			return true
	return false

func has(uuid: String) -> bool:
	return items.any(
		func(e): return uuid == e.entity
	)
	
func save() -> Dictionary:
	return {
		'items': items,
		'max_items': max_items
	}
