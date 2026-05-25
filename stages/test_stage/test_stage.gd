extends Node3D


func _on_p1_defeated() -> void:
	print("PLAYER 2 WINS")
	get_tree().paused = true


func _on_p2_defeated() -> void:
	print("PLAYER 1 WINS")
	get_tree().paused = true


func _ready() -> void:
	$Player.hp_changed.connect($HUD._on_p1_hp_changed)
	$Player2.hp_changed.connect($HUD._on_p2_hp_changed)
	$Player.defeated.connect(_on_p1_defeated)
	$Player2.defeated.connect(_on_p2_defeated)
