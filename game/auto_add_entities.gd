extends Node2D

func init_entities(map_name: String):
	print('Auto-initializing children: ', get_children())
	for child in get_children():
		var opts = {
			'blueprint': child.get_meta('blueprint') if child.has_meta('blueprint') else 'quadropus'
		}
		var props = child.get_meta('props', {})
		var new_entity = Entity.new(opts)
		var coords = Coords.get_coord(child.position)
		if new_entity.location:
			new_entity.location.position = coords
		else: 
			new_entity.location = Location.new(MapManager.map, coords)
		for prop in props:
			new_entity[prop] = props[prop]
		ECS.add(new_entity)
		# print('auto-added: ', new_entity.blueprint.name, ' to map ', MapManager.map)
		child.queue_free()
