extends ColorRect

const N_VERT = 6
const N_HORZ = 6
const CELL_WIDTH = 81
const BOARD_WIDTH = CELL_WIDTH * N_HORZ
const BOX_WIDTH = CELL_WIDTH * N_HORZ / 2
const BOX_HEIGHT = CELL_WIDTH * N_VERT / 3

const COL = Color("#e0e0e0")

func _ready():
	pass # Replace with function body.

func _draw():
	draw_rect(Rect2(0, 0, BOX_WIDTH, BOX_HEIGHT), COL)
	draw_rect(Rect2(BOX_WIDTH, BOX_HEIGHT, BOX_WIDTH, BOX_HEIGHT), COL)
	draw_rect(Rect2(0, BOX_HEIGHT*2, BOX_WIDTH, BOX_HEIGHT), COL)
