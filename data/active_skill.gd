class_name ActiveSkill
extends Skill

@export var sequence: Array[SkillSequence] = []

func _init():
	is_active = true
