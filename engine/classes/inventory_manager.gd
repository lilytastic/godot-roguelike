extends Node

func give(receiver: Entity, item: Entity):
	if item.location and item.blueprint.item:
		item.location = null
		receiver.inventory.add({ 'entity': item.uuid, 'num': 1 })
		return true
	return false

func equip(receiver: Entity, item: Entity):
	if item.blueprint.item:
		var success = receiver.equipment.equip(item)
		# TODO: Add anything that got swapped out to the inventory!
		if success:
			receiver.inventory.remove(item.uuid)
	
func unequip(receiver: Entity, item: Entity):
	for slot in receiver.equipment.slots:
		if receiver.equipment.slots[slot] == item.uuid:
			var equipped = receiver.equipment.unequip(slot)
			if equipped != -1:
				receiver.inventory.add({ 'entity': equipped, 'num': 1 })
			print('in equipment')
			return true
	return false
