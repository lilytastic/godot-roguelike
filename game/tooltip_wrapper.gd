extends Panel

func _ready():
	PlayerInput.item_hovered.connect(
		func(_entity):
			if !_entity:
				%ItemPreview.item = ''
				visible = false
				return
			if %ItemPreview.item != _entity:
				visible = true
				%ItemPreview.item = _entity
	)


func _process(delta):
	if visible and Global.ui_visible:
		visible = false
		return
		
