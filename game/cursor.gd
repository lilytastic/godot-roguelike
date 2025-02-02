extends Node2D

var _path := []
var path: Array:
	get:
		return _path
	set(value):
		_path = value
		_set_path()
		
var show_path: bool:
	set(value):
		%Path.visible = value
		
var _mouse_moved: bool

	
func _ready() -> void:
	PlayerInput.cursor = self
	PlayerInput.action_triggered.connect(func(action):
		_mouse_moved = false
	)

func _process(delta) -> void:
	if Global.player.current_path:
		# show_path = true
		# path = Global.player.current_path
		%Path.start = 0
		%Path.end = 0
	else:
		%Path.start = 1
		%Path.end = 0
		
	show_path = _check_path_visibility()
	
	var current_modulate = $Sprite2D.modulate
	
	var target = Global.ecs.entity(Global.player.current_target)
	if !target and PlayerInput.entities_under_cursor.size() > 0:
		target = PlayerInput.entities_under_cursor[0]
	$Sprite2D.modulate = _get_color(target)

	$Sprite2D.visible = !Global.ui_visible
	$Sprite2D.position = $Sprite2D.position.lerp(
		PlayerInput.mouse_position_in_world if (!target or !target.location) else Coords.get_position(target.location.position) + Vector2(8, 8),
		delta * 80
	)
	
	if $Sprite2D.modulate != current_modulate:
		_set_path()

	if Global.player and Global.player.can_see(PlayerInput.mouse_position_in_world / 16):
		$Sprite2D.modulate = Color($Sprite2D.modulate, 1)
	else:
		$Sprite2D.modulate = Color($Sprite2D.modulate, 0.5)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and !Global.player.current_path:
		_mouse_moved = true


func _get_color(entity):
	if entity:
		if entity.blueprint.equipment and entity.uuid != Global.player.uuid:
			return Color.RED
		if entity.blueprint.item:
			return Color.GREEN
	return Color.AQUA

func _set_path():
	# Draw path
	%Path.draw(path, $Sprite2D.modulate)
	
func _check_path_visibility():
	if Global.player.current_target != -1:
		return false
		
	if Global.player.current_path:
		return true
		
	if !PlayerInput.mouse_in_window or Global.ui_visible:
		return false

	if _mouse_moved:
		return true
	
	return false
