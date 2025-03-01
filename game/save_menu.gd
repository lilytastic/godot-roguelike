extends Panel

@export var mode = 'save'
var slots: Array = []

func _ready():
	%SaveSlots.slot_hovered.connect(
		func(slot):
			print(slot)
			preview_slot(slot)
	)
	_reset()
	update()

func update():
	print(mode)
	%SaveSlots.mode = mode
	slots = %SaveSlots.update_slots()
	%SaveSlotsLabel.text = 'Load Game' if mode == 'load' else 'Save Game'

func preview_slot(_slot: SaveSlot):
	var image = Image.new()

	if _slot:
		%SaveName.text = _slot.slot_name
		%SaveDescription.text = _slot.slot_type.capitalize()
		%SaveDate.text = _slot.slot_date
		%ThumbnailPreview.texture = null
	else:
		_reset()
		return

	var _path = _slot.path.substr(0, _slot.path.rfind('.')) + ".jpg"
	if FileAccess.file_exists(_path):
		image.load(_path)
		print(_path, image.get_size())
		var t = ImageTexture.create_from_image(image)
		print(t)
		if t:
			print('texture: ', t, t.get_size())
			%ThumbnailPreview.expand_mode = TextureRect.ExpandMode.EXPAND_FIT_WIDTH
			%ThumbnailPreview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			%ThumbnailPreview.texture = t
	else:
		%ThumbnailPreview.texture = null

func _reset():
	%SaveName.text = ''
	%SaveDescription.text = ''
	%SaveDate.text = ''
	%ThumbnailPreview.texture = null
