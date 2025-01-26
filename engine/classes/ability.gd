class_name Ability

static func load_from_files(resources: Array) -> Dictionary:
	var preprocess: Dictionary
	
	for resource in resources:
		print(resource)
		var data = Files.get_dictionary(resource)
		if data.has('abilities'):
			var _abilities = data.abilities
			for ability in _abilities:
				if ability.has('id'):
					preprocess[ability.id] = Blueprint.new(ability)

	for ability in preprocess:
		var current = preprocess[ability]
		var curr = preprocess[ability]
		while curr.parent:
			if !preprocess.has(curr.parent):
				break
			curr = preprocess[curr.parent]
			current.concat(curr)
	
	return preprocess
