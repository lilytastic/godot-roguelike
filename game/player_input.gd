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

signal action_triggered
signal ui_action_triggered
signal double_click


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_update_mouse_position()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed('quicksave'):
		Global.quicksave()
		return
		
	var action := _check_for_action(event)
	if action:
		action_triggered.emit(action)

func try_path_to(start: Vector2, destination: Vector2) -> Dictionary:
	var rect = Global.map_view.get_used_rect()
	if destination.x < 0 or destination.x > rect.end.x - 1:
		return { 'success': false, 'path': [] }
		
	var navigation_map = Global.navigation_map
	if navigation_map.has_point(Global.map_view.get_astar_pos(start.x, start.y)) and Global.navigation_map.has_point(Global.map_view.get_astar_pos(destination.x, destination.y)):
		var start_point = Global.map_view.get_astar_pos(start.x, start.y)
		var destination_point = Global.map_view.get_astar_pos(destination.x, destination.y)
		var was_disabled = navigation_map.is_point_disabled(start_point)
		navigation_map.set_point_disabled(start_point, false)
		navigation_map.set_point_disabled(destination_point, false)
		var path = navigation_map.get_point_path(
			start_point,
			destination_point,
			true
		)
		navigation_map.set_point_disabled(start_point, was_disabled)
		if path.size() == 0:
			return { 'success': true, 'path': path }
		return { 'success': true, 'path': path }
	return { 'success': false, 'path': [] }

func _notification(event):
	match event:
		NOTIFICATION_WM_MOUSE_EXIT:
			mouse_in_window = false
		NOTIFICATION_WM_MOUSE_ENTER:
			mouse_in_window = true

func _update_mouse_position() -> void:
	var camera = get_viewport().get_camera_2d()

	if Global.player and Global.player.current_path.size() > 0:
		cursor.path = Global.player.current_path
		# return

	if !camera:
		return

	var player = Global.player
	var new_position = Coords.get_coord(camera.get_global_mouse_position()) * Vector2i(16, 16) + Vector2i(8, 8)
	if player and new_position != mouse_position_in_world and player.current_path.size() == 0:
		var player_position = player.location.position
		var coord = Coords.get_coord(new_position)
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

func update_cursor(actors: Dictionary) -> void:
	var coord = Vector2(Coords.get_coord(mouse_position_in_world))
	entities_under_cursor = actors.values().filter(
		func(entity): return entity.location and entity.location.position == coord
	)
