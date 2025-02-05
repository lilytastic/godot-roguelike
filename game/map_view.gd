class_name MapView
extends TileMapLayer

var actor_prefab: PackedScene = preload('res://game/actor.tscn')

signal actor_added

func _ready():
	if MapManager.map == '':
		MapManager.map_changed.connect(func(map): _ready())
		return
		
	MapManager.map_view = self
	
	print('init map ', MapManager.map)

	visible = false

	ECS.entity_added.connect(
		func(entity: Entity):
			if MapManager.map and entity.location and entity.location.map == MapManager.map:
				_init_actor(entity)
	)
	
	for entity in ECS.entities.values():
		if MapManager.map and entity.location and entity.location.map == MapManager.map:
			_init_actor(entity)
			
	MapManager.navigation_map.clear()
	_init_navigation_map()

	"""
	var is_loaded = MapManager.maps_loaded.keys().has(MapManager.map)
	if is_loaded:
		print('Map already loaded; not auto-initializing')
		return;
	"""

func _process(delta):
	for actor in %Entities.get_children():
		if actor and actor.entity and actor.entity.location:
			actor.visible = AIManager.can_see(Global.player, actor.entity.location.position)


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
						
func _init_actor(entity: Entity):
	var new_actor: Actor = null
	var child = %Entities.find_child('Entity<'+str(entity.uuid)+'>')

	if !child:
		new_actor = actor_prefab.instantiate()
		new_actor.name = 'Entity<'+str(entity.uuid)+'>'
	else:
		new_actor = child

	new_actor.entity = entity
	
	if new_actor.get_parent():
		new_actor.reparent(%Entities)
	else:
		%Entities.add_child(new_actor)
		
	if entity.location:
		new_actor.position = Coords.get_position(entity.location.position)

	if new_actor.has_method('_load'):
		new_actor._load(entity.uuid)

	actor_added.emit(new_actor)
	return new_actor
