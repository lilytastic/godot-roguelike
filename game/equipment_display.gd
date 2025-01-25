extends HBoxContainer

var _equipment: EquipmentProps
var equipment: EquipmentProps:
	get: return _equipment
	set(value):
		_equipment = value
		if _equipment:
			_equipment.item_unequipped.connect(
				func(item):
					print(item)
					_initialize_slots()
			)
			_equipment.item_equipped.connect(
				func(item):
					print(item)
					_initialize_slots()
			)
		_initialize_slots()


func _ready():
	_initialize_slots()

func _initialize_slots():
	if equipment:
		print('initialized equipment display with ', equipment.slots)
		var tiles = %SlotsLeft.get_children() + %SlotsRight.get_children()
		print(tiles)
		for tile in tiles:
			var slot = tile.slot if tile is TileItem else ''
			if slot:
				if equipment.slots.has(slot):
					print(equipment.slots[slot])
					tile.stack = {
						'entity': equipment.slots[slot]
					}
					continue
				else:
					tile.stack = {}
