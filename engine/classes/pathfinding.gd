class_name Pathfinding

static func move_towards(entity: Entity, target_position: Vector2):
	var _path := []
	var path_result = Pathfinding.try_path_to(
		entity.location.position,
		target_position
	)
	if path_result.success and path_result.path.size() > 0:
		_path = path_result.path
		return _path[0]
	else:
		return null

static func try_path_to(start: Vector2, destination: Vector2) -> Dictionary:
	if !MapManager.map_view:
		return { 'success': false, 'path': [] }
	var rect = MapManager.map_view.get_used_rect()
	if destination.x < 0 or destination.x > rect.end.x - 1:
		return { 'success': false, 'path': [] }
		
	var navigation_map = MapManager.navigation_map
	var map_view = MapManager.map_view
	if navigation_map.has_point(map_view.get_astar_pos(start.x, start.y)) and navigation_map.has_point(map_view.get_astar_pos(destination.x, destination.y)):
		var start_point = MapManager.map_view.get_astar_pos(start.x, start.y)
		var destination_point = MapManager.map_view.get_astar_pos(destination.x, destination.y)

		var was_disabled = navigation_map.is_point_disabled(start_point)
		navigation_map.set_point_disabled(start_point, false)
		navigation_map.set_point_disabled(destination_point, false)

		var path = navigation_map.get_point_path(
			start_point,
			destination_point,
			true
		)
		navigation_map.set_point_disabled(start_point, was_disabled)
		return { 'success': true, 'path': path.slice(1) }
	return { 'success': false, 'path': [] }
