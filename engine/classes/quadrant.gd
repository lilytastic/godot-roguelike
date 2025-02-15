class_name Quadrant

var direction: Vector2i
var origin: Vector2i

func _init(_direction, _origin):
	direction = _direction
	origin = _origin

func transform(tile):
	var col = tile.col
	var row = tile.depth
	if direction == Vector2i.UP:
		return Vector2i(origin.x + col, origin.y - row)
	if direction == Vector2i.DOWN:
		return Vector2i(origin.x + col, origin.y + row)
	if direction == Vector2i.RIGHT:
		return Vector2i(origin.x + row, origin.y + col)
	if direction == Vector2i.LEFT:
		return Vector2i(origin.x - row, origin.y + col)
