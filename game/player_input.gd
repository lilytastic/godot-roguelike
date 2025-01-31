extends Node

var dragging := {}
var entity_dragging: Entity:
	get:
		if PlayerInput.dragging.has('entity') and Global.ecs.entities.has(PlayerInput.dragging.entity):
			return Global.ecs.entity(PlayerInput.dragging.entity)
		return null

var cursor: Node2D = null
var mouse_position_in_world := Vector2i(0,0)

signal action_triggered
signal ui_action_triggered
signal double_click

func _input(event: InputEvent) -> void:
	var camera = get_viewport().get_camera_2d()
	if event is InputEventMouseMotion:
		if camera:
			var new_position = Coords.get_coord(camera.get_global_mouse_position()) * Vector2i(16, 16) + Vector2i(8, 8)
			if Global.player and new_position != mouse_position_in_world:
				var player_position = Global.player.location.position
				var coord = Coords.get_coord(new_position)
				if cursor:
					if Global.player.can_see(coord) and Global.navigation_map.has_point(Global.map_view.get_astar_pos(coord.x, coord.y)):
						var path = Global.navigation_map.get_point_path(
							Global.map_view.get_astar_pos(player_position.x, player_position.y),
							Global.map_view.get_astar_pos(coord.x, coord.y),
							true
						)
						cursor.path = path
					else:
						cursor.path = []
			mouse_position_in_world = new_position

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed('quicksave'):
		Global.quicksave()
		return
		
	var action := _check_for_action(event)
	if action:
		action_triggered.emit(action)

func _check_for_action(event: InputEvent) -> Action:
	for i: StringName in InputTag.MOVE_ACTIONS:
		if event.is_action_pressed(i):
			return MovementAction.new(_input_to_direction(i))

	if event.is_action_pressed('use'):
		if !Global.player:
			var entities = Global.ecs.find_by_location(Global.player.location).filter(
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
