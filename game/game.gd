extends Node

const PC_TAG = 'PC'
var player: Entity
var cameraSpeed := 6


func _ready() -> void:
	RenderingServer.set_default_clear_color(Palette.PALETTE.BACKGROUND)
	Global.ecs.load_data()
	$TileMapLayer.map = 'Test'

	_new_game()


func _process(delta: float) -> void:
	if player.position != null:
		$Camera2D.position = lerp($Camera2D.position, Coords.get_position(player.position), delta * cameraSpeed)
	$Camera2D.offset = Vector2i(8 + 16 * 0, 8)
	

func _unhandled_input(event: InputEvent) -> void:
	for i: StringName in InputTag.MOVE_ACTIONS:
		if event.is_action_pressed(i):
			_move_pc(i)
			return
	
	if event.is_action_pressed('quicksave'):
		save()
		return

func _new_game() -> void:
	var options = EntityCreationOptions.new()
	options.blueprint = 'hero'
	player = Global.ecs.create(options)
	player.map = 'Test'
	# player.position = Coords.get_position(Vector2i(0, 0))
	save()
	

func save() -> void:
	var data = {}
	data.entities = Global.ecs.entities.values().map(
		func(entity): return entity.save()
	)
	data.player = player.uuid
	Files.save(data)


func _move_pc(direction: StringName) -> void:
	if !player:
		return

	var coord: Vector2i = player.position
	
	match direction:
		InputTag.MOVE_LEFT:
			coord += Vector2i.LEFT
		InputTag.MOVE_RIGHT:
			coord += Vector2i.RIGHT
		InputTag.MOVE_UP:
			coord += Vector2i.UP
		InputTag.MOVE_DOWN:
			coord += Vector2i.DOWN

	player.position = coord
