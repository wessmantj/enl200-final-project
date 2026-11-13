extends CharacterBody2D

const SPEED := 80.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var interaction_area: Area2D = $InteractionArea

var _facing := "down"
var _can_move := true

func _ready() -> void:
	DialogueManager.dialogue_started.connect(_on_dialogue_started)
	DialogueManager.dialogue_ended.connect(_on_dialogue_ended)

func _physics_process(_delta: float) -> void:
	if not _can_move:
		velocity = Vector2.ZERO
		return

	var dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = dir * SPEED

	if dir != Vector2.ZERO:
		_update_facing(dir)
		_play_walk()
	else:
		_play_idle()

	move_and_slide()

	if Input.is_action_just_pressed("interact"):
		_try_interact()

func _update_facing(dir: Vector2) -> void:
	if abs(dir.x) > abs(dir.y):
		_facing = "right" if dir.x > 0 else "left"
	else:
		_facing = "down" if dir.y > 0 else "up"

func _play_walk() -> void:
	sprite.play("walk_" + _facing)

func _play_idle() -> void:
	sprite.play("idle_" + _facing)

func _try_interact() -> void:
	var bodies := interaction_area.get_overlapping_bodies()
	var areas := interaction_area.get_overlapping_areas()
	for body in bodies:
		if body.has_method("interact"):
			body.interact(self)
			return
	for area in areas:
		if area.has_method("interact"):
			area.interact(self)
			return

func _on_dialogue_started() -> void:
	_can_move = false

func _on_dialogue_ended() -> void:
	_can_move = true
