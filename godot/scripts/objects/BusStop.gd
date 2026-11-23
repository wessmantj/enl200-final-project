extends StaticBody2D
## The factory shuttle stop. In a home zone it carries you to the shared Bridge;
## on the Bridge it carries you back to whichever zone you came from.

@export var to_bridge := true  # false = the Bridge's return stop

@onready var sprite: Sprite2D = $Sprite2D

func get_prompt(_player: Node) -> String:
	return "[E] Wait for the factory shuttle"

func interact(_player: Node) -> void:
	if to_bridge:
		# Let the home level stash its in-progress day before we leave.
		var level := get_tree().current_scene
		if level and level.has_method("on_board_bus"):
			level.on_board_bus()
		WorldTravel.go_to_bridge()
	else:
		WorldTravel.return_home()
