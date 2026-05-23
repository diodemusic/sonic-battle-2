extends CharacterBody3D


const SPEED = 5.0
const JUMP_VELOCITY = 4.5
const JAB_DURATION = 0.3

@onready var camera := get_viewport().get_camera_3d()

enum State {IDLE, MOVE, JUMP, FALL, LAND, ATTACK}
var state := State.IDLE
var attack_timer := 0.0

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var direction := (Vector3(input_dir.x, 0, input_dir.y)).rotated(Vector3.UP, camera.rotation.y).normalized()

	match state:
		State.MOVE:
			velocity.x = direction.x * SPEED
			velocity.z = direction.z * SPEED

			if not direction:
				state = State.IDLE
			
			if Input.is_action_just_pressed("jump") and is_on_floor():
				velocity.y = JUMP_VELOCITY
				state = State.JUMP

			if not is_on_floor():
				state = State.FALL
			
			if Input.is_action_just_pressed("attack") and is_on_floor():
				attack_timer = JAB_DURATION
				state = State.ATTACK
		State.IDLE:
			velocity.x = 0
			velocity.z = 0

			if direction:
				state = State.MOVE
			
			if Input.is_action_just_pressed("jump") and is_on_floor():
				velocity.y = JUMP_VELOCITY
				state = State.JUMP
			
			if not is_on_floor():
				state = State.FALL
			
			if Input.is_action_just_pressed("attack") and is_on_floor():
				attack_timer = JAB_DURATION
				state = State.ATTACK
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

			if attack_timer <= 0:
				state = State.IDLE

	move_and_slide()
