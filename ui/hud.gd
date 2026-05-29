extends CanvasLayer


func _on_p1_hp_changed(hp: int) -> void:
	$P1HealthBar.value = hp

func _on_p2_hp_changed(hp: int) -> void:
	$P2HealthBar.value = hp

func _on_p1_finisher_meter_changed(new_finisher_meter: int) -> void:
	var bar := $P1FinisherMeter
	$P1FinisherMeter.value = new_finisher_meter
	var col := Color.GREEN

	match new_finisher_meter:
		0:
			col = Color.WHITE
		1:
			col = Color.GREEN
		2:
			col = Color.YELLOW
		3:
			col = Color.RED
	
	bar.modulate = col


func _on_p2_finisher_meter_changed(new_finisher_meter: int) -> void:
	var bar := $P2FinisherMeter
	$P2FinisherMeter.value = new_finisher_meter
	var col := Color.GREEN

	match new_finisher_meter:
		0:
			col = Color.WHITE
		1:
			col = Color.GREEN
		2:
			col = Color.YELLOW
		3:
			col = Color.RED
	
	bar.modulate = col
