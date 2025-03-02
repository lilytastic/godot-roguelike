using Godot;
using GodotInk;
using System;

public partial class InkManager : Node
{
	public InkStory story;
	
	[Signal]
	public delegate void ScriptStartedEventHandler();
	[Signal]
	public delegate void ScriptEndedEventHandler();
	
	public override void _Ready() {
		GD.Print("Hello from C#");
		story = GD.Load<InkStory>("res://assets/ink/crossroads_godot.ink");
		GD.Print(story.ContinueMaximally());
	}
	
	public void Init(InkStory new_story) {
		GD.Print("Init!");
		story = new_story;
		GD.Print("Ready! ", story.Continue());
	}
	
	public void Execute(string path, string entity = "") {
		GD.Print(path);
		story.ChoosePathString(path);
		GD.Print(story.ContinueMaximally());
	}
}
