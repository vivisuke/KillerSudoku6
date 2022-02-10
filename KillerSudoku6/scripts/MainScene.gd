extends Node2D

enum {
	HORZ = 1,
	VERT,
	BOX,
	CELL,
}
enum {
	CAGE_SUM = 0,			# ケージ内数字合計
	CAGE_IX_LIST,			# ケージ内セル位置配列
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
#const COLOR_INPUT = Color("#2980b9")	# VELIZE HOLE
const COLOR_INPUT = Color.black
const UNDO_TYPE_CELL = 0		# セル数字入力
const UNDO_TYPE_MEMO = 1		# メモ数字反転
const UNDO_TYPE_AUTO_MEMO = 2	# 自動メモ
const UNDO_TYPE_DEL_MEMO = 3	# メモ削除
const UNDO_ITEM_TYPE = 0
const UNDO_ITEM_IX = 1
const UNDO_ITEM_NUM = 2			# for メモ数字
const UNDO_ITEM_OLD = 2			# for セル数字
const UNDO_ITEM_NEW = 3			# for セル数字
const UNDO_ITEM_MEMOIX = 4		# メモ数字反転位置リスト
const UNDO_ITEM_MEMO = 5		# 数字を入れた位置のメモ数字（ビット値）
const UNDO_ITEM_MEMO_LST = 1

const CAGE_TABLE = [
]
# 要素：[sum, [ix1, ix2, ...]]
const QUEST1 = [ # by wikipeida
	[8, [0, 1, 6]], [7, [2, 3, 4]], [11, [5, 11]],
	[12, [6, 7, 12, 13]], [3, [8, 14]], [9, [9, 15]], [7, [10, 16]],
	[7, [12, 18]], [6, [17, 23]],
	[12, [19, 24, 25]], [11, [20, 21]], [6, [22, 28]],
	[5, [26, 27]], [10, [29, 34, 35]],
	[12, [30, 31, 32, 33]],
]

var qix                 	# 問題番号 [0, N]
var qID                 	# 問題ID
var qSolved = false     	# 現問題をクリア済みか？
#var qSolvedStat = false     # 現問題をクリア状態か？
var elapsedTime = 0.0   	# 経過時間（単位：秒）
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
var saved_time
var nEmpty = 0				# 空欄数
var nDuplicated = 0			# 重複、合計不正数字数
#var optGrade = -1			# 問題グレード、0: 入門、1:初級、2:ノーマル（初中級）
var diffculty = 0			# 難易度、フルハウス: 1, 隠れたシングル: 2, 裸のシングル: 10pnt？
var num_buttons = []		# 各数字ボタンリスト [0] -> 削除ボタン、[1] -> Button1, ...
var num_used = []			# 各数字使用数（手がかり数字＋入力数字）
var cur_num = -1			# 選択されている数字ボタン、-1 for 選択無し
var cur_cell_ix = -1		# 選択されているセルインデックス、-1 for 選択無し
var input_num = 0			# 入力された数字
var nRemoved
var nAnswer = 0				# 解答数

var cage_labels = []		# ケージ合計数字用ラベル配列
var clue_labels = []		# 手がかり数字用ラベル配列
var input_labels = []		# 入力数字用ラベル配列
var ans_bit = []			# 解答の各セル数値（0 | BIT_1 | BIT_2 | ... | BIT_9）
var cell_bit = []			# 各セル数値（0 | BIT_1 | BIT_2 | ... | BIT_9）
var quest_cages = []		# クエストケージリスト配列、要素：[sum, ix1, ix2, ...]
var cage_list = []			# ケージリスト配列、要素：IX_CAGE_XXX
var cage_ix = []			# 各セルのケージリスト配列インデックス
var candidates_bit = []		# 入力可能ビット論理和
var line_used = []			# 各行の使用済みビット
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

onready var g = get_node("/root/Global")

func _ready():
	if true:
		randomize()
		rng.randomize()
	else:
		var sd = 2
		seed(sd)
		rng.set_seed(sd)
	cell_bit.resize(N_CELLS)
	candidates_bit.resize(N_CELLS)
	cage_ix.resize(N_CELLS)
	line_used.resize(N_HORZ)
	column_used.resize(N_HORZ)
	box_used.resize(N_HORZ)
	memo_text.resize(N_CELLS)
	num_used.resize(N_HORZ + 1)		# +1 for 0
	#
	num_buttons.push_back($DeleteButton)
	for i in range(N_HORZ):
		num_buttons.push_back(get_node("Button%d" % (i+1)))
	#
	init_labels()
	#gen_ans()
	#show_clues()	# 手がかり数字表示
	#gen_cages()
	#set_quest(QUEST1)
	#is_proper_quest()
	while true:
		gen_ans()
		gen_cages()
		#gen_cages_3x2()		# 3x2 単位で分割
		#break
		if is_proper_quest():
			break
	#
	pass # Replace with function body.
func xyToIX(x, y) -> int: return x + y * N_HORZ
func num_to_bit(n : int): return 1 << (n-1) if n > 0 else 0
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
			label.add_color_override("font_color", Color("#2980b9"))	# VELIZE HOLE
			label.rect_position = Vector2(px + 4, py + 4)
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
			label.rect_position = Vector2(px+12, py + 8)
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
func gen_ans_sub(ix : int, line_used):
	#print_cells()
	#print_box_used()
	var x : int = ix % N_HORZ
	if x == 0: line_used = 0
	var x3 = x / 3
	var y2 = ix / (N_HORZ*2)
	var bix = y2 * 2 + x3
	var used = line_used | column_used[x] | box_used[bix]
	if used == ALL_BITS: return false		# 全数字が使用済み
	var lst = []
	var mask = BIT_1
	for i in range(N_HORZ):
		if (used & mask) == 0: lst.push_back(mask)		# 数字未使用の場合
		mask <<= 1
	if ix == N_CELLS - 1:
		cell_bit[ix] = lst[0]
		return true
	if lst.size() > 1: lst.shuffle()
	for i in range(lst.size()):
		cell_bit[ix] = lst[i]
		column_used[x] |= lst[i]
		box_used[bix] |= lst[i]
		if gen_ans_sub(ix+1, line_used | lst[i]): return true
		column_used[x] &= ~lst[i]
		box_used[bix] &= ~lst[i]
	cell_bit[ix] = 0
	return false;
func gen_ans():		# 解答生成
	for i in range(N_CELLS):
		#clue_labels[i].text = "?"
		input_labels[i].text = ""
	for i in range(box_used.size()): box_used[i] = 0
	for i in range(cell_bit.size()): cell_bit[i] = 0
	var t = []
	for i in range(N_HORZ): t.push_back(1<<i)
	t.shuffle()
	for i in range(N_HORZ):
		cell_bit[i] = t[i]
		column_used[i] = t[i]
		box_used[i/3] |= t[i]
	#print(cell_bit)
	gen_ans_sub(N_HORZ, 0)
	print_cells()
	#update_cell_labels()
	ans_bit = cell_bit.duplicate()
	for i in range(N_CELLS): input_labels[i].text = ""		# 入力ラベル全消去
	#for i in range(N_CELLS): input_labels[i].text = bit_to_numstr(cell_bit[i])
	pass
func print_cells():
	var ix = 0
	for y in range(N_VERT):
		var lst = []
		for x in range(N_HORZ):
			lst.push_back(bit_to_num(cell_bit[ix]))
			ix += 1
		print(lst)
	print("")
func gen_cages_3x2():
	for i in range(N_CELLS): cage_labels[i].text = ""
	cage_list = []
	for y in range(0, N_VERT, N_VERT/3):
		for x in range(0, N_HORZ, N_HORZ/2):
			var ix = xyToIX(x, y)
			if rng.randf_range(0.0, 1.0) < 0.5:
				# 縦＋横*2行
				cage_list.push_back([0, [ix, ix+N_HORZ]])
				cage_list.push_back([0, [ix+1, ix+2]])
				cage_list.push_back([0, [ix+N_HORZ+1, ix+N_HORZ+2]])
			else:
				# 横*2行＋縦
				cage_list.push_back([0, [ix, ix+1]])
				cage_list.push_back([0, [ix+N_HORZ, ix+N_HORZ+1]])
				cage_list.push_back([0, [ix+2, ix+N_HORZ+2]])
	for i in range(cage_ix.size()): cage_ix[i] = -1
	for ix in range(cage_list.size()):
		var lst = cage_list[ix][1]
		for k in range(lst.size()): cage_ix[lst[k]] = ix
	$Board/CageGrid.cage_ix = cage_ix
	$Board/CageGrid.update()
func gen_cages():
	for i in range(N_CELLS): cage_labels[i].text = ""
	#quest_cages = []
	cage_list = []
	if rng.randf_range(0.0, 1.0) < 0.5:
		cage_list.push_back([0, [0, 1]])
		var ix0 = N_HORZ-1
		cage_list.push_back([0, [ix0, ix0+N_HORZ]])
		ix0 = N_HORZ * (N_VERT - 1)
		cage_list.push_back([0, [ix0, ix0-N_HORZ]])
		ix0 = N_CELLS - 1
		cage_list.push_back([0, [ix0, ix0-1]])
	else:
		cage_list.push_back([0, [0, N_HORZ]])
		var ix0 = N_HORZ-1
		cage_list.push_back([0, [ix0, ix0-1]])
		ix0 = N_HORZ * (N_VERT - 1)
		cage_list.push_back([0, [ix0, ix0+1]])
		ix0 = N_CELLS - 1
		cage_list.push_back([0, [ix0, ix0-N_HORZ]])
	#var ix0 = 0
	#var ix2 = ix0 + 1 if rng.randf_range(0.0, 1.0) < 0.5 else ix0 + N_HORZ
	#cage_list.push_back([0, [ix0, ix2]])
	#ix0 = N_HORZ - 1
	#ix2 = (ix0 - 1) if rng.randf_range(0.0, 1.0) < 0.5 else ix0 + N_HORZ
	#cage_list.push_back([0, [ix0, ix2]])
	#ix0 = N_HORZ * (N_VERT - 1)
	#ix2 = (ix0 + 1) if rng.randf_range(0.0, 1.0) < 0.5 else ix0 - N_HORZ
	#cage_list.push_back([0, [ix0, ix2]])
	#ix0 = N_HORZ * N_VERT - 1
	#ix2 = (ix0 - 1) if rng.randf_range(0.0, 1.0) < 0.5 else ix0 - N_HORZ
	#cage_list.push_back([0, [ix0, ix2]])
	for i in range(cage_ix.size()): cage_ix[i] = -1
	for ix in range(cage_list.size()):
		var lst = cage_list[ix][1]
		for k in range(lst.size()): cage_ix[lst[k]] = ix
	#
	var ar = []
	for ix in range(N_CELLS): ar.push_back(ix)
	ar.shuffle()
	for i in range(ar.size()):
		var ix = ar[i]
		if cage_ix[ix] < 0:	# 未分割の場合
			var x = ix % N_HORZ
			var y = ix / N_HORZ
			var lst0 = []	# 空欄リスト
			var lst1 = []	# １セルケージリスト
			var lst2 = []	# ２セルケージリスト
			if y != 0:
				var i2 = xyToIX(x, y-1)
				if cage_ix[i2] < 0: lst0.push_back(i2)
				elif cage_list[cage_ix[i2]][1].size() == 2: lst2.push_back(i2)
			if x != 0:
				var i2 = xyToIX(x-1, y)
				if cage_ix[i2] < 0: lst0.push_back(i2)
				elif cage_list[cage_ix[i2]][1].size() == 2: lst2.push_back(i2)
			if x != N_HORZ-1:
				var i2 = xyToIX(x+1, y)
				if cage_ix[i2] < 0: lst0.push_back(i2)
				elif cage_list[cage_ix[i2]][1].size() == 2: lst2.push_back(i2)
			if y != N_VERT-1:
				var i2 = xyToIX(x, y+1)
				if cage_ix[i2] < 0: lst0.push_back(i2)
				elif cage_list[cage_ix[i2]][1].size() == 2: lst2.push_back(i2)
			#if ix == 13 || ix == 14:
			#	print("ix = ", ix)
			if !lst0.empty():	# ４近傍に未分割セルがある場合
				var ix2 = lst0[0] if lst0.size() == 1 else lst0[rng.randi_range(0, lst0.size() - 1)]
				#cage_list.back()[1].push_back(i2)
				cage_ix[ix] = cage_list.size()
				cage_ix[ix2] = cage_list.size()
				cage_list.push_back([0, [ix, ix2]])
			elif !lst2.empty():	# ４近傍に２セルのケージがある場合
				# ２セルのケージに ix をマージ
				var i2 = lst2[0] if lst2.size() == 1 else lst2[rng.randi_range(0, lst2.size() - 1)]
				var lstx = cage_ix[i2]
				cage_list[lstx][1].push_back(ix)
				cage_ix[ix] = lstx
			else:
				cage_ix[ix] = cage_list.size()
				cage_list.push_back([0, [ix]])
	for ix in range(cage_list.size()):
		var item = cage_list[ix]
		var sum = 0
		var lst = item[1]
		for k in range(lst.size()):
			sum += bit_to_num(cell_bit[lst[k]])
		item[0] = sum
		#print(cage_list[ix])
		cage_labels[lst.min()].text = String(sum)
		#for k in range(lst.size()): cage_ix[lst[k]] = ix
	$Board/CageGrid.cage_ix = cage_ix
	$Board/CageGrid.update()
# cix: cage_list's index, lix: ix_list's index, ub: used bits in the cage
func ipq_sub(cix, lix, ub, sum) -> bool:	# false for 解の個数が２以上
	if cix == cage_list.size():
		nAnswer += 1
		print(nAnswer, ":")
		print_cells()	# cell_bit の内容を表示
	else:
		var cage = cage_list[cix]
		var ix = cage[CAGE_IX_LIST][lix]
		var x = ix % N_HORZ
		var y = ix / N_HORZ
		var x3 = x / 3
		var y2 = y / 2
		var bix = y2 * 2 + x3
		var bits = ~(ub | line_used[y] | column_used[x] | box_used[bix]) & ALL_BITS
		if !bits: return true		# 配置可能ビット無し
		if lix == cage[CAGE_IX_LIST].size() - 1:		# 最後のセルの場合
			var n = cage[CAGE_SUM] - sum
			var b = num_to_bit(n)
			if n <= 0 || (bits&b) == 0:
				return true
			line_used[y] |= b
			column_used[x] |= b
			box_used[bix] |= b
			cell_bit[ix] = b
			if !ipq_sub(cix+1, 0, 0, 0):
				return false
			line_used[y] ^= b
			column_used[x] ^= b
			box_used[bix] ^= b
		else:	# 最後のセルでない場合
			while bits != 0:
				var b = -bits & bits		# 最も小さい１のビット
				bits ^= b					# b のビットを消去
				line_used[y] |= b
				column_used[x] |= b
				box_used[bix] |= b
				cell_bit[ix] = b
				if !ipq_sub(cix, lix+1, (ub | b), sum+bit_to_num(b)):
					return false
				line_used[y] ^= b
				column_used[x] ^= b
				box_used[bix] ^= b
		cell_bit[ix] = 0
	return nAnswer < 2
# cage_list をチェック、手がかり数字は無し
func is_proper_quest() -> bool:
	nAnswer = 0
	for ix in range(N_CELLS): cell_bit[ix] = 0
	for ix in range(N_HORZ):
		line_used[ix] = 0
		column_used[ix] = 0
		box_used[ix] = 0
	ipq_sub(0, 0, 0, 0)
	return nAnswer == 1
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
func is_duplicated(ix : int):
	var n = get_cell_numer(ix)
	if n == 0: return false
	var x = ix % N_HORZ
	var y = ix / N_HORZ
	for t in range(N_HORZ):
		if t != x && get_cell_numer(xyToIX(t, y)) == n:
			return true
		if t != y && get_cell_numer(xyToIX(x, t)) == n:
			return true
	var x0 = x - x % 3		# 3x2ブロック左上位置
	var y0 = y - y % 2
	for v in range(2):
		for h in range(3):
			var ix3 = xyToIX(x0+h, y0+v)
			if ix3 != ix && get_cell_numer(ix3) == n:
				return true
	return false
func check_duplicated():
	nDuplicated = 0
	for ix in range(N_CELLS):
		if is_duplicated(ix):
			nDuplicated += 1
			clue_labels[ix].add_color_override("font_color", COLOR_DUP)
			input_labels[ix].add_color_override("font_color", COLOR_DUP)
		else:
			clue_labels[ix].add_color_override("font_color", COLOR_CLUE)
			input_labels[ix].add_color_override("font_color", COLOR_INPUT)
	pass
func check_cages():		# 必ず check_duplicated() の直後にコールすること
	for i in range(cage_list.size()):
		var ixs = cage_list[i][1]
		var sum = 0
		for k in range(ixs.size()):
			var n = get_cell_numer(ixs[k])
			if n == 0:
				sum = 0
				break
			sum += n
		if sum != 0 && sum != cage_list[i][0]:
			nDuplicated += 1
			for k in range(ixs.size()):
				input_labels[ixs[k]].add_color_override("font_color", COLOR_DUP)
	pass
func update_num_buttons_disabled():		# 使い切った数字ボタンをディセーブル
	#var nUsed = []		# 各数字の使用数 [0] for EMPTY
	for i in range(N_HORZ+1): num_used[i] = 0
	for ix in range(N_CELLS):
		num_used[get_cell_numer(ix)] += 1
	for i in range(N_HORZ):
		num_buttons[i+1].disabled = num_used[i+1] >= N_HORZ
func update_undo_redo():
	$UndoButton.disabled = undo_ix == 0
	$RedoButton.disabled = undo_ix == undo_stack.size()
func push_to_undo_stack(item):
	if undo_stack.size() > undo_ix:
		undo_stack.resize(undo_ix)
	undo_stack.push_back(item)
	undo_ix += 1
func sound_effect():
	if sound:
		if input_num > 0 && num_used[input_num] >= N_HORZ:
			$AudioNumCompleted.play()
		else:
			$AudioNumClicked.play()
func clear_cell_cursor():
	for y in range(N_VERT):
		for x in range(N_HORZ):
			$Board/TileMap.set_cell(x, y, TILE_NONE)
func reset_TileMap():
	for y in range(N_VERT):
		for x in range(N_HORZ):
			$Board/TileMap.set_cell(x, y, TILE_NONE)
func do_emphasize(ix : int, type, fullhouse):
	reset_TileMap()
	if paused: return
	var x = ix % N_HORZ
	var y = ix / N_HORZ
	if type == CELL || fullhouse:
		$Board/TileMap.set_cell(x, y, TILE_CURSOR)
	pass
func add_falling_char(num_str, ix : int):
	pass
func add_falling_memo(num : int, ix : int):
	pass
func get_cell_numer(ix) -> int:		# ix 位置に入っている数字の値を返す、0 for 空欄
	if clue_labels[ix].text != "":
		return int(clue_labels[ix].text)
	if input_labels[ix].text != "":
		return int(input_labels[ix].text)
	return 0
func get_memo_bits(ix) -> int:
	var bits = 0
	var mask = BIT_1
	for i in range(N_HORZ):
		if memo_labels[ix][i].text != "": bits |= mask
		mask <<= 1
	return bits
func update_cell_cursor(num):		# 選択数字ボタンと同じ数字セルを強調
	if num > 0 && !paused:
		var num_str = String(num)
		for y in range(N_VERT):
			for x in range(N_HORZ):
				var ix = xyToIX(x, y)
				if num != 0 && get_cell_numer(ix) == num:
					$Board/TileMap.set_cell(x, y, TILE_CURSOR)
				else:
					$Board/TileMap.set_cell(x, y, TILE_NONE)
				for v in range(3):
					for h in range(3):
						var n = v * 3 + h + 1
						var t = TILE_NONE
						if memo_labels[ix][n-1].text == num_str:
							t = TILE_CURSOR
						##$Board/MemoTileMap.set_cell(x*3+h, y*3+v, t)
	else:
		for y in range(N_VERT):
			for x in range(N_HORZ):
				$Board/TileMap.set_cell(x, y, TILE_NONE)
				##for v in range(3):
				##	for h in range(3):
				##		$Board/MemoTileMap.set_cell(x*3+h, y*3+v, TILE_NONE)
		if cur_cell_ix >= 0:
			do_emphasize(cur_cell_ix, CELL, false)
	pass
func set_num_cursor(num):	# 当該ボタンだけを選択状態に
	cur_num = num
	for i in range(num_buttons.size()):
		num_buttons[i].pressed = (i == num)
func update_all_status():
	##update_undo_redo()
	update_cell_cursor(cur_num)
	##update_NEmptyLabel()
	update_num_buttons_disabled()
	check_duplicated()
	check_cages()
func update_nEmpty():
	nEmpty = 0
	for ix in range(N_CELLS):
		if get_cell_numer(ix) == 0: nEmpty += 1
func is_solved():
	update_nEmpty()
	return nEmpty == 0 && nDuplicated == 0
func _process(delta):
	if !solvedStat:
		elapsedTime += delta
		var sec = int(elapsedTime)
		var h = sec / (60*60)
		sec -= h * (60*60)
		var m = sec / 60
		sec -= m * 60
		$TimeLabel.text = "%02d:%02d:%02d" % [h, m, sec]
	pass
func on_solved():
	solvedStat = true
	if sound:
		$AudioSolved.play()		# （どんっ）効果音再生
	pass
func remove_all_memo_at(ix):
	for i in range(N_HORZ):
		if memo_labels[ix][i].text != "":
			add_falling_memo(int(memo_labels[ix][i].text), ix)
			memo_labels[ix][i].text = ""
func remove_all_memo():
	for ix in range(N_CELLS):
		for i in range(N_HORZ):
			if memo_labels[ix][i].text != "":
				add_falling_memo(int(memo_labels[ix][i].text), ix)
				memo_labels[ix][i].text = ""
	for v in range(N_VERT*3):
		for h in range(N_HORZ*3):
			$Board/MemoTileMap.set_cell(h, v, TILE_NONE)
func remove_memo_num(ix : int, num : int):		# ix に num を入れたときに、メモ数字削除
	var lst = []
	var x = ix % N_HORZ
	var y = ix / N_HORZ
	for h in range(N_HORZ):
		var ix2 = xyToIX(h, y)
		if memo_labels[ix2][num-1].text != "":
			add_falling_memo(num, ix2)
			memo_labels[ix2][num-1].text = ""
			lst.push_back(ix2)
		ix2 = xyToIX(x, h)
		if memo_labels[ix2][num-1].text != "":
			add_falling_memo(num, ix2)
			memo_labels[ix2][num-1].text = ""
			lst.push_back(ix2)
	var x0 = x - x % 3
	var y0 = y - y % 3
	for v in range(3):
		for h in range(3):
			var ix2 = xyToIX(x0 + h, y0 + v)
			if memo_labels[ix2][num-1].text != "":
				add_falling_memo(num, ix2)
				memo_labels[ix2][num-1].text = ""
				lst.push_back(ix2)
	return lst
func flip_memo_num(ix : int, num : int):
	if memo_labels[ix][num-1].text == "":
		memo_labels[ix][num-1].text = String(num)
	else:
		add_falling_memo(int(memo_labels[ix][num-1].text), ix)
		memo_labels[ix][num-1].text = ""
func clear_all_memo(ix):
	for i in range(N_HORZ): memo_labels[ix][i].text = ""
func _input(event):
	if menuPopuped: return
	if event is InputEventMouseButton && event.is_pressed():
		if event.button_index == BUTTON_WHEEL_UP || event.button_index == BUTTON_WHEEL_DOWN:
				return
		##if paused: return
		var mp = $Board/TileMap.world_to_map($Board/TileMap.get_local_mouse_position())
		#print(mp)
		if mp.x < 0 || mp.x >= N_HORZ || mp.y < 0 || mp.y >= N_VERT:
			return		# 盤面セル以外の場合
		input_num = -1
		var ix = xyToIX(mp.x, mp.y)
		if clue_labels[ix].text != "":
			# undone: 手がかり数字ボタン選択
			num_button_pressed(int(clue_labels[ix].text), true)
		else:
			if cur_num < 0:			# 数字ボタン非選択の場合
				clear_cell_cursor()
				if ix == cur_cell_ix:
					cur_cell_ix = -1
				else:
					cur_cell_ix = ix
					do_emphasize(ix, CELL, false)
				update_all_status()
				return
			if cur_num == 0:	# 削除ボタン選択中
				if input_labels[ix].text != "":
					##add_falling_char(input_labels[ix].text, ix)
					#push_to_undo_stack([UNDO_TYPE_CELL, ix, int(input_labels[ix].text), 0, [], 0])		# ix, old, new
					input_labels[ix].text = ""
				else:
					for i in range(N_HORZ):
						if memo_labels[ix][i].text != "":
					#		add_falling_memo(int(memo_labels[ix][i].text), ix)
							memo_labels[ix][i].text = ""	# メモ数字削除
					pass
			# 数字ボタン選択状態の場合 → セルにその数字を入れる or メモ数字反転
			elif !memo_mode:
				if input_labels[ix].text != "":
					add_falling_char(input_labels[ix].text, ix)
				var num_str = String(cur_num)
				if input_labels[ix].text == num_str:	# 同じ数字が入っていれば消去
					##push_to_undo_stack([UNDO_TYPE_CELL, ix, int(cur_num), 0, [], 0])		# ix, old, new
					input_labels[ix].text = ""
				else:	# 上書き
					input_num = int(cur_num)
					##var lst = remove_memo_num(ix, cur_num)
					#var mb = get_memo_bits(ix)
					#push_to_undo_stack([UNDO_TYPE_CELL, ix, int(input_labels[ix].text), input_num, lst, mb])
					input_labels[ix].text = num_str
				for i in range(N_HORZ): memo_labels[ix][i].text = ""	# メモ数字削除
				pass
		update_all_status()
		sound_effect()
		if !solvedStat && is_solved():
			on_solved()
	if event is InputEventKey && event.is_pressed():
		#print(event.as_text())
		if paused: return
		##if event.as_text() != "Alt" && hint_showed:
		##	close_hint()
		##	return
		if event.as_text() == "W" :
			shock_wave_timer = 0.0      # start shock wave
		var n = int(event.as_text())
		if n >= 1 && n <= 9:
			num_button_pressed(n, true)
	pass
func num_button_pressed(num : int, button_pressed):
	#print("num = ", num)
	if in_button_pressed: return		# ボタン押下処理中の場合
	if paused: return			# ポーズ中
	in_button_pressed = true
	if cur_cell_ix >= 0:		# セルが選択されている場合
		if num == 0:			# 削除ボタン押下の場合
			var old = get_cell_numer(cur_cell_ix)
			if old != 0:
				##add_falling_char(input_labels[cur_cell_ix].text, cur_cell_ix)
				##push_to_undo_stack([UNDO_TYPE_CELL, cur_cell_ix, old, 0, [], 0])
				input_labels[cur_cell_ix].text = ""
			##else:
			##	remove_all_memo_at(cur_cell_ix)
		else:
			if !memo_mode:
				if button_pressed:
					var old = get_cell_numer(cur_cell_ix)
					if old != 0:
						add_falling_char(input_labels[cur_cell_ix].text, cur_cell_ix)
					if num == old:		# 同じ数字を入れる → 削除
						##push_to_undo_stack([UNDO_TYPE_CELL, cur_cell_ix, old, 0, [], 0])
						input_labels[cur_cell_ix].text = ""
					else:
						input_num = num
						var lst = remove_memo_num(cur_cell_ix, num)
						var mb = get_memo_bits(cur_cell_ix)
						push_to_undo_stack([UNDO_TYPE_CELL, cur_cell_ix, old, num, lst, mb])
						#undo_stack.back().back() = lst
						input_labels[cur_cell_ix].text = String(num)
					for i in range(N_HORZ):
						if memo_labels[cur_cell_ix][i].text != "":
							add_falling_memo(int(memo_labels[cur_cell_ix][i].text), cur_cell_ix)
							memo_labels[cur_cell_ix][i].text = ""
					num_buttons[num].pressed = false
					update_all_status()
					sound_effect()
					if !solvedStat && is_solved():
						on_solved()
				pass
		pass
	else:	# セルが選択されていない場合
		if button_pressed:
			set_num_cursor(num)
		else:
			cur_num = -1		# toggled
		update_cell_cursor(cur_num)
	in_button_pressed = false
	update_all_status()
	pass
func _on_DeleteButton_toggled(button_pressed):
	num_button_pressed(0, button_pressed)
func _on_Button1_toggled(button_pressed):
	num_button_pressed(1, button_pressed)
func _on_Button2_toggled(button_pressed):
	num_button_pressed(2, button_pressed)
func _on_Button3_toggled(button_pressed):
	num_button_pressed(3, button_pressed)
func _on_Button4_toggled(button_pressed):
	num_button_pressed(4, button_pressed)
func _on_Button5_toggled(button_pressed):
	num_button_pressed(5, button_pressed)
func _on_Button6_toggled(button_pressed):
	num_button_pressed(6, button_pressed)

func _on_DeselectButton_pressed():
	if paused: return		# ポーズ中
	cur_cell_ix = -1
	update_cell_cursor(0)
	#cur_num = -1
	set_num_cursor(-1)
	update_all_status()
