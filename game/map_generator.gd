extends TileMapLayer

var cells := []

func _ready():
	cells = get_used_cells()
	print(cells)
	for coord in cells:
		var atlas_coords = get_cell_atlas_coords(coord)
		if atlas_coords == Vector2i(13, 2):
			_add_digger(coord)


func _add_digger(coord: Vector2i):
	print('digger at ', coord)
	var alt = get_cell_alternative_tile(coord)


func _get_direction(coord: Vector2i):
	var vec = Vector2.RIGHT
	var alt = get_cell_alternative_tile(coord)
	if alt & TileSetAtlasSource.TRANSFORM_TRANSPOSE:
		vec = Vector2(vec.y, vec.x)
	if alt & TileSetAtlasSource.TRANSFORM_FLIP_H:
		vec.x *= -1
	if alt & TileSetAtlasSource.TRANSFORM_FLIP_V:
		vec.y *= -1
	vec = Vector2(-vec.y, vec.x)
	return vec
