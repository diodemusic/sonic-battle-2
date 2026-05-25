extends Node3D


func _ready() -> void:
	$Player.hp_changed.connect($HUD._on_p1_hp_changed)
	$Player2.hp_changed.connect($HUD._on_p2_hp_changed)
