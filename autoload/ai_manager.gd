extends Node


func _process(delta):
	# Check if the Scheduler.next_actor is not the player, then trigger an action
	var player = Global.player
	var next_actor = Scheduler.next_actor

	if !player:
		return
	if next_actor != null and !next_actor.is_acting:
		take_turn(next_actor)


func take_turn(entity: Entity) -> bool:
	var player = Global.player
	if !entity:
		return false
	if player and entity.uuid == player.uuid:
		# Player turn
		var result = await trigger_action(
			entity,
			ECS.entity(entity.targeting.current_target)
		)
		if result:
			return true
		else:
			var _target_position = player.targeting.target_position(false)
			if player.location.position.x == _target_position.x and player.location.position.y == _target_position.y:
				player.targeting.clear_targeting()
	else:
		# AI turn
		if player and Coords.get_range(entity.location.position, player.location.position) < 4:
			entity.targeting.current_target = player.uuid

		if entity.targeting.has_target():
			var path_result = PlayerInput.try_path_to(
				entity.location.position,
				entity.targeting.target_position()
			)
			entity.targeting.current_path = path_result.path

		var result = await trigger_action(
			entity,
			ECS.entity(entity.targeting.current_target)
		)
		if !result:
			result = await perform_action(
				entity,
				MovementAction.new(
					PlayerInput._input_to_direction(
						InputTag.MOVE_ACTIONS.pick_random()
					)
				),
			false)
			
		if result:
			return true
	return false


func can_see(entity: Entity, pos: Vector2) -> bool:
	return true # Coords.get_range(pos, location.position) < 7

func can_act(entity: Entity) -> bool:
	return entity.blueprint.equipment != null

func blocks_entities(entity: Entity) -> bool:
	return can_act(entity)

func is_hostile(entity: Entity, other: Entity) -> bool:
	if other.uuid == entity.uuid:
		return false
	return can_act(entity)


func trigger_action(entity: Entity, target: Entity):
	var targeting = entity.targeting

	var act_range = 0
	if target and AIManager.blocks_entities(target):
		act_range = 1
	if targeting.current_path.size() and targeting.current_path[0] == entity.location.position:
		targeting.current_path = targeting.current_path.slice(1)

	# TODO: Check actual distance in case the path is wrong
	var distance = targeting.current_path.size()
	if distance > act_range:
		var result = await perform_action(
			entity,
			MovementAction.new(
				targeting.current_path[0] - entity.location.position
			),
			false
		)
		if result.success:
			targeting.current_path = targeting.current_path.slice(1)
		else:
			targeting.clear_path()
			targeting.clear_targeting()

		return result
	else:
		if target:
			var default_action = get_default_action(entity, target)
			if !default_action:
				default_action = MovementAction.new(
					PlayerInput._input_to_direction(
						InputTag.MOVE_ACTIONS.pick_random()
					)
				)
			var result = null
			if default_action:
				result = await perform_action(entity, default_action)
			targeting.clear_path()
			targeting.clear_targeting()
			if result:
				return result

	return null

func get_default_action(entity: Entity, target: Entity) -> Action:
	# TODO: If it's hostile, use this entity's first weaponskill on it.
	if target.blueprint.equipment:
		if entity.equipment:
			for uuid in entity.equipment.slots.values():
				var worn_item = ECS.entity(uuid)
				if worn_item.blueprint.weapon:
					var ability = worn_item.blueprint.weapon.weaponskills[0]
					return UseAbilityAction.new(
						target,
						ability,
						{ 'conduit': worn_item } if worn_item else {}
					)
		return UseAbilityAction.new(
			target,
			'slash'
		)
	# TODO: Otherwise, if it's usable, use it!
	if target.blueprint.item:
		return UseAction.new(target)
		
	return null

func perform_action(entity: Entity, action: Action, allow_recursion := true):
	entity.is_acting = true
	var result = await action.perform(entity)
	entity.energy -= result.cost_energy
	if !result.success and result.alternate:
		if allow_recursion:
			return await perform_action(entity, result.alternate)
	entity.is_acting = false
	Scheduler.finish_turn()
	entity.action_performed.emit(action, result)
	return result
