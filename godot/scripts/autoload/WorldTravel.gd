extends Node
## The factory shuttle. Moves the player between a home zone and the shared
## Bridge. A trip is a timeless side-outing: the day clock pauses on the way
## out and resumes, at the same time, on the way back (see GameState's clock
## snapshot + day_progress). current_character routes the return bus home.

const BRIDGE := "res://scenes/levels/BridgeLevel.tscn"
const LEVELS := {
	"yoshiko": "res://scenes/levels/YoshikoLevel.tscn",
	"narrator": "res://scenes/levels/NarratorLevel.tscn",
	"furufue": "res://scenes/levels/FurufueLevel.tscn",
}

func go_to_bridge() -> void:
	GameState.snapshot_clock()
	GameClock.stop()
	SceneTransition.change_scene(BRIDGE)

func return_home() -> void:
	GameState.returning_from_bridge = true
	var path: String = LEVELS.get(GameState.current_character, LEVELS["yoshiko"])
	SceneTransition.change_scene(path)
