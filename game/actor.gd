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


signal destroyed



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
				delta * Global.STEP_LENGTH * 100.0
			)
		
	if entity and entity.animation and entity.animation.progress >= entity.animation.length:
		entity.animation = null
	if entity and entity.animation:
		var state = entity.animation.process(entity, delta)
		if state and %Sprite2D:
			%Sprite2D.position = state.position
			%Sprite2D.scale = state.scale
			modulate = state.color
	else:
		%Sprite2D.position = Vector2.ZERO
		%Sprite2D.scale = %Sprite2D.scale.lerp(Vector2.ONE, delta * Global.STEP_LENGTH * 100.0)
		if glyph:
			modulate = modulate.lerp(glyph.fg, delta * Global.STEP_LENGTH * 100.0)


func _on_action_performed(action: Action, result: ActionResult):
	if !result.success:
		return
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
				if entity and !entity.animation:
					modulate = Color(1,0,0)
		)
	entity.on_death.connect(
		func():
			await get_tree().create_timer(0.1).timeout
			queue_free()
	)
