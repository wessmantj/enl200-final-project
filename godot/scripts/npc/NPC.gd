extends CharacterBody2D
## Simple NPC: IDLE (optionally playing its work animation) or PATROL between
## offsets from its spawn point; switches to DIALOGUE when talked to.
## Conversations cycle in order and the last one repeats. A line may be a
## String (spoken by this NPC) or a full {"speaker", "text"} Dictionary.

enum State { IDLE, PATROL, DIALOGUE }

@export var display_name := ""
@export var walk_sheet: Texture2D
@export var work_sheet: Texture2D
@export var working := false  # idle with the work animation
@export var conversations: Array = []
@export var patrol_offsets: Array[Vector2] = []
@export var patrol_speed := 90.0
@export var patrol_pause := 2.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var state := State.IDLE
var _home := Vector2.ZERO
var _patrol_index := 0
var _pause_left := 0.0
var _facing := "down"
var _conversation_index := 0
var _stuck_time := 0.0

const STUCK_SECONDS := 1.0

func _ready() -> void:
	_home = global_position
	sprite.sprite_frames = SheetFrames.build(walk_sheet, work_sheet)
	state = State.PATROL if patrol_offsets.size() > 1 else State.IDLE
	_play_idle()

func _physics_process(delta: float) -> void:
	if state != State.PATROL:
		velocity = Vector2.ZERO
		return
	if _pause_left > 0.0:
		_pause_left -= delta
		_play_idle()
		return
	var target := _home + patrol_offsets[_patrol_index]
	var to_target := target - global_position
	if to_target.length() < 4.0:
		_patrol_index = (_patrol_index + 1) % patrol_offsets.size()
		_pause_left = patrol_pause
		velocity = Vector2.ZERO
		return
	velocity = to_target.normalized() * patrol_speed
	_facing = SheetFrames.facing_from(velocity)
	sprite.play("walk_" + _facing)
	var before := global_position
	move_and_slide()
	# Blocked by something? Give up on this waypoint and head for the next.
	if global_position.distance_to(before) < patrol_speed * delta * 0.25:
		_stuck_time += delta
		if _stuck_time > STUCK_SECONDS:
			_stuck_time = 0.0
			_patrol_index = (_patrol_index + 1) % patrol_offsets.size()
			_pause_left = patrol_pause
	else:
		_stuck_time = 0.0

func _play_idle() -> void:
	var anim := ("work_" if working else "idle_") + _facing
	if not sprite.sprite_frames.has_animation(anim):
		anim = "idle_" + _facing
	sprite.play(anim)

func get_prompt(_player: Node) -> String:
	return "[E] Talk to %s" % display_name

func interact(player: Node2D) -> void:
	if conversations.is_empty():
		return
	var previous := state
	state = State.DIALOGUE
	_facing = SheetFrames.facing_from(player.global_position - global_position)
	sprite.play("idle_" + _facing)

	var lines: Array = []
	for line in conversations[_conversation_index]:
		lines.append(line if line is Dictionary else {"speaker": display_name, "text": line})
	_conversation_index = mini(_conversation_index + 1, conversations.size() - 1)

	DialogueManager.start(lines)
	await DialogueManager.dialogue_ended
	state = previous
	_play_idle()
