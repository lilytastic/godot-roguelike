using Godot;
using System;
using System.Collections.Generic;
using System.Linq;

public partial class Row {

  public int depth;
  public float start_slope;
  public float end_slope;


  public Row(int _depth, float _start_slope, float _end_slope) {
    depth = _depth;
    start_slope = _start_slope;
    end_slope = _end_slope;
  }


  public Tile[] tiles() {
    var min_col = round_ties_up(depth * start_slope);
    var max_col = round_ties_down(depth * end_slope);
    List<Tile> arr = new List<Tile>();
    for (var col = min_col; col < max_col + 1; col ++) {
      arr.Add(new Tile(){ depth = depth, col = col });
    }
    return arr.ToArray();
  }

  public Row next() {
    return new Row(
      depth + 1,
      start_slope,
      end_slope
    );
  }

  public float slope(Tile tile) {
    var row_depth = tile.depth;
    var col = tile.col;
    var x = 2.0f * col - 1.0;
    var y = 2.0f * row_depth;
    return (2 * col - 1) / (2.0f * row_depth);
  }

  public bool is_symmetric(Row row, Tile tile) {
    var row_depth = tile.depth;
    var col = tile.col;
    return col >= row.depth * row.start_slope && col <= row.depth * row.end_slope;
  }

  private int round_ties_up(float n) {
    return Mathf.FloorToInt(n + 0.5f);
  }

  private int round_ties_down(float n) {
    return Mathf.CeilToInt(n - 0.5f);
  }
}