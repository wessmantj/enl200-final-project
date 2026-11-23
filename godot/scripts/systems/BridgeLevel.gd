extends Node2D
## The Bridge — the shared space the three narrators pass through but never
## quite meet in. The factory river, a span across it, and the Okinawan
## restaurant where Yoshiko and Furufue both eat alone. Reached by the shuttle
## from any zone; the day clock is paused for the length of the outing.

const TILE := 64

# Legend:
#   #  wall      .  deck / path    W  river
#   P  player start (the shuttle stop)   U  return shuttle
#   K  Okinawan restaurant    O  Goto
const LAYOUT: Array[String] = [
	"########################",
	"#..........K...........#",
	"#......................#",
	"#WWWWWWWWWW..WWWWWWWWWW#",
	"#WWWWWWWWWW..WWWWWWWWWW#",
	"#..........O...........#",
	"#......................#",
	"#......................#",
	"#.....U....P...........#",
	"#......................#",
	"########################",
]

const TILE_DECK := Vector2i(0, 0)    # factory_floor
const TILE_WALL := Vector2i(2, 0)
const TILE_RIVER := Vector2i(1, 0)   # basement_floor stands in for water

const NPCScene := preload("res://scenes/actors/NPC.tscn")
const PropScene := preload("res://scenes/objects/Prop.tscn")
const BusStopScene := preload("res://scenes/objects/BusStop.tscn")

const CHAR_SHEETS := {
	"yoshiko": {
		"walk": preload("res://assets/sprites/characters/yoshiko_walk.png"),
		"work": preload("res://assets/sprites/characters/yoshiko_work.png"),
	},
	"narrator": {
		"walk": preload("res://assets/sprites/characters/narrator_walk.png"),
		"work": preload("res://assets/sprites/characters/narrator_work.png"),
	},
	"furufue": {
		"walk": preload("res://assets/sprites/characters/furufue_walk.png"),
		"work": preload("res://assets/sprites/characters/furufue_work.png"),
	},
}

const GOTO := {
	"name": "Goto",
	"walk": preload("res://assets/sprites/npcs/goto_walk.png"),
	"conversations": [
		[
			{"speaker": "Goto", "text": "Ah — you! On the bridge. Everyone ends up here eventually. I just like to see who's crossing."},
			"He's the same vague, smiling man from the basement, the office, the grounds. He is, apparently, everywhere.",
			{"speaker": "Goto", "text": "The restaurant's good. Okinawan. Half the factory eats there and never notices the other half."},
		],
		[{"speaker": "Goto", "text": "Mind the river. Not that it's dangerous. It just goes on, and on."}],
	],
}

@onready var floor_layer: TileMapLayer = $Floor
@onready var entities: Node2D = $Entities
@onready var player: CharacterBody2D = $Entities/Player
@onready var hud: CanvasLayer = $HUD

func _ready() -> void:
	_build_level()

	player.prompt_changed.connect(hud.set_prompt)
	player.carrying_changed.connect(hud.set_carry)
	hud.set_carry("")

	# Look like whoever we arrived as (the shared Player.tscn is Yoshiko by default).
	var sheets: Dictionary = CHAR_SHEETS.get(GameState.current_character, CHAR_SHEETS["yoshiko"])
	player.walk_sheet = sheets.walk
	player.work_sheet = sheets.work
	player.sprite.sprite_frames = SheetFrames.build(sheets.walk, sheets.work)
	player.sprite.play("idle_down")

	hud.set_stats("")
	hud.set_surreal(_surreal_amount(), 0.01)
	# No clock out here — the bridge is time out of the day.
	hud.toast("The bridge. The river goes on forever. The Okinawan place is open.", 4.0)

# --- Level construction ---------------------------------------------------------

func _build_level() -> void:
	for y in LAYOUT.size():
		var row := LAYOUT[y]
		for x in row.length():
			var ch := row[x]
			var cell := Vector2i(x, y)
			var pos := Vector2(x * TILE + TILE / 2.0, y * TILE + TILE / 2.0)

			var tile := TILE_DECK
			if ch == "#":
				tile = TILE_WALL
			elif ch == "W":
				tile = TILE_RIVER
			floor_layer.set_cell(cell, 0, tile)

			match ch:
				"P":
					player.position = pos
				"U":
					var stop := BusStopScene.instantiate()
					stop.to_bridge = false
					stop.position = pos
					entities.add_child(stop)
				"K":
					_spawn_restaurant(pos)
				"O":
					_spawn_npc(GOTO, pos)

	var cam: Camera2D = player.camera
	cam.limit_left = 0
	cam.limit_top = 0
	cam.limit_right = LAYOUT[0].length() * TILE
	cam.limit_bottom = LAYOUT.size() * TILE

func _spawn_restaurant(pos: Vector2) -> void:
	# The restaurant building: examining it narrates the glimpse of the other
	# narrator(s) already seated nearby.
	var prop := PropScene.instantiate()
	prop.texture = preload("res://assets/sprites/objects/desk.png")
	prop.examine_text = "Look into the restaurant"
	prop.lines = _restaurant_lines()
	prop.position = pos
	entities.add_child(prop)

	# Seat whoever the current narrator would (not) recognise.
	match GameState.current_character:
		"yoshiko":
			_spawn_guest("furufue", "A mild man", pos + Vector2(-TILE, TILE))
		"furufue":
			_spawn_guest("yoshiko", "A woman in a grey apron", pos + Vector2(TILE, TILE))
		"narrator":
			_spawn_guest("yoshiko", "A woman in a grey apron", pos + Vector2(-TILE, TILE))
			_spawn_guest("furufue", "A mild man", pos + Vector2(TILE, TILE))
	GameState.met_at_restaurant = true

func _restaurant_lines() -> Array:
	match GameState.current_character:
		"yoshiko":
			return [
				"Steam, grilled meat, a radio. The Okinawan place on the bridge.",
				"A mild, unhurried man eats alone by the window — some kind of researcher, by the mud on his boots.",
				{"speaker": "Yoshiko", "text": "(I've seen him on the grounds, crouched over the moss. We nod. We will never speak.)"},
			]
		"furufue":
			return [
				"Steam, grilled meat, a radio. The Okinawan place on the bridge.",
				"A tired woman in a grey apron eats alone, a red lanyard still around her neck. Print Services, by the look of it.",
				{"speaker": "Furufue", "text": "(The basement people come up to eat here. She has the far-off eyes of someone who feeds paper to a machine all day.)"},
			]
		"narrator":
			return [
				"Steam, grilled meat, a radio. The Okinawan place on the bridge.",
				"A woman in a grey apron eats at one table; a mud-booted man at another. Neither looks up.",
				{"speaker": "Narrator", "text": "The apron — that set of the shoulders. Yoshiko? And the man... the moss researcher from the reports I mark?"},
				{"speaker": "Narrator", "text": "(Everyone in this factory is a stranger eating alone. Even, it seems, my own sister.)"},
			]
		_:
			return ["The Okinawan place on the bridge. Steam, grilled meat, a radio playing to no one."]

func _spawn_guest(character: String, label: String, pos: Vector2) -> void:
	var sheets: Dictionary = CHAR_SHEETS.get(character, CHAR_SHEETS["yoshiko"])
	var guest := NPCScene.instantiate()
	guest.display_name = label
	guest.walk_sheet = sheets.walk
	guest.work_sheet = sheets.work
	guest.working = true  # seated, heads-down
	guest.conversations = [[{"speaker": "", "text": "%s eats alone, and does not look up." % label}]]
	guest.position = pos
	entities.add_child(guest)

func _spawn_npc(data: Dictionary, pos: Vector2) -> void:
	var npc := NPCScene.instantiate()
	npc.display_name = data.name
	npc.walk_sheet = data.walk
	npc.work_sheet = data.get("work")
	npc.working = data.get("working", false)
	npc.conversations = data.conversations
	var patrol: Array[Vector2] = []
	patrol.assign(data.get("patrol", []))
	npc.patrol_offsets = patrol
	npc.position = pos
	entities.add_child(npc)

func _surreal_amount() -> float:
	match GameState.current_character:
		"yoshiko": return GameState.yoshiko_rhythm
		"narrator": return GameState.narrator_haze
		"furufue": return GameState.furufue_drift
		_: return 0.0
