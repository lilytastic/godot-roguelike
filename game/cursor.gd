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
	
func _ready() -> void:
	PlayerInput.cursor = self

func _process(delta) -> void:
	$Sprite2D.position = $Sprite2D.position.lerp(PlayerInput.mouse_position_in_world, delta * 80)
	if Global.player and Global.player.can_see(PlayerInput.mouse_position_in_world / 16):
		$Sprite2D.modulate = Color($Sprite2D.modulate, 1)
	else:
		$Sprite2D.modulate = Color($Sprite2D.modulate, 0.5)

func _set_path():
	# Draw path
	%Path.draw(path, $Sprite2D.modulate)
	
