using Godot;
using GodotInk;
using System;
using System.Linq;

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
		story.BindExternalFunction("addVectors", (string pos1, string pos2) => {
			return pos1;
		});
		story.BindExternalFunction("getPosition", (string uuid) => {
			return uuid;
		});
		GD.Print(story.ContinueMaximally());
	}
	
	public void Execute(string path) {
		GD.Print("no args");
		Execute(path, null);
	}
	public void Execute(string path, Godot.Collections.Array args) {
		GD.Print(path);
		GD.Print("args: ", args);
		if (args == null) {
			story.ChoosePathString(path, true);
		} else {
			story.ChoosePathString(path, true, args.ToArray<Variant>());
		}
		GD.Print(story.ContinueMaximally());
	}
}
