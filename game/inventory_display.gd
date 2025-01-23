extends GridContainer

var tile_prefab = preload('res://game/tile_item.tscn')

var _inventory: InventoryProps
var inventory: InventoryProps:
	get: return _inventory
	set(value):
		_inventory = value
		if _inventory:
			_inventory.items_changed.connect(func():
				_initialize_slots()
			)
		_initialize_slots()

func _ready():
	_initialize_slots()
	
func _initialize_slots():
	for child in get_children():
		child.queue_free()
	
	if inventory:
		print('initialized inventory display')
		for i in inventory.max_items:
			var tile = tile_prefab.instantiate()
			add_child(tile)
			if inventory.items.size() > i:
				var item = inventory.items[i]
				if item:
					tile.stack = item
