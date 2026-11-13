extends Node
## Persistent progress shared across scenes (save/load will serialize this).

var day := 1

# Yoshiko: how deep the shredding rhythm has sunk in (0..1). Reaching 1.0
# triggers her ending — she becomes a black bird.
var yoshiko_rhythm := 0.0
var yoshiko_pages_total := 0

func reset_yoshiko() -> void:
	day = 1
	yoshiko_rhythm = 0.0
	yoshiko_pages_total = 0
