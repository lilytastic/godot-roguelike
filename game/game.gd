extends Node

const PC_TAG = 'PC'
var player: Entity:
	get: return Global.player
var camera_speed := 4

var scheduler = Scheduler.new()
var actors := {} # All entities on the "scene"
var next_actor: Entity

@export var map = ''


func _ready() -> void:
	if !Global.player:
		Global.new_game()
		# Global.autosave()

	if !Global.player.location:
		$Camera2D.position = Coords.get_position(
			Global.player.location.position
		)
		
	if PlayerInput.ui_action_triggered.get_connections().size() > 0:
		PlayerInput.ui_action_triggered.disconnect(_on_ui_action)
	PlayerInput.ui_action_triggered.connect(_on_ui_action)

	Global.ecs.entity_added.connect(
		func(entity: Entity):
			if map and entity.location and entity.location.map == map:
				actors[entity.uuid] = entity
	)
	
	PlayerInput.action_triggered.connect(func(action):
		if next_actor and next_actor.uuid == Global.player.uuid:
			var result = await _perform_action(action, Global.player)
			if result.success:
				next_actor.energy -= result.cost_energy
				next_actor = null
	)	
	
	_init_map(map)
	

func _process(delta):
	if player and player.location != null:
		var _camera_position = Coords.get_position(player.location.position)
		var _camera_speed = camera_speed
		var _target = Global.ecs.entity(player.current_target)
		if _target:
			_camera_position = _camera_position.lerp(
				Coords.get_position(_target.location.position),
				0.5
			)
		else:
			if player.current_path.size() > 0:
				_camera_position = _camera_position.lerp(
					Coords.get_position(
						player.current_path[floor(player.current_path.size() / 2)]
					),
					0.5
				)
				# _camera_speed /= 2.0
		$Camera2D.position = lerp(
			$Camera2D.position,
			_camera_position,
			delta * _camera_speed
		)

	$Camera2D.offset = Vector2i(8 + 16 * 0, 8)
	PlayerInput._update_mouse_position()
	
	if next_actor != null or !Global.player:
		return
	
	var valid = actors.keys().filter(
		func(uuid):
			if !actors[uuid] or !actors[uuid].location or actors[uuid].location.map != map:
				actors.erase(uuid)
				return false

			var actor = actors[uuid]
			if !Global.ecs.entity(uuid) or !actor.can_act():
				return false
			return actor.blueprint.speed >= 0 and actor.energy >= 0
	)
	
	scheduler.entities = valid
	
	var next = actors[valid[0]] if valid.size() else null
	
	if next != null:
		next_actor = next
		if Global.player and next_actor.uuid == Global.player.uuid:
			_check_path(next_actor)
			# Player turn
			var result = await _trigger_action(next_actor, Global.ecs.entity(next_actor.current_target))
			if result:
				next_actor.energy -= result.cost_energy
				next_actor = null
		else:
			# AI turn
			var result = await _perform_action(
				MovementAction.new(
					PlayerInput._input_to_direction(
						InputTag.MOVE_ACTIONS.pick_random()
					)
				),
				next_actor
			)
			next_actor.energy -= result.cost_energy
			next_actor = null

	if !next_actor:
		for actor in actors:
			if !actors[actor]:
				continue
			var entity = actors[actor]
			if entity and entity.blueprint.speed:
				var mod = delta
				if Global.player.current_path.size() > 0:
					mod *= 0.2
				entity.energy += (entity.blueprint.speed * 1.0) * mod
				entity.energy = min(1, entity.energy)


func _input(event: InputEvent) -> void:
	if %SystemMenu:
		Global.ui_visible = %SystemMenu.isMenuOpen
	else:
		Global.ui_visible = false
	
	var coord = Vector2(Coords.get_coord(PlayerInput.mouse_position_in_world))

	if event is InputEventMouseMotion:
		PlayerInput.entities_under_cursor = actors.values().filter(
			func(entity): return entity.location and entity.location.position == coord
		)

	if event is InputEventMouseButton:
		var valid = Global.player and Global.player.can_see(coord)
		if valid:
			# print(PlayerInput.entities_under_cursor)
			if !event.double_click and event.pressed:
				if PlayerInput.entities_under_cursor.size() > 0:
					Global.player.current_target = PlayerInput.entities_under_cursor[0].uuid
				else:
					Global.player.set_target_position(Coords.get_coord(PlayerInput.mouse_position_in_world))

			if event.double_click:
				_on_double_click_tile(coord)

func _unhandled_input(event) -> void:
	pass
	"""
	if event.is_released():
		Global.player.clear_path()
		Global.player.clear_targeting()
	"""


func _on_double_click_tile(coord: Vector2i):
	_act()

func _act():
	var entity = next_actor
	# Is player...
	if next_actor and next_actor.uuid == Global.player.uuid:
		_check_path(entity)
		var target = Global.ecs.entity(entity.current_target)
		var result = await _trigger_action(entity, target)
		if result and result.success:
			next_actor.energy -= result.cost_energy
			next_actor = null


func _check_path(entity: Entity):
	entity.current_path = PlayerInput._get_path(
		entity.location.position,
		entity.target_position()
	).slice(1)
		
func _trigger_action(entity: Entity, target: Entity):
	var act_range = 1 if (target and target.blueprint.equipment) else 0
	if entity.current_path.size() > act_range:
		var result = await _perform_action(
			MovementAction.new(
				entity.current_path[0] - entity.location.position
			),
			entity,
			false
		)
		if result.success:
			entity.current_path = entity.current_path.slice(1)
		else:
			entity.clear_path()
			entity.clear_targeting()
		return result
	else:
		if target:
			var result = await _perform_action(
				entity.act_on(target),
				entity
			)
			entity.clear_path()
			entity.clear_targeting()

	return null
	
	
func _perform_action(action: Action, _entity: Entity, allow_recursion := true):
	var result = await action.perform(_entity)
	if !result.success and result.alternate:
		if allow_recursion:
			return await _perform_action(result.alternate, _entity)
	_entity.action_performed.emit(action, result)
	return result

func _on_ui_action(action):
	action.perform(Global.player)
	

func _init_map(_map):
	print('Switched to map ', _map)

	if map != _map:
		map = _map

	Global.maps_loaded[_map] = true
	actors = {}
	
	var entities = Global.ecs.entities.values().filter(
		func(entity):
			if !entity.location: return false
			return entity.location.map == _map
	)
	
	for entity in entities:
		actors[entity.uuid] = entity
