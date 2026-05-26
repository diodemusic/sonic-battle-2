extends AnimatedSprite3D


func _process(_delta: float) -> void:
	var player: Player = get_parent()

	match player.state:
		Player.State.MOVE:
			if animation == "move_start":
				if not is_playing():
					play("move")
			elif animation != "move":
				play("move_start")
		Player.State.IDLE:
			if animation != "idle":
				play("idle")
		Player.State.JUMP:
			if animation != "jump":
				play("jump")
		Player.State.FALL:
			if animation != "fall":
				play("fall")
		Player.State.LAND:
			if animation != "idle":
				play("idle")
		Player.State.JAB:
			var jab_animation := "jab" + str(player.combo_count)

			if animation != jab_animation:
				play(jab_animation)
		Player.State.HEAVY:
			if animation != "heavy":
				play("heavy")
		Player.State.UPPER:
			if animation != "upper":
				play("upper")
		Player.State.HURT:
			var hurt_animation := "hurt_air" if player.launched else "hurt"

			if animation != hurt_animation:
				play(hurt_animation)
		Player.State.GUARD:
			if animation != "guard":
				play("guard")
		Player.State.HEAL:
			if animation == "heal_start":
				if not is_playing():
					play("heal")
			elif animation != "heal":
				play("heal_start")
		Player.State.SHOT:
			if animation != "idle":
				play("idle")
		Player.State.KO:
			if animation != "ko":
				play("ko")
		_:
			if animation != "idle":
				play("idle")
