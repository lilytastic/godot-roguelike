class_name Targeting
extends Node


var current_path := []
var current_target := '' # uuid
var current_target_position: Vector2i = Vector2i(-1, -1)

func clear():
	clear_path()
	clear_targeting()

func clear_path():
	current_path = []
	
func path_needs_updating() -> bool:
	var _reset_path = false
	var navigation_map = MapManager.navigation_map
	if has_target():
		if current_path.size() == 0:
			_reset_path = true
		else:
			var _target_position = target_position()
			var _last_position = current_path[current_path.size() - 1]
			for coord in current_path.slice(1, -1):
				if navigation_map.is_point_disabled(MapManager.get_astar_pos(coord.x, coord.y)):
					_reset_path = true
			if _target_position.x != _last_position.x or _target_position.y != _last_position.y:
				_reset_path = true
	return _reset_path


func clear_targeting():
	current_target_position = Vector2i(-1, -1)
	current_target = ''

func set_target_position(pos: Vector2):
	current_target_position = pos
	current_target = ''

func has_target() -> bool:
	if current_target != '':
		return true
		
	if current_target_position != Vector2i(-1, -1):
		return true

	return false

func target_position():
	var target = ECS.entity(current_target)
	if target and target.location:
		return target.location.position
		
	if current_target_position != Vector2i(-1, -1):
		return current_target_position

	return Vector2(-1, -1)
