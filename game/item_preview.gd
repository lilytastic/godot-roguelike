extends VBoxContainer

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
	_update()

func _update():
	if !is_instance_valid(entity):
		visible = false
		return
	
	visible = true
	%ItemIcon.texture = entity.glyph.to_atlas_texture()
	%ItemIcon.modulate = entity.glyph.fg
	if is_instance_valid(entity.blueprint):
		%ItemName.text = entity.blueprint.name.capitalize()
		%ItemType.text = entity.blueprint.type.capitalize()
		%Description.text = entity.blueprint.description
		if entity.blueprint.weapon:
			%WeaponInfo.visible = true
			%WeaponDamage.text = str(entity.blueprint.weapon.damage[0]) + '-' + str(entity.blueprint.weapon.damage[1]) + ' Damage'
			%WeaponSpeed.text = 'x' + str(entity.blueprint.weapon.speed) + ' Attack Speed'
		else:
			%WeaponInfo.visible = false
