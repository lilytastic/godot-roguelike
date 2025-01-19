class_name MapView
extends TileMapLayer

var map := ''
var actor: PackedScene = preload("res://game/actor.tscn")
var subscription := _init_map
var actors := {}

var _player: Entity
var player: Entity:
	get: return _player
	set(value):
		if _player:
			_player.map_changed.disconnect(subscription)
		_player = value
		_player.map_changed.connect(subscription)


func _ready():
	_assign_entities()
	_init_map(map)
	_clear_uncast_children()
	
	Global.ecs.entity_added.connect(
		func(value: Entity):
			print('added ', value.uuid)
			_init_actor(value)
	)
	Global.player_changed.connect(
		func(value: Entity):
			player = value
			print('new player ', value)
			_init_map(player.map)
			print('actors', actors)
			for child in get_children():
				if (child.entity and child.entity.map != map):
					print('assign ' + str(child.entity.uuid) + ' to map: ' + map)
					child.entity.map = map
			_clear_uncast_children()
	)


func _assign_entities():
	print('get_children() ', get_children())
	for child in get_children():
		if (!child.entity):
			var opts = EntityCreationOptions.new()
			if child.has_meta('blueprint'):
				opts.blueprint = child.get_meta('blueprint')
			else: opts.blueprint = 'quadropus'
			print(child.blueprint)
			print('loading new actor ', child)
			var new_entity = Global.ecs.create(opts)
			_init_actor(new_entity, child)


func _init_map(_map):
	if map != _map:
		print('Initializing map: ', _map)
		map = _map

	actors = {}
	
	var entities = Global.ecs.entities.values().filter(
		func(entity): return entity.map == _map
	)
	
	for entity in entities:
		var child = find_child('Entity<'+str(entity.uuid)+'>')
		if !child:
			_init_actor(entity)
		else:
			actors[entity.uuid] = child

func _init_actor(entity: Entity, new_actor := Actor.new()):
	entity.position = Coords.get_coord(new_actor.position)
	new_actor.entity = entity
	if new_actor.get_parent():
		new_actor.reparent(self)
	else:
		add_child(new_actor)
	actors[entity.uuid] = new_actor
	if new_actor.has_method('load'):
		new_actor.load(entity.uuid)
	return new_actor


func _clear_uncast_children():
	print('clearing children ', get_children())
	for child in get_children():
		if (!child.entity or child.entity.map != map):
			print('deleting actor for ' + str(child.entity.uuid) if child.entity else '<unknown>')
			child.queue_free()
