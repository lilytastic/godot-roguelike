extends ScrollContainer

func _ready():
	PlayerInput.item_hovered.connect(
		func(_entity):
			if Global.ui_visible:
				if !_entity:
					%ItemPreview.item = ''
					return
				if %ItemPreview.item != _entity:
					%ItemPreview.item = _entity
			else:
				%ItemPreview.item = ''
	)
