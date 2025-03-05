class_name MovementAction
extends Action

var vector: Vector2
var can_alternate = true


func _init(_vector, _can_alternate = true):
	vector = _vector
	can_alternate = _can_alternate

func perform(entity: Entity) -> ActionResult:
	if !MapManager.can_walk(entity.location.position) and entity.uuid == Global.player.uuid:
		entity.location.position = MapManager.current_map.navigation_map.get_closest_position_in_segment(entity.location.position)
		return ActionResult.new(false)
		

	var new_position = entity.location.position + vector

	if !MapManager.can_walk(new_position):
		var collisions = MapManager.get_collisions(new_position)
		if can_alternate and collisions.size():
			var action = AgentManager.get_default_action(entity, collisions[0])
			if action:
				return ActionResult.new(
					false,
					{'alternate': action}
				)
		return ActionResult.new(false)
	
		
	if !MapManager.can_walk(new_position):
		return ActionResult.new(false)
		
	var collisions = ECS.entities.values().filter(
		func(_entity):
			return AgentManager.blocks_entities(_entity) and _entity.location and _entity.location.map == entity.location.map
	).filter(
		func(_entity):
			return _entity.location.position.x == new_position.x and _entity.location.position.y == new_position.y
	)

	if collisions.size():
		for collision in collisions:
			if can_alternate:
				var action = AgentManager.get_default_action(entity, collision)
				if action:
					return ActionResult.new(
						false,
						{'alternate': action}
					)
			else:
				return ActionResult.new(false)
			pass
		return ActionResult.new(false)

	entity.animation = AnimationSequence.new(
		[
			{ 'position': Vector2.ZERO * 0.0, 'scale': Vector2(1, 1) },
			{ 'position': Vector2.UP * 2.0, 'scale': Vector2(1, 1) },
			{ 'position': Vector2.UP * 2.0, 'scale': Vector2(1, 1) },
			{ 'position': Vector2.ZERO * 0.0, 'scale': Vector2(1, 1) },
			{ 'position': Vector2.ZERO * 0.0, 'scale': Vector2(1.1, 0.9) },
		],
		Global.STEP_LENGTH
	)
	
	entity.location.facing = entity.location.position.direction_to(new_position)
	entity.location.position = new_position
	
	if Global.player and entity.uuid == Global.player.uuid:
		pass # await Global.sleep(65)

	return ActionResult.new(true, { 'cost_energy': 100 })
