class_name SkillTreeDisplay
extends GridContainer

var _current_tree: SkillTree
@export var current_tree: SkillTree:
	get: return _current_tree
	set(value):
		_current_tree = value
		_update()

var skills: Array[Skill] = []

var _skill_hovered: Skill = null
signal skill_hovered

var _skill_selected: Skill = null
signal skill_selected

func _update():
	for child in get_children():
		child.queue_free()
	
	for skill in AgentManager.skills.values().filter(
		func(skill):
			return skill.skill_tree == current_tree
	):
		var btn = Button.new()
		add_child(btn)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.text = skill.name
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.mouse_entered.connect(
			func():
				_skill_hovered = skill
				skill_hovered.emit(skill)
		)
		btn.mouse_exited.connect(
			func():
				if _skill_hovered == skill:
					_skill_hovered = null
					skill_hovered.emit(null)
		)
		btn.pressed.connect(
			func():
				_skill_selected = skill
				skill_selected.emit(skill)
		)
	pass
	
