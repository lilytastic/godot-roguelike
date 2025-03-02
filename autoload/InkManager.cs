using Godot;
using GodotInk;
using System;
using System.Linq;

public partial class InkManager : Node
{
	public InkStory story;

	GDScript ECS = GD.Load<GDScript>("res://autoload/ecs.gd");
	GDScript ActionResult = GD.Load<GDScript>("res://engine/classes/action_result.gd");
	GDScript Entity = GD.Load<GDScript>("res://engine/classes/entity.gd");
	
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
			GD.Print("getPosition", uuid);
			var entity = (GodotObject)ECS.Call("entity", uuid);
			return uuid;
		});
		GD.Print(story.ContinueMaximally());
	}

	public Variant Perform(GodotObject entity, string path) {
		return Perform(entity, path, new Godot.Collections.Array());
	}
	public Variant Perform(GodotObject entity, string path, Godot.Collections.Array args) {
		if (args == null) {
			story.ChoosePathString(path, true);
		} else {
			story.ChoosePathString(path, true, args.ToArray<Variant>());
		}
		GD.Print(story.ContinueMaximally());
		return ActionResult.New(true);
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
