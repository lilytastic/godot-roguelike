class_name MapView
extends TileMapLayer

var map := ''
var actor: PackedScene = preload("res://game/actor.tscn")

func _init():
	_update()
	Global.ecs.entity_added.connect(
		func(entity):
			print('added ', entity.uuid)
			_update()
	)
	Global.ecs.map_changed.connect(
		func(_map):
			_update()
	)

func _update():
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
