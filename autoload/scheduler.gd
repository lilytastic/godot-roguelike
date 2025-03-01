extends Node


var next_actor: Entity
var next_queue := []

var last_uuid_selected = ''

var turn_in_progress = false
var player_can_act: bool:
	get:
		if !next_actor or !Global.player:
			return false
		return next_actor.uuid == Global.player.uuid and !Global.player.is_acting

var last_tick = 0
var last_player_turn = 0

var lock = false
func _process(delta: float):
	if lock or turn_in_progress:
		return
	lock = true
	# print('_process after ', last_tick - Time.get_ticks_msec(), 'ms')
	last_tick = Time.get_ticks_msec()
	var player = Global.player
	var player_is_valid = player and ECS.entity(player.uuid) and player.health.current > 0

	if next_actor != null or !player_is_valid or MapManager.is_switching:
		lock = false
		return
		
	var actors = MapManager.actors
	if !turn_in_progress:
		if !next_actor and player_is_valid:
			_update_energy()

		for actor in actors:
			if !actors[actor]:
				continue
			var _entity = actors[actor]
			if _entity.energy >= 0.0:
				if next_queue.find(_entity) == -1 and (!next_actor or next_actor.uuid != _entity.uuid):
					next_queue.append(_entity)
	
	if !turn_in_progress and next_queue.size() > 0:
		var next = next_queue[0]
		if !next or !AgentManager.can_act(next):
			next_queue.pop_front()
		else:
			# print('switch to: ', next.uuid, ' with ', next.energy)
			next = next_queue.pop_front()
			var next_uuid = next.uuid
			turn_in_progress = true
			next_actor = next
			last_uuid_selected = next_uuid
			if next_uuid == Global.player.uuid:
				var ticks = Time.get_ticks_msec()
				print("Player's turn after ", ticks - last_player_turn, "ms")
				last_player_turn = ticks
			# This should make it run synchronously and therefore faster, but fucks up the logic somewhere.
			await take_turn(next_actor)
			turn_in_progress = false
			
	lock = false
	_process(0.0)


func take_turn(_actor: Entity):
	var player = Global.player
	
	if !player:
		turn_in_progress = false
		return
		
	if !player.health or player.health.current <= 0:
		# You are dead.
		pass
		
	"""
	if !PlayerInput.is_on_screen(_actor.location.position) and !_actor.targeting.has_target():
		turn_in_progress = false
		_actor.energy -= 100
		if next_actor and next_actor.uuid == _actor.uuid:
			next_actor = null
		return
	"""
		
	if _actor != null and !_actor.is_acting:
		lock = true
		if next_actor and next_actor.uuid == _actor.uuid:
			next_actor = null
		var success = await AgentManager.take_turn(_actor)
		lock = false
		turn_in_progress = false
		# print('success? ', success)
		# print('next actor: ', next_actor)
		if !success:
			next_actor = _actor


var last_chosen = {}
func _update_energy():
	var next_turn_energy = null

	for actor in MapManager.actors:
		if !MapManager.actors[actor]:
			continue
		var _entity = MapManager.actors[actor]
		if !AgentManager.can_act(_entity):
			continue
		
		if _entity.blueprint.speed:
			var speed = float(_entity.blueprint.speed) / 100.0
			var to_next_entity = -minf(0.0, float(_entity.energy))
			# print(to_next_entity)
			if (next_turn_energy == null or next_turn_energy > to_next_entity):
				next_turn_energy = to_next_entity

	# print('progressing: ', next_turn_energy)
	if next_turn_energy and next_turn_energy > 0:
		# print('to next: ', next_turn_energy)
		for actor in MapManager.actors:
			var _entity = MapManager.actors[actor]
			var speed = _entity.blueprint.speed / 100.0
			_entity.energy += next_turn_energy
			_entity.energy = min(0.0, _entity.energy)


func finish_turn(_actor: Entity):
	# print('finished', _actor)
	if next_actor != _actor:
		return
	if _actor:
		# print('finished: ', next_actor.uuid)
		if _actor.uuid == Global.player.uuid:
			last_player_turn = Time.get_ticks_msec()
		_actor.is_acting = false
	next_actor = null
	next_queue.sort_custom(
		func(a, b):
			return a.energy > b.energy
	)
	turn_in_progress = false
	lock = false
	# _process(0.0) # THIS IS THE MAGIC SAUCE
