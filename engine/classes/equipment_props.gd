class_name EquipmentProps

var slots := {}

signal item_equipped
signal item_unequipped


func _init(props: Dictionary):
	slots = props
	
func _empty_slots_first(a, b):
	var all_slots_empty = a.filter(
		func(key):
			return slots.has(key) and slots[key] != null
	).size() == 0
	
	var all_slots_empty_b = b.filter(
		func(key):
			return slots.has(key) and slots[key] != null
	).size() == 0
	
	if all_slots_empty and !all_slots_empty_b:
		return true
	return false

func equip(entity: Entity, opts := {}) -> Dictionary:
	var blueprint = entity.blueprint
	if !blueprint or !blueprint.item:
		return { 'success': false }
		
	var item_slots = blueprint.item.slots.duplicate(true)
	item_slots.sort_custom(_empty_slots_first)

	var swapped = []
	for slotSet in item_slots:
		print(slotSet)
		for slot in slotSet:
			if slots.has(slot):
				swapped.append(unequip(slot))
			slots[slot] = entity.uuid

		print('equipped to ', slotSet)
		item_equipped.emit({ 'slots': slotSet, 'item': entity.uuid })
		return { 'success': true, 'items_swapped': swapped }

	return { 'success': false }
	
func unequip(slot) -> int:
	if !slots.has(slot):
		return -1

	var previously_equipped = slots[slot]
	slots.erase(slot)
	item_unequipped.emit(previously_equipped)

	return previously_equipped

func has(uuid: int) -> bool:
	return slots.values().any(
		func(e): return uuid == e
	)
	
func save():
	return slots
