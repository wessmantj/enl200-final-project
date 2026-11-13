extends StaticBody2D
## Static, examinable scenery (lockers, desks, the Power Tower...).

@export var texture: Texture2D
@export var examine_text := ""
@export var lines: Array = []

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	if texture:
		sprite.texture = texture

func get_prompt(_player: Node) -> String:
	return "[E] %s" % examine_text if not lines.is_empty() else ""

func interact(_player: Node) -> void:
	if not lines.is_empty():
		DialogueManager.start(lines)
