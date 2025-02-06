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

func _process(delta):
	MapManager.update_tiles()

	_update_camera(delta)

	PlayerInput._update_mouse_position()
	
	if PlayerInput.cursor and Global.player:
		PlayerInput.cursor.path = Global.player.targeting.current_path
		
	if player.targeting.path_needs_updating():
		var path_result = PlayerInput.try_path_to(
			player.location.position,
			player.targeting.target_position()
		)
		if path_result.success:
			Global.player.targeting.current_path = path_result.path

func _input(event: InputEvent) -> void:
	if %SystemMenu:
		Global.ui_visible = %SystemMenu.isMenuOpen
	else:
		Global.ui_visible = false

func _update_camera(delta):
	if player and player.location != null:
		var _camera_position = Coords.get_position(player.location.position)
		var _desired_camera_speed = 2.0
		var _target = ECS.entity(player.targeting.current_target)
		var _target_position = player.targeting.target_position()
		if player.targeting.current_path.size() > 0:
			_desired_camera_speed = 3.0
			_camera_position = _camera_position.lerp(
				Coords.get_position(
					player.targeting.current_path[floor(player.targeting.current_path.size() / 2)]
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
