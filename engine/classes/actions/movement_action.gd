class_name MovementAction
extends Action

var vector: Vector2

func _init(_vector):
	vector = _vector

func perform(entity: Entity) -> ActionResult:
	var new_position = entity.location.position + vector
	
	var collisions = Global.ecs.entities.values().filter(func(_entity): return _entity.location and _entity.location.map == entity.location.map).filter(
		func(_entity):
			return _entity.location.position.x == new_position.x and _entity.location.position.y == new_position.y
	)
	if collisions.size():
		return
	
	entity.location.position = new_position
	return ActionResult.new(true)
