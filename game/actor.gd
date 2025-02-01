class_name Actor
extends Node2D

var entity: Entity:
	get: return Global.ecs.entity(_entityId)
	set(value): self._load(value.uuid)

var _entityId: int

var blueprint: Blueprint:
	get: return entity.blueprint if entity else null

var glyph: Glyph:
	get: return blueprint.glyph if blueprint else null
	
var animation: AnimationSequence = null


signal destroyed

const STEP_LENGTH = 0.15


func _ready() -> void:
	# snap to grid
	position = Coords.get_position(
		Coords.get_coord(position),
		-%Sprite2D.offset + Vector2(0, 8)
	)
	if blueprint and blueprint.equipment:
		z_index = 1


func _process(delta: float) -> void:
	if entity:
		if !entity.location:
			destroyed.emit()
			queue_free()
		else:
			position = lerp(
				position,
				Coords.get_position(
					entity.location.position,
					-%Sprite2D.offset + Vector2(8, 8)
				),
				delta * STEP_LENGTH * 100.0
			)
	if glyph:
		modulate = modulate.lerp(glyph.fg, delta * STEP_LENGTH * 100)
	if animation and animation.progress >= animation.length:
		animation = null
	if animation:
		var state = animation.process(delta)
		if state and %Sprite2D:
			%Sprite2D.position = state.position
			%Sprite2D.scale = state.scale
	else:
		%Sprite2D.position = Vector2.ZERO
		%Sprite2D.scale = %Sprite2D.scale.lerp(Vector2.ONE, delta * STEP_LENGTH * 100)


func _on_action_performed(action: Action, result: ActionResult):
	if !result.success:
		return
	if action is MovementAction:
		animation = AnimationSequence.new(
			[
				{ 'position': Vector2.ZERO * 0.0, 'scale': Vector2(1, 1) },
				{ 'position': Vector2.UP * 5.0, 'scale': Vector2(1, 1) },
				{ 'position': Vector2.UP * 5.0, 'scale': Vector2(1, 1) },
				{ 'position': Vector2.ZERO * 0.0, 'scale': Vector2(1.2, 0.8) },
			],
			STEP_LENGTH
		)
	if action is UseAction:
		animation = AnimationSequence.new(
			[
				{ 'scale': Vector2(1, 1) },
				{ 'scale': Vector2(1.2, 0.8) },
			],
			STEP_LENGTH * 0.5
		)
	if action is UseAbilityAction:
		animation = AnimationSequence.new(
			[
				{ 'position': Vector2.ZERO * 0.0 },
				{ 'position': entity.location.position.direction_to(action.target.location.position) * 5.0 },
				{ 'position': Vector2.ZERO * 0.0 },
			],
			STEP_LENGTH * 0.5
		)
	pass


func _load(id: int):
	_entityId = id
	name = 'Entity<' + str(entity.uuid) + '>'
	if entity.location:
		position = Coords.get_position(
			entity.location.position,
			-%Sprite2D.offset + Vector2(8, 8)
		)
	if glyph:
		if %Sprite2D:
			%Sprite2D.set_texture(glyph.to_atlas_texture())
		modulate = glyph.fg
	entity.action_performed.connect(_on_action_performed)
	if entity.health:
		entity.health_changed.connect(
			func(amount):
				modulate = Color(1,0,0)
		)
	entity.on_death.connect(
		func():
			await get_tree().create_timer(0.1).timeout
			queue_free()
	)
