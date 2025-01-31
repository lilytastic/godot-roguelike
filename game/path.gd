extends Node2D

func draw(path: Array) -> void:
	for child in get_children():
		child.free()
		
	for index in range(path.slice(1, -1).size()):
		var point = path[index + 1]
		var sprite = Sprite2D.new()
		add_child(sprite)
		sprite.position = point * 16 + Vector2(8, 8)
		var atlas = AtlasTexture.new()
		atlas.set_atlas(Glyph.tileset)
		var coords = Vector2i(25, 13) # Vector2i(24, 12)
		var last_point = path[index]
		var next_point = path[index + 2]
		if next_point.x != last_point.x and next_point.y != last_point.y:
			coords = Vector2i(28, 13)
			# Going right
			if last_point.x < point.x:
				# Going right then down
				if point.y < next_point.y:
					sprite.rotation_degrees = 90
				# Going right then up
				if point.y > next_point.y:
					sprite.rotation_degrees = 180
			# Going left
			if last_point.x > point.x:
				# Going left then up
				if point.y < next_point.y:
					sprite.rotation_degrees = 0
				# Going left then down
				if point.y > next_point.y:
					sprite.rotation_degrees = 270
			# Going up
			if last_point.y > point.y:
				# Going up then right?
				if point.x < next_point.x:
					sprite.rotation_degrees = 0
				# Going up then left?
				if point.x > next_point.x:
					sprite.rotation_degrees = 90
			# Going down
			if last_point.y < point.y:
				# Going down then right
				if point.x < next_point.x:
					sprite.rotation_degrees = 270
				# Going down then left
				if point.x > next_point.x:
					sprite.rotation_degrees = 180
		else:
			if point.x > last_point.x:
				sprite.rotation_degrees = 90
			if point.x < last_point.x:
				sprite.rotation_degrees = 270
			if point.y > last_point.y:
				sprite.rotation_degrees = 180
			if point.y < last_point.y:
				sprite.rotation_degrees = 0

		atlas.set_region(Rect2(coords.x * 16, coords.y * 16, 16, 16))
		sprite.texture = atlas
