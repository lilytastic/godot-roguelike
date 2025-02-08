class_name Map

const uuid_util = preload('res://addons/uuid/uuid.gd')

var uuid := ''
var name := ''
var tiles := {}
var size := Vector2(0,0)
var neighbours := [] # TODO: Neighbouring cells, particularly for exteriors.
var _default_tile = null
var default_tile:
	get:
		if _default_tile:
			return _default_tile
		# TODO: If exterior, return soil. If interior, return void.
		return null


func _init(_map_name: String, data := {}) -> void:
	uuid = data.get('uuid',  uuid_util.v4())
	name = _map_name
	tiles = data.get('tiles', {})
	size = Global.string_to_vector(data.get('size', Vector2(0,0)))
	for key in tiles.keys():
		tiles[key] = tiles[key].reduce(
			func(accum, str):
				if str is Vector2i:
					return accum + [str]
				var vec = Vector2i(0,0)
				var coords = str.substr(1, str.length() - 2).split(',')
				if coords.size() < 2:
					return accum
				vec = Vector2i(int(coords[0]), int(coords[1]))
				return accum + [vec],
				[]
			)
	print('tiles: ', tiles)
	print('size: ', size)
	# TODO: Set default tile to the most frequent tile in the array
	_default_tile = data.get('default_tile', 'void')


static func load_from_data(data: Dictionary) -> Map:
	print('load map from data: ', data)
	return Map.new(data.name, data)
