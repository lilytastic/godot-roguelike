class_name Map

const uuid_util = preload('res://addons/uuid/uuid.gd')

var uuid := ''
var name := ''
var tiles := {}
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
	# TODO: Set default tile to the most frequent tile in the array
	_default_tile = data.get('default_tile', 'void')


static func load_from_data(data: Dictionary) -> Map:
	print('load map from data: ', data)
	return Map.new(data.name, data)
