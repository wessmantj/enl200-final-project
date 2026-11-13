extends CanvasLayer
## Bottom-of-screen dialogue box with a typewriter effect.
## E / Enter / Space: finish the current line, then advance.

const CHARS_PER_SECOND := 60.0

@onready var panel: PanelContainer = $Panel
@onready var speaker_label: Label = $Panel/VBox/Speaker
@onready var text_label: RichTextLabel = $Panel/VBox/Text

var _tween: Tween

func _ready() -> void:
	panel.visible = false
	DialogueManager.dialogue_started.connect(_on_start)
	DialogueManager.dialogue_ended.connect(_on_end)
	DialogueManager.line_shown.connect(_on_line)

func _unhandled_input(event: InputEvent) -> void:
	if not panel.visible:
		return
	if event.is_action_pressed("interact") or event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		if text_label.visible_ratio < 1.0:
			if _tween:
				_tween.kill()
			text_label.visible_ratio = 1.0
		else:
			DialogueManager.advance()

func _on_start() -> void:
	panel.visible = true

func _on_end() -> void:
	panel.visible = false

func _on_line(speaker: String, text: String) -> void:
	speaker_label.text = speaker
	speaker_label.visible = not speaker.is_empty()
	text_label.text = text
	text_label.visible_ratio = 0.0
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(text_label, "visible_ratio", 1.0, maxf(text.length() / CHARS_PER_SECOND, 0.05))
