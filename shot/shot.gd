extends Area3D

const SPEED = 12.0
const MAX_DISTANCE = 12.0
const DAMAGE = 10


var direction = Vector3.ZERO
var distance_travelled := 0.0
var player_owner: CharacterBody3D

func _on_area_entered(area: Area3D) -> void:
	var opponent := area.get_parent() as CharacterBody3D

	if opponent == player_owner:
		return # stop shooting yourself lol

	opponent.take_damage(DAMAGE, Vector3.ZERO)
	queue_free()


func _ready() -> void:
	area_entered.connect(_on_area_entered)


func _physics_process(delta: float) -> void:
	var step: Vector3 = direction * SPEED * delta
	position += step
	distance_travelled += step.length()

	if distance_travelled >= MAX_DISTANCE:
		queue_free()
