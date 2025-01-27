extends GridContainer

var tile_prefab = preload('res://game/tile_item.tscn')

var _inventory: InventoryProps
var inventory: InventoryProps:
	get: return _inventory
	set(value):
		_inventory = value
		if _inventory:
			_inventory.items_changed.connect(
				func(): _update_slots()
			)
		_initialize_slots()
		_update_slots()
		
var tiles := []

signal tiles_changed


func _ready():
	_initialize_slots()
	_update_slots()
	
func _initialize_slots():
	for child in get_children():
		child.queue_free()
	
	tiles.clear()
	if inventory:
		print('initialized inventory display')
		for i in inventory.max_items:
			var tile = tile_prefab.instantiate()
			add_child(tile)
			tiles.append(tile)
	tiles_changed.emit(tiles)

func _update_slots():
	for i in tiles.size():
		if inventory and inventory.items.size() > i:
			var item = inventory.items[i]
			if item:
				tiles[i].stack = item
			else:
				tiles[i].stack = {}
		else:
			tiles[i].stack = {}
