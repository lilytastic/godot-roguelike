using Godot;
using System;
using System.Collections.Generic;
using System.Linq;

public partial class FOV : GodotObject {
	// class_name FOV
	GodotObject entity;
	
	public FOV(GodotObject _entity) {
		this.entity = _entity;
	}
	
	void compute_fov(Vector2I origin) {
		entity.Call("reveal", origin);
		List<Vector2I> directions = new List<Vector2I>();
		directions.Add(Vector2I.Up);
		directions.Add(Vector2I.Left);
		directions.Add(Vector2I.Right);
		directions.Add(Vector2I.Down);
		foreach(var direction in directions) {
			var quadrant = new Quadrant(direction, origin);
			var first_row = new Row(1, -1.0f, 1.0f);
			scan(first_row, quadrant);
		}
	}

	void scan(Row row, Quadrant quadrant) {
		Tile prev_tile = null;
		foreach(var tile in row.tiles()) {
			if (is_wall(tile, quadrant) || row.is_symmetric(row, tile)) {
				reveal(tile, quadrant);
			}
			if (is_wall(prev_tile, quadrant) && is_floor(tile, quadrant)) {
				row.start_slope = row.slope(tile);
			}
			if (is_floor(prev_tile, quadrant) && is_wall(tile, quadrant)) {
				var next_row = row.next();
				next_row.end_slope = row.slope(tile);
				scan(next_row, quadrant);
			}
			prev_tile = tile;
		}
		if (is_floor(prev_tile, quadrant)) {
			scan(row.next(), quadrant);
		}
		return;
	}

	void reveal(Tile tile, Quadrant quadrant) {
		var pos = quadrant.Transform(tile);
		entity.Call("reveal", pos);
	}

	bool is_wall(Tile tile, Quadrant quadrant) {
		if (tile == null) {
			return false;
		}
		var pos = quadrant.Transform(tile);
		return (bool)entity.Call("is_blocking", pos);
	}

	bool is_floor(Tile tile, Quadrant quadrant) {
		if (tile == null) {
			return false;
		}
		var pos = quadrant.Transform(tile);
		return !(bool)entity.Call("is_blocking", pos);
	}
}
