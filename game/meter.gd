extends Panel

@export var value = 1.0
@export var max = 1
@export var label = ''

func _process(delta: float) -> void:
	var _scaled_value = float(value) / max * size.y
	%Fill.position = %Fill.position.lerp(Vector2(0, size.y - _scaled_value), delta * 30.0)
	%Fill.size = %Fill.size.lerp(Vector2(size.x, _scaled_value), delta * 30.0)
	%Label.text = '[center]' + label + '[/center]'
