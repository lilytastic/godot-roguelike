extends Node

var skills: Dictionary = {}
var skill_trees: Dictionary = {}

func _ready():
	var resources = Files.get_all_files('res://data/skills')
	skills.clear()
	skill_trees.clear()
	for resource in resources:
		var obj = load(resource)
		var rid = obj.get_instance_id()
		if obj is Skill:
			skills[rid] = obj
		if obj is SkillTree:
			skill_trees[rid] = obj
# 	print("Skills: ", skills)
#	print("Skill trees: ", skill_trees)
	
var lock = false

func _process(delta):
	if lock:
		return
	# Check if the Scheduler.next_actor is not the player, then trigger an action
	var player = Global.player
	var next_actor = Scheduler.next_actor
	
	if !player:
		return
		
	if !player.health or player.health.current <= 0:
		# You are dead.
		pass

	if next_actor != null and !next_actor.is_acting:
		lock = true
		Scheduler.next_actor = null
		var success = await take_turn(next_actor)
		lock = false
		if success:
			Scheduler.finish_turn()
		else:
			Scheduler.next_actor = next_actor



func perform_action(entity: Entity, action: Action, allow_recursion := true) -> ActionResult:
	entity.is_acting = true
	var result = await action.perform(entity)
	entity.energy -= result.cost_energy
	entity.is_acting = false
	if !result.success and result.alternate:
		if allow_recursion:
			return await perform_action(entity, result.alternate)
	if result.success:
		Scheduler.finish_turn()
		entity.update_fov()
	entity.action_performed.emit(action, result)
	return result



func take_turn(entity: Entity) -> bool:
	var player = Global.player
	
	if !entity:
		return false

	if player and is_hostile(entity, player) and entity.location and player.location:
		if Coords.get_range(entity.location.position, player.location.position) < 4:
			entity.targeting.current_target = player.uuid

	var target = ECS.entity(entity.targeting.current_target)
	if target:
		var default_action = get_default_action(entity, target)
		if default_action and is_within_range(entity, target, default_action):
			var result = await perform_action(entity, default_action)
			entity.targeting.clear()
			if result:
				return true
	var _result = await try_close_distance(
		entity,
		entity.targeting.target_position()
	)
	if _result:
		return true

	if entity.uuid != player.uuid:
		# print('doing stuff as ', entity.blueprint.name, '; ', Time.get_ticks_msec())
		# Idling
		if randf_range(0, 100) < 50:
			var result = await perform_action(
				entity,
				MovementAction.new(
					PlayerInput._input_to_direction(
						InputTag.MOVE_ACTIONS.pick_random()
					)
				),
				false
			)
			if result:
				return true
		else:
			var result = await perform_action(
				entity,
				MovementAction.new(Vector2i.ZERO),
				false
			)
			if result:
				return true
	else:
		var _target_position = player.targeting.target_position()
		# print("_target_position ", _target_position)
		if player.location.position.x == _target_position.x and player.location.position.y == _target_position.y:
			player.targeting.clear_targeting()
	
	return false

func get_default_action(entity: Entity, target: Entity) -> Action:
	# If it's hostile, use this entity's first weaponskill on it.
	if is_hostile(entity, target):
		var dict = get_abilities(entity, target)[0]
		return UseAbilityAction.new(
			target,
			dict.ability,
			dict
		)
	# Otherwise, if it's usable, use it!
	if target and (target.blueprint.item or target.blueprint.use):
		return UseAction.new(target)
		
	return null

func get_abilities(entity: Entity, target: Entity = null) -> Array[Dictionary]: 
	var arr: Array[Dictionary] = []
	if entity.equipment:
		var weapons := []
		for uuid in entity.equipment.slots.values():
			if weapons.find(uuid) != -1:
				continue
			weapons.append(uuid)

		# TODO: The basic attack (0) should be different when dual-wielding
		for uuid in weapons:
			var worn_item = ECS.entity(uuid)
			if worn_item.blueprint.weapon:
				for ability in worn_item.blueprint.weapon.weaponskills:
					arr.append({'ability': ability, 'conduit': worn_item})
	if arr.size() == 0:
		arr.append({'ability': 'slash'})
	return arr

func try_close_distance(entity: Entity, position: Vector2) -> bool:
	var next_position = Pathfinding.move_towards(entity, position)
	var next_in_path = null

	var used_path = false
	if entity.targeting.current_path.size():
		used_path = true
		next_in_path = entity.targeting.current_path[0]

	if next_in_path and Coords.get_range(next_in_path, entity.location.position) < 2:
		var result = await perform_action(
			entity,
			MovementAction.new(next_in_path - entity.location.position),
			false
		)
		if result.success:
			entity.targeting.current_path = entity.targeting.current_path.slice(1)
			return true
	
	if !next_position:
		return false

	var result = await perform_action(
		entity,
		MovementAction.new(next_position - entity.location.position),
		false
	)
	return result.success


func can_see(entity: Entity, seen_position: Vector2i) -> bool:
	if !entity.location:
		return false
	var position = entity.location.position
	return entity.visible_tiles.get(seen_position, false)

func can_act(entity: Entity) -> bool:
	if !entity:
		return false
	if !entity.health or entity.health.current <= 0:
		return false
	return entity.blueprint.equipment != null

func blocks_entities(entity: Entity) -> bool:
	return can_act(entity)

func is_hostile(entity: Entity, other: Entity) -> bool:
	if other.uuid == entity.uuid:
		return false
	if entity.blueprint.name == 'trainer' or other.blueprint.name == 'trainer':
		return false
	return can_act(entity)

# TODO: Move within Action class?
func is_within_range(entity: Entity, target: Entity, action: Action) -> bool:
	var act_range = 0
	if target and AgentManager.blocks_entities(target):
		act_range = 1

	var distance = Coords.get_range(entity.location.position, entity.targeting.target_position())
	if distance > act_range:
		return false

	return true
