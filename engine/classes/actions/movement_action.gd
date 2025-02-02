class_name MovementAction
extends Action

var vector: Vector2


func _init(_vector):
	vector = _vector

func perform(entity: Entity) -> ActionResult:
	var new_position = entity.location.position + vector

	var rect = Global.map_view.get_used_rect()
	if new_position.x < 0 or new_position.x >= rect.end.x or new_position.y < 0 or new_position.y >= rect.end.y:
		return ActionResult.new(false)
	
	var cell_data = Global.map_view.get_cell_tile_data(new_position)
	if cell_data:
		var is_solid = cell_data.get_collision_polygons_count(0) > 0
		if is_solid:
			return ActionResult.new(false)
	
	var collisions = Global.ecs.entities.values().filter(
		func(_entity):
			return _entity.blueprint.equipment and _entity.location and _entity.location.map == entity.location.map
	).filter(
		func(_entity):
			return _entity.location.position.x == new_position.x and _entity.location.position.y == new_position.y
	)

	if collisions.size():
		for collision in collisions:
			var action = entity.act_on(collision)
			if action:
				return ActionResult.new(
					false,
					{'alternate': action}
				)
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
	return ActionResult.new(true, { 'cost_energy': 3 })
