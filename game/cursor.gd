extends Node2D

var _path := []
var path: Array:
	get:
		return _path
	set(value):
		_path = value
		_set_path()
	
func _ready() -> void:
	PlayerInput.cursor = self

func _process(delta) -> void:
	$Sprite2D.position = $Sprite2D.position.lerp(PlayerInput.mouse_position_in_world, delta * 80)

func _set_path():
	# Draw path
	%Path.draw(path, $Sprite2D.modulate)
	
