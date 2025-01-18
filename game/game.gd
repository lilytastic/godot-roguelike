extends Node

const PC_TAG = 'PC'


func _ready() -> void:
	RenderingServer.set_default_clear_color(Palette.PALETTE.BACKGROUND)
	var options = EntityCreationOptions.new()
	options.blueprint = 'hero'
	var new_id = ECS.add(Entity.new(options))
	print(new_id, ECS.entity(new_id))
	var resource = preload("res://data/creatures.json").data
	var blueprints = resource.data.blueprints
	var dict: Dictionary
	for blueprint in blueprints:
		dict[blueprint.get("id")] = Blueprint.new(blueprint)
	print(dict.values().size(), " records loaded")
	print(dict['hero'].glyph.ch)
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
