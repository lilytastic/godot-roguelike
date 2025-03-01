using Godot;
using System;

public partial class Quadrant
{
	public Vector2I direction;
	public Vector2I origin;

	public Quadrant(Vector2I _direction, Vector2I _origin) {
		direction = _direction;
		origin = _origin;
	}

	public Vector2I Transform(Tile tile) {
		var col = tile.col;
		var row = tile.depth;
		if (direction == Vector2I.Up) {
			return new Vector2I(origin.X + col, origin.Y - row);
		} else if (direction == Vector2I.Left) {
				return new Vector2I(origin.X - row, origin.Y + col);
		} else if (direction == Vector2I.Right) {
				return new Vector2I(origin.X + row, origin.Y + col);
		} else if (direction == Vector2I.Down) {
				return new Vector2I(origin.X + col, origin.Y + row);
		}
		return new Vector2I(0, 0);
	}

}
