class_name Ability

var id: String
var name: String
var is_active: bool
var effects: Array
var area: Dictionary
var icon: Dictionary


func _init(props: Dictionary):
	id = props.id
	name = props.get('name', '')
	is_active = props.get('isActive', false)
	effects = props.get('effects', [])
	area = props.get('area', {})
	icon = props.get('icon', {})

static func load_from_files(resources: Array) -> Dictionary:
	var preprocess: Dictionary
	
	for resource in resources:
		var data = Files.get_dictionary(resource)
		if data.has('abilities'):
			var _abilities = data.abilities
			for ability in _abilities:
				if ability.has('id'):
					preprocess[ability.id] = Ability.new(ability)

	"""
	for ability in preprocess:
		var current = preprocess[ability]
		var curr = preprocess[ability]
		while curr.parent:
			if !preprocess.has(curr.parent):
				break
			curr = preprocess[curr.parent]
			current.concat(curr)
	"""
	
	return preprocess
