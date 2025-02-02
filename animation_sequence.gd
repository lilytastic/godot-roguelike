class_name AnimationSequence

var length = 1.0
var sequence := []
var progress = 0.0

func _init(_sequence := [], _length := 1.0):
	sequence = _sequence
	length = _length
	
func process(entity: Entity, delta: float) -> Dictionary:
	progress = min(progress + delta, length)
	var glyph = entity.blueprint.glyph
	# 0.5 -> [0, 1, 2]
	var index = progress / length * (sequence.size() - 1)
	var min = floor(index)
	var max = ceil(index)
	var step = index - min
	var position = [
		sequence[min].position if sequence[min].has('position') else Vector2.ZERO,
		sequence[max].position if sequence[max].has('position') else Vector2.ZERO
	]
	var scale = [
		sequence[min].scale if sequence[min].has('scale') else Vector2.ONE,
		sequence[max].scale if sequence[max].has('scale') else Vector2.ONE,
	]
	var color = [
		sequence[min].color if sequence[min].has('color') else glyph.fg,
		sequence[max].color if sequence[max].has('color') else glyph.fg,
	]
	return {
		'position': position[0].lerp(position[1], step),
		'scale': scale[0].lerp(scale[1], step),
		'color': color[0].lerp(color[1], step),
	}
