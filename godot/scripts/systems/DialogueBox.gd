extends CanvasLayer

@onready var panel: PanelContainer = $Panel
@onready var speaker_label: Label = $Panel/VBox/Speaker
@onready var text_label: RichTextLabel = $Panel/VBox/Text

func _ready() -> void:
	panel.visible = false
	DialogueManager.dialogue_started.connect(_on_start)
	DialogueManager.dialogue_ended.connect(_on_end)
	DialogueManager.line_shown.connect(_on_line)

func _unhandled_input(event: InputEvent) -> void:
	if not panel.visible:
		return
	if event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		DialogueManager.advance()

func _on_start() -> void:
	panel.visible = true

func _on_end() -> void:
	panel.visible = false

func _on_line(speaker: String, text: String) -> void:
	speaker_label.text = speaker
	speaker_label.visible = not speaker.is_empty()
	text_label.text = text
