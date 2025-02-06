class_name Pathfinding

static func move_towards(entity: Entity, target_position: Vector2):
	var _path := []
	var path_result = PlayerInput.try_path_to(
		entity.location.position,
		target_position
	)
	if path_result.success and path_result.path.size() > 0:
		_path = path_result.path
		return _path[0]
	else:
		return null
