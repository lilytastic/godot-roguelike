class_name MapView
extends TileMapLayer

var actor_prefab: PackedScene = preload('res://game/actor.tscn')

signal actor_added

func _ready():
	print('init map ', MapManager.map)

	visible = false
	
	MapManager.navigation_map.clear()
	_init_navigation_map()


func get_astar_pos(x, y) -> int:
	var rect := get_used_rect()
	var width = rect.end.x
	return x + width * y

func _init_navigation_map():
	var cells := get_used_cells()
	var rect := get_used_rect()
	var width = rect.end.x
	var height = rect.end.y

	for x in range(width):
		for y in range(height):
			var tile_data = get_cell_tile_data(Vector2i(x, y))
			if tile_data and !tile_data.get_collision_polygons_count(0) > 0:
				MapManager.navigation_map.add_point(
					get_astar_pos(x, y),
					Vector2(x, y)
				)

	for x in range(width):
		for y in range(height):
			var pos = get_astar_pos(x, y)
			if MapManager.navigation_map.has_point(pos):
				for i: StringName in InputTag.MOVE_ACTIONS:
					var offset = Vector2i(x, y) + PlayerInput._input_to_direction(i)
					var point = get_astar_pos(offset.x, offset.y)
					if offset.x < 0 or offset.x > width - 1:
						continue
					if offset.y < 0 or offset.y > height - 1:
						continue
					if MapManager.navigation_map.has_point(point):
						MapManager.navigation_map.connect_points(
							pos,
							point
						)
						
