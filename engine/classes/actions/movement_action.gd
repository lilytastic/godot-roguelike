class_name MovementAction
extends Action

var vector: Vector2
var can_alternate = true


func _init(_vector, _can_alternate = true):
	vector = _vector
	can_alternate = _can_alternate

func perform(entity: Entity) -> ActionResult:
	var new_position = entity.location.position + vector

	if !MapManager.map_view:
		return ActionResult.new(false)

	var rect = MapManager.map_view.get_used_rect()
	if new_position.x < 0 or new_position.x >= rect.end.x or new_position.y < 0 or new_position.y >= rect.end.y:
		return ActionResult.new(false)
	
	var cell_data = MapManager.map_view.get_cell_tile_data(new_position)
	if cell_data:
		var is_solid = cell_data.get_collision_polygons_count(0) > 0
		if is_solid:
			return ActionResult.new(false)
	
	var collisions = ECS.entities.values().filter(
		func(_entity):
			return AIManager.blocks_entities(_entity) and _entity.location and _entity.location.map == entity.location.map
	).filter(
		func(_entity):
			return _entity.location.position.x == new_position.x and _entity.location.position.y == new_position.y
	)

	if collisions.size():
		for collision in collisions:
			if can_alternate:
				var action = AIManager.get_default_action(entity, collision)
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
			{ 'position': Vector2.UP * 3.0, 'scale': Vector2(1, 1) },
			{ 'position': Vector2.UP * 3.0, 'scale': Vector2(1, 1) },
			{ 'position': Vector2.ZERO * 0.0, 'scale': Vector2(1, 1) },
			{ 'position': Vector2.ZERO * 0.0, 'scale': Vector2(1.2, 0.8) },
		],
		Global.STEP_LENGTH
	)
	
	entity.location.position = new_position
	
	if Global.player and entity.uuid == Global.player.uuid:
		await Global.sleep(80)

	return ActionResult.new(true, { 'cost_energy': 3 })
