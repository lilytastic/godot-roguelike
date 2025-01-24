class_name UseAction
extends Action

var target: Entity

func _init(_target: Entity):
	target = _target
	pass

func perform(entity: Entity) -> ActionResult:
	print(entity.uuid)
	if !target:
		return ActionResult.new(false)

	if target.location:
		target.location = null
		entity.inventory.add({ 'entity': target.uuid, 'num': 1 })
		return ActionResult.new(true)
		
	return ActionResult.new(false)
