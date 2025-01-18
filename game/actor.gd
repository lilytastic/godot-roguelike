extends Sprite2D

var entity: Entity:
	get: return ECS.entity(_entityId)

var _entityId: int

var blueprint: Blueprint:
	get: return entity.blueprint

var glyph: Glyph:
	get: return blueprint.glyph

func load(id: int):
	_entityId = id
	if glyph:
		set_texture(glyph.to_atlas_texture())
		modulate = glyph.fg

func _process(delta: float) -> void:
	position = lerp(position, Coords.get_position(entity.position), delta * 30)
	
