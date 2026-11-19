extends Area2D
## A clump of moss on the factory grounds. Furufue crouches to examine and log
## it in his notebook. Scattered by FastNoiseLite in FurufueLevel; once logged
## it greys out and can't be logged again.

signal logged(is_rare: bool)

const TEX_PATCH := preload("res://assets/sprites/tilesets/moss_patch.png")
const TEX_DENSE := preload("res://assets/sprites/tilesets/moss_dense.png")
const EXAMINE_SECONDS := 1.5

@export var rare := false  # dense, rarer moss — worth a note

@onready var sprite: Sprite2D = $Sprite2D

var collected := false

func _ready() -> void:
	add_to_group("moss")
	sprite.texture = TEX_DENSE if rare else TEX_PATCH

func get_prompt(_player: Node) -> String:
	if collected:
		return ""
	return "[E] Examine the %s moss" % ("dense" if rare else "common")

func interact(player: Node) -> void:
	if collected:
		return
	player.face_toward(global_position)
	await player.do_work(EXAMINE_SECONDS)
	collected = true
	var fade := create_tween()
	fade.tween_property(sprite, "modulate", Color(0.5, 0.5, 0.5, 0.5), 0.4)
	logged.emit(rare)
