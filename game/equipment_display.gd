extends HBoxContainer

var _equipment: EquipmentProps
var equipment: EquipmentProps:
	get: return _equipment
	set(value):
		_update_equipment(value)

var tiles := []

signal double_click


func _ready():
	_initialize_slots()
	_update_slots()

func _initialize_slots():
	if equipment:
		tiles.clear()
		
		var _tiles = %SlotsLeft.get_children() + %SlotsRight.get_children()

		for tile in _tiles:
			var slot = tile.slot if (tile is TileItem) else ''
			if !slot:
				continue
			tiles.append(tile)

func _update_equipment(value: EquipmentProps):
	_equipment = value
	if _equipment:
		_equipment.item_unequipped.connect(
			func(item):
				_update_slots()
		)
		_equipment.item_equipped.connect(
			func(item):
				_update_slots()
		)
	_initialize_slots()
	_update_slots()

func _update_slots():
	for tile in tiles:
		var slot = tile.slot if (tile is TileItem) else ''
		if !slot:
			continue
		if equipment.slots.has(slot):
			tile.stack = {
				'entity': equipment.slots[slot]
			}
		else:
			tile.stack = {}
