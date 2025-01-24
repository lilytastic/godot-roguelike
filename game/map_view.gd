class_name MapView
extends TileMapLayer

@export var map := ''
var actor: PackedScene = preload('res://game/actor.tscn')
var subscription := _init_map
var actors := {}

var scheduler = Scheduler.new()
var next_actor: Entity

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
	
	PlayerInput.action_triggered.connect(func(action):
		if next_actor and next_actor.uuid == Global.player.uuid:
			var result = _perform_action(action, Global.player)
			if result.success:
				next_actor.energy -= result.cost_energy
				next_actor = null
	)

func _perform_action(action: Action, _entity: Entity):
	var result = action.perform(_entity)
	if !result.success and result.alternate:
		return _perform_action(result.alternate, _entity)
	return result

func _process(delta):
	scheduler.entities = actors.keys()
	if next_actor != null or !Global.player:
		return
	
	var valid = actors.values().filter(
		func(actor):
			if !actor:
				actors.erase(actor)
				return false
			return actor.entity.blueprint.speed >= 0 and actor.entity.energy >= 0
	)
	var next = valid[0] if valid.size() else null
	
	if next != null:
		next_actor = next.entity
		print('ready! ', next_actor.blueprint.id)
		if Global.player and next_actor.uuid == Global.player.uuid:
			print('it you')
		else:
			next_actor.energy -= 10
			next_actor = null

	if !next_actor:
		for actor in actors:
			if !actors[actor]:
				continue
			var entity = actors[actor].entity
			if entity and entity.blueprint.speed:
				# print(entity.energy, ' ', entity.blueprint.speed * delta)
				entity.energy += entity.blueprint.speed * delta
			

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
