extends Node

signal bell_rang(event_name: String)
signal minute_changed(hour: int, minute: int)
signal day_ended

const REAL_SECONDS_PER_GAME_MINUTE := 2.0

# Bell schedule: [hour, minute, event_name]
const BELL_SCHEDULE := [
	[8, 55, "pre_start"],
	[9, 0, "work_start"],
	[12, 0, "lunch_start"],
	[12, 55, "pre_return"],
	[13, 0, "lunch_end"],
	[17, 30, "work_end"],
]

var hour := 8
var minute := 50
var is_running := false
var _accumulator := 0.0

func _ready() -> void:
	pass

func start_day() -> void:
	hour = 8
	minute = 50
	is_running = true

func _process(delta: float) -> void:
	if not is_running:
		return
	_accumulator += delta
	while _accumulator >= REAL_SECONDS_PER_GAME_MINUTE:
		_accumulator -= REAL_SECONDS_PER_GAME_MINUTE
		_advance_minute()

func _advance_minute() -> void:
	minute += 1
	if minute >= 60:
		minute = 0
		hour += 1
	emit_signal("minute_changed", hour, minute)
	_check_bells()
	if hour >= 18:
		is_running = false
		emit_signal("day_ended")

func _check_bells() -> void:
	for entry in BELL_SCHEDULE:
		if entry[0] == hour and entry[1] == minute:
			emit_signal("bell_rang", entry[2])

func get_time_string() -> String:
	return "%02d:%02d" % [hour, minute]
