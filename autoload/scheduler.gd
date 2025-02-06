extends Node


var next_actor: Entity

var turn_in_progress = false
var player_can_act: bool:
	get:
		if !next_actor or !Global.player:
			return false
		return next_actor.uuid == Global.player.uuid and !Global.player.is_acting


func _process(delta):
	var player = Global.player

	if !next_actor and player and ECS.entity(player.uuid):
		_update_energy(delta)

	if next_actor != null or !player:
		return
	
	var actors = MapManager.actors
	if !turn_in_progress:
		var valid = actors.keys().filter(
			func(uuid):
				var actor = actors[uuid]
				if !ECS.entity(uuid) or !AIManager.can_act(actor):
					return false
				return actor.blueprint.speed >= 0 and actor.energy >= 0
		)
		
		var next = actors[valid[0]] if valid.size() else null
		if next != null:
			var next_uuid = next.uuid
			turn_in_progress = true
			next_actor = next


# Return the next entity in sequence
func next():
	var actors = MapManager.actors
	var next = actors.values().filter(func(entity): entity.energy >= 0)
	
	if next.size():
		return actors[next[0]]
	else:
		return null


func finish_turn():
	if next_actor:
		next_actor.is_acting = false
	next_actor = null
	turn_in_progress = false

func _update_energy(delta):
	for actor in MapManager.actors:
		if !MapManager.actors[actor]:
			continue
		var entity = MapManager.actors[actor]
		if entity and entity.blueprint.speed:
			var mod = delta
			if Global.player.targeting.current_path.size() > 0:
				mod *= 0.2
			entity.energy += (entity.blueprint.speed * 1.0) * mod
			entity.energy = min(1, entity.energy)
