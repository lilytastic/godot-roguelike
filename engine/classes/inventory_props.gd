class_name InventoryProps

var items: Array = []
var max_items = 20

signal items_changed

func _init(opts := {}):
	items = opts.get('items', [])
	max_items = opts.get('max_items', 20)
	_initialized()
	Global.player_changed.connect(func(player): _initialized())
	Global.game_loaded.connect(func(): _initialized())

func _initialized():
	for n in max_items:
		# items.append(null)
		items_changed.emit(items)

func add(stack: Dictionary) -> bool:
	var slot = items.find(func(_slot): return _slot != null)
	print('stack ', stack)
	print('slot ', slot)
	if slot != -1:
		slot = stack
		items_changed.emit(items)
		return true
	if items.size() < max_items:
		items.append(stack)
		items_changed.emit(items)
		return true
	return false

func save() -> Dictionary:
	return {
		'items': items,
		'max_items': max_items
	}
