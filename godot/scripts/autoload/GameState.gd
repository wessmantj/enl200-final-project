extends Node
## Persistent progress shared across scenes (save/load will serialize this).

var day := 1

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

func reset_yoshiko() -> void:
	day = 1
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
