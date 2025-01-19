class_name MapView
extends TileMapLayer

var map := ''
var actor: PackedScene = preload("res://game/actor.tscn")
var subscription := func(_map): _init_actors(_map)
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
	_init_actors(map)
	
	Global.ecs.entity_added.connect(
		func(value: Entity):
			print('added ', value.uuid)
			_create(value)
	)
	Global.player_changed.connect(
		func(value: Entity):
			player = value
			print('new player ', value)
			_init_actors(map)
			_clear_children()
	)


func _assign_entities():
	print('get_children() ', get_children())
	for child in get_children():
		if (!child.entity):
			var opts = EntityCreationOptions.new()
			opts.blueprint = 'quadropus'
			print('loading new actor ', child)
			_create(Global.ecs.create(opts), child)


func _init_actors(_map):
	if !player:
		return

	map = _map
	actors = {}
	
	var entities = Global.ecs.entities.values().filter(
		func(entity): return entity.map == map
	)
	
	for entity in entities:
		var child = find_child('Entity<'+str(entity.uuid)+'>')
		if !child:
			_create(entity)


func _create(entity: Entity, new_actor := Actor.new()):
	entity.position = Coords.get_coord(new_actor.position)
	new_actor.entity = entity
	add_child(new_actor)
	actors[entity.uuid] = find_child('Entity<'+str(entity.uuid)+'>')
	if new_actor.has_method('load'):
		new_actor.load(entity.uuid)
	return new_actor


func _clear_children():
	print('clearing children ', get_children())
	for child in get_children():
		if (!child.entity):
			print('deleting actor for ' + child.entity.uuid if child.entity else '<unknown>')
			child.queue_free()
