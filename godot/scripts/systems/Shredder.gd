extends Area2D

signal shredded(machine_id: int)
signal jammed(machine_id: int)

enum State { IDLE, ACTIVE, JAMMED, FULL }

@export var machine_id := 0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var prompt_label: Label = $PromptLabel

var state := State.IDLE
var pages_shredded := 0
var bag_capacity := 50

func _ready() -> void:
	prompt_label.visible = false
	_update_sprite()

func interact(player: Node) -> void:
	match state:
		State.IDLE:
			if player.has_method("has_documents") and player.has_documents():
				_start_shredding(player)
			else:
				DialogueManager.start([
					{"speaker": "", "text": "The shredder hums, waiting."}
				])
		State.JAMMED:
			_clear_jam()
		State.FULL:
			if player.has_method("has_shred_bag") and player.has_shred_bag():
				_swap_bag(player)
			else:
				DialogueManager.start([
					{"speaker": "", "text": "Bag is full. You need an empty shred bag."}
				])
		State.ACTIVE:
			pass

func _start_shredding(player: Node) -> void:
	state = State.ACTIVE
	_update_sprite()
	player.take_documents()
	await get_tree().create_timer(2.0).timeout
	pages_shredded += 10
	_check_state()

func _check_state() -> void:
	if pages_shredded >= bag_capacity:
		state = State.FULL
	elif randf() < 0.08:
		state = State.JAMMED
		emit_signal("jammed", machine_id)
	else:
		state = State.IDLE
		emit_signal("shredded", machine_id)
	_update_sprite()

func _clear_jam() -> void:
	state = State.IDLE
	_update_sprite()
	DialogueManager.start([
		{"speaker": "", "text": "You clear the jam. The shredder resets."}
	])

func _swap_bag(player: Node) -> void:
	player.take_shred_bag()
	pages_shredded = 0
	state = State.IDLE
	_update_sprite()

func _update_sprite() -> void:
	match state:
		State.IDLE:
			sprite.play("idle")
		State.ACTIVE:
			sprite.play("active")
		State.JAMMED:
			sprite.play("jammed")
		State.FULL:
			sprite.play("full")

func _on_body_entered(_body: Node) -> void:
	prompt_label.visible = true

func _on_body_exited(_body: Node) -> void:
	prompt_label.visible = false
