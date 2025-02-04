class_name MapView
extends TileMapLayer

@export var map := ''
var actor_prefab: PackedScene = preload('res://game/actor.tscn')

var _fov_map := {}
var last_position: Vector2

signal actor_added


func _enter_tree():
	Global.map_view = self

func init():
	print('init map')
	visible = false
	Global.map_view = self

	Global.ecs.entity_added.connect(
		func(entity: Entity):
			if map and entity.location and entity.location.map == map:
				_init_actor(entity)
	)
	
	for entity in Global.ecs.entities.values():
		if map and entity.location and entity.location.map == map:
			_init_actor(entity)
			
	Global.navigation_map.clear()
	_init_navigation_map()
	
	get_viewport().connect("size_changed", _render_fov)
	_render_fov()

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
				Global.navigation_map.add_point(
					get_astar_pos(x, y),
					Vector2(x, y)
				)

	for x in range(width):
		for y in range(height):
			var pos = get_astar_pos(x, y)
			if Global.navigation_map.has_point(pos):
				for i: StringName in InputTag.MOVE_ACTIONS:
					var offset = Vector2i(x, y) + PlayerInput._input_to_direction(i)
					var point = get_astar_pos(offset.x, offset.y)
					if offset.x < 0 or offset.x > width - 1:
						continue
					if offset.y < 0 or offset.y > height - 1:
						continue
					if Global.navigation_map.has_point(point):
						Global.navigation_map.connect_points(
							pos,
							point
						)

func _process(delta):
	if last_position != Global.player.location.position:
		last_position = Global.player.location.position
		_render_fov()

	for actor in %Entities.get_children():
		if actor and actor.entity and actor.entity.location:
			actor.visible = Global.player.can_see(actor.entity.location.position)

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


func _render_fov() -> void:
	# print('render fov')

	for child in %Tiles.get_children():
		child.free()
	
	var tiles = get_used_cells().filter(
		func(tile):
			# TODO: filter for visible area
			return Global.player and Global.player.can_see(tile) # tile.y == Global.player.location.position.y or tile.x == Global.player.location.position.x
	)

	for tile in tiles:
		%Tiles.add_child(MapTile.generate_tile(tile, self))
