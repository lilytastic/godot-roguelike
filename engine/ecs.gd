class_name ECS

var entities: Dictionary = {}
var blueprints: Dictionary = {}

signal entity_added

func entity(id: int) -> Entity:
	if (entities.has(id)):
		return entities[id]
	return null

func add(_entity: Entity) -> int:
	entities[_entity.uuid] = _entity
	entity_added.emit(_entity)
	return _entity.uuid
	
func load_from_save(data: Dictionary) -> void:
	var opts = { 'uuid': data.uuid, 'blueprint': data.blueprint }
	var entity = Entity.new(opts)
	print('data: ', data)
	var _pos = str(data.position).trim_prefix('(').trim_suffix(')').split(', ')
	entity.location = Location.new(
		data.map,
		Vector2(int(_pos[0]), int(_pos[1]))
	)
	var new_id = add(entity)
	print('created ', entity.location.position)
	
func clear() -> void:
	entities.clear()

func create(opts: Dictionary) -> Entity:
	var new_entity = Entity.new(opts)
	var new_id = add(new_entity)
	# print(new_id, entity(new_id))
	return entity(new_id)

func load_data() -> void:
	var resources = Files.get_all_files('res://data')
	var preprocess: Dictionary
	
	for resource in resources:
		print(resource)
		var data = Files.get_dictionary(resource)
		if data.has('blueprints'):
			var _blueprints = data.blueprints
			for blueprint in _blueprints:
				if blueprint.has('id'):
					preprocess[blueprint.id] = Blueprint.new(blueprint)

	for blueprint in preprocess:
		var current = preprocess[blueprint]
		var curr = preprocess[blueprint]
		while curr.parent:
			if !preprocess.has(curr.parent):
				break
			curr = preprocess[curr.parent]
			current.concat(curr)
		
	blueprints = preprocess
	print(blueprints.values().size(), " records loaded")
	
