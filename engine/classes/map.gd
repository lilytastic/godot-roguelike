class_name Map

var uuid := -1
var name := ''

func _init(_map_name: String, _id := -1) -> void:
	print('init: ', _id)
	if _id != -1:
		uuid = _id
	else:
		uuid = ResourceUID.create_id()
	name = _map_name

static func load_from_data(data: Dictionary) -> Map:
	print('load_from_data ', data)
	return Map.new(data.name, int(data.uuid))
