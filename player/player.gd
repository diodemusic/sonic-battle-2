extends CharacterBody3D


const SPEED = 5.0
const JUMP_VELOCITY = 4.5
const HURT_DURATION = 0.25
const MOVES = {
	State.JAB: {
		"duration" = 0.25,
		"startup" = 0.05,
		"damage" = 5,
		"finisher_damage" = 15,
		"knockback_force" = 10.0,
	},
	State.HEAVY: {
		"duration" = 0.55,
		"startup" = 0.1,
		"damage" = 15,
		"knockback_force" = 12.0,
	},
	State.UPPER: {
		"duration" = 0.5,
		"startup" = 0.08,
		"damage" = 10,
		"launch_force" = 7.0,
	},
}

var state := State.IDLE
var attack_timer := 0.0
var combo_count := 0
var attack_buffered := false
var hp := 100
var keys := {}
var launched := false

enum State {IDLE, MOVE, JUMP, FALL, LAND, JAB, HEAVY, UPPER, HURT}

@onready var camera := get_viewport().get_camera_3d()
@export var input_prefix := "p1_"


func _tick_attack(stats: Dictionary, delta: float) -> bool:
	velocity.x = 0
	velocity.z = 0
	attack_timer -= delta

	if attack_timer < stats["duration"] - stats["startup"] and not $Hitbox.monitoring:
		$Hitbox.monitoring = true

	return attack_timer <= 0


func take_damage(amount: int, knockback: Vector3) -> void:
	hp -= amount
	velocity = knockback
	launched = knockback.y > 0
	attack_timer = HURT_DURATION
	state = State.HURT

	print(self.name, " hp: ", hp)


func _away_from(opponent: CharacterBody3D, force: float) -> Vector3:
	var dir := opponent.global_position - global_position
	dir.y = 0
	
	return dir.normalized() * force


func _on_hitbox_area_entered(area: Area3D) -> void:
	var opponent := area.get_parent() as CharacterBody3D

	if opponent == self:
		return # stop hitting yourself lol
	
	var stats: Dictionary = MOVES[state]
	var damage: int = stats["damage"]
	var knockback := Vector3.ZERO

	if state == State.JAB and combo_count == 3:
		damage = stats["finisher_damage"]
		knockback = _away_from(opponent, stats["knockback_force"])
	elif state == State.HEAVY:
		damage = stats["damage"]
		knockback = _away_from(opponent, stats["knockback_force"])
	elif state == State.UPPER:
		damage = stats["damage"]
		knockback = Vector3.UP * stats["launch_force"]

	opponent.take_damage(damage, knockback)


func _ready() -> void:
	keys = {
		"move_left": input_prefix + "move_left",
		"move_right": input_prefix + "move_right",
		"move_up": input_prefix + "move_up",
		"move_down": input_prefix + "move_down",
		"jump": input_prefix + "jump",
		"attack_jab": input_prefix + "attack_jab",
		"attack_heavy": input_prefix + "attack_heavy",
		"attack_upper": input_prefix + "attack_upper"
	}

	$Hitbox.area_entered.connect(_on_hitbox_area_entered)


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	var input_dir := Input.get_vector(keys["move_left"], keys["move_right"], keys["move_up"], keys["move_down"])
	var direction := (Vector3(input_dir.x, 0, input_dir.y)).rotated(Vector3.UP, camera.rotation.y).normalized()

	match state:
		State.MOVE:
			velocity.x = direction.x * SPEED
			velocity.z = direction.z * SPEED

			if not direction:
				state = State.IDLE
			
			if Input.is_action_just_pressed(keys["jump"]) and is_on_floor():
				velocity.y = JUMP_VELOCITY
				state = State.JUMP

			if not is_on_floor():
				state = State.FALL
			
			if Input.is_action_just_pressed(keys["attack_jab"]) and is_on_floor():
				attack_timer = MOVES[State.JAB]["duration"]
				combo_count = 1
				state = State.JAB

			if Input.is_action_just_pressed(keys["attack_heavy"]) and is_on_floor():
				attack_timer = MOVES[State.HEAVY]["duration"]
				state = State.HEAVY
			
			if Input.is_action_just_pressed(keys["attack_upper"]) and is_on_floor():
				attack_timer = MOVES[State.UPPER]["duration"]
				state = State.UPPER
		State.IDLE:
			velocity.x = 0
			velocity.z = 0

			if direction:
				state = State.MOVE
			
			if Input.is_action_just_pressed(keys["jump"]) and is_on_floor():
				velocity.y = JUMP_VELOCITY
				state = State.JUMP
			
			if not is_on_floor():
				state = State.FALL
			
			if Input.is_action_just_pressed(keys["attack_jab"]) and is_on_floor():
				attack_timer = MOVES[State.JAB]["duration"]
				combo_count = 1
				state = State.JAB

			if Input.is_action_just_pressed(keys["attack_heavy"]) and is_on_floor():
				attack_timer = MOVES[State.HEAVY]["duration"]
				state = State.HEAVY
			
			if Input.is_action_just_pressed(keys["attack_upper"]) and is_on_floor():
				attack_timer = MOVES[State.UPPER]["duration"]
				state = State.UPPER
		State.JUMP:
			velocity.x = direction.x * SPEED
			velocity.z = direction.z * SPEED

			if velocity.y <= 0:
				state = State.FALL
		State.FALL:
			velocity.x = direction.x * SPEED
			velocity.z = direction.z * SPEED

			if is_on_floor(): state = State.LAND
		State.LAND:
			if direction:
				state = State.MOVE
			else:
				state = State.IDLE
		State.JAB:
			var expired := _tick_attack(MOVES[State.JAB], delta)

			if Input.is_action_just_pressed(keys["attack_jab"]) and is_on_floor():
				attack_buffered = true

			if expired:
				$Hitbox.monitoring = false

				if attack_buffered and combo_count < 3:
					combo_count += 1
					attack_timer = MOVES[State.JAB]["duration"]
					attack_buffered = false
				else:
					combo_count = 0
					attack_buffered = false
					state = State.IDLE
		State.HEAVY:
			if _tick_attack(MOVES[State.HEAVY], delta):
				$Hitbox.monitoring = false
				state = State.IDLE
		State.UPPER:
			if _tick_attack(MOVES[State.UPPER], delta):
				$Hitbox.monitoring = false
				state = State.IDLE
		State.HURT:
			if launched:
				if is_on_floor():
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

	# print(State.keys()[state])

	move_and_slide()
