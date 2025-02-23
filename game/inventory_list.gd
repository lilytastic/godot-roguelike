extends VBoxContainer

var item_prefab = preload('res://game/list_item.tscn')

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
signal double_click


func _ready():
	_initialize_slots()
	_update_slots()
	
func _initialize_slots():
	for child in get_children():
		child.queue_free()
	
	tiles.clear()
	if inventory:
		for i in inventory.items:
			var tile = item_prefab.instantiate()
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
