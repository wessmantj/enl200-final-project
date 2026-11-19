extends Area2D
## A factory animal — a shag that can't truly fly, or a coypu up from the
## drains. Ambient; bobs in place and offers a line when watched.

@export var texture: Texture2D
@export var display_name := "creature"
@export var lines: Array = []

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	if texture:
		sprite.texture = texture
	# A small, restless idle bob.
	var bob := create_tween().set_loops()
	bob.tween_property(sprite, "position:y", -3.0, 0.6).set_trans(Tween.TRANS_SINE)
	bob.tween_property(sprite, "position:y", 0.0, 0.6).set_trans(Tween.TRANS_SINE)

func get_prompt(_player: Node) -> String:
	return "[E] Watch the %s" % display_name if not lines.is_empty() else ""

func interact(_player: Node) -> void:
	if not lines.is_empty():
		DialogueManager.start(lines)
