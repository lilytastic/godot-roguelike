class_name SkillSequence
extends Resource

@export_enum("Apply Effect", "Move", "Sleep") var type: String
@export var distance = 1
@export var angle = 0
@export var effects: Array[ScriptEffect] = []
