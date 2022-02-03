extends Node2D

enum {
	HORZ = 1,
	VERT,
	BOX,
	CELL,
}
enum {
	#IX_CAGE_COLOR = 0,		# ケージ背景色、0, 1, 2, 3
	IX_CAGE_TOP_LEFT = 0,	# ケージ左上位置
	IX_CAGE_N,				# ケージ内数字数
	IX_CAGE_SUM,			# ケージ内数字合計
	IX_CAGE_BITS,			# ケージ内数字ビット論理和
	#IX_CAGE_IX_LIST,		# ケージに含まれるセルIXのリスト
}

const N_COLOR = 4			# ケージ色種数
const CAGE_N_NUM_MAX = 4	# ケージ最大セル数
const N_VERT = 6
const N_HORZ = 6
const N_CELLS = N_HORZ * N_VERT
const CELL_WIDTH = 81
const CELL_WIDTH3 = CELL_WIDTH/3
const CELL_WIDTH4 = CELL_WIDTH/4
const BIT_1 = 1
const BIT_2 = 1<<1
const BIT_3 = 1<<2
const BIT_4 = 1<<3
const BIT_5 = 1<<4
const BIT_6 = 1<<5
const BIT_7 = 1<<6
const BIT_8 = 1<<7
const BIT_9 = 1<<8
const ALL_BITS = (1<<N_HORZ) - 1
const BIT_MEMO = 1<<10
const TILE_NONE = -1
const TILE_CURSOR = 0
const TILE_LTBLUE = 1				# 強調カーソル（薄青）
const TILE_LTORANGE = 2				# 強調カーソル（薄橙）
const TILE_PINK = 3					# 強調カーソル（薄ピンク）
const COLOR_INCORRECT = Color.red
const COLOR_DUP = Color.red
const COLOR_CLUE = Color.black
const COLOR_INPUT = Color("#2980b9")	# VELIZE HOLE

const CAGE_TABLE = [
]
# 要素：[sum, ix1, ix2, ...]
const QUEST1 = [ # by wikipeida
	[5, 0, 1, 6], [7, 2, 3, 4], [11, 5, 11],
	[12, 6, 7, 12], [3, 8, 14], [9, 9, 15], [7, 10, 16],
	[7, 12, 18], [6, 17, 23],
	[12, 19, 24, 25], [11, 20, 21], [6, 22, 28],
	[5, 26, 27], [10, 29, 34, 35],
	[12, 30, 31, 32, 33],
]

var symmetric = true		# 対称形問題
var qCreating = false		# 問題生成中
var solvedStat = false		# クリア済み状態
var paused = false			# ポーズ状態
var sound = true			# 効果音
var menuPopuped = false
var hint_showed = false
var memo_mode = false		# メモ（候補数字）エディットモード
var in_button_pressed = false	# ボタン押下処理中
var hint_next_pos			# 次ボタン位置
var hint_next_pos0			# 次ボタン初期位置
var hint_next_vy			# 次ボタン速度
var saved_cell_data = []

#var hint_next_scale = 1.0	# ヒント次ボタン表示スケール
#var hint_num				# ヒントで確定する数字、[1, 9]
var hint_numstr				# ヒントで確定する数字、[1, 9]
var hint_ix = 0				# 0, 1, 2, ...
var hint_texts = []			# ヒントテキスト配列
#var restarted = false
#var elapsedTime = 0.0   	# 経過時間（単位：秒）
var saved_time
var nEmpty = 0				# 空欄数
var nDuplicated = 0			# 重複数字数
#var optGrade = -1			# 問題グレード、0: 入門、1:初級、2:ノーマル（初中級）
var diffculty = 0			# 難易度、フルハウス: 1, 隠れたシングル: 2, 裸のシングル: 10pnt？
var num_buttons = []		# 各数字ボタンリスト [0] -> 削除ボタン、[1] -> Button1, ...
var num_used = []			# 各数字使用数（手がかり数字＋入力数字）
var cur_num = -1			# 選択されている数字ボタン、-1 for 選択無し
var cur_cell_ix = -1		# 選択されているセルインデックス、-1 for 選択無し
var input_num = 0			# 入力された数字
var nRemoved

var cage_labels = []		# ケージ合計数字用ラベル配列
var clue_labels = []		# 手がかり数字用ラベル配列
var input_labels = []		# 入力数字用ラベル配列
var ans_bit = []			# 解答の各セル数値（0 | BIT_1 | BIT_2 | ... | BIT_9）
var cell_bit = []			# 各セル数値（0 | BIT_1 | BIT_2 | ... | BIT_9）
var quest_cages = []		# クエストケージリスト配列、要素：[sum, ix1, ix2, ...]
var cage_list = []			# ケージリスト配列、要素：IX_CAGE_XXX
var cage_ix = []			# 各セルのケージリスト配列インデックス
var candidates_bit = []		# 入力可能ビット論理和
var column_used = []		# 各カラムの使用済みビット
var box_used = []			# 各3x3ブロックの使用済みビット
var memo_labels = []		# メモ（候補数字）用ラベル配列（２次元）
var memo_text = []			# ポーズ復活時用ラベルテキスト配列（２次元）
var shock_wave_timer = -1
var undo_ix = 0
var undo_stack = []			# 要素：[ix old new]、old, new は 0～9 の数値、0 for 空欄

var rng = RandomNumberGenerator.new()

var CageLabel = load("res://CageLabel.tscn")
var ClueLabel = load("res://ClueLabel.tscn")
var InputLabel = load("res://InputLabel.tscn")
var MemoLabel = load("res://MemoLabel.tscn")

func _ready():
	if false:
		randomize()
		rng.randomize()
	else:
		var sd = 1
		seed(sd)
		rng.set_seed(sd)
	cell_bit.resize(N_CELLS)
	candidates_bit.resize(N_CELLS)
	cage_ix.resize(N_CELLS)
	column_used.resize(N_HORZ)
	box_used.resize(N_HORZ)
	memo_text.resize(N_CELLS)
	column_used.resize(N_HORZ)
	num_used.resize(N_HORZ + 1)		# +1 for 0
	#
	num_buttons.push_back($DeleteButton)
	for i in range(N_HORZ):
		num_buttons.push_back(get_node("Button%d" % (i+1)))
	#
	init_labels()
	#gen_ans()
	#show_clues()	# 手がかり数字表示
	#gen_cage()
	set_quest(QUEST1)
	pass # Replace with function body.
func xyToIX(x, y) -> int: return x + y * N_HORZ
func num_to_bit(n : int): return 1 << (n-1) if n != 0 else 0
func bit_to_num(b):
	var mask = 1
	for i in range(N_HORZ):
		if (b & mask) != 0: return i + 1
		mask <<= 1
	return 0
func bit_to_numstr(b):
	if b == 0: return ""
	return String(bit_to_num(b))
func init_labels():
	# 手がかり数字、入力数字用 Label 生成
	for y in range(N_VERT):
		for x in range(N_HORZ):
			var px = x * CELL_WIDTH
			var py = y * CELL_WIDTH
			# ケージ合計用ラベル
			var label = CageLabel.instance()
			cage_labels.push_back(label)
			label.rect_position = Vector2(px + 1, py + 1)
			label.text = ""
			$Board.add_child(label)
			# 手がかり数字用ラベル
			label = ClueLabel.instance()
			clue_labels.push_back(label)
			label.rect_position = Vector2(px, py + 2)
			label.text = ""		#String((x+y)%9 + 1)
			$Board.add_child(label)
			# 入力数字用ラベル
			label = InputLabel.instance()
			input_labels.push_back(label)
			label.rect_position = Vector2(px, py + 2)
			label.text = ""
			$Board.add_child(label)
			# 候補数字用ラベル
			var lst = []
			for v in range(3):
				for h in range(3):
					label = MemoLabel.instance()
					lst.push_back(label)
					label.rect_position = Vector2(px + CELL_WIDTH4*(h+1)-3, py + CELL_WIDTH4*(v+1)-3)
					label.text = ""		#String(v*3+h+1)
					$Board.add_child(label)
			memo_labels.push_back(lst)
func init_cell_bit():		# clue_labels, input_labels から 各セルの cell_bit 更新
	for ix in range(N_CELLS):
		var n = get_cell_numer(ix)
		if n == 0:
			cell_bit[ix] = 0
		else:
			cell_bit[ix] = num_to_bit(n)
func init_candidates():		# cell_bit から各セルの候補数字計算
	for i in range(N_CELLS):
		candidates_bit[i] = ALL_BITS if cell_bit[i] == 0 else 0
	for y in range(N_VERT):
		for x in range(N_HORZ):
			var b = cell_bit[xyToIX(x, y)]
			if b != 0:
				for t in range(N_HORZ):
					candidates_bit[xyToIX(t, y)] &= ~b
					candidates_bit[xyToIX(x, t)] &= ~b
				var x0 = x - x % 3		# 3x3ブロック左上位置
				var y0 = y - y % 3
				for v in range(3):
					for h in range(3):
						candidates_bit[xyToIX(x0 + h, y0 + v)] &= ~b
	pass
func set_quest(cages):
	quest_cages = cages
	##for y in range(N_VERT):
	##	for x in range(N_HORZ):
	##		$Board/CageTileMap.set_cell(x, y, -1)
	#var col = 0
	for cix in range(cages.size()):
		var item = cages[cix]			# [sum, col, ix1, ix2, ... ]
		cage_labels[item[1]].text = String(item[0])
		var x1 = item[1] % N_HORZ
		var y1 = item[1] / N_HORZ
		#while( $Board/CageTileMap.get_cell(x1, y1-1) == col || $Board/CageTileMap.get_cell(x1-1, y1) == col ||
		#		$Board/CageTileMap.get_cell(x1, y1+1) == col || $Board/CageTileMap.get_cell(x1+1, y1) == col ):
		#	col = (col + 1) % N_COLOR
		#var col = item[1]
		for k in range(1, item.size()):
			cage_ix[item[k]] = cix
			#var x = item[k] % N_HORZ
			#var y = item[k] / N_HORZ
			#$Board/CageTileMap.set_cell(x, y, col)
	$Board/CageGrid.cage_ix = cage_ix
	$Board/CageGrid.update()
	#update()
func get_cell_numer(ix) -> int:		# ix 位置に入っている数字の値を返す、0 for 空欄
	if clue_labels[ix].text != "":
		return int(clue_labels[ix].text)
	if input_labels[ix].text != "":
		return int(input_labels[ix].text)
	return 0
