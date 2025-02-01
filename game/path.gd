extends Node2D

var start = 1
var end = 0

func draw(path: Array, color := Color.WHITE) -> void:
	for child in get_children():
		child.free()
		
	if path.size() <= 2:
		visible = false
		return
		
	var length = path.slice(start, end).size() if end < 0 else path.slice(start).size() 
	for index in range(length):
		var point = path[index + start]
		var sprite = Sprite2D.new()
		add_child(sprite)
		sprite.position = point * 16 + Vector2(8, 8)
		var atlas = AtlasTexture.new()
		atlas.set_atlas(Glyph.tileset)
		var last_point = path[index - 1 + start]
		var next_index = index + 1 + start
		var next_point = path[next_index] if path.size() > next_index else Vector2.ZERO
		var coords = Vector2i(25, 13) # Vector2i(24, 12)
			
		sprite.rotation_degrees = _get_degrees(last_point, point, next_point)
		
		if path.size() > next_index and next_point.x != last_point.x and next_point.y != last_point.y:
			coords = Vector2i(28, 13)
					
		if index == 0:
			coords = Vector2i(26, 13)
			if point.x > next_point.x:
				sprite.rotation_degrees = 90
			if point.x < next_point.x:
				sprite.rotation_degrees = 270
			if point.y > next_point.y:
				sprite.rotation_degrees = 180
			if point.y < next_point.y:
				sprite.rotation_degrees = 0
			sprite.rotation_degrees += 180
			

		if path.size() > next_index and next_point.x != last_point.x and next_point.y != last_point.y:
			pass
		else:
			if path.size() == next_index:
				coords = Vector2i(24, 12)
				if last_point.x > point.x:
					sprite.rotation_degrees += 0
				if last_point.x < point.x:
					sprite.rotation_degrees += 270
				if last_point.y > point.y:
					sprite.rotation_degrees += 270
					
			

		atlas.set_region(Rect2(coords.x * 16, coords.y * 16, 16, 16))
		sprite.texture = atlas
		sprite.modulate = color
		


func _get_degrees(last_point, point, next_point):
	if next_point.x != last_point.x and next_point.y != last_point.y:
		# Going right
		if last_point.x < point.x:
			# Going right then down
			if point.y < next_point.y:
				return 90
			# Going right then up
			if point.y > next_point.y:
				return 180
		# Going left
		if last_point.x > point.x:
			# Going left then up
			if point.y < next_point.y:
				return 0
			# Going left then down
			if point.y > next_point.y:
				return 270
		# Going up
		if last_point.y > point.y:
			# Going up then right
			if point.x < next_point.x:
				return 0
			# Going up then left
			if point.x > next_point.x:
				return 90
		# Going down
		if last_point.y < point.y:
			# Going down then right
			if point.x < next_point.x:
				return 270
			# Going down then left
			if point.x > next_point.x:
				return 180
	else:
		if point.x > last_point.x:
			return 90
		if point.x < last_point.x:
			return 270
		if point.y > last_point.y:
			return 180
		if point.y < last_point.y:
			return 0
			
	return 0
