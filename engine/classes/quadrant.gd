class_name Quadrant

var direction: Vector2
var position: Vector2

func _init(_direction, origin):
	direction = _direction
	position = origin

func transform(tile):
	var col = tile.x
	var row = tile.y
	if direction == Vector2.UP:
		return Vector2(position.x + col, position.y - row)
	if direction == Vector2.DOWN:
		return Vector2(position.x + col, position.y + row)
	if direction == Vector2.RIGHT:
		return Vector2(position.x + row, position.y + col)
	if direction == Vector2.LEFT:
		return Vector2(position.x - row, position.y + col)
