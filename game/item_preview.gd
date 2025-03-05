extends VBoxContainer

var _item = ''
@export var item: String = '':
	get:
		return _item
	set(value):
		_item = value
		_update()

@export var show_weapon_info = true
@export var show_description = true

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
		%ItemTags.text = ''
		if entity.health and entity.health.current <= 0:
			%ItemTags.text = '(dead)'
		%ItemType.text = entity.blueprint.type.capitalize()
		if !show_description and !show_weapon_info:
			%WeaponAndDescription.visible = false
		else:
			%WeaponAndDescription.visible = true
		if show_description:
			%Description.visible = true
			%Description.text = entity.blueprint.description
		else:
			%Description.visible = false
		if entity.blueprint.weapon and show_weapon_info:
			%WeaponInfo.visible = true
			%WeaponDamage.text = str(roundi(entity.blueprint.weapon.damage[0])) + '-' + str(roundi(entity.blueprint.weapon.damage[1])) + ' Damage'
			%WeaponSpeed.text = 'x' + str(entity.blueprint.weapon.speed) + ' Attack Speed'
		else:
			%WeaponInfo.visible = false
		
		if entity.blueprint.item:
			%Weight.text = str(entity.blueprint.item.weight) + 'lb'
		else:
			%Weight.text = '-'
		
		if entity.blueprint.item:
			%Value.text = str(entity.blueprint.item.value) + 'g'
		else:
			%Value.text = '-'
