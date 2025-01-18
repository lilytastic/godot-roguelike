class_name Entity

var uuid: int = ResourceUID.create_id()
var _blueprint: String
var position: Vector2i


var blueprint: Blueprint:
	get: return ECS.blueprints.get(_blueprint, null)
	set(value): _blueprint = value.id


func _init(opts: EntityCreationOptions):
	print('Initializing entity with template: ', opts.blueprint)
	_blueprint = opts.blueprint
	return

func save() -> Dictionary:
	var dict := {}
	dict.blueprint = _blueprint
	dict.position = position
	dict.uuid = uuid
	return dict
