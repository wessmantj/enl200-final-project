extends StaticBody2D
## One industrial shredder. Feed it a document container; after enough pages
## the bag fills and must be pulled. Occasionally it jams — a jammed machine
## is left alone (you switch to the next one) until maintenance clears it.

signal shredded(machine_id: int, pages: int)
signal jammed(machine_id: int)

enum State { IDLE, ACTIVE, JAMMED, FULL }

const PAGES_PER_CONTAINER := 10
const BAG_CAPACITY := 50
const JAM_CHANCE := 0.08
const SHRED_SECONDS := 2.0

const TEX_IDLE := preload("res://assets/sprites/objects/shredder.png")
const TEX_ON := preload("res://assets/sprites/objects/shredder_on.png")
const TEX_JAMMED := preload("res://assets/sprites/objects/shredder_jammed.png")

@export var machine_id := 0

@onready var sprite: Sprite2D = $Sprite2D

var state := State.IDLE
var pages_in_bag := 0
var _shake: Tween

func _ready() -> void:
	add_to_group("shredders")
	_refresh()

func get_prompt(player: Node) -> String:
	match state:
		State.IDLE:
			if player.has_documents():
				return "[E] Feed documents into #%d" % machine_id
			return "Shredder #%d — bag %d/%d" % [machine_id, pages_in_bag, BAG_CAPACITY]
		State.JAMMED:
			return "Shredder #%d is jammed. Use another." % machine_id
		State.FULL:
			if player.hands_free():
				return "[E] Pull the full bag from #%d" % machine_id
			return "Shredder #%d — bag full. Free your hands." % machine_id
	return ""

func interact(player: Node) -> void:
	match state:
		State.IDLE:
			if player.has_documents():
				_shred(player)
			else:
				DialogueManager.start(["The shredder hums, waiting."])
		State.JAMMED:
			DialogueManager.start([
				"Paper is wadded deep in the blades. The motor whines when you touch the switch.",
				{"speaker": "Yoshiko", "text": "Itsumi said not to fight a jam. Just move to the next machine."},
			])
		State.FULL:
			if player.hands_free():
				player.give_full_bag()
				pages_in_bag = 0
				state = State.IDLE
				_refresh()
			else:
				DialogueManager.start(["The bag is full. You'll need both hands to pull it."])

func _shred(player: Node) -> void:
	player.take_documents()
	player.face_toward(global_position)
	state = State.ACTIVE
	_refresh()
	await player.do_work(SHRED_SECONDS)
	pages_in_bag += PAGES_PER_CONTAINER
	if pages_in_bag >= BAG_CAPACITY:
		state = State.FULL
	elif randf() < JAM_CHANCE:
		state = State.JAMMED
		jammed.emit(machine_id)
	else:
		state = State.IDLE
	_refresh()
	shredded.emit(machine_id, PAGES_PER_CONTAINER)

func clear_jam() -> void:
	if state == State.JAMMED:
		state = State.IDLE
		_refresh()

func _refresh() -> void:
	sprite.modulate = Color.WHITE
	sprite.position = Vector2.ZERO
	if _shake:
		_shake.kill()
	match state:
		State.IDLE:
			sprite.texture = TEX_IDLE
		State.ACTIVE:
			sprite.texture = TEX_ON
			_shake = create_tween().set_loops()
			_shake.tween_property(sprite, "position:x", 2.0, 0.05)
			_shake.tween_property(sprite, "position:x", -2.0, 0.05)
		State.JAMMED:
			sprite.texture = TEX_JAMMED
		State.FULL:
			sprite.texture = TEX_IDLE
			sprite.modulate = Color(1.0, 0.7, 0.6)
