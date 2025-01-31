extends Sprite2D
	
func _process(delta) -> void:
	position = position.lerp(PlayerInput.mouse_position_in_world, delta * 60)
