extends Node2D

const SHREDDER_COUNT := 14

@onready var player: CharacterBody2D = $Player
@onready var tran_delivery: Node2D = $TRANDelivery
@onready var clock_label: Label = $UI/ClockLabel
@onready var surreal_overlay: ColorRect = $UI/SurrealOverlay

var _pages_shredded_today := 0
var _surreal_level := 0.0

func _ready() -> void:
	GameClock.start_day()
	GameClock.bell_rang.connect(_on_bell)
	GameClock.minute_changed.connect(_on_minute)
	GameClock.day_ended.connect(_on_day_ended)
	tran_delivery.delivery_arrived.connect(_on_tran_delivery)

	# Connect all shredder signals
	for shredder in get_tree().get_nodes_in_group("shredders"):
		shredder.shredded.connect(_on_shredded)

	surreal_overlay.color = Color(0, 0, 0, 0)

func _on_bell(event_name: String) -> void:
	match event_name:
		"work_start":
			DialogueManager.start([
				{"speaker": "Itsumi", "text": "Morning meeting. Everyone look sharp."},
			])
		"lunch_start":
			DialogueManager.start([
				{"speaker": "", "text": "The bell rings. Lunch."},
			])
		"work_end":
			_trigger_end_of_day()

func _on_minute(hour: int, minute: int) -> void:
	clock_label.text = "%02d:%02d" % [hour, minute]

func _on_tran_delivery() -> void:
	DialogueManager.start([
		{"speaker": "TRAN Worker", "text": "Container's here. Sign nothing."},
	])

func _on_shredded(_id: int) -> void:
	_pages_shredded_today += 10
	_surreal_level = clampf(_surreal_level + 0.01, 0.0, 1.0)
	_update_surreal()

func _update_surreal() -> void:
	# As the day wears on and shredding rhythm builds, faint color shift creeps in
	var tween := create_tween()
	tween.tween_property(surreal_overlay, "color", Color(0.0, 0.0, 0.1, _surreal_level * 0.4), 1.0)

func _trigger_end_of_day() -> void:
	if _surreal_level >= 0.8:
		_play_transformation()
	else:
		DialogueManager.start([
			{"speaker": "", "text": "5:30. The machines go quiet. Yoshiko gathers her things."},
		])

func _play_transformation() -> void:
	# Yoshiko becomes a black bird — final scene of her arc
	DialogueManager.start([
		{"speaker": "", "text": "The last pages go in. The machine hums."},
		{"speaker": "", "text": "Rain on the high windows. The shredder sounds like wind."},
		{"speaker": "", "text": "Yoshiko feeds the last page. Something shifts."},
		{"speaker": "", "text": "On the floor where she stood, only a black feather."},
	])
	await DialogueManager.dialogue_ended
	SceneTransition.change_scene("res://scenes/ui/MainMenu.tscn")

func _on_day_ended() -> void:
	pass
