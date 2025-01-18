class_name ECS

static var entities: Dictionary = {}
static var blueprints: Dictionary = {}

static func entity(id: int) -> Entity:
	if (entities.has(id)):
		return entities[id]
	return null

static func add(_entity: Entity) -> int:
	entities[_entity.uuid] = _entity
	return _entity.uuid

static func create(opts: EntityCreationOptions):
	var actor: PackedScene = preload("res://game/actor.tscn")
	var new_actor = actor.instantiate()

	var new_entity = Entity.new(opts)
	var new_id = ECS.add(new_entity)
	print(new_id, ECS.entity(new_id))
	new_actor.load(new_id)
	return new_actor

static func load_data() -> void:
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
	
