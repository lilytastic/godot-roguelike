class_name Entity

var _uuid: int = 0
var uuid: int:
	get: return _uuid
	set(value):
		Global.ecs.entities.erase(_uuid)
		_uuid = value
var _blueprint: String
var blueprint: Blueprint:
	get: return Global.ecs.blueprints.get(_blueprint, null)
	set(value): _blueprint = value.id
var location := Location.new()
var inventory: InventoryProps

signal map_changed

var map: String:
		get: return location.map
		set(value):
			location.map = value
			map_changed.emit(location.map)

var position: Vector2:
		get: return location.position
		set(value):
			location.position = value


func _init(opts: Dictionary):
	print('Initializing entity with template: ', opts.blueprint)
	_blueprint = opts.blueprint
	uuid = opts.uuid if opts.has('uuid') else ResourceUID.create_id()
	
	return


func save() -> Dictionary:
	var dict := {}
	dict.blueprint = _blueprint
	dict.map = location.map
	dict.position = position
	dict.uuid = uuid
	if inventory:
		print(inventory)
		dict.inventory = inventory.save()
	print('saving ', dict)
	return dict

func load_from_save(data: Dictionary) -> void:
	print('data: ', data)
	var _pos = str(data.position).trim_prefix('(').trim_suffix(')').split(', ')
	location = Location.new(
		data.map,
		Vector2(int(_pos[0]), int(_pos[1]))
	)
	var new_id = Global.ecs.add(self)
	uuid = new_id
	var json = JSON.new()
	if data.has('inventory'):
		inventory = InventoryProps.new(data)
	
	
