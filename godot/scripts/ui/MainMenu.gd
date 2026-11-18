extends Control

const YOSHIKO_LEVEL := "res://scenes/levels/YoshikoLevel.tscn"
const NARRATOR_LEVEL := "res://scenes/levels/NarratorLevel.tscn"

@onready var yoshiko_button: Button = $VBox/YoshikoButton
@onready var narrator_button: Button = $VBox/NarratorButton
@onready var quit_button: Button = $VBox/QuitButton

func _ready() -> void:
	GameClock.stop()
	yoshiko_button.pressed.connect(_on_yoshiko)
	narrator_button.pressed.connect(_on_narrator)
	quit_button.pressed.connect(func(): get_tree().quit())
	yoshiko_button.grab_focus()

func _on_yoshiko() -> void:
	GameState.reset_yoshiko()
	SceneTransition.change_scene(YOSHIKO_LEVEL)

func _on_narrator() -> void:
	GameState.reset_narrator()
	SceneTransition.change_scene(NARRATOR_LEVEL)
