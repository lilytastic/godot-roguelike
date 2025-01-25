class_name EquipmentProps

var slots := {}

signal item_equipped
signal item_unequipped

func _init(props: Dictionary):
	slots = props

func equip(entity: Entity) -> bool:
	var blueprint = entity.blueprint
	var swapped = []
	if !blueprint or !blueprint.item:
		return false

	print(blueprint.item.slots)

	for slotSet in blueprint.item.slots:
		print(slotSet)
		var isValid = slotSet.filter(
			func(key):
				return slots.has(key) and slots[key] != null
		).size() == 0
		
		if isValid:
			for slot in slotSet:
				if slots.has('slot'):
					swapped.append(slots[slot])
				slots[slot] = entity.uuid

			print('equipped to ', slotSet)
			item_equipped.emit({ 'slots': slotSet, 'item': entity.uuid })
			return true

	print(entity.uuid, entity.blueprint)
	return false
	
func unequip(slot) -> int:
	if !slots.has(slot):
		return -1
	var equipped = slots[slot]
	slots.erase(slot)
	item_unequipped.emit(equipped)
	return equipped

func save():
	return slots
