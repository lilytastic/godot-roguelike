extends Node2D

@export var map := -1

func _ready():
	if map == -1:
		print('Default map to: ', MapManager.current_map.name)
		map = MapManager.current_map.id

	if MapManager.maps_loaded.has(map):
		for child in get_children():
			child.queue_free()
		print('Map already loaded; not auto-initializing')
		return;
	MapManager.maps_loaded[map] = true

	print('Auto-initializing children: ', get_children())
	for child in get_children():
		var opts = {
			'blueprint': child.get_meta('blueprint') if child.has_meta('blueprint') else 'quadropus'
		}
		var new_entity = Entity.new(opts)
		var coords = Coords.get_coord(child.position)
		if new_entity.location:
			new_entity.location.position = coords
		else: 
			new_entity.location = Location.new(map, coords)
		ECS.add(new_entity)
		print('auto-added: ', new_entity.blueprint.name, ' to map ', map)
		child.queue_free()
