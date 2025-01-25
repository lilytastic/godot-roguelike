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
	
	if is_in_inventory:
		# ...
		pass

	return ActionResult.new(false)
