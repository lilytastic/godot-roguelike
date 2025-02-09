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
		faces[direction] = get_faces(direction)

func set_cells(_cells: Array):
	cells = _cells
	update_faces()

func reposition(position: Vector2i):
	set_cells(cells.map(func(cell): return cell + position))
	# TODO: Exits! Don't forget exits!

func get_faces(direction: Vector2i):
	var _faces := []
	for cell in cells:
		# TODO: Ensure there's no tiles between this cell and the edge
		if cells.find(cell + direction) == -1:
			_faces.append(cell + direction)
	return _faces
