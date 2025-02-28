extends Node

const PC_TAG = 'PC'
var player: Entity:
	get: return Global.player
var camera_speed := 2.0

@export var map_name = ''


func _ready() -> void:
	if !Global.player:
		await Global.new_game()
		# Global.autosave()

	if Global.player.location:
		$Camera2D.position = Coords.get_position(
			Global.player.location.position
		)
		
	if %BlackOverlay:
		%BlackOverlay.modulate = Color(Palette.PALETTE.BACKGROUND, 1.0)


func _process(delta):
	_update_camera(delta)
	
	PlayerInput._update_mouse_position()
	
	if PlayerInput.cursor and Global.player:
		PlayerInput.cursor.path = Global.player.targeting.current_path
		
	if player.targeting.path_needs_updating():
		var path_result = Pathfinding.try_path_to(
			player.location.position,
			player.targeting.target_position()
		)
		if path_result.success:
			Global.player.targeting.current_path = path_result.path


func _input(event: InputEvent) -> void:
	if %UIManager:
		Global.ui_visible = %UIManager.is_menu_open
	else:
		Global.ui_visible = false
	
	var camera = get_viewport().get_camera_2d()
	if event.is_action_pressed('zoom_out'):
		if camera.zoom.x > 1:
			camera.zoom -= Vector2.ONE
	if event.is_action_pressed('zoom_in'):
		if camera.zoom.x < 3:
			camera.zoom += Vector2.ONE


func _update_camera(delta):
	if player and player.location != null:
		var _camera_position = Coords.get_position(player.location.position)
		var _desired_camera_speed = 2.0
		
		var _averaged = Vector2.ZERO
		if player.visible_tiles.keys().size() > 0:
			for tile in player.visible_tiles.keys():
				_averaged += Vector2(tile)
			_averaged /= player.visible_tiles.keys().size()
		# _camera_position = _averaged * 16
		
		_camera_position = Coords.get_position(player.location.position + PlayerInput.camera_offset).lerp(_averaged * 16, 0.5)
		"""
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
		"""
		
		var camera = get_viewport().get_camera_2d()
		var camera_shake = PlayerInput.camera_shake / camera.zoom.length()
		camera_speed = lerp(camera_speed, _desired_camera_speed, delta)
		var randomized = Vector2(randf_range(-camera_shake.length(), camera_shake.length()), randf_range(-camera_shake.length(), camera_shake.length()))
		$Camera2D.position = lerp(
			$Camera2D.position,
			_camera_position,
			delta * camera_speed
		) + (camera_shake + randomized)

	$Camera2D.offset = Vector2i(8 + 16 * 0, 8)

	if %BlackOverlay:
		%BlackOverlay.modulate = Color(Palette.PALETTE.BACKGROUND, PlayerInput.overlay_opacity)
