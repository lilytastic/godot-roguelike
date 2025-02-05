extends Node

const PC_TAG = 'PC'
var player: Entity:
	get: return Global.player
var camera_speed := 2.0

@export var map_name = ''

	
func _ready() -> void:
	if !Global.player:
		Global.new_game()
		# Global.autosave()

	if Global.player.location:
		$Camera2D.position = Coords.get_position(
			Global.player.location.position
		)
	
	# var map = Map.new(map_name)
	# MapManager.switch_map(map)
	

func _process(delta):
	MapManager.update_tiles()

	_update_camera(delta)

	PlayerInput._update_mouse_position()
	
	if PlayerInput.cursor and Global.player:
		PlayerInput.cursor.path = Global.player.current_path
		
	if player.path_needs_updating():
		var path_result = PlayerInput.try_path_to(
			player.location.position,
			player.target_position()
		)
		if path_result.success:
			Global.player.current_path = path_result.path

func _input(event: InputEvent) -> void:
	if %SystemMenu:
		Global.ui_visible = %SystemMenu.isMenuOpen
	else:
		Global.ui_visible = false
		
	if Global.ui_visible:
		return
	
	if !player:
		return

	var player_is_valid = Global.player and ECS.entities.has(Global.player.uuid)
	if player_is_valid:
		PlayerInput.update_cursor(MapManager.actors)

	if event is InputEventMouseButton:
		var coord = Vector2(Coords.get_coord(PlayerInput.mouse_position_in_world))
		var valid = player_is_valid and Global.player.can_see(coord)
		if valid:
			if event.button_index != 1:
				Global.player.clear_path()
				Global.player.clear_targeting()
				return
			if !event.double_click and event.pressed:
				if PlayerInput.entities_under_cursor.size() > 0:
					Global.player.current_target = PlayerInput.entities_under_cursor[0].uuid
				else:
					Global.player.set_target_position(Coords.get_coord(PlayerInput.mouse_position_in_world))

func _unhandled_input(event: InputEvent) -> void:
	if event.is_pressed():
		Global.player.clear_path()
		Global.player.clear_targeting()

func _update_camera(delta):
	if player and player.location != null:
		var _camera_position = Coords.get_position(player.location.position)
		var _desired_camera_speed = 2.0
		var _target = ECS.entity(player.current_target)
		var _target_position = player.target_position(false)
		if player.current_path.size() > 0:
			_desired_camera_speed = 3.0
			_camera_position = _camera_position.lerp(
				Coords.get_position(
					player.current_path[floor(player.current_path.size() / 2)]
				),
				0.5
			)
		camera_speed = lerp(camera_speed, _desired_camera_speed, delta)
		$Camera2D.position = lerp(
			$Camera2D.position,
			_camera_position,
			delta * camera_speed
		)

	$Camera2D.offset = Vector2i(8 + 16 * 0, 8)
