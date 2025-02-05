extends Node2D

func _ready():
	if MapManager.map == '':
		MapManager.map_changed.connect(func(map): _ready())
		return
		
		
	var is_loaded = MapManager.maps_loaded.keys().has(MapManager.map)
	if is_loaded:
		for child in get_children():
			child.queue_free()
		print('Map already loaded; not auto-initializing')
		return;

	MapManager.maps_loaded[MapManager.map] = true

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
			new_entity.location = Location.new(MapManager.map, coords)
		ECS.add(new_entity)
		# print('auto-added: ', new_entity.blueprint.name, ' to map ', MapManager.map)
		child.queue_free()
