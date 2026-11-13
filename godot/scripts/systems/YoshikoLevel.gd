extends Node2D
## Yoshiko's level — the Print Services basement / shredder station.
## The room is built from LAYOUT below so it can be edited as text.

const LEVEL_PATH := "res://scenes/levels/YoshikoLevel.tscn"
const MENU_PATH := "res://scenes/ui/MainMenu.tscn"
const TILE := 64

# Legend:
#   #  wall              .  basement floor     ,  reception / factory floor
#   S  shredder (14)     T  TRAN cart          P  player start
#   L  locker            W  Power Tower        R  reception counter
#   C  Captain Samukawa  I  Itsumi             H  Hanzake
#   G  the Giant         O  Goto
const LAYOUT: Array[String] = [
	"##############################",
	"#LLLL....#,,,,,,,,R,,,,,O,,,,#",
	"#........#,,,,,,,,,,,,,,,,,,,#",
	"#..P.....#,,,,,,,,,,,,,,,,,,,#",
	"#........#,,,,,,,,,,,,,,,,,,,#",
	"###..#####,,,,,,,,,,,,,,,,,,,#",
	"#............................#",
	"#..S.S.S.S.S.S.S.............#",
	"#............................#",
	"#..S.S.S.S.S.S.S.......W.....#",
	"#............................#",
	"#......I.....H.....G...C.....#",
	"#............................#",
	"#............................#",
	"#............................#",
	"#.............T..............#",
	"#############,,,,#############",
	"##############################",
]

# Atlas coords in assets/sprites/tilesets/_sheet_tileset.png
const TILE_FACTORY_FLOOR := Vector2i(0, 0)
const TILE_BASEMENT_FLOOR := Vector2i(1, 0)
const TILE_WALL := Vector2i(2, 0)

const START_CONTAINERS := 4
const CONTAINERS_PER_DELIVERY := 5
const RHYTHM_PER_CONTAINER := 0.03  # ~0.4 per full day → ending on day 3
const DAYS_BEFORE_ENDING := 3

const ShredderScene := preload("res://scenes/objects/Shredder.tscn")
const NPCScene := preload("res://scenes/actors/NPC.tscn")
const PropScene := preload("res://scenes/objects/Prop.tscn")
const BLACK_BIRD := preload("res://assets/sprites/objects/factory_shag.png")

const PROPS := {
	"L": {
		"texture": preload("res://assets/sprites/objects/filing_cabinet.png"),
		"examine": "Check locker",
		"lines": ["A gray locker. Inside hangs a spare apron, an employee number sewn onto the chest."],
	},
	"W": {
		"texture": preload("res://assets/sprites/objects/power_tower.png"),
		"examine": "Look at the Power Tower",
		"lines": [
			"The Captain's Power Tower. A pull-up bar, a dip station, handles worn smooth.",
			"Nobody else touches it.",
		],
	},
	"R": {
		"texture": preload("res://assets/sprites/objects/desk.png"),
		"examine": "Look at the counter",
		"lines": ["The Print Services reception counter. There is never anyone behind it."],
	},
}

var NPCS := {
	"I": {
		"name": "Itsumi",
		"walk": preload("res://assets/sprites/npcs/itsumi_walk.png"),
		"work": preload("res://assets/sprites/npcs/itsumi_work.png"),
		"patrol": [Vector2.ZERO, Vector2(4 * TILE, 0)],
		"conversations": [
			[
				"Morning, Ushiyama-san. The TRAN people bring containers down at ten and three.",
				"Until then, work through whatever's left on the cart.",
				"If a machine jams, don't fight it. Move to the next one. There are fourteen.",
				"Full bags go back on the cart. They take them away. Where to, I've never asked.",
			],
			["You're doing fine. Steady is better than fast down here."],
		],
	},
	"H": {
		"name": "Hanzake",
		"walk": preload("res://assets/sprites/npcs/hanzake_walk.png"),
		"work": preload("res://assets/sprites/npcs/hanzake_work.png"),
		"working": true,
		"conversations": [
			[
				"Mm? Don't mind the leg. A jack came down on it, back when I was on the line.",
				"Upstairs they call me the Giant Salamander. I don't mind.",
				"Salamanders live a long time.",
			],
			["Feed it slow. It sounds nicer that way."],
		],
	},
	"G": {
		"name": "The Giant",
		"walk": preload("res://assets/sprites/npcs/the_giant_walk.png"),
		"patrol": [Vector2.ZERO, Vector2(0, -2 * TILE), Vector2(2 * TILE, -2 * TILE)],
		"conversations": [
			[
				"...",
				{"speaker": "", "text": "He grins, all teeth, and gives a low grunt that might be a greeting."},
			],
			[{"speaker": "", "text": "The Giant nods at your machine, then at his own. Approval, maybe."}],
		],
	},
	"C": {
		"name": "Captain Samukawa",
		"walk": preload("res://assets/sprites/npcs/captain_samukawa_walk.png"),
		"work": preload("res://assets/sprites/npcs/captain_samukawa_work.png"),
		"min_day": 2,  # in hospital on day one
		"conversations": [
			[
				"Ah! The new one. Ushiyama-san! Sorry I wasn't here to welcome you.",
				"Hospital. Terrible food. I'm fine now, fine.",
				"That's my Power Tower over there. A few pull-ups between batches keeps the blood moving.",
			],
			["Tonight, maybe a commercial. Moo-Moo Yakiniku. We'll see, we'll see."],
		],
	},
	"O": {
		"name": "Goto",
		"walk": preload("res://assets/sprites/npcs/goto_walk.png"),
		"conversations": [
			[
				"Ah, Ushiyama-san! Yes. The shredding. Very important work. Very confidential.",
				"You signed the pledge? Good, good. Nothing leaves the factory. Not even, ah... well. Nothing.",
				"If anyone asks for me, I'm upstairs. Or in PR. One of those.",
			],
			["Shredding! Excellent. Keep it up. Whatever it is."],
		],
	},
}

const RHYTHM_FRAGMENTS := [
	"The pages sound like wings.",
	"Black, white, black, white.",
	"Your arms feel lighter than they should.",
	"Is this work, or just a sound?",
	"The hum is inside your chest now.",
]

@onready var floor_layer: TileMapLayer = $Floor
@onready var entities: Node2D = $Entities
@onready var player: CharacterBody2D = $Entities/Player
@onready var tran_cart: StaticBody2D = $Entities/TranCart
@onready var tran_delivery: Node = $TRANDelivery
@onready var hud: CanvasLayer = $HUD

var _pages_today := 0
var _bags_today := 0
var _ending_started := false

func _ready() -> void:
	_build_level()

	player.prompt_changed.connect(hud.set_prompt)
	player.carrying_changed.connect(hud.set_carry)
	hud.set_carry("")
	tran_delivery.delivery_arrived.connect(_on_tran_delivery)
	tran_cart.bag_loaded.connect(_on_bag_loaded)
	for shredder in get_tree().get_nodes_in_group("shredders"):
		shredder.shredded.connect(_on_shredded)
	GameClock.bell_rang.connect(_on_bell)

	tran_cart.deliver(START_CONTAINERS)
	_update_stats()
	hud.set_surreal(GameState.yoshiko_rhythm, 0.01)

	GameClock.start_day()
	if GameState.day >= DAYS_BEFORE_ENDING:
		hud.toast("Rain on the high windows.", 4.0)
	else:
		hud.toast("Day %d. Print Services, basement." % GameState.day, 3.0)

# --- Level construction ---------------------------------------------------------

func _build_level() -> void:
	var shredder_id := 1
	for y in LAYOUT.size():
		var row := LAYOUT[y]
		for x in row.length():
			var ch := row[x]
			var cell := Vector2i(x, y)
			var pos := Vector2(x * TILE + TILE / 2.0, y * TILE + TILE / 2.0)

			var tile := TILE_BASEMENT_FLOOR
			if ch == "#":
				tile = TILE_WALL
			elif ch in [",", "R", "O"]:
				tile = TILE_FACTORY_FLOOR
			floor_layer.set_cell(cell, 0, tile)

			match ch:
				"P":
					player.position = pos
				"T":
					tran_cart.position = pos
				"S":
					var s := ShredderScene.instantiate()
					s.machine_id = shredder_id
					s.position = pos
					entities.add_child(s)
					shredder_id += 1
				_:
					if PROPS.has(ch):
						_spawn_prop(PROPS[ch], pos)
					elif NPCS.has(ch):
						_spawn_npc(NPCS[ch], pos)

	var cam: Camera2D = player.camera
	cam.limit_left = 0
	cam.limit_top = 0
	cam.limit_right = LAYOUT[0].length() * TILE
	cam.limit_bottom = LAYOUT.size() * TILE

func _spawn_prop(data: Dictionary, pos: Vector2) -> void:
	var prop := PropScene.instantiate()
	prop.texture = data.texture
	prop.examine_text = data.examine
	prop.lines = data.lines
	prop.position = pos
	entities.add_child(prop)

func _spawn_npc(data: Dictionary, pos: Vector2) -> void:
	if GameState.day < data.get("min_day", 1):
		return
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

# --- Day structure ----------------------------------------------------------------

func _on_bell(event_name: String) -> void:
	match event_name:
		"pre_start":
			hud.toast("The bell. Five minutes to nine.")
		"work_start":
			var lines: Array = ["Nine o'clock. Across the floor, the morning meeting begins."]
			if GameState.day == 1:
				lines.append({"speaker": "Itsumi", "text": "The Captain's still in hospital, so it's just me today. Same as always: shred, bag, cart."})
			else:
				lines.append({"speaker": "Captain Samukawa", "text": "Good morning! Another fine day for paper. Let's be careful out there."})
			DialogueManager.start(lines)
		"lunch_start":
			hud.toast("Noon bell. Lunch.")
			_clear_jams()
		"pre_return":
			hud.toast("Five minutes.")
		"lunch_end":
			hud.toast("One o'clock. Back to the machines.")
		"work_end":
			_end_day()

func _clear_jams() -> void:
	for shredder in get_tree().get_nodes_in_group("shredders"):
		shredder.clear_jam()

func _on_tran_delivery(_slot: int) -> void:
	var collected: int = tran_cart.deliver(CONTAINERS_PER_DELIVERY)
	_clear_jams()
	var lines: Array = [
		"The south door rattles open. Two TRAN workers wheel in fresh containers.",
	]
	if collected > 0:
		lines.append("They heave %d full bag%s onto their trolley without a word." % [collected, "" if collected == 1 else "s"])
	lines.append({"speaker": "TRAN Worker", "text": "Maintenance came through. Machines are clear."})
	DialogueManager.start(lines)

func _on_shredded(_id: int, pages: int) -> void:
	_pages_today += pages
	GameState.yoshiko_pages_total += pages
	GameState.yoshiko_rhythm = clampf(GameState.yoshiko_rhythm + RHYTHM_PER_CONTAINER, 0.0, 1.0)
	hud.set_surreal(GameState.yoshiko_rhythm)
	_update_stats()

	if GameState.yoshiko_rhythm >= 1.0 and GameState.day >= DAYS_BEFORE_ENDING:
		_play_transformation()
	elif GameState.yoshiko_rhythm > 0.5 and randf() < 0.35:
		hud.toast(RHYTHM_FRAGMENTS.pick_random(), 2.5)

func _on_bag_loaded() -> void:
	_bags_today += 1
	_update_stats()

func _update_stats() -> void:
	hud.set_stats("Pages %d   Bags %d" % [_pages_today, _bags_today])

func _end_day() -> void:
	if _ending_started:
		return
	GameClock.stop()
	var lines: Array = [
		"5:30. One by one the machines wind down.",
		"%d pages today. Yoshiko hangs up her apron." % _pages_today,
	]
	if GameState.day == 2:
		lines.append({"speaker": "Captain Samukawa", "text": "Commercial! Moo-Moo Yakiniku, everyone. My treat. Well, partly."})
	DialogueManager.start(lines)
	await DialogueManager.dialogue_ended
	GameState.day += 1
	SceneTransition.change_scene(LEVEL_PATH)

func _play_transformation() -> void:
	if _ending_started:
		return
	_ending_started = true
	GameClock.stop()
	player.frozen = true
	DialogueManager.start([
		"The last pages go in. The machine hums.",
		"Rain on the high windows. The shredder sounds like wind.",
		"Yoshiko feeds the last page. Something shifts.",
	])
	await DialogueManager.dialogue_ended

	# She becomes a black bird.
	var sprite: AnimatedSprite2D = player.sprite
	sprite.visible = false
	player.carry_sprite.visible = false
	var bird := Sprite2D.new()
	bird.texture = BLACK_BIRD
	bird.scale = Vector2(2, 2)
	player.add_child(bird)
	hud.set_surreal(1.0, 2.0)
	await get_tree().create_timer(2.5).timeout

	DialogueManager.start([
		"On the floor where she stood, a black bird shakes out its feathers.",
		"It does not fly. It walks, unhurried, toward the river.",
	])
	await DialogueManager.dialogue_ended
	GameState.reset_yoshiko()
	SceneTransition.change_scene(MENU_PATH)
