extends Control

var tile_prefab = preload('res://game/tile_item.tscn')

var _entity: Entity
var entity: Entity:
	get: return _entity
	set(value):
		_entity = value
		%InventoryDisplay.inventory = _entity.inventory
		%EquipmentDisplay.equipment = _entity.equipment
	
