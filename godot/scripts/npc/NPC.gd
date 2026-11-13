extends CharacterBody2D

enum State { IDLE, PATROL, DIALOGUE }

@export var dialogue_lines: Array[Dictionary] = []
@export var patrol_points: Array[Vector2] = []
@export var patrol_speed := 40.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var state := State.IDLE
var _patrol_index := 0
var _facing := "down"

func _physics_process(_delta: float) -> void:
	match state:
		State.PATROL:
			_do_patrol()

func _do_patrol() -> void:
	if patrol_points.is_empty():
		return
	var target := patrol_points[_patrol_index]
	var dir := (target - global_position).normalized()
	velocity = dir * patrol_speed

	if global_position.distance_to(target) < 4.0:
		_patrol_index = (_patrol_index + 1) % patrol_points.size()
		velocity = Vector2.ZERO

	if velocity != Vector2.ZERO:
		_update_facing(velocity)
		sprite.play("walk_" + _facing)
	else:
		sprite.play("idle_" + _facing)

	move_and_slide()

func _update_facing(dir: Vector2) -> void:
	if abs(dir.x) > abs(dir.y):
		_facing = "right" if dir.x > 0 else "left"
	else:
		_facing = "down" if dir.y > 0 else "up"

func interact(_player: Node) -> void:
	if dialogue_lines.is_empty():
		return
	DialogueManager.start(dialogue_lines)
