using Godot;
using Godot.Collections;
using GodotInk;
using System;
using System.Linq;

public partial class InkManager : Node
{
	public InkStory story;

	Node ECS;
	GDScript Entity = GD.Load<GDScript>("res://engine/classes/entity.gd");
	GDScript ActionResult = GD.Load<GDScript>("res://engine/classes/action_result.gd");
	
	[Signal]
	public delegate void ScriptStartedEventHandler();
	[Signal]
	public delegate void ScriptEndedEventHandler();
	
	SceneTree tree = (SceneTree)Engine.GetMainLoop();
	
	public override void _Ready() {
		ECS = tree.Root.GetNode("/root/ECS");

		GD.Print("Hello from C#");
		story = GD.Load<InkStory>("res://assets/ink/crossroads_godot.ink");
		story.BindExternalFunction("addVectors", (string pos1, string pos2) => {
			GD.Print("addVectors called with ", pos1, " and", pos2);
			var coords1 = pos1.Substr(1, pos1.Length - 2).Split(',');
			var vector1 = new Vector2I(int.Parse(coords1[0]), int.Parse(coords1[1]));

			var coords2 = pos2.Substr(1, pos2.Length - 2).Split(',');
			var vector2 = new Vector2I(int.Parse(coords2[0]), int.Parse(coords2[1]));

			GD.Print(vector1);
			return (vector1 + vector2).ToString();
		});
		story.BindExternalFunction("getPosition", (string uuid) => {
			GD.Print("getPosition called with: ", uuid);
			GD.Print("ECS ", ECS);
			var entity = (RefCounted)ECS.Call("entity", uuid);
			GD.Print("Entity ", entity);
			var location = (RefCounted)entity.Get("location");
			GD.Print("Location: ", location);
			return location.Get("position").ToString();
			// location.TryGetValue("position", out value);
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
