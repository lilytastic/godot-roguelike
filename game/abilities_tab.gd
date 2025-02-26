extends Control

func _ready():
	%SkillTreeSelect.tab_clicked.connect(
		func(tab: int):
			var tree = %SkillTreeSelect.skill_trees[tab]
			%SkillTree.current_tree = tree
			%SkillTreeDescription.text = tree.description
			%SkillDisplay.skill = null
			pass
	)
