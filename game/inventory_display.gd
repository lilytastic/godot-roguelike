extends GridContainer

var tile_prefab = preload('res://game/tile_item.tscn')

var _entity: Entity
var entity: Entity:
	get: return _entity
	set(value):
		_entity = value
		_initialize_slots()

func _ready():
	_initialize_slots()
	
func _initialize_slots():
	for child in get_children():
		child.queue_free()
	
	if entity and entity.inventory:
		print('initialized inventory display with ', entity.uuid)
		for i in entity.inventory.max_items:
			var tile = tile_prefab.instantiate()
			add_child(tile)
			if entity.inventory.items.size() > i:
				var item = entity.inventory.items[i]
				if item:
					tile.stack = item
