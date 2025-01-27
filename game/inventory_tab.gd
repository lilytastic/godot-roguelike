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
				if tile.double_click.get_connections().size() > 0:
					tile.double_click.disconnect(_on_double_click)
				tile.double_click.connect(_on_double_click)

func _on_double_click(stack):
	if stack and stack.entity:
		var action = UseAction.new(Global.ecs.entity(stack.entity))
		PlayerInput.ui_action_triggered.emit(action)
