class_name UseProps
extends Node

var type: String
var knot: String = ''

func _init(data: Dictionary):
	type = data.get('type', type)
	knot = data.get('knot', knot)
