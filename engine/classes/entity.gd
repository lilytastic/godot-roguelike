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
var location: Location
var inventory: InventoryProps

signal map_changed

var map: String:
		get: return location.map if location else ''
		set(value):
			if !location:
				location = Location.new()
			location.map = value
			map_changed.emit(location.map)

var position: Vector2:
		get:
			if location:
				return location.position
			return Vector2(0,0)
		set(value):
			if !location:
				location = Location.new()
			location.position = value


func _init(opts: Dictionary):
	print('Initializing entity with template: ', opts.blueprint)
	_blueprint = opts.blueprint
	uuid = opts.uuid if opts.has('uuid') else ResourceUID.create_id()
	
	return


func save() -> Dictionary:
	var dict := {}
	dict.blueprint = _blueprint
	if location:
		dict.map = location.map
		dict.position = location.position
	dict.uuid = uuid
	if inventory:
		print(inventory)
		dict.inventory = inventory.save()
	print('saving ', dict)
	return dict


func load_from_save(data: Dictionary) -> void:
	print('data: ', data)
	
	if data.has('position'):
		var _pos = str(data.position).trim_prefix('(').trim_suffix(')').split(', ')
		location = Location.new(
			data.map,
			Vector2(int(_pos[0]), int(_pos[1]))
		)
		print('location: ', location.position)
		map_changed.emit(location.map)

	var new_id = Global.ecs.add(self)
	var json = JSON.new()

	if data.has('inventory'):
		inventory = InventoryProps.new(data)
	
	
