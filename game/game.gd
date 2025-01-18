extends Node

const PC_TAG = 'PC'
var player: Sprite2D
var cameraSpeed := 6


func _ready() -> void:
	RenderingServer.set_default_clear_color(Palette.PALETTE.BACKGROUND)
	ECS.load_data()

	_new_game()


func _process(delta: float) -> void:
	$Camera2D.position = lerp($Camera2D.position, player.position, delta * cameraSpeed)
	$Camera2D.offset = Vector2i(8, 8)
	

func _unhandled_input(event: InputEvent) -> void:
	for i: StringName in InputTag.MOVE_ACTIONS:
		if event.is_action_pressed(i):
			_move_pc(i)


func _new_game() -> void:
	var options = EntityCreationOptions.new()
	options.blueprint = 'hero'
	player = ECS.create(options)
	player.position = Coords.get_position(Vector2i(0, 0))
	add_child(player)
	save()
	

func save() -> void:
	var data = {}
	data.entities = ECS.entities.values().map(
		func(entity): return entity.save()
	)
	data.player = player._entityId
	Files.save(data)


func _move_pc(direction: StringName) -> void:
	var coord: Vector2i = player.entity.position
	
	match direction:
		InputTag.MOVE_LEFT:
			coord += Vector2i.LEFT
		InputTag.MOVE_RIGHT:
			coord += Vector2i.RIGHT
		InputTag.MOVE_UP:
			coord += Vector2i.UP
		InputTag.MOVE_DOWN:
			coord += Vector2i.DOWN

	player.entity.position = coord
