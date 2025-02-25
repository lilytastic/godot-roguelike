extends Control

func _ready():
	%SkillTreeSelect.tab_clicked.connect(
		func(tab: int):
			print(tab)
			var tree = %SkillTreeSelect.trees[tab]
			%SkillTree.current_tree = tree
			%SkillTreeDescription.text = tree.description
			pass
	)
