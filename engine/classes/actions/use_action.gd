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
		if InventoryManager.give(entity, target):
			return ActionResult.new(true)

	if entity.equipment and entity.equipment.has(target.uuid):
		if InventoryManager.unequip(entity, target):
			return ActionResult.new(true)

	if entity.inventory and entity.inventory.has(target.uuid):
		if InventoryManager.equip(entity, target):
			return ActionResult.new(true)

	return ActionResult.new(false)
