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
func _process(delta: float):
	if delta > 1:
		delta = 1
	# print('_process after ', last_tick - Time.get_ticks_msec(), 'ms')
	last_tick = Time.get_ticks_msec()
	var player = Global.player
	var player_is_valid = player and ECS.entity(player.uuid) and player.health.current > 0

	if next_actor != null or !player_is_valid or MapManager.is_switching:
		return
		
	var actors = MapManager.actors
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
			# print('switch to: ', next.uuid)
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
			AgentManager._process(0.0)
	
	if !next_actor and player_is_valid and delta > 0.0:
		_update_energy(delta)



var last_chosen = {}
func _update_energy(delta: float):
	var mod = delta
	if Global.player and Global.player.targeting.current_path.size() > 0:
		mod *= 0.4

	for actor in MapManager.actors:
		if !MapManager.actors[actor]:
			continue
		var _entity = MapManager.actors[actor]
		if !PlayerInput.is_on_screen(_entity.location.position) and !_entity.targeting.has_target():
			continue
		if !_entity.is_touched:
			_entity.is_touched = true
		if _entity.blueprint.speed:
			if _entity.energy < 0:
				# print(_entity.blueprint.name, ' ', _entity.blueprint.speed, ' -> ', _entity.energy)
				_entity.energy += _entity.blueprint.speed * mod * 15.0
			# _entity.energy = min(1.0, _entity.energy)


func finish_turn():
	if next_actor:
		# print('finished: ', next_actor.uuid)
		if next_actor.uuid == Global.player.uuid:
			last_player_turn = Time.get_ticks_msec()
		next_actor.is_acting = false
	next_actor = null
	turn_in_progress = false
	_process(0.0) # THIS IS THE MAGIC SAUCE
