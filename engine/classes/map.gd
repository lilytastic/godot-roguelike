class_name Map

const uuid_util = preload('res://addons/uuid/uuid.gd')

var uuid := ''
var name := ''
var tile_pattern := []
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
	tile_pattern = data.get('tile_pattern', [])


static func load_from_data(data: Dictionary) -> Map:
	print('load map from data: ', data)
	return Map.new(data.name, data)
