class_name SkillDisplay
extends VBoxContainer

@export var skill_tree_display: SkillTreeDisplay

var _skill: Skill
@export var skill: Skill:
	get: return _skill
	set(value):
		_skill = value
		_update()
		
func _ready():
	skill_tree_display.skill_hovered.connect(
		func(__skill):
			if __skill:
				skill = __skill
			else:
				skill = skill_tree_display._skill_selected
	)
	skill_tree_display.skill_selected.connect(
		func(__skill):
			skill = __skill
	)

func _update():
	if !skill:
		visible = false
		return
	visible = true
	%NameLabel.text = skill.name
	%DescLabel.text = skill.description
