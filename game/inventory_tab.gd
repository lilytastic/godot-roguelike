extends Control

var tile_prefab = preload('res://game/tile_item.tscn')

var _entity: Entity
var entity: Entity:
	get: return _entity
	set(value):
		_entity = value
		%InventoryDisplay.inventory = _entity.inventory
		%EquipmentDisplay.equipment = _entity.equipment
	
		var tiles = %InventoryDisplay.tiles + %EquipmentDisplay.tiles
		for tile in tiles:
			if tile is TileItem:
				tile.double_click.connect(
					func(stack):
						print(stack)
						if stack.entity:
							var action = UseAction.new(Global.ecs.entity(stack.entity))
							PlayerInput.ui_action_triggered.emit(action)
				)
