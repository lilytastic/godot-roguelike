extends Node

var actor_prefab: PackedScene = preload('res://game/actor.tscn')
var current_pattern: TileMapPattern

signal actor_added


func _ready():
	ECS.entity_added.connect(
		func(entity: Entity):
			if MapManager.map and entity.location and entity.location.map == MapManager.map:
				_init_actor(entity)
	)

	MapManager.actors_changed.connect(
		func():
			_check_entities()
	)
	
	_check_entities()
	

func _check_entities():
	for actor in %Entities.get_children():
		actor.queue_free()
		continue

	for entity in ECS.entities.values():
		if MapManager.map and entity.location and entity.location.map == MapManager.map:
			_init_actor(entity)


func _process(delta):
	for actor in %Entities.get_children():
		if !actor or !actor.entity or !ECS.entity(actor.entity.uuid):
			if !actor.is_dying:
				actor.queue_free()
			continue

		if actor.entity.location:
			actor.visible = AIManager.can_see(Global.player, actor.entity.location.position)


func _init_actor(entity: Entity):
	var new_actor: Actor = null
	var child = %Entities.find_child('Entity<'+str(entity.uuid)+'>')

	if !child:
		new_actor = actor_prefab.instantiate()
		new_actor.name = 'Entity<'+str(entity.uuid)+'>'
	else:
		new_actor = child

	new_actor.entity = entity
	
	if new_actor.get_parent():
		new_actor.reparent(%Entities)
	else:
		%Entities.add_child(new_actor)
		
	if entity.location:
		new_actor.position = Coords.get_position(entity.location.position)

	if new_actor.has_method('_load'):
		new_actor._load(entity.uuid)

	actor_added.emit(new_actor)
	return new_actor
