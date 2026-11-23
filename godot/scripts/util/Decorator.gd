class_name Decorator
extends RefCounted
## Scatters non-interactive decal sprites (stains, cracks, paper, puddles,
## debris, posters, pipes, cables, boxes) across a level's floors and walls to
## make the rooms feel lived-in. Deterministic per seed so a room looks the
## same every day. Decals go in a layer just above the floor and below the
## entities, so props and the player always draw over them; they have no
## collision or `interact`, so they never affect movement or prompts.

const TILE := 64

const DECAL := {
	"stain":  preload("res://assets/sprites/decals/stain.png"),
	"crack":  preload("res://assets/sprites/decals/crack.png"),
	"paper":  preload("res://assets/sprites/decals/paper.png"),
	"puddle": preload("res://assets/sprites/decals/puddle.png"),
	"debris": preload("res://assets/sprites/decals/debris.png"),
	"poster": preload("res://assets/sprites/decals/poster.png"),
	"pipe":   preload("res://assets/sprites/decals/pipe.png"),
	"cables": preload("res://assets/sprites/decals/cables.png"),
	"box":    preload("res://assets/sprites/decals/box.png"),
}

# Per-zone look. `floor`/`wall` lists are weighted by repetition.
const PROFILES := {
	"basement": {
		"floor": ["stain", "stain", "crack", "debris", "cables", "paper", "box"],
		"wall": ["poster", "pipe", "pipe"],
		"floor_density": 0.16, "wall_density": 0.16,
	},
	"office": {
		"floor": ["paper", "paper", "stain", "debris", "cables"],
		"wall": ["poster", "poster", "pipe"],
		"floor_density": 0.13, "wall_density": 0.16,
	},
	"grounds": {
		"floor": ["puddle", "debris", "debris", "crack", "stain"],
		"wall": ["pipe"],
		"floor_density": 0.10, "wall_density": 0.06,
	},
	"bridge": {
		"floor": ["puddle", "debris", "crack", "cables"],
		"wall": ["pipe", "poster"],
		"floor_density": 0.12, "wall_density": 0.10,
	},
}

## Builds a "Decals" layer under `level` (just above its Floor) and scatters.
static func decorate(level: Node2D, kind: String, floor_cells: Array, wall_cells: Array, seed_val: int) -> void:
	var prof: Dictionary = PROFILES.get(kind, PROFILES["basement"])
	var layer := Node2D.new()
	layer.name = "Decals"
	level.add_child(layer)
	level.move_child(layer, 1)  # Floor is child 0; keep decals below Entities.

	var rng := RandomNumberGenerator.new()
	rng.seed = seed_val
	for cell in floor_cells:
		if rng.randf() < prof.floor_density:
			_place(layer, prof.floor[rng.randi() % prof.floor.size()], cell, rng, true)
	for cell in wall_cells:
		if rng.randf() < prof.wall_density:
			_place(layer, prof.wall[rng.randi() % prof.wall.size()], cell, rng, false)

static func _place(layer: Node2D, name: String, cell: Vector2i, rng: RandomNumberGenerator, jitter: bool) -> void:
	var s := Sprite2D.new()
	s.texture = DECAL[name]
	var pos := Vector2(cell.x * TILE + TILE / 2.0, cell.y * TILE + TILE / 2.0)
	if jitter:
		pos += Vector2(rng.randf_range(-18.0, 18.0), rng.randf_range(-18.0, 18.0))
	s.position = pos
	s.flip_h = rng.randf() < 0.5
	s.modulate.a = rng.randf_range(0.75, 1.0)
	layer.add_child(s)
