extends CanvasLayer


func _on_p1_hp_changed(hp: int) -> void:
	$P1HealthBar.value = hp

func _on_p2_hp_changed(hp: int) -> void:
	$P2HealthBar.value = hp
