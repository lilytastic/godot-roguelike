class_name Map

const uuid_util = preload('res://addons/uuid/uuid.gd')

var uuid := ''
var name := ''
var tile_pattern

func _init(_map_name: String, data := {}) -> void:
	if data.has('uuid'):
		uuid = data.uuid
	else:
		uuid = uuid_util.v4()
	name = _map_name
	tile_pattern = data.tile_pattern if data.has('tile_pattern') else null

static func load_from_data(data: Dictionary) -> Map:
	print('load map from data: ', data)
	return Map.new(data.name, data)
