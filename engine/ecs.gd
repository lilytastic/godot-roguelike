class_name ECS

static var entities: Dictionary = {}

static func entity(id: int) -> Entity:
	if (entities.has(id)):
		return entities[id]
	return null

static func add(_entity: Entity) -> int:
	entities[_entity.uuid] = _entity
	return _entity.uuid
