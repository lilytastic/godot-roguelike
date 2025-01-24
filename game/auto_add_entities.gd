extends Node2D

@export var map := ''

func _ready():
	if Global.maps_loaded.has(map):
		print('map already loaded')
		for child in get_children():
			child.queue_free()
		return;

	print('get_children() ', get_children())
	for child in get_children():
		var opts = {
			'blueprint': child.get_meta('blueprint') if child.has_meta('blueprint') else 'quadropus'
		}
		print(child.blueprint)
		print('loading new actor ', child)
		var new_entity = Global.ecs.create(opts)
		var coords = Coords.get_coord(child.position)
		if new_entity.location:
			new_entity.location.position = coords
		else: 
			new_entity.location = Location.new(map, coords)
		child.queue_free()
