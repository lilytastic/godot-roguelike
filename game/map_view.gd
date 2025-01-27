class_name MapView
extends TileMapLayer

@export var map := ''
var actor_prefab: PackedScene = preload('res://game/actor.tscn')
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
	_init_player()
	
	Global.ecs.entity_added.connect(
		func(value: Entity):
			if map and value.location and value.location.map == map:
				_init_actor(value)
	)
	
	Global.player_changed.connect(
		func(value: Entity):
			_init_player()
	)
	
	if PlayerInput.ui_action_triggered.get_connections().size() > 0:
		PlayerInput.ui_action_triggered.disconnect(_on_ui_action)
	PlayerInput.ui_action_triggered.connect(_on_ui_action)
	
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
	
	var valid = actors.keys().filter(
		func(uuid):
			if !actors[uuid]:
				actors.erase(uuid)
				return false
			var actor = actors[uuid]
			if !actor.entity:
				return false
			return actor.entity.blueprint.speed >= 0 and actor.entity.energy >= 0
	)
	
	var next = actors[valid[0]] if valid.size() else null
	
	if next != null:
		next_actor = next.entity
		if Global.player and next_actor.uuid == Global.player.uuid:
			pass
		else:
			next_actor.energy -= 10
			next_actor = null

	if !next_actor:
		for actor in actors:
			if !actors[actor]:
				continue
			var entity = actors[actor].entity
			if entity and entity.blueprint.speed:
				entity.energy += entity.blueprint.speed * delta
			

func _init_player() -> void:
	_player = Global.player
	
	if _player and _player.location:
		_init_map(_player.location.map)

func _on_ui_action(action):
	action.perform(Global.player)

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
