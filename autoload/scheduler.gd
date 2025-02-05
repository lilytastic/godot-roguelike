extends Node


var next_actor: Entity

var turn_in_progress = false
var player_can_act: bool:
	get:
		return next_actor and next_actor.uuid == Global.player.uuid and !Global.player.is_acting

func _ready():
	PlayerInput.action_triggered.connect(
		func(action):
			if Scheduler.player_can_act:
				var result = await Global.player.perform_action(action)
				if result.success and Scheduler.next_actor:
					Scheduler.next_actor.energy -= result.cost_energy
					Scheduler.next_actor = null
	)
	
func _process(delta):
	var player = Global.player

	if Scheduler.next_actor != null or !player:
		return
	
	var actors = MapManager.actors
	if !Scheduler.turn_in_progress:
		var valid = actors.keys().filter(
			func(uuid):
				if !actors[uuid] or !actors[uuid].location or !MapManager.is_current_map(actors[uuid].location.map):
					actors.erase(uuid)
					return false

				var actor = actors[uuid]
				if !ECS.entity(uuid) or !actor.can_act():
					return false
				return actor.blueprint.speed >= 0 and actor.energy >= 0
		)
		
		var next = actors[valid[0]] if valid.size() else null
		
		if next != null and ECS.entity(player.uuid):
			var next_uuid = next.uuid
			Scheduler.turn_in_progress = true
			Scheduler.next_actor = next
			var result = await _take_turn(Scheduler.next_actor)
			if result:
				Scheduler.next_actor = null
			Scheduler.turn_in_progress = false
			MapManager.update_tiles()

	if !Scheduler.next_actor and ECS.entity(player.uuid):
		_update_energy(delta)


# Return the next entity in sequence
func next():
	var entities = MapManager.actors
	var next = MapManager.actors.values().find(func(entity): entity.energy >= 0)
	
	if next != -1:
		return entities[next]
	else:
		return null


func _take_turn(entity: Entity) -> bool:
	var player = Global.player
	if player and entity.uuid == player.uuid:
		# Player turn
		var result = await entity.trigger_action(ECS.entity(entity.current_target))
		if result:
			entity.energy -= result.cost_energy
			return true
		else:
			var _target_position = player.target_position(false)
			if player.location.position.x == _target_position.x and player.location.position.y == _target_position.y:
				player.clear_targeting()
	else:
		# AI turn
		if player and Coords.get_range(entity.location.position, player.location.position) < 4:
			entity.current_target = player.uuid

		if entity.has_target():
			var path_result = PlayerInput.try_path_to(
				entity.location.position,
				entity.target_position()
			)
			entity.current_path = path_result.path

		var result = await entity.trigger_action(ECS.entity(entity.current_target))
		if !result:
			result = await entity.perform_action(MovementAction.new(
				PlayerInput._input_to_direction(
					InputTag.MOVE_ACTIONS.pick_random()
				)
			), false)

		if result:
			entity.energy -= result.cost_energy
		else:
			entity.energy -= 3
		return true
	return false

func _update_energy(delta):
	for actor in MapManager.actors:
		if !MapManager.actors[actor]:
			continue
		var entity = MapManager.actors[actor]
		if entity and entity.blueprint.speed:
			var mod = delta
			if Global.player.current_path.size() > 0:
				mod *= 0.2
			entity.energy += (entity.blueprint.speed * 1.0) * mod
			entity.energy = min(1, entity.energy)
	
