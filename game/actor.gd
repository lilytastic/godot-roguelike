class_name Actor
extends Node2D

var entity: Entity:
	get: return ECS.entity(_entityId)
	set(value): _entityId = value.uuid

var _entityId: String

var is_dying = false

var blueprint: Blueprint:
	get: return entity.blueprint if entity else null

var glyph: Glyph:
	get: return blueprint.glyph if blueprint else null


signal destroyed



func _init() -> void:
	position = Coords.get_position(
		Coords.get_coord(position),
		Vector2(8, 16)
	)
	if AIManager.blocks_entities(entity):
		z_index = 1
	if AIManager.can_act(entity):
		z_index = 2


func _process(delta: float) -> void:
	if !entity or is_dying:
		return

	if !entity.location:
		destroyed.emit()
		queue_free()
		return
		
	var _can_see = AIManager.can_see(Global.player, entity.location.position)
	var _known_position = Vector2(-1, -1)
	if _can_see:
		_known_position = entity.location.position
	if !_can_see and Global.player.known_entity_locations.has(entity.uuid):
		_known_position = Global.player.known_entity_locations[entity.uuid]

	if _known_position != Vector2(-1, -1):
		position = lerp(
			position,
			Coords.get_position(
				_known_position,
				-%Sprite2D.offset + Vector2(8, 8)
			),
			(delta * Global.STEP_LENGTH * 100.0) if _can_see else 1.0
		)

	if entity and entity.animation and entity.animation.progress >= entity.animation.length:
		entity.animation = null

	var color = glyph.fg
	if _can_see:
		if entity and entity.animation:
			var state = entity.animation.process(entity, delta)
			if state and %Sprite2D:
				%Sprite2D.position = state.position
				%Sprite2D.scale = state.scale
				color = state.color
		else:
			%Sprite2D.position = Vector2.ZERO
			%Sprite2D.scale = %Sprite2D.scale.lerp(Vector2.ONE, delta * Global.STEP_LENGTH * 100.0)
			if glyph:
				color = glyph.fg
	else:
		%Sprite2D.position = Vector2.ZERO
		%Sprite2D.scale = %Sprite2D.scale.lerp(Vector2.ONE, delta * Global.STEP_LENGTH * 100.0)
		if glyph:
			color = glyph.fg

	modulate = modulate.lerp(
		Color(color, 1.0 if _can_see else (0.3 if _known_position != Vector2(-1, -1) else 0.0)),
		delta * 10.0
	)

func _on_action_performed(action: Action, result: ActionResult):
	if !result.success:
		return


func _load(id: String):
	_entityId = id
	name = 'Entity<' + str(entity.uuid) + '>'
	entity.actor = self
	if entity.location:
		position = Coords.get_position(
			entity.location.position,
			-%Sprite2D.offset + Vector2(8, 8)
		)
	else:
		position = Coords.get_position(
			Coords.get_coord(position),
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
			die()
	)


func die():
	if is_dying:
		return
	is_dying = true
	await Global.sleep(400)
	destroyed.emit()
	queue_free()
