class_name Skill
extends Resource

@export var name: String
@export var description: String
@export var is_passive: bool
@export_enum("Combat", "Strength", "Dexterity", "Mind", "Charisma", "Arcane", "Boons") var skill_tree: int

@export var effects: Array[ScriptEffect] = []
