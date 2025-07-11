using Godot;
using Godot.Collections;
using GodotInk;
using System;
using System.Linq;

public partial class InkManager : Node
{
	public InkStory story;

	Node ECS;
	Node MapManager;
	GDScript Entity = GD.Load<GDScript>("res://engine/classes/entity.gd");
	GDScript ActionResult = GD.Load<GDScript>("res://engine/classes/action_result.gd");
	
	[Signal]
	public delegate string CommandTriggeredEventHandler();
	[Signal]
	public delegate void ScriptStartedEventHandler();
	[Signal]
	public delegate void ScriptEndedEventHandler();
	
	SceneTree tree = (SceneTree)Engine.GetMainLoop();

	private const double DegToRad = Math.PI/180;

	public override void _Ready() {
		ECS = tree.Root.GetNode("/root/ECS");
		MapManager = tree.Root.GetNode("/root/MapManager");

		// GD.Print("Hello from C#");
		story = GD.Load<InkStory>("res://assets/ink/crossroads_godot.ink");
		story.BindExternalFunction("rotate", (string vec, float angle) => {
			var rotated = stringToVector(vec).Rotated((float)(angle * DegToRad));
			// GD.Print("rotate called with ", vec, " and ", angle, "deg = ", rotated.ToString());
			return rotated.Normalized().ToString();
		});
		story.BindExternalFunction("snapToGrid", (string vec) => {
			var vector = stringToVector(vec);
			vector.X = (float)Math.Round(vector.X);
			vector.Y = (float)Math.Round(vector.Y);
			return vector.ToString();
		});
		story.BindExternalFunction("addVectors", (string pos1, string pos2) => {
			// GD.Print("addVectors called with ", pos1, " and ", pos2);
			var vector1 = stringToVector(pos1);
			var vector2 = stringToVector(pos2);

			// GD.Print("added: ", vector1 + vector2);
			return (vector1 + vector2).ToString();
		});
		story.BindExternalFunction("getPosition", (string uuid) => {
			// GD.Print("getPosition called with: ", uuid);
			return getPosition(uuid).ToString();
			// location.TryGetValue("position", out value);
		});
		// GD.Print(story.ContinueMaximally());
	}

	RefCounted getEntity(string uuid) {
		return (RefCounted)ECS.Call("entity", uuid);
	}

	Vector2 getPosition(string uuid) {
		var entity = getEntity(uuid);
		var location = (RefCounted)entity.Get("location");
		if (location == null) {
			return Vector2.Zero;
		}
		return (Vector2)location.Get("position");
	}

	Vector2 stringToVector(string str) {
			var coords = str.Substr(1, str.Length - 2).Split(',');
			return new Vector2(float.Parse(coords[0]), float.Parse(coords[1]));
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
		// GD.Print(story.ContinueMaximally());
		return ActionResult.New(true);
	}
	
	public void Execute(string path) {
		// GD.Print("no args");
		Execute(path, null);
	}
	public void Execute(string path, Godot.Collections.Array args) {
		// GD.Print(path);
		// GD.Print("args: ", args);
		if (args == null) {
			story.ChoosePathString(path, true);
		} else {
			story.ChoosePathString(path, true, args.ToArray<Variant>());
		}
		while (story.CanContinue) {
			var line = story.Continue();
			// GD.Print(line);
			if (line.StartsWith(">>>")) {
				var tokens = line.Substr(3, line.Length - 3).Split(" ").Select((x) => x.Trim()).Where((x) => x.Length > 0).ToArray();
				var tagDictionary = new Dictionary();
				foreach (var tag in story.GetCurrentTags()) {
					var t = tag.Split("=");
					if (t.Length == 2) {
						tagDictionary[t[0].Trim()] = t[1].Trim();
					}
				}
				var result = new Dictionary();
				result.Add("tokens", tokens);
				result.Add("tagDictionary", tagDictionary);
				result.Add("tags", story.GetCurrentTags());
				EmitSignal(SignalName.CommandTriggered, result);
				// GD.Print(tokens.Join(", "), " - tags: ", story.CurrentTags.ToArray().Join(", "));
			}
		}
	}
}
