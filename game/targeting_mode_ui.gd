extends Label

func _process(delta: float) -> void:
	visible = PlayerInput.awaiting_target
