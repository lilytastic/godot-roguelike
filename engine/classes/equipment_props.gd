class_name EquipmentProps

var slots := {}

func _init(props: Dictionary):
	if !(props.get('slots', {}) is Dictionary):
		return
	slots = props.get('slots', {})

func equip(uuid: int):
	var entity = Global.ecs.entity(uuid)
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
			return true
	print(entity.uuid, entity.blueprint)
	return false

func save():
	return slots
