class_name MovementAction
extends Action

var vector: Vector2

func _init(_vector):
	vector = _vector

func perform(entity: Entity) -> ActionResult:
	var new_position = entity.position + vector
	
	var collisions = Global.ecs.entities.values().filter(func(_entity): return _entity.map == entity.map).filter(
		func(_entity):
			return _entity.position.x == new_position.x and _entity.position.y == new_position.y
	)
	if collisions.size():
		return
	
	entity.position = new_position
	return ActionResult.new(true)
