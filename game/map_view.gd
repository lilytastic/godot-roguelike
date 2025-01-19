class_name MapView
extends TileMapLayer

var map := ''
var actor: PackedScene = preload("res://game/actor.tscn")
var subscription := func(_map): _update()

var _player: Entity
var player: Entity:
	get: return _player
	set(value):
		if _player:
			_player.map_changed.disconnect(subscription)
		_player = value
		_player.map_changed.connect(subscription)

func _init():
	_update()
	Global.ecs.entity_added.connect(
		func(entity):
			print('added ', entity.uuid)
			_update()
	)
	Global.player_changed.connect(
		func(__player):
			player = __player
			_update()
	)

func _update():
	if !player:
		return

	map = player.map
	
	var entities = Global.ecs.entities.values().filter(
		func(entity): return entity.map == map
	)
	
	var safe := {}
	
	for entity in entities:
		var child = find_child('Entity<'+str(entity.uuid)+'>')
		if !child:
			var new_actor = Actor.new(entity)
			add_child(new_actor)
			safe[entity.uuid] = find_child('Entity<'+str(entity.uuid)+'>')
			if !new_actor.has_method('load'):
				continue
			new_actor.load(entity.uuid)

	for child in find_children('Entity'):
		if (!child.uuid or !safe.has(child.uuid)):
			child.queue_free()
