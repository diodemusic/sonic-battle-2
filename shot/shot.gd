extends Area3D

const SPEED = 12.0
const MAX_DISTANCE = 12.0


var direction = Vector3.ZERO
var distance_travelled := 0.0
var player_owner: CharacterBody3D


func _physics_process(delta: float) -> void:
	var step: Vector3 = direction * SPEED * delta
	position += step
	distance_travelled += step.length()

	if distance_travelled >= MAX_DISTANCE:
		queue_free()
