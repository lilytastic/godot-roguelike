extends Node

const PC_TAG = 'PC'


func _ready() -> void:
	RenderingServer.set_default_clear_color(Palette.PALETTE.BACKGROUND)
	var options = EntityCreationOptions.new()
	options.blueprint = 'hero'
	var new_id = ECS.add(Entity.new(options))
	print(new_id, ECS.entity(new_id))
	var resources = get_all_files('res://data')
	var dict: Dictionary
	for resource in resources:
		print(resource)
		var file_access = FileAccess.open(resource, FileAccess.READ)
		var file = JSON.parse_string(file_access.get_as_text())
		file_access.close()
		var data = file.data if file.has('data') else {}
		if data.has('blueprints'):
			var blueprints = data.blueprints
			for blueprint in blueprints:
				dict[blueprint.get("id")] = Blueprint.new(blueprint)
	print(dict.values().size(), " records loaded")
	_create_pc()
	

func _unhandled_input(event: InputEvent) -> void:
	for i: StringName in InputTag.MOVE_ACTIONS:
		if event.is_action_pressed(i):
			_move_pc(i)


func _create_pc() -> void:
	var pc: PackedScene = preload("res://game/player.tscn")
	var new_pc: Node2D
	var new_position: Vector2i = Vector2i(0, 0)
	
	new_pc = pc.instantiate()
	new_pc.position = Coords.get_position(new_position)
	new_pc.add_to_group(PC_TAG)
	new_pc.modulate = Palette.PALETTE["GREEN"]
	add_child(new_pc)


func _move_pc(direction: StringName) -> void:
	var pc: Node2D = get_tree().get_first_node_in_group(PC_TAG)
	var coord: Vector2i = Coords.get_coord(pc)
	
	match direction:
		InputTag.MOVE_LEFT:
			coord += Vector2i.LEFT
		InputTag.MOVE_RIGHT:
			coord += Vector2i.RIGHT
		InputTag.MOVE_UP:
			coord += Vector2i.UP
		InputTag.MOVE_DOWN:
			coord += Vector2i.DOWN

	pc.position = Coords.get_position(coord)


## returns list of files at given path recursively
## [br]taken from - https://gist.github.com/hiulit/772b8784436898fd7f942750ad99e33e
static func get_all_files(path: String, file_ext := "", files : Array[String] = []) -> Array[String]:
	var dir : = DirAccess.open(path)
	if file_ext.begins_with("."): # get rid of starting dot if we used, for example ".tscn" instead of "tscn"
		file_ext = file_ext.substr(1,file_ext.length()-1)
	
	if DirAccess.get_open_error() == OK:
		dir.list_dir_begin()

		var file_name = dir.get_next()

		while file_name != "":
			if dir.current_is_dir():
				# recursion
				files = get_all_files(dir.get_current_dir() +"/"+ file_name, file_ext, files)
			else:
				if file_ext and file_name.get_extension() != file_ext:
					file_name = dir.get_next()
					continue
				
				files.append(dir.get_current_dir() +"/"+ file_name)

			file_name = dir.get_next()
	else:
		print("[get_all_files()] An error occurred when trying to access %s." % path)
	return files
