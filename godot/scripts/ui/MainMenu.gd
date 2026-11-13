extends Control

const YOSHIKO_LEVEL := "res://scenes/levels/YoshikoLevel.tscn"

@onready var yoshiko_button: Button = $VBox/YoshikoButton
@onready var quit_button: Button = $VBox/QuitButton

func _ready() -> void:
	GameClock.stop()
	yoshiko_button.pressed.connect(_on_yoshiko)
	quit_button.pressed.connect(func(): get_tree().quit())
	yoshiko_button.grab_focus()

func _on_yoshiko() -> void:
	GameState.reset_yoshiko()
	SceneTransition.change_scene(YOSHIKO_LEVEL)
