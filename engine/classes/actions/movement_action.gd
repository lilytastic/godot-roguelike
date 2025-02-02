class_name MovementAction
extends Action

var vector: Vector2


func _init(_vector):
	vector = _vector

func perform(entity: Entity) -> ActionResult:
	var new_position = entity.location.position + vector

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
			# TODO: If it's hostile, use this entity's first weaponskill on it.
			if collision.blueprint.equipment and entity.equipment:
				for uuid in entity.equipment.slots.values():
					var equipment = Global.ecs.entity(uuid)
					if equipment.blueprint.weapon:
						return ActionResult.new(
							false,
							{'alternate': UseAbilityAction.new(
								collision,
								equipment.blueprint.weapon.weaponskills[0],
								{ 'conduit': equipment }
							)}
						)
			# TODO: Otherwise, if it's usable, use it!
			pass
		return ActionResult.new(false)
	
	entity.location.position = new_position
	return ActionResult.new(true, { 'cost_energy': 3 })
