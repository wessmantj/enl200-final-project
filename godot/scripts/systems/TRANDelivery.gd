extends Node2D

signal delivery_arrived
signal delivery_complete

@export var spawn_point: NodePath
@export var drop_point: NodePath
@export var document_scene: PackedScene

var _scheduled_deliveries := [
	{"hour": 10, "minute": 0},
	{"hour": 15, "minute": 0},
]

func _ready() -> void:
	GameClock.bell_rang.connect(_on_bell)
	GameClock.minute_changed.connect(_on_minute)

func _on_bell(_event: String) -> void:
	pass

func _on_minute(hour: int, minute: int) -> void:
	for slot in _scheduled_deliveries:
		if slot.hour == hour and slot.minute == minute:
			_trigger_delivery()

func _trigger_delivery() -> void:
	emit_signal("delivery_arrived")
	# Spawn TRAN NPC + document container
	# The Level scene connects to this signal to handle spawning
