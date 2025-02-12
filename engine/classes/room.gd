class_name Room
extends Feature

func get_center() -> Vector2i:
	var averaged = Vector2i(0,0)
	for cell in cells:
		averaged += cell
	averaged /= cells.size()
	return averaged
