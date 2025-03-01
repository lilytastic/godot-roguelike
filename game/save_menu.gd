extends Panel

@export var mode = 'save'

func _ready():
	%SaveSlots.slot_hovered.connect(
		func(slot):
			preview_slot(slot)
	)
	update()

func update():
	print(mode)
	%SaveSlots.mode = mode
	%SaveSlots._init()
	%SaveSlotsLabel.text = 'Load Game' if mode == 'load' else 'Save Game'

func preview_slot(_name: String):
	var image = Image.new()
	var _path = _name.substr(0, _name.rfind('.')) + ".jpg"
	if FileAccess.file_exists(_path):
		image.load(_path)
		print(_name, image.get_size())
		var t = ImageTexture.create_from_image(image)
		print(t)
		if t:
			print('texture: ', t, t.get_size())
			%ThumbnailPreview.expand_mode = TextureRect.ExpandMode.EXPAND_FIT_WIDTH
			%ThumbnailPreview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			%ThumbnailPreview.texture = t
	else:
		%ThumbnailPreview.texture = null
