class_name UseAction
extends Action

var target: Entity

func _init(_target: Entity):
	target = _target

func perform(entity: Entity) -> ActionResult:
	if !target:
		return ActionResult.new(false)
		
	entity.animation = AnimationSequence.new(
		[
			{ 'scale': Vector2(1, 1) },
			{ 'scale': Vector2(1.3, 0.7) },
			{ 'scale': Vector2(1.3, 0.7) },
		],
		Global.STEP_LENGTH * 0.5
	)

	if target.blueprint.use:
		print(target.blueprint.use)
		match target.blueprint.use:
			'teleport':
				if !target.destination:
					return ActionResult.new(false)
				print(target.destination)
				
				if !target.destination.has('map'):
					var _map = await MapManager.create_map(target.destination)
					var _entities = ECS.entities.values().filter(func(e): return e.location and e.location.map == _map.uuid)
					print(_entities.size(), ' entities found at ', _map.uuid)
					var _starting_position = Vector2i(-1, -1)
					for _entity in _entities:
						print(_entity.destination)
						if _entity.destination:
							_starting_position = _entity.location.position
					target.destination = {
						'map': _map.uuid,
						'position': _starting_position
					}
					if !_map:
						return ActionResult.new(false)
					
				if target.destination.has('map'):
					entity.location.map = target.destination.map
					entity.location.position = Global.string_to_vector(target.destination.position)
					MapManager.switch_map(MapManager.maps[target.destination.map], entity)
					MapManager.init_actors()
					return ActionResult.new(true, { 'cost_energy': 100 })
				
		pass

	if target.location and target.blueprint.item:
		if InventoryManager.give(entity, target):
			return ActionResult.new(true, { 'cost_energy': 100 })

	if entity.equipment and entity.equipment.has(target.uuid):
		if InventoryManager.unequip(entity, target):
			return ActionResult.new(true)

	if entity.inventory and entity.inventory.has(target.uuid):
		if InventoryManager.equip(entity, target):
			return ActionResult.new(true)

	return ActionResult.new(false)
