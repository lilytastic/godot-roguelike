extends Node

const PC_TAG = 'PC'
var player: Sprite2D

func _ready() -> void:
	RenderingServer.set_default_clear_color(Palette.PALETTE.BACKGROUND)
	ECS.load_data()

	_create_pc()


func _unhandled_input(event: InputEvent) -> void:
	for i: StringName in InputTag.MOVE_ACTIONS:
		if event.is_action_pressed(i):
			_move_pc(i)


func _create_pc() -> void:
	var options = EntityCreationOptions.new()
	options.blueprint = 'hero'
	player = ECS.create(options)
	var new_position: Vector2i = Vector2i(0, 0)
	player.position = Coords.get_position(new_position)
	player.add_to_group(PC_TAG)
	add_child(player)


func _move_pc(direction: StringName) -> void:
	var coord: Vector2i = Coords.get_coord(player)
	
	match direction:
		InputTag.MOVE_LEFT:
			coord += Vector2i.LEFT
		InputTag.MOVE_RIGHT:
			coord += Vector2i.RIGHT
		InputTag.MOVE_UP:
			coord += Vector2i.UP
		InputTag.MOVE_DOWN:
			coord += Vector2i.DOWN

	player.position = Coords.get_position(coord)
