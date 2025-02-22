extends HBoxContainer

func _ready():
	for child in get_children():
		if child is HotbarItem:
			child.atlas_coords = Vector2(3, 0)
			pass
