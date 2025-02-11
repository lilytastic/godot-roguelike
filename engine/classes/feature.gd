class_name Feature

var cells := []
var exits := []

var rect: Rect2i

var faces = {
	Vector2i.RIGHT: [],
	Vector2i.DOWN: [],
	Vector2i.LEFT: [],
	Vector2i.UP: [],
}

func update_faces():
	for direction in Global.directions:
		faces[direction] = get_faces(direction)

func get_random_face(_direction := Vector2i(0,0)):
	if _direction == Vector2i(0,0):
		_direction = Global.directions.pick_random()
	if faces[_direction].size() == 0:
		return null
	return faces[_direction].pick_random()

func set_cells(_cells: Array):
	cells = _cells
	
	if cells.size() == 0:
		update_faces()
		return
	
	var min_x = cells.map(func(c): return c.x).min()
	var max_x = cells.map(func(c): return c.x).max()
	var min_y = cells.map(func(c): return c.y).min()
	var max_y = cells.map(func(c): return c.y).max()
	rect = Rect2(
		min_x,
		min_y,
		(max_x - min_x) + 1,
		(max_y - min_y) + 1
	)
	
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
