class_name UseAction
extends Action

var target: Entity

func _init(_target: Entity):
	target = _target
	pass

func perform(entity: Entity) -> ActionResult:
	entity.energy -= 10
	return ActionResult.new(true)
