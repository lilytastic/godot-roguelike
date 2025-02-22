extends Node

var dragging := {}
var entity_dragging: Entity:
	get:
		if PlayerInput.dragging.has('entity') and ECS.entities.has(PlayerInput.dragging.entity):
			return ECS.entity(PlayerInput.dragging.entity)
		return null
var entities_under_cursor := []

var cursor: Node2D = null
var mouse_position_in_world := Vector2i(0,0)

var mouse_in_window = true
var targeting = Targeting.new()

var overlay_opacity := 0.00
var camera_shake := Vector2(0,0)

signal action_triggered
signal ui_action_triggered
signal double_click

func _process(delta) -> void:
	_update_cursor()
	
	camera_shake = camera_shake.lerp(Vector2.ZERO, delta * 20)
	
	var desired_opacity = 0.0 if !MapManager.is_switching else 1.0
	overlay_opacity = lerp(overlay_opacity, desired_opacity, delta * 3.0)
	
	if Global.player and Global.player.location:
		var _target_position = targeting.target_position()
		if Global.player.location.position.x == _target_position.x and Global.player.location.position.y == _target_position.y:
			targeting.clear_targeting()


func _input(event: InputEvent) -> void:
	if Global.ui_visible or MapManager.is_switching or overlay_opacity > 0.2:
		return
	
	if event is InputEventMouseMotion:
		_update_mouse_position()
		
	var player_is_valid = Global.player and ECS.entities.has(Global.player.uuid)
	if !player_is_valid:
		return

	var coord = Vector2i(Coords.get_coord(mouse_position_in_world))
	if event is InputEventMouseButton:
		var valid = player_is_valid and AgentManager.can_see(Global.player, coord)
		if valid:
			if event.button_index != 1:
				targeting.clear()
				Global.player.targeting.clear()
				return

		var _targeting = targeting
		if event.double_click:
			_targeting = Global.player.targeting
		
		if event.is_pressed():
			print('collisions in line: ', MapManager.get_collisions_line(
				Global.player.location.position,
				Coords.get_coord(mouse_position_in_world)
			))
			var _coord = Coords.get_coord(mouse_position_in_world)
			if Vector2i(_targeting.target_position()) == _coord:
				_targeting.clear_targeting()
			else:
				_targeting.set_target_position(_coord)

			if entities_under_cursor.size() > 0 and entities_under_cursor[0].uuid != Global.player.uuid:
				_targeting.current_target = entities_under_cursor[0].uuid

func _unhandled_input(event: InputEvent) -> void:
	if MapManager.is_switching or overlay_opacity > 0.25:
		return

	if event.is_pressed() and Global.player:
		# targeting.clear()
		Global.player.targeting.clear()
		
	if event.is_action_pressed('quicksave'):
		Global.quicksave()
		return
		
	var action := _check_for_action(event)
	if action:
		# targeting.clear()
		action_triggered.emit(action)
		if Scheduler.player_can_act:
			await AgentManager.perform_action(Global.player, action)


func _notification(event):
	match event:
		NOTIFICATION_WM_MOUSE_EXIT:
			mouse_in_window = false
		NOTIFICATION_WM_MOUSE_ENTER:
			mouse_in_window = true

func _update_mouse_position() -> void:
	var camera = get_viewport().get_camera_2d()

	if Global.player and Global.player.targeting.current_path.size() > 0:
		cursor.path = Global.player.targeting.current_path
		# return

	if !camera:
		return

	var player = Global.player
	var new_position = Coords.get_coord(camera.get_global_mouse_position()) * Vector2i(16, 16) + Vector2i(8, 8)
	mouse_position_in_world = new_position

func _check_for_action(event: InputEvent) -> Action:
	for i: StringName in InputTag.MOVE_ACTIONS:
		if event.is_action(i) and (event.is_pressed() or event.is_echo()):
			return MovementAction.new(_input_to_direction(i), !event.is_echo())

	if event.is_action_released('use'):
		if Global.player:
			var entities = ECS.find_by_location(Global.player.location).filter(
				func(entity): return entity.uuid != Global.player.uuid
			)
			if entities.size() > 0:
				return UseAction.new(entities[0])

	return null

func _input_to_direction(direction: StringName):
	var coord: Vector2i = Vector2i.ZERO
	
	match direction:
		InputTag.MOVE_LEFT:
			coord += Vector2i.LEFT
		InputTag.MOVE_RIGHT:
			coord += Vector2i.RIGHT
		InputTag.MOVE_UP:
			coord += Vector2i.UP
		InputTag.MOVE_DOWN:
			coord += Vector2i.DOWN

	return coord

func _update_cursor() -> void:
	var coord = Vector2(Coords.get_coord(mouse_position_in_world))
	entities_under_cursor = MapManager.actors.values().filter(
		func(entity): return entity.location and entity.location.position == coord
	)

func _on_double_click_tile(coord: Vector2i):
	if Scheduler.player_can_act:
		_act(Scheduler.next_actor)

func _act(entity: Entity) -> void:
	var path_result = Pathfinding.try_path_to(
		entity.location.position,
		entity.targeting.target_position()
	)
	if path_result.success:
		entity.targeting.current_path = path_result.path

	var target = ECS.entity(entity.targeting.current_target)
	if target:
		var default_action = AgentManager.get_default_action(entity, target)
		if AgentManager.is_within_range(entity, target, default_action):
			await AgentManager.perform_action(entity, default_action)
			return

	await AgentManager.try_close_distance(Scheduler.next_actor, entity.targeting.target_position())

func _on_ui_action(action):
	action.perform(Global.player)
	
