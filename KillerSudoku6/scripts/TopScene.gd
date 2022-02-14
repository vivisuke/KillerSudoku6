extends Node2D

var buttons = []
onready var g = get_node("/root/Global")

func _ready():
	g.load_environment()
	if !g.env.has(g.KEY_LOGIN_DATE) || g.env[g.KEY_LOGIN_DATE] != g.today_string():
		g.env[g.KEY_LOGIN_DATE] = g.today_string()
		g.env[g.KEY_N_COINS] += g.DAYLY_N_COINS
		g.save_environment()
	$CoinButton/NCoinLabel.text = String(g.env[g.KEY_N_COINS])
	g.load_stats()
	pass # Replace with function body.


func to_LevelScene(qLevel):
	#print($LineEdit.text)
	g.qLevel = qLevel
	g.qName = ""
	g.qRandom = false	#$LineEdit.text == ""
	g.todaysQuest = false
	get_tree().change_scene("res://LevelScene.tscn")
func _on_Button3_pressed():
	to_LevelScene(0)
func _on_Button4_pressed():
	to_LevelScene(1)
func _on_Button5_pressed():
	to_LevelScene(2)
