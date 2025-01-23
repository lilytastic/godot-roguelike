class_name MapView
extends TileMapLayer

@export var map := ''
var actor: PackedScene = preload('res://game/actor.tscn')
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
	_init_player(Global.player)
	
	Global.ecs.entity_added.connect(
		func(value: Entity):
			print('added ', value.uuid)
			if map and value.location and value.location.map == map:
				_init_actor(value)
	)
	Global.player_changed.connect(
		func(value: Entity):
			print('new player ', value)
			_init_player(Global.player)
	)


func _init_player(player: Entity) -> void:
	player = Global.player
	
	if player and player.location:
		_init_map(player.location.map)


func _init_actor(entity: Entity, new_actor := Actor.new()):
	new_actor.entity = entity
	if new_actor.get_parent():
		new_actor.reparent(self)
	else:
		add_child(new_actor)
	actors[entity.uuid] = new_actor
	if entity.location:
		new_actor.position = Coords.get_position(entity.location.position) + Vector2(8, 8)
	if new_actor.has_method('load'):
		new_actor.load(entity.uuid)
	return new_actor


func _init_map(_map):
	if map != _map:
		print('Initializing map: ', _map)
		Global.maps_loaded[_map] = true
		map = _map

	actors = {}
	
	var entities = Global.ecs.entities.values().filter(
		func(entity):
			if !entity.location: return false
			return entity.location.map == _map
	)
	
	for entity in entities:
		var child = find_child('Entity<'+str(entity.uuid)+'>')
		if !child:
			_init_actor(entity)
		else:
			actors[entity.uuid] = child
