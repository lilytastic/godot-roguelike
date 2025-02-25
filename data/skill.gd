class_name Skill
extends Resource

@export var name: String
@export var description: String
@export var is_passive: bool
@export var skill_tree: SkillTree

@export var effects: Array[ScriptEffect] = []
