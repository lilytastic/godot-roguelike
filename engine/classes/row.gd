class_name Row

var depth: int
var start_slope: float
var end_slope: float


func _init(depth, start_slope, end_slope):
	self.depth = depth
	self.start_slope = start_slope
	self.end_slope = end_slope


func tiles() -> Array[Dictionary]:
	var min_col = round_ties_up(depth * start_slope)
	var max_col = round_ties_down(depth * end_slope)
	var arr: Array[Dictionary] = []
	for col in range(min_col, max_col + 1):
		arr.append({"depth": depth, "col": col})
	return arr

func next() -> Row:
	return Row.new(
		depth + 1,
		start_slope,
		end_slope
	)

func slope(tile) -> float:
	var row_depth = tile.depth
	var col = tile.col
	var x = 2.0 * col - 1.0
	var y = 2.0 * row_depth
	return (2 * col - 1) / float(2 * row_depth) # Vector2(2.0 * col - 1.0, 2.0 * row_depth)

func is_symmetric(row, tile) -> bool:
	var row_depth = tile.depth
	var col = tile.col
	return (col >= row.depth * row.start_slope and col <= row.depth * row.end_slope)

func round_ties_up(n) -> int:
	return floor(n + 0.5)

func round_ties_down(n) -> int:
	return ceil(n - 0.5)
