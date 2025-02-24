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
		print('no item for blueprint')
		return { 'success': false }
		
	var item_slots = blueprint.item.slots.duplicate(true)
	item_slots.sort_custom(_empty_slots_first)

	var swapped = []
	for slotSet in item_slots:
		for slot in slotSet:
			var previously_equipped = unequip(slot)
			if previously_equipped != '':
				swapped.append(previously_equipped)
			slots[slot] = entity.uuid

		item_equipped.emit({ 'slots': slotSet, 'item': entity.uuid })
		return { 'success': true, 'items_swapped': swapped }

	print('no slot for blueprint')
	return { 'success': false }
	
func unequip(slot) -> String:
	if !slots.has(slot):
		return ''

	var previously_equipped = slots[slot]
	for _slot in slots.keys():
		if slots[_slot] == previously_equipped:
			slots.erase(_slot)
	item_unequipped.emit(previously_equipped)

	return previously_equipped

func has(uuid: String) -> bool:
	return slots.values().any(
		func(e): return uuid == e
	)
	
func save():
	return slots
