class_name Player
extends CharacterBody3D

const SPEED := 7.0
const JUMP_VELOCITY := 5.5
const JUMP_GRAVITY := 15.0
const FALL_GRAVITY := 23.0
const HURT_DURATION := 0.25
const MAX_HP := 100
const HEAL_RATE := 15.0
const SHOT_SCENE := preload("res://shot/shot.tscn")
const STARTING_LIVES := 3
const KO_DURATION := 1.5
const GUARD_DURATION := 1.5
const GUARD_COOLDOWN := 2.0
const PARRY_COOLDOWN := 0.5
const MOVES := {
	State.LAUNCHER: {
		"duration" = 0.6,
		"startup" = 0.2,
		"damage" = 10,
		"launch_force" = 11.0,
	},
	State.LINKER: {
		"duration" = 0.75,
		"startup" = 0.2,
		"damage" = 7,
		"launch_force" = 8.0,
		"speed" = 13.0,
		"decay" = 0.7,
		"recovery_duration" = 0.25,
		"bounce_force_xz" = 12.0,
		"bounce_force_y" = -4.0,
		"hitstop_duration" = 0.16,
		"parry_range" = 3.5,
	},
		State.FINISHER: {
		"duration" = 0.4,
		"startup" = 0.13,
		"damage" = 5,
		"final_hit_duration" = 0.53,
		"final_hit_damage" = 35,
		"knockback_force" = 20.0,
		"max_meter" = 3,
		"hitstop_duration" = 0.10,
		"freeze_duration" = 0.5,
	},
	State.SHOT: {
		"duration" = 0.5,
		"startup" = 0.08,
	},
	State.HEAVY: {
		"duration" = 1.07,
		"startup" = 0.33,
		"damage" = 8,
		"knockback_force" = 15.0,
	},
}

var state := State.IDLE
var attack_timer := 0.0
var combo_count := 0
var hp := MAX_HP
var keys := {}
var launched := false
var heal_buffer := 0.0
var opponent: CharacterBody3D
var air_shot_used := false
var lives := STARTING_LIVES
var ko_timer := 0.0
var guard_timer := 0.0
var guard_cooldown_timer := 0.0
var link_count := 0
var hitstop_timer := 0.0
var finisher_meter := 0
var metered_finisher := false
var parryable := false
var parry_cooldown_timer := 0.0
var link_winding_up := false
var combo_hits := 0

signal hp_changed(new_hp: int)
signal defeated()
signal finisher_meter_changed(new_finsher_meter: int)
signal hit_landed()
signal combo_changed(hits: int)

enum State {IDLE, MOVE, JUMP, FALL, LAND, HEAVY, LAUNCHER, LINKER, FINISHER, HURT, GUARD, HEAL, SHOT, KO}

@onready var camera := get_viewport().get_camera_3d()
@export var input_prefix := "p1_"

func _fire_shot() -> void:
	var shot := SHOT_SCENE.instantiate()
	shot.player_owner = self
	shot.direction = _direction_to(opponent)
	shot.global_position = global_position
	get_parent().add_child(shot)


func _check_action_triggers() -> void:
	if Input.is_action_just_pressed(keys["jump"]):
		velocity.y = JUMP_VELOCITY
		state = State.JUMP
	elif Input.is_action_just_pressed(keys["attack_heavy"]):
		attack_timer = MOVES[State.HEAVY]["duration"]
		state = State.HEAVY
	elif Input.is_action_just_pressed(keys["attack_launcher"]):
		attack_timer = MOVES[State.LAUNCHER]["duration"]
		state = State.LAUNCHER
	elif Input.is_action_just_pressed(keys["attack_linker"]) and opponent.state == State.HURT and opponent.launched:
		attack_timer = MOVES[State.LINKER]["duration"]
		state = State.LINKER
	elif Input.is_action_just_pressed(keys["attack_finisher"]):
		attack_timer = MOVES[State.FINISHER]["duration"]
		combo_count = 1
		metered_finisher = (finisher_meter == MOVES[State.FINISHER]["max_meter"])
		state = State.FINISHER
	elif Input.is_action_just_pressed(keys["guard"]) and guard_cooldown_timer <= 0:
		guard_timer = GUARD_DURATION
		state = State.GUARD
	elif Input.is_action_pressed(keys["heal"]):
		state = State.HEAL
	elif Input.is_action_just_pressed(keys["attack_shot"]):
		attack_timer = MOVES[State.SHOT]["duration"]
		_fire_shot()
		state = State.SHOT


func _check_air_action_triggers() -> void:
	if Input.is_action_just_pressed(keys["attack_shot"]) and not air_shot_used:
		_fire_shot()
		air_shot_used = true


func _tick_attack(delta: float, startup: float, duration: float) -> bool:
	velocity.x = 0
	velocity.z = 0
	attack_timer -= delta

	if attack_timer < duration - startup and not $Hitbox.monitoring:
		$Hitbox.monitoring = true

	return attack_timer <= 0


func take_damage(amount: int, knockback: Vector3, bypass_guard: bool = false) -> void:
	if state == State.GUARD:
		if not bypass_guard:
			return

		guard_cooldown_timer = GUARD_COOLDOWN

	if state == State.KO:
		return

	hit_landed.emit()

	if state != State.HURT:
		combo_hits = 0

	combo_hits += 1
	combo_changed.emit(combo_hits)
	hp = max(hp - amount, 0)
	hp_changed.emit(hp)

	if hp == 0:
		state = State.KO
		lives -= 1

		if lives == 0:
			defeated.emit()

			return

		ko_timer = KO_DURATION

		return

	velocity = knockback
	launched = knockback.y > 0
	attack_timer = HURT_DURATION
	state = State.HURT


func link_parried() -> void:
	$Hitbox.monitoring = false
	parryable = false
	state = State.FALL
	link_winding_up = false


func _away_from(target: CharacterBody3D, force: float) -> Vector3:
	var dir := target.global_position - global_position
	dir.y = 0
	
	return dir.normalized() * force


func _direction_to(target: CharacterBody3D) -> Vector3:
	var dir := target.global_position - global_position
	dir.y = 0
	
	return dir.normalized()


func _on_hitbox_area_entered(area: Area3D) -> void:
	var victim := area.get_parent() as CharacterBody3D

	if victim == self:
		return # stop hitting yourself lol
	
	var stats: Dictionary = MOVES[state]
	var damage: int = stats["damage"]
	var knockback := Vector3.ZERO

	if state == State.HEAVY:
		damage = stats["damage"]
		knockback = _away_from(victim, stats["knockback_force"])
	elif state == State.LAUNCHER:
		damage = stats["damage"]
		knockback = Vector3.UP * stats["launch_force"]
		link_count = 0
	elif state == State.LINKER:
		damage = stats["damage"]
		knockback = Vector3.UP * stats["launch_force"] * pow(stats["decay"], link_count)
		var dir := (global_position - victim.global_position)
		dir.y = 0
		velocity = dir.normalized() * stats["bounce_force_xz"]
		velocity.y = stats["bounce_force_y"]
		attack_timer = MOVES[State.LINKER]["recovery_duration"]
		$Hitbox.monitoring = false
		link_count += 1
		hitstop_timer = MOVES[State.LINKER]["hitstop_duration"]
		victim.hitstop_timer = MOVES[State.LINKER]["hitstop_duration"]
		finisher_meter = min(finisher_meter + 1, MOVES[State.FINISHER]["max_meter"])
		finisher_meter_changed.emit(finisher_meter)
	elif state == State.FINISHER and combo_count == 1 and metered_finisher:
		damage = stats["damage"]
		finisher_meter = 0
		finisher_meter_changed.emit(finisher_meter)
	elif state == State.FINISHER and combo_count == 3:
		damage = stats["final_hit_damage"]
		knockback = _away_from(victim, stats["knockback_force"])

	if state == State.FINISHER and metered_finisher:
		hitstop_timer = MOVES[State.FINISHER]["hitstop_duration"]

		if combo_count < 3:
			victim.hitstop_timer = MOVES[State.FINISHER]["freeze_duration"]
		else:
			victim.hitstop_timer = MOVES[State.FINISHER]["hitstop_duration"]

	victim.take_damage(damage, knockback, state == State.HEAVY)


func _ready() -> void:
	keys = {
		"move_left": input_prefix + "move_left",
		"move_right": input_prefix + "move_right",
		"move_up": input_prefix + "move_up",
		"move_down": input_prefix + "move_down",
		"jump": input_prefix + "jump",
		"attack_heavy": input_prefix + "attack_heavy",
		"attack_launcher": input_prefix + "attack_launcher",
		"attack_linker": input_prefix + "attack_linker",
		"attack_finisher": input_prefix + "attack_finisher",
		"guard": input_prefix + "guard",
		"heal": input_prefix + "heal",
		"attack_shot": input_prefix + "attack_shot",
	}

	$Hitbox.area_entered.connect(_on_hitbox_area_entered)
	
	for node in get_parent().get_children():
		if node is CharacterBody3D and node != self:
			opponent = node
			break


func _physics_process(delta: float) -> void:
	if hitstop_timer > 0:
		hitstop_timer -= delta
		return

	if not is_on_floor():
		var g = FALL_GRAVITY if velocity.y < 0 else JUMP_GRAVITY
		velocity.y -= g * delta

	var input_dir := Input.get_vector(keys["move_left"], keys["move_right"], keys["move_up"], keys["move_down"])
	var direction := (Vector3(input_dir.x, 0, input_dir.y)).rotated(Vector3.UP, camera.rotation.y).normalized()
	guard_cooldown_timer = max(guard_cooldown_timer - delta, 0)
	parry_cooldown_timer = max(parry_cooldown_timer - delta, 0)

	match state:
		State.MOVE:
			velocity.x = direction.x * SPEED
			velocity.z = direction.z * SPEED

			if not direction:
				state = State.IDLE

			if not is_on_floor():
				state = State.FALL
				return

			_check_action_triggers()
		State.IDLE:
			velocity.x = 0
			velocity.z = 0

			if direction:
				state = State.MOVE
			
			if not is_on_floor():
				state = State.FALL
				return
			
			_check_action_triggers()
		State.JUMP:
			velocity.x = direction.x * SPEED
			velocity.z = direction.z * SPEED
			_check_air_action_triggers()

			if velocity.y <= 0:
				state = State.FALL
		State.FALL:
			velocity.x = direction.x * SPEED
			velocity.z = direction.z * SPEED
			_check_air_action_triggers()

			if is_on_floor():
				state = State.LAND
		State.LAND:
			if direction:
				state = State.MOVE
			else:
				state = State.IDLE

			air_shot_used = false
		State.HEAVY:
			if _tick_attack(delta, MOVES[State.HEAVY]["startup"], MOVES[State.HEAVY]["duration"]):
				$Hitbox.monitoring = false
				state = State.IDLE
		State.LAUNCHER:
			if _tick_attack(delta, MOVES[State.LAUNCHER]["startup"], MOVES[State.LAUNCHER]["duration"]):
				$Hitbox.monitoring = false
				state = State.IDLE
		State.LINKER:
			if attack_timer > MOVES[State.LINKER]["duration"] - MOVES[State.LINKER]["startup"]:
				velocity.x = 0
				velocity.z = 0
				parryable = false
				link_winding_up = true
			elif attack_timer > MOVES[State.LINKER]["recovery_duration"]:
				var dir := (opponent.global_position - global_position).normalized()
				velocity = dir * MOVES[State.LINKER]["speed"]
				$Hitbox.monitoring = true
				parryable = global_position.distance_to(opponent.global_position) < MOVES[State.LINKER]["parry_range"]
				link_winding_up = false
			else:
				parryable = false
				link_winding_up = false

			attack_timer -= delta

			if attack_timer <= 0:
				$Hitbox.monitoring = false
				state = State.FALL
		State.FINISHER:
			var final_hit_duration: float = MOVES[State.FINISHER]["final_hit_duration"] if combo_count == 3 else MOVES[State.FINISHER]["duration"]
			var expired := _tick_attack(delta, MOVES[State.FINISHER]["startup"], final_hit_duration)

			if expired:
				$Hitbox.monitoring = false

				if metered_finisher and combo_count < 3:
					combo_count += 1

					if combo_count == 3:
						attack_timer = MOVES[State.FINISHER]["final_hit_duration"]
					else:
						attack_timer = MOVES[State.FINISHER]["duration"]
				else:
					combo_count = 0
					metered_finisher = false
					state = State.IDLE
		State.HURT:
			if launched:
				if Input.is_action_just_pressed(keys["guard"]) and parry_cooldown_timer <= 0:
					if opponent.parryable:
						launched = false
						velocity.x = 0
						velocity.z = 0
						state = State.FALL
						opponent.link_parried()
					else:
						parry_cooldown_timer = PARRY_COOLDOWN

				if is_on_floor() and velocity.y <= 0:
					velocity.x = 0
					velocity.z = 0
					launched = false
					state = State.IDLE
			else:
				attack_timer -= delta

				if attack_timer <= 0:
					velocity.x = 0
					velocity.z = 0
					state = State.IDLE
		State.GUARD:
			velocity.x = 0
			velocity.z = 0
			guard_timer -= delta

			if guard_timer <= 0 or not Input.is_action_pressed(keys["guard"]):
				guard_cooldown_timer = GUARD_COOLDOWN
				state = State.IDLE
		State.HEAL:
			velocity.x = 0
			velocity.z = 0
			heal_buffer += HEAL_RATE * delta
			var whole := int(heal_buffer)

			if whole > 0:
				hp = min(hp + whole, MAX_HP)
				hp_changed.emit(hp)
				heal_buffer -= whole

			if not Input.is_action_pressed(keys["heal"]):
				heal_buffer = 0.0
				state = State.IDLE
		State.SHOT:
			velocity.x = 0
			velocity.z = 0
			attack_timer -= delta

			if attack_timer <= 0:
				state = State.IDLE
		State.KO:
			velocity.x = 0
			velocity.z = 0
			ko_timer -= delta

			if lives > 0 and ko_timer <= 0:
				hp = MAX_HP
				hp_changed.emit(hp)
				finisher_meter = 0
				finisher_meter_changed.emit(finisher_meter)
				state = State.IDLE
			
	move_and_slide()
