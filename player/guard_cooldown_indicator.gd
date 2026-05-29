extends Sprite3D

func _process(_delta: float) -> void:
	self.visible = get_parent().guard_cooldown_timer > 0
