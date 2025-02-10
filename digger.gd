class_name Digger

var position: Vector2i
var direction: Vector2i
var directions = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
var dig: Callable
var can_dig: Callable
var corridor_width = 1
var layer: TileMapLayer
var life = 40

var cells := []

var time_since_direction_change = 0
var time_since_size_change = 0

func _init(coord: Vector2i, _direction: Vector2i, _corridor_width: int, _can_dig: Callable, _dig: Callable):
	direction = _direction
	corridor_width = _corridor_width
	dig = _dig
	can_dig = _can_dig
	position = coord

func step():
	var tiles_dug = 0

	var lookahead = 2
	for i in lookahead:
		for ii in range(3):
			var to_check = position + direction * (i + 1)
			if ii == 0:
				to_check += Vector2i.UP if direction.x != 0 else Vector2i.LEFT
			if ii == 2:
				to_check += Vector2i.DOWN if direction.x != 0 else Vector2i.RIGHT
			if can_dig.call(to_check) == false or cells.has(to_check):
				print('no dig ', position + direction * (i + 1))
				_change_direction()
				life -= 1
				return tiles_dug

	dig.call(position)
	cells.append(position)

	for x in range(corridor_width):
		for y in range(corridor_width):
			pass
			# dig.call(position + Vector2i(x, y))
			# cells.append(position  + Vector2i(x, y))
			# tiles_dug += 1

	life -= 1
	
	position += direction
	
	time_since_direction_change += 1
	time_since_size_change += 1
	
	var change_direction = time_since_direction_change > 9 and randi_range(0, 100) < 50

	if change_direction:
		_change_direction()

	return tiles_dug

func _change_direction():
	print('change direction')
	direction = directions.filter(
		func(vec):
			return vec != direction and vec != -direction
	).pick_random()
	time_since_direction_change = 0
	if time_since_size_change > 4 and randi_range(0, 100) < 40:
		var mod = [-1, 1].pick_random()
		corridor_width = max(1, corridor_width + mod)
		
		time_since_size_change = 0
