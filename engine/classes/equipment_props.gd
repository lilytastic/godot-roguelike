class_name EquipmentProps

var slots := {}

signal item_equipped
signal item_unequipped

func _init(props: Dictionary):
	slots = props

func equip(entity: Entity):
	var blueprint = entity.blueprint
	if !blueprint or !blueprint.item:
		return
	print(blueprint.item.slots)
	for slotSet in blueprint.item.slots:
		print(slotSet)
		var invalidSlots = slotSet.filter(
			func(key):
				return slots.has(key) and slots[key] != null
		)
		if invalidSlots.size() == 0:
			for slot in slotSet:
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
