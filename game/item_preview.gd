extends VBoxContainer

var _item = ''
@export var item: String = '':
	get:
		return _item
	set(value):
		_item = value
		_update()
		
@export var wrapper: Control = null

var entity: Entity:
	get:
		return ECS.entity(item)
	set(value):
		item = value.uuid
		
func _ready():
	PlayerInput.item_hovered.connect(
		func(_entity):
			if !_entity:
				item = ''
				return
			if item != _entity:
				print('picked up ', _entity)
				item = _entity
	)
	_update()

func _update():
	if !is_instance_valid(entity):
		if wrapper:
			wrapper.visible = false
		else:
			visible = false
		return
	
	if wrapper:
		wrapper.visible = true
	visible = true
	%ItemIcon.texture = entity.glyph.to_atlas_texture()
	%ItemIcon.modulate = entity.glyph.fg
	if is_instance_valid(entity.blueprint):
		%ItemName.text = entity.blueprint.name.capitalize()
		%ItemType.text = entity.blueprint.type.capitalize()
		%Description.text = entity.blueprint.description
		if entity.blueprint.weapon:
			%WeaponDamage.text = str(entity.blueprint.weapon.damage[0]) + '-' + str(entity.blueprint.weapon.damage[1]) + ' Damage'
			%WeaponSpeed.text = 'x' + str(entity.blueprint.weapon.speed) + ' Attack Speed'
