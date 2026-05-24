extends CharacterBody3D


const SPEED = 5.0
const JUMP_VELOCITY = 4.5
const JAB_DURATION = 0.25
const HEAVY_DURATION = 0.55
const UPPER_DURATION = 0.5
const JAB_STARTUP = 0.05
const KNOCKBACK_FORCE = 8.0
const HURT_DURATION = 0.2

var state := State.IDLE
var attack_timer := 0.0
var combo_count := 0
var attack_buffered := false
var hp := 100

var keys := {}

enum State {IDLE, MOVE, JUMP, FALL, LAND, ATTACK, HEAVY, UPPER, HURT}

@onready var camera := get_viewport().get_camera_3d()
@export var input_prefix := "p1_"


func take_damage(amount: int, knockback: Vector3) -> void:
	hp -= amount
	velocity = knockback
	attack_timer = HURT_DURATION
	state = State.HURT

	print(self.name, " hp: ", hp)


func _on_hitbox_area_entered(area: Area3D) -> void:
	var opponent := area.get_parent() as CharacterBody3D

	if opponent == self:
		return # stop hitting yourself lol
	
	var knockback := Vector3.ZERO

	if combo_count == 3:
		var dir := opponent.global_position - global_position
		dir.y = 0
		knockback = dir.normalized() * KNOCKBACK_FORCE

	opponent.take_damage(10, knockback)


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
				attack_timer = JAB_DURATION
				combo_count = 1
				state = State.ATTACK

			if Input.is_action_just_pressed(keys["attack_heavy"]) and is_on_floor():
				attack_timer = HEAVY_DURATION
				state = State.HEAVY
			
			if Input.is_action_just_pressed(keys["attack_upper"]) and is_on_floor():
				attack_timer = UPPER_DURATION
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
				attack_timer = JAB_DURATION
				combo_count = 1
				state = State.ATTACK

			if Input.is_action_just_pressed(keys["attack_heavy"]) and is_on_floor():
				attack_timer = HEAVY_DURATION
				state = State.HEAVY
			
			if Input.is_action_just_pressed(keys["attack_upper"]) and is_on_floor():
				attack_timer = UPPER_DURATION
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
		State.ATTACK:
			velocity.x = 0
			velocity.z = 0

			attack_timer -= delta

			if attack_timer < JAB_DURATION - JAB_STARTUP and not $Hitbox.monitoring:
				$Hitbox.monitoring = true

			if Input.is_action_just_pressed(keys["attack_jab"]) and is_on_floor():
				attack_buffered = true

			if attack_timer <= 0:
				$Hitbox.monitoring = false

				if attack_buffered and combo_count < 3:
					combo_count += 1
					attack_timer = JAB_DURATION
					attack_buffered = false
				else:
					combo_count = 0
					attack_buffered = false
					state = State.IDLE
		State.HEAVY:
			velocity.x = 0
			velocity.z = 0

			attack_timer -= delta

			if attack_timer <= 0:
				state = State.IDLE
		State.UPPER:
			velocity.x = 0
			velocity.z = 0

			attack_timer -= delta

			if attack_timer <= 0:
				state = State.IDLE
		State.HURT:
			attack_timer -= delta

			if attack_timer <= 0:
				velocity.x = 0
				velocity.z = 0
				state = State.IDLE

	# print(State.keys()[state])

	move_and_slide()
