extends Control

var tile_prefab = preload('res://game/tile_item.tscn')

var _entity: Entity
var entity: Entity:
	get: return _entity
	set(value):
		_entity = value

		if _entity:
			%InventoryDisplay.inventory = _entity.inventory
			%EquipmentDisplay.equipment = _entity.equipment
		
func _ready():
	PlayerInput.double_click.connect(_on_double_click)

func _on_double_click(stack):
	if !visible:
		return
	if stack and stack.entity:
		var action = UseAction.new(ECS.entity(stack.entity))
		action.perform(Global.player)
		PlayerInput.ui_action_triggered.emit(action)
