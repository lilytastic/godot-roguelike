class_name Digger

static func add(coord: Vector2i, direction: Vector2i, size: int, dig: Callable):
	var digger_coord = coord
	
	dig.call(coord)
	
	var directions = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]

	var time_since_direction_change = 0
	var time_since_size_change = 0

	for i in range(12):
		for x in range(size):
			for y in range(size):
				dig.call(digger_coord + Vector2i(x, y))
		digger_coord += direction
		
		if time_since_size_change > 4 and randi_range(0, 100) < 20:
			var mod = [-1, 1].pick_random()
			var new_size = max(1, size + mod)
			size = new_size
			
			time_since_size_change = 0
		else:
			time_since_size_change += 1
			
		if time_since_direction_change > (5 + size) and randi_range(0, 100) < 50:
			print('change direction')
			direction = directions.filter(
				func(vec):
					return vec != direction and vec != -direction
			).pick_random()
			time_since_direction_change = 0
		else:
			time_since_direction_change += 1
	
