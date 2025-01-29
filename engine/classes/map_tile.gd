class_name MapTile

static var fast_noise_lite = FastNoiseLite.new();

static func generate_tile(tile: Vector2i, tile_map: TileMapLayer) -> Sprite2D:
	var spr = Sprite2D.new()
	spr.position = Coords.get_position(tile) + Vector2(8, 8)
	var atlas = AtlasTexture.new()
	atlas.set_atlas(Glyph.tileset)
	var coords = tile_map.get_cell_atlas_coords(tile)
	atlas.set_region(Rect2(coords.x * 16, coords.y * 16, 16, 16))
	spr.texture = atlas
	spr.z_index = -1
	var _noise = fast_noise_lite.get_noise_2d(tile.x * 20, tile.y * 20)
	var col = Color(_noise, _noise, _noise) / 8
	spr.modulate = tile_map.get_cell_tile_data(tile).modulate + col
	spr.name = str(tile)
	return spr
