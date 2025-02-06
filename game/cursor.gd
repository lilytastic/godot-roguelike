extends Node2D

var _path := []
var path: Array:
	get:
		return _path
	set(value):
		_path = value
		_set_path()
		
var _mouse_moved: bool

	
func _ready() -> void:
	PlayerInput.cursor = self
	PlayerInput.action_triggered.connect(func(action):
		_mouse_moved = false
	)

func _process(delta) -> void:
	visible = !Global.ui_visible and Global.player and ECS.entities.has(Global.player.uuid)

	if Global.player.targeting.current_path:
		# path = Global.player.current_path
		%Path.start = 0
		%Path.end = 0
	else:
		%Path.start = 1
		%Path.end = 0
		
	%Path.visible = _check_path_visibility()
	
	var current_modulate = %Tracker.modulate
	
	var _current_target = Global.player.targeting.current_target if Global.player.targeting.current_target else PlayerInput.targeting.current_target
	var target = ECS.entity(_current_target)
	%Target.modulate = _get_color(target)
	
	if PlayerInput.entities_under_cursor.size() > 0:
		%Tracker.modulate = _get_color(PlayerInput.entities_under_cursor[0])
	else:
		%Tracker.modulate = _get_color(null)
		

	var tracker_position = PlayerInput.mouse_position_in_world
	%Tracker.position = %Tracker.position.lerp(
		tracker_position,
		delta * 80
	)
	
	var target_coords = Global.player.targeting.target_position()
	if target_coords.x == -1 and target_coords.y == -1:
		target_coords = PlayerInput.targeting.target_position()
	var target_position = Coords.get_position(target_coords) + Vector2(8, 8)
	%Target.visible = target_coords.x != -1 and target_coords.y != -1
	
	if target_position != Vector2(tracker_position):
		%Target.texture.set_region(Rect2(28 * 16, 14 * 16, 16, 16))
	else:
		%Target.texture.set_region(Rect2(31 * 16, 14 * 16, 16, 16))
	
	if target_position == Vector2(-1, -1):
		pass

	%Target.position = target_position
	# Handles the flashing
	# NOTE: Put thiis below the _set_path() call to stop path from flashing.
	if target:
		var sin = sin(Time.get_ticks_msec() / 70.0) * 0.25 + 0.25
		%Tracker.modulate = %Tracker.modulate.lerp(Color.WHITE, sin)
		%Target.modulate = %Target.modulate.lerp(Color.WHITE, sin)
			
	if %Tracker.modulate != current_modulate:
		_set_path()

	if Global.player and AIManager.can_see(Global.player, PlayerInput.mouse_position_in_world / 16):
		%Tracker.modulate = Color(%Tracker.modulate, 1)
	else:
		%Tracker.modulate = Color(%Tracker.modulate, 0.5)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and !Global.player.targeting.current_path:
		_mouse_moved = true


func _get_color(entity):
	if entity:
		if AIManager.is_hostile(entity, Global.player):
			return Color.CRIMSON
		if entity.blueprint.item:
			return Color.GREEN
	return Color.AQUA

func _set_path():
	# Draw path
	%Path.draw(path, %Target.modulate)
	
func _check_path_visibility():
	if !Global.player.targeting.has_target():
		return false
		
	if Global.player.targeting.current_path:
		return true
		
	if Global.ui_visible: # or !PlayerInput.mouse_in_window 
		return false

	if _mouse_moved:
		return true
	
	return true
