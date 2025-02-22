extends Control

@export var value = 1.0
@export var max = 1
@export var label = ''
@export var color = Color.WHITE
@export var fill_direction := Vector2i.RIGHT

func _process(delta: float) -> void:
	if fill_direction == Vector2i.UP:
		var _scaled_value = float(value) / max * %Meter.size.y
		%Fill.position = %Fill.position.lerp(Vector2(0, size.y - _scaled_value), delta * 30.0)
		%Fill.size = %Fill.size.lerp(Vector2(%Fill.size.x, _scaled_value), delta * 30.0)
	if fill_direction == Vector2i.DOWN:
		var _scaled_value = float(value) / max * %Meter.size.y
		%Fill.size = %Fill.size.lerp(Vector2(%Fill.size.x, _scaled_value), delta * 30.0)
	if fill_direction == Vector2i.LEFT:
		var _scaled_value = float(value) / max * %Meter.size.x
		%Fill.position = %Fill.position.lerp(Vector2(_scaled_value - %Fill.size.x, 0), delta * 30.0)
		%Fill.size = %Fill.size.lerp(Vector2(_scaled_value, %Fill.size.y), delta * 30.0)
	if fill_direction == Vector2i.RIGHT:
		var _scaled_value = float(value) / max * %Meter.size.x
		%Fill.size = %Fill.size.lerp(Vector2(_scaled_value, %Fill.size.y), delta * 30.0)
	%Label.text = label
	modulate = color
