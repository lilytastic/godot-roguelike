extends HBoxContainer

var _entity: Entity
var entity: Entity:
	get: return _entity
	set(value):
		_entity = value
		_initialize_slots()

func _ready():
	_initialize_slots()
	
func _initialize_slots():
	if entity and entity.equipment:
		print('initialized equipment display with ', entity.uuid)
		var tiles = %SlotsLeft.get_children() + %SlotsRight.get_children()
		print(tiles)
		for tile in tiles:
			var slot = tile.get_meta('slot')
			print(slot, ': ', entity.equipment.slots.has(slot))
			if slot and entity.equipment.slots.has(slot):
				print(entity.equipment.slots[slot])
				tile.stack = {
					'entity': entity.equipment.slots[slot]
				}
				continue
