extends CharacterBody2D
## Top-down player. Anything with interact(player) (and optionally
## get_prompt(player) -> String) in front of the player can be used with E.

signal prompt_changed(text: String)
signal carrying_changed(text: String)

enum Carry { NONE, DOCUMENTS, FULL_BAG }

const SPEED := 260.0
const INTERACT_REACH := 40.0
const FACING_VEC := {
	"down": Vector2.DOWN, "up": Vector2.UP, "left": Vector2.LEFT, "right": Vector2.RIGHT,
}
const CARRY_TEXTURES := {
	Carry.DOCUMENTS: preload("res://assets/sprites/items/document_packet.png"),
	Carry.FULL_BAG: preload("res://assets/sprites/items/shred_bag.png"),
}
const CARRY_NAMES := {
	Carry.NONE: "",
	Carry.DOCUMENTS: "Carrying: document container",
	Carry.FULL_BAG: "Carrying: full shred bag",
}

@export var walk_sheet: Texture2D
@export var work_sheet: Texture2D

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var interaction_area: Area2D = $InteractionArea
@onready var carry_sprite: Sprite2D = $CarrySprite
@onready var camera: Camera2D = $Camera2D

var carrying := Carry.NONE
var frozen := false  # set by cutscenes
var _facing := "down"
var _in_dialogue := false
var _working := false
var _prompt := ""

func _ready() -> void:
	sprite.sprite_frames = SheetFrames.build(walk_sheet, work_sheet)
	sprite.play("idle_down")
	DialogueManager.dialogue_started.connect(_on_dialogue_started)
	DialogueManager.dialogue_ended.connect(_on_dialogue_ended)
	_refresh_carry()

func _physics_process(_delta: float) -> void:
	if _in_dialogue or _working or frozen:
		velocity = Vector2.ZERO
		if not _working:
			sprite.play("idle_" + _facing)
		_set_prompt("")
		return

	var dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = dir * SPEED
	if dir != Vector2.ZERO:
		_facing = SheetFrames.facing_from(dir)
		sprite.play("walk_" + _facing)
	else:
		sprite.play("idle_" + _facing)
	move_and_slide()

	interaction_area.position = FACING_VEC[_facing] * INTERACT_REACH + Vector2(0, 12)
	var target := _find_interactable()
	var prompt := ""
	if target and target.has_method("get_prompt"):
		prompt = target.get_prompt(self)
	_set_prompt(prompt)

	if target and Input.is_action_just_pressed("interact"):
		target.interact(self)

func _find_interactable() -> Node2D:
	var best: Node2D = null
	var best_dist := INF
	var candidates: Array = interaction_area.get_overlapping_bodies() + interaction_area.get_overlapping_areas()
	for node in candidates:
		if node == self or not node.has_method("interact"):
			continue
		var d := interaction_area.global_position.distance_to(node.global_position)
		if d < best_dist:
			best_dist = d
			best = node
	return best

func _set_prompt(text: String) -> void:
	if text != _prompt:
		_prompt = text
		prompt_changed.emit(text)

# --- Work animation -----------------------------------------------------------

func face_toward(pos: Vector2) -> void:
	_facing = SheetFrames.facing_from(pos - global_position)

## Plays the work animation and blocks movement for `seconds`.
func do_work(seconds: float) -> void:
	_working = true
	var anim := "work_" + _facing
	if sprite.sprite_frames.has_animation(anim):
		sprite.play(anim)
	await get_tree().create_timer(seconds).timeout
	_working = false

# --- Carrying -----------------------------------------------------------------

func hands_free() -> bool:
	return carrying == Carry.NONE

func has_documents() -> bool:
	return carrying == Carry.DOCUMENTS

func has_full_bag() -> bool:
	return carrying == Carry.FULL_BAG

func give_documents() -> void:
	_set_carry(Carry.DOCUMENTS)

func take_documents() -> void:
	_set_carry(Carry.NONE)

func give_full_bag() -> void:
	_set_carry(Carry.FULL_BAG)

func take_full_bag() -> void:
	_set_carry(Carry.NONE)

func _set_carry(c: Carry) -> void:
	carrying = c
	_refresh_carry()

func _refresh_carry() -> void:
	carry_sprite.visible = carrying != Carry.NONE
	if carrying != Carry.NONE:
		carry_sprite.texture = CARRY_TEXTURES[carrying]
	carrying_changed.emit(CARRY_NAMES[carrying])

# --- Dialogue lock ------------------------------------------------------------

func _on_dialogue_started() -> void:
	_in_dialogue = true

func _on_dialogue_ended() -> void:
	# Short grace period so the key press that closed the box doesn't
	# immediately re-trigger whatever we're standing next to.
	await get_tree().create_timer(0.15).timeout
	_in_dialogue = DialogueManager.is_active
