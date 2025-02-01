extends Node

const PC_TAG = 'PC'
var player: Entity:
	get: return Global.player
var cameraSpeed := 6

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
			var result = _perform_action(action, Global.player)
			if result.success:
				next_actor.energy -= result.cost_energy
				next_actor = null
	)	
	
	_init_map(map)
	

func _process(delta):
	if player and player.location != null:
		$Camera2D.position = lerp(
			$Camera2D.position,
			Coords.get_position(player.location.position),
			delta * cameraSpeed
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
		# print('next! ', next)
		next_actor = next
		if Global.player and next_actor.uuid == Global.player.uuid:
			# Player turn
			var result = _check_path(next_actor)
			if result:
				next_actor.energy -= result.cost_energy
				next_actor = null
		else:
			# AI turn
			var result = _perform_action(
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
	var coord = Coords.get_coord(PlayerInput.mouse_position_in_world)
	if Global.player and Global.player.can_see(coord) and event.is_released() and event is InputEventMouseButton:
		Global.player.current_path = PlayerInput._get_path(
			Global.player.location.position,
			coord
		).slice(1)
		if next_actor and next_actor.uuid == Global.player.uuid:
			# print(Global.player.current_path)
			var result = _check_path(Global.player)
			PlayerInput.cursor.show_path = false
			if result and result.success:
				next_actor.energy -= result.cost_energy
				next_actor = null

func _unhandled_input(event) -> void:
	if event.is_released():
		Global.player.current_path = []


func _check_path(entity: Entity):
	if entity.current_path.size() > 0:
		var result = _perform_action(
			MovementAction.new(
				entity.current_path[0] - entity.location.position
			),
			entity
		)
		if result.success:
			entity.current_path = entity.current_path.slice(1)
		else:
			entity.current_path.clear()
		return result
	return null
	
	
func _perform_action(action: Action, _entity: Entity):
	var result = action.perform(_entity)
	if !result.success and result.alternate:
		return _perform_action(result.alternate, _entity)
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
