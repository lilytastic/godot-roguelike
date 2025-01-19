extends TileMapLayer

var map: String
var actor: PackedScene = preload("res://game/actor.tscn")

func _init():
	_update()
	Global.ecs.entity_added.connect(
		func(entity):
			print('added ', entity.uuid)
			_update()
	)

func _update():
	var entities = Global.ecs.entities.values().filter(
		func(entity): return entity.map == map
	)
	for entity in entities:
		if !find_child('Entity<'+str(entity.uuid)+'>'):
			var new_actor = Actor.new(entity)
			add_child(new_actor)
			if !new_actor.has_method('load'):
				continue
			new_actor.load(entity.uuid)
