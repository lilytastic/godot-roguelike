class_name StorageProps

var weight: int

func _init(props: Dictionary):
	weight = props['weight'] if props.has('weight') else 0
