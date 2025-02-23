extends Panel

var _item = ''
@export var item: String = '':
	get:
		return _item
	set(value):
		_item = value
		_update()

var entity: Entity:
	get:
		return ECS.entity(item)
	set(value):
		item = value.uuid
		
func _ready():
	PlayerInput.item_hovered.connect(
		func(_entity):
			if item != _entity:
				print('picked up ', _entity)
				item = _entity
	)
	_update()

func _update():
	if !entity:
		visible = false
		return
	visible = true
	%ItemIcon.texture = entity.glyph.to_atlas_texture()
	%ItemIcon.modulate = entity.glyph.fg
	%ItemName.text = entity.blueprint.name.capitalize()
	print(entity)
