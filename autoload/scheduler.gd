extends Node


var next_actor: Entity
var next_queue := []

var last_uuid_selected = -1

var turn_in_progress = false
var player_can_act: bool:
	get:
		if !next_actor or !Global.player:
			return false
		return next_actor.uuid == Global.player.uuid and !Global.player.is_acting


func _process(delta):
	var player = Global.player
	var player_is_valid = player and ECS.entity(player.uuid)

	if !next_actor and player_is_valid:
		await _update_energy(delta)

	if next_actor != null or !player_is_valid:
		return
	
	var actors = MapManager.actors
	if !turn_in_progress and next_queue.size() > 0:
		var next = next_queue.pop_front()
		if next != null:
			# print('switch to: ', next.uuid)
			var next_uuid = next.uuid
			turn_in_progress = true
			last_uuid_selected = next_uuid
			next_actor = next
			AIManager._process(delta)

var last_chosen = {}
func _update_energy(delta: float):
	for actor in MapManager.actors:
		if !MapManager.actors[actor]:
			continue
		var _entity = MapManager.actors[actor]
		if _entity and _entity.blueprint.speed:
			var mod = delta
			if Global.player.targeting.current_path.size() > 0:
				mod *= 0.2
			# print(_entity.blueprint.name, ' ', _entity.blueprint.speed, ' -> ', _entity.energy)
			_entity.energy += (float(_entity.blueprint.speed) * 1.0) * mod * 100.0
			_entity.energy = min(1.0, _entity.energy)
			if _entity.energy >= 1.0:
				if next_queue.find(_entity) == -1:
					next_queue.append(_entity)


func finish_turn():
	if next_actor:
		next_actor.is_acting = false
	next_actor = null
	turn_in_progress = false
	_process(0.01) # THIS IS THE MAGIC SAUCE
