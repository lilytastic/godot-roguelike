class_name UseAction
extends Action

var target: Entity

func _init(_target: Entity):
	target = _target
	pass

func perform(entity: Entity) -> ActionResult:
	if !target:
		return ActionResult.new(false)

	if target.location and target.blueprint.item:
		target.location = null
		entity.inventory.add({ 'entity': target.uuid, 'num': 1 })
		return ActionResult.new(true)
	
	var is_in_inventory = entity.inventory and entity.inventory.items.any(
		func(e): return target.uuid == e.entity
	)
	var is_in_equipment = entity.equipment and entity.equipment.slots.values().any(
		func(e): return target.uuid == e
	)
	
	if is_in_equipment:
		for slot in entity.equipment.slots:
			if entity.equipment.slots[slot] == target.uuid:
				entity.equipment.slots.erase(slot)
				entity.equipment.item_unequipped.emit(target)
				entity.inventory.add({ 'entity': target.uuid, 'num': 1 })
				print('in equipment')
				return ActionResult.new(true)
	
	if is_in_inventory:
		if target.blueprint.item:
			var item_props = target.blueprint.item
			if !item_props.slots:
				pass
			print(item_props.slots)

	return ActionResult.new(false)
