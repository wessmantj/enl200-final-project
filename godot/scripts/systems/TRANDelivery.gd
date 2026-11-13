extends Node
## Fires a delivery at the scheduled times. The level decides what a delivery
## does (refill the TRAN cart, collect bags, show dialogue).

signal delivery_arrived(slot: int)

const SCHEDULE := [
	{"hour": 10, "minute": 0},
	{"hour": 15, "minute": 0},
]

func _ready() -> void:
	GameClock.minute_changed.connect(_on_minute)

func _on_minute(hour: int, minute: int) -> void:
	for i in SCHEDULE.size():
		if SCHEDULE[i].hour == hour and SCHEDULE[i].minute == minute:
			delivery_arrived.emit(i)
