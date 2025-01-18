class_name Entity

var uuid: int = ResourceUID.create_id()
var _blueprint: String

var blueprint: Blueprint:
	get:
		return ECS.blueprints.get(_blueprint, null)
	set(value):
		_blueprint = value.id

func _init(opts: EntityCreationOptions):
	print(opts.blueprint)
	_blueprint = opts.blueprint
	return
