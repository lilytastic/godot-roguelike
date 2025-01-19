class_name MovementAction
extends Action

var vector: Vector2

func _init(_vector):
	vector = _vector

func perform(entity: Entity) -> ActionResult:
	entity.position = entity.position + vector
	return ActionResult.new(true)
