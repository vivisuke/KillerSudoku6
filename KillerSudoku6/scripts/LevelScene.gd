extends Node2D

const N_SOLVED_QUEST = 10		# クリア済み問題数

var autoScrolled = false
var panels = []

onready var g = get_node("/root/Global")

func _ready():
	var txt = ""
	if g.qLevel == 0: txt = "入門"
	elif g.qLevel == 1: txt = "初級"
	elif g.qLevel == 2: txt = "初中級"
	txt += "問題集"
	$TitleBar/Label.text = txt
	pass # Replace with function body.

func _on_BackButton_pressed():
	get_tree().change_scene("res://TopScene.tscn")
