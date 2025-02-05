extends Node


func give(receiver: Entity, item: Entity):
	if item.blueprint.item:
		item.location = null
		receiver.inventory.add({ 'entity': item.uuid, 'num': 1 })
		return true
	return false

func equip(receiver: Entity, item: Entity):
	if item.blueprint.item:
		var result = receiver.equipment.equip(item)
		for other_item in result.get('items_swapped', []):
			give(receiver, ECS.entity(other_item))
		if result.success:
			receiver.inventory.remove(item.uuid)
			return true
		return false

func unequip(receiver: Entity, item: Entity):
	var slots_taken = 0
	for slot in receiver.equipment.slots:
		if receiver.equipment.slots[slot] == item.uuid:
			var equipped = receiver.equipment.unequip(slot)
			slots_taken += 1
			if equipped != '':
				if !receiver.inventory.has(equipped):
					give(receiver, item)
	return slots_taken > 0
