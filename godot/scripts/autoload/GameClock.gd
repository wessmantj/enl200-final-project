extends Node

signal bell_rang(event_name: String)
signal minute_changed(hour: int, minute: int)
signal day_ended

const REAL_SECONDS_PER_GAME_MINUTE := 2.0
const FAST_FORWARD_MULTIPLIER := 10.0  # hold Tab (debug / impatience)

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

func start_day() -> void:
	hour = 8
	minute = 50
	_accumulator = 0.0
	is_running = true

func stop() -> void:
	is_running = false

## Jump the clock forward, minute by minute, so bells in between still ring
## (used by the Narrator's sleep mechanic — he dozes through part of the day).
func skip(minutes: int) -> void:
	for _i in minutes:
		if not is_running:
			break
		_advance_minute()

func is_fast_forwarding() -> bool:
	return is_running and Input.is_action_pressed("fast_forward")

func _process(delta: float) -> void:
	# Time stops while someone is talking.
	if not is_running or DialogueManager.is_active:
		return
	_accumulator += delta * (FAST_FORWARD_MULTIPLIER if is_fast_forwarding() else 1.0)
	while is_running and _accumulator >= REAL_SECONDS_PER_GAME_MINUTE:
		_accumulator -= REAL_SECONDS_PER_GAME_MINUTE
		_advance_minute()

func _advance_minute() -> void:
	minute += 1
	if minute >= 60:
		minute = 0
		hour += 1
	minute_changed.emit(hour, minute)
	_check_bells()
	if hour >= 18:
		is_running = false
		day_ended.emit()

func _check_bells() -> void:
	for entry in BELL_SCHEDULE:
		if entry[0] == hour and entry[1] == minute:
			bell_rang.emit(entry[2])

func get_time_string() -> String:
	return "%02d:%02d" % [hour, minute]
