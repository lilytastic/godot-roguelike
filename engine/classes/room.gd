class_name Room

var cells := []
var exits = {
	Vector2i.RIGHT: [],
	Vector2i.DOWN: [],
	Vector2i.LEFT: [],
	Vector2i.UP: [],
}

var faces = {
	Vector2i.RIGHT: [],
	Vector2i.DOWN: [],
	Vector2i.LEFT: [],
	Vector2i.UP: [],
}

func update_faces():
	for direction in [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]:
		faces[direction] = _get_faces(direction)

func _get_faces(direction: Vector2i):
	var _faces := []
	for cell in cells:
		# TODO: Ensure there's no tiles between this cell and the edge
		if cells.find(cell + direction) == -1:
			_faces.append(cell + direction)
	return _faces
