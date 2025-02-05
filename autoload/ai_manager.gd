extends Node


func _process(delta):
	# Check if the Scheduler.next_actor is not the player, then trigger an action
	var player = Global.player
	var next_actor = Scheduler.next_actor

	if !player:
		return
	if next_actor != null and !next_actor.is_acting:
		var result = await take_turn(next_actor)
		if !result:
			if next_actor.uuid == player.uuid:
				var _target_position = player.targeting.target_position(false)
				if player.location.position.x == _target_position.x and player.location.position.y == _target_position.y:
					player.targeting.clear_targeting()
			else:
				result = await perform_action(
					next_actor,
					MovementAction.new(
						PlayerInput._input_to_direction(
							InputTag.MOVE_ACTIONS.pick_random()
						)
					),
				false)

func take_turn(entity: Entity) -> bool:
	var player = Global.player
	
	if !entity:
		return false
		
	if player and entity.uuid != player.uuid:
		if Coords.get_range(entity.location.position, player.location.position) < 4:
			entity.targeting.current_target = player.uuid

	var result = await trigger_action(
		entity,
		ECS.entity(entity.targeting.current_target)
	)

	if result: return true
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

# TODO: Untangle this shit and stop PlayerInput from calling it
func trigger_action(entity: Entity, target: Entity) -> ActionResult:
	var target_position = entity.targeting.target_position(false)

	var act_range = 0
	if !entity.targeting.has_target():
		return

	if target and AIManager.blocks_entities(target):
		act_range = 1

	var distance = Coords.get_range(entity.location.position, target_position)
	if distance > act_range:
		if !entity.targeting.current_path.size():
			var path_result = PlayerInput.try_path_to(
				entity.location.position,
				target_position
			)
			if path_result.success:
				entity.targeting.current_path = path_result.path

		if entity.targeting.current_path.size() and entity.targeting.current_path[0] == entity.location.position:
			entity.targeting.current_path = entity.targeting.current_path.slice(1)

		if !entity.targeting.current_path.size():
			return null
			
		var result = await perform_action(
			entity,
			MovementAction.new(
				entity.targeting.current_path[0] - entity.location.position
			),
			false
		)
		if result.success:
			entity.targeting.current_path = entity.targeting.current_path.slice(1)
		else:
			entity.targeting.clear_path()
			entity.targeting.clear_targeting()

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
			entity.targeting.clear_path()
			entity.targeting.clear_targeting()
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

func perform_action(entity: Entity, action: Action, allow_recursion := true) -> ActionResult:
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
