class_name Row

var depth: int
var start_slope: float
var end_slope: float


func _init(depth, start_slope, end_slope):
	self.depth = depth
	self.start_slope = start_slope
	self.end_slope = end_slope


func tiles():
	var min_col = round_ties_up(depth * start_slope)
	var max_col = round_ties_down(depth * end_slope)
	var arr = []
	for col in range(min_col, max_col + 1):
		arr.append({"depth": depth, "col": col})
	return arr

func next():
	return Row.new(
		depth + 1,
		start_slope,
		end_slope
	)

func slope(tile):
	var row_depth = tile.depth
	var col = tile.col
	return Vector2(2.0 * col - 1.0, 2.0 * row_depth)

func is_symmetric(row, tile):
	var row_depth = tile.depth
	var col = tile.col
	return (col >= row.depth * row.start_slope and col <= row.depth * row.end_slope)

func round_ties_up(n):
	return floor(n + 0.5)

func round_ties_down(n):
	return ceil(n - 0.5)
