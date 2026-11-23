extends Node
## Persistent progress shared across scenes (save/load will serialize this).

var day := 1

# Which narrator is being played: "yoshiko" | "narrator" | "furufue". Set by
# each level on entry; WorldTravel uses it to send the bus back to the right zone.
var current_character := ""

# --- Bus trips (Phase 6) ----------------------------------------------------------
# A trip to the shared Bridge is a side outing: the day clock pauses and the
# level's in-progress tally is kept so stepping away doesn't cost the day.
var returning_from_bridge := false
var met_at_restaurant := false  # glimpsed another narrator at the Okinawan place

var _clock_snap := {}
# Per-character "today" counters, preserved across a bus trip and cleared when a
# fresh day actually starts. Keyed by current_character.
var day_progress := {}

func snapshot_clock() -> void:
	_clock_snap = {"h": GameClock.hour, "m": GameClock.minute, "run": GameClock.is_running}

func restore_clock() -> void:
	if _clock_snap.is_empty():
		return
	GameClock.hour = _clock_snap.h
	GameClock.minute = _clock_snap.m
	GameClock.is_running = _clock_snap.run
	_clock_snap = {}

func save_day_progress(data: Dictionary) -> void:
	day_progress[current_character] = data

func take_day_progress() -> Dictionary:
	# Consumed once on return from the bridge, then cleared.
	var data: Dictionary = day_progress.get(current_character, {})
	day_progress.erase(current_character)
	return data

# Yoshiko: how deep the shredding rhythm has sunk in (0..1). Reaching 1.0
# triggers her ending — she becomes a black bird.
var yoshiko_rhythm := 0.0
var yoshiko_pages_total := 0

# Narrator: how blurred the line between sleep and waking has become (0..1).
# Rises as he proofreads and dozes; drives the surreal overlay and his ending.
var narrator_haze := 0.0
var narrator_packets_total := 0
var narrator_saw_yoshiko := false  # spotted his sister crossing the grounds
var narrator_read_report := false  # proofread Hikaru Samukawa's fauna report

func _reset_common() -> void:
	day = 1
	returning_from_bridge = false
	met_at_restaurant = false
	day_progress.clear()
	_clock_snap = {}

func reset_yoshiko() -> void:
	_reset_common()
	yoshiko_rhythm = 0.0
	yoshiko_pages_total = 0

func reset_narrator() -> void:
	day = 1
	narrator_haze = 0.0
	narrator_packets_total = 0
	narrator_saw_yoshiko = false
	narrator_read_report = false

# Furufue: how far he has drifted into a small, well-paid, purposeless life
# (0..1). Rises as he logs moss. At day 3 Aoyama asks what fifteen years bought.
var furufue_drift := 0.0
var furufue_samples_total := 0
var furufue_hunt_done := false      # ran the family moss hunt
var furufue_samukawa_done := false  # old man Samukawa + Hikaru visited

func reset_furufue() -> void:
	day = 1
	furufue_drift = 0.0
	furufue_samples_total = 0
	furufue_hunt_done = false
	furufue_samukawa_done = false
