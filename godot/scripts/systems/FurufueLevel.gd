extends Node2D
## Furufue's level — the factory grounds and his live-in lab. A bryologist
## paid to "green the roofs," he logs moss across grounds scattered by Perlin
## noise, runs the family moss hunt, and is finally asked what fifteen years
## of this bought. Structure comes from LAYOUT; the moss comes from noise.

const LEVEL_PATH := "res://scenes/levels/FurufueLevel.tscn"
const MENU_PATH := "res://scenes/ui/MainMenu.tscn"
const TILE := 64

# Legend:
#   #  wall             .  grounds            ,  lab interior
#   W  river            P  player start       A  Aoyama
#   D  desk             M  microscope         E  bed
#   T  tomato plant     H  shiso              R  river sign
#   S  factory shag     C  coypu (drains)
const LAYOUT: Array[String] = [
	"############################",
	"#,,,,,#.....T.H.T.H.T......#",
	"#,D,M,#....................#",
	"#,,,,,#....................#",
	"#,E,,,.....................#",
	"#,,,,,#....................#",
	"#######....................#",
	"#..........................#",
	"#...P.....................C#",
	"#..........A..............C#",
	"#.........................C#",
	"#.........................##",
	"#.R......................S.#",
	"#WWWWWWWSWWWWWWWSWWWWWWWSWW#",
	"#WWWWWWWWWWWWWWWWWWWWWWWWWW#",
	"############################",
]

const TILE_GROUNDS := Vector2i(0, 0)   # factory_floor
const TILE_LAB := Vector2i(1, 0)       # basement_floor (interior)
const TILE_WALL := Vector2i(2, 0)
const TILE_RIVER := Vector2i(1, 0)     # basement_floor stands in for water

const MOSS_THRESHOLD := 0.12
const RARE_THRESHOLD := 0.42
const SAMPLES_GOAL := 10
const DRIFT_PER_SAMPLE := 0.03
const RARE_DRIFT_BONUS := 0.05
const HUNT_SAMPLES_TRIGGER := 3
const DAYS_BEFORE_ENDING := 3

const MossScene := preload("res://scenes/objects/MossSample.tscn")
const CritterScene := preload("res://scenes/objects/Critter.tscn")
const NPCScene := preload("res://scenes/actors/NPC.tscn")
const PropScene := preload("res://scenes/objects/Prop.tscn")

const TEX_SHAG := preload("res://assets/sprites/objects/factory_shag.png")
const TEX_COYPU := preload("res://assets/sprites/objects/coypu.png")

const PROPS := {
	"D": {
		"texture": preload("res://assets/sprites/objects/desk.png"),
		"examine": "Look at the desk",
		"lines": ["Field notebooks, a loupe, pressed samples between glass. Fifteen years of moss, catalogued and shelved."],
	},
	"M": {
		"texture": preload("res://assets/sprites/objects/desk.png"),
		"examine": "Look through the microscope",
		"lines": [
			"Under the lens, the moss is a forest in miniature — rhizoids, stems, tiny unfurling leaves.",
			{"speaker": "Furufue", "text": "Beautiful. Genuinely beautiful. And no one will ever ask me why it matters, or whether it does."},
		],
	},
	"E": {
		"texture": preload("res://assets/sprites/objects/filing_cabinet.png"),
		"examine": "Look at the bed",
		"lines": ["He lives where he works. The factory gave him a house on its grounds. He has never once left for long."],
	},
	"T": {
		"texture": preload("res://assets/sprites/tilesets/moss_dense.png"),
		"examine": "Check the tomatoes",
		"lines": ["Tomatoes, ripening in the factory's grey light. He grows them out back, with shiso, for something to tend."],
	},
	"H": {
		"texture": preload("res://assets/sprites/tilesets/moss_patch.png"),
		"examine": "Check the shiso",
		"lines": ["Shiso, broad and green. It does better here than it has any right to."],
	},
	"R": {
		"texture": preload("res://assets/sprites/objects/desk.png"),
		"examine": "Look at the river",
		"lines": ["The factory river, slow and brown. A grey-headed shag stands on a rock and does not fly."],
	},
}

var NPCS := {
	"A": {
		"name": "Aoyama",
		"walk": preload("res://assets/sprites/npcs/aoyama_walk.png"),
		"patrol": [Vector2.ZERO, Vector2(2 * TILE, 0)],
		"conversations": [
			[
				{"speaker": "Aoyama", "text": "Furufue-san! The green-roof project, yes. Walk the grounds, log the moss, note what spreads. That's the whole of it."},
				"Deadlines? None. A report, eventually. Whenever. The factory is patient.",
				{"speaker": "Furufue", "text": "(Patient, or indifferent. I've stopped being able to tell the difference.)"},
			],
			["Oh — the staff want a family moss hunt. Bring the kids out, show them the green. Harmless. Come find me when you've logged a few."],
			["Good work. Or work, anyway. Keep at it."],
		],
	},
}

const DRIFT_FRAGMENTS := [
	"The moss spreads whether you log it or not.",
	"Fifteen years. The grounds look exactly the same.",
	"A bird that cannot fly is still, technically, a bird.",
	"Well-paid. Unhurried. Hollow.",
	"What, exactly, is the work?",
]

@onready var floor_layer: TileMapLayer = $Floor
@onready var entities: Node2D = $Entities
@onready var player: CharacterBody2D = $Entities/Player
@onready var hud: CanvasLayer = $HUD

var _samples_today := 0
var _ending_started := false

func _ready() -> void:
	_build_level()

	player.prompt_changed.connect(hud.set_prompt)
	player.carrying_changed.connect(hud.set_carry)
	hud.set_carry("")
	for moss in get_tree().get_nodes_in_group("moss"):
		moss.logged.connect(_on_moss_logged)
	for npc in entities.get_children():
		if npc.has_signal("talked"):
			npc.talked.connect(_on_npc_talked)
	GameClock.bell_rang.connect(_on_bell)

	_update_stats()
	hud.set_surreal(GameState.furufue_drift, 0.01)

	GameClock.start_day()
	hud.toast("Day %d. Green Roofs — the factory grounds." % GameState.day, 3.0)

# --- Level construction ---------------------------------------------------------

func _build_level() -> void:
	var noise := FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	noise.frequency = 0.14
	noise.seed = 1983  # the year the novel is set; moss regrows the same each day

	for y in LAYOUT.size():
		var row := LAYOUT[y]
		for x in row.length():
			var ch := row[x]
			var cell := Vector2i(x, y)
			var pos := Vector2(x * TILE + TILE / 2.0, y * TILE + TILE / 2.0)

			var tile := TILE_GROUNDS
			match ch:
				"#":
					tile = TILE_WALL
				",":
					tile = TILE_LAB
				"W":
					tile = TILE_RIVER
			floor_layer.set_cell(cell, 0, tile)

			match ch:
				"P":
					player.position = pos
				"S":
					_spawn_critter(TEX_SHAG, "shag", pos, [
						"A factory shag. It opens its wings, thinks better of it, and folds them again.",
						{"speaker": "Furufue", "text": "They've forgotten how, or never learned. They walk to the river instead."},
					])
				"C":
					_spawn_critter(TEX_COYPU, "coypu", pos, [
						"A coypu, slick and unbothered, come up from the drains. There are more every year.",
					])
				".":
					# Grounds: Perlin noise decides where moss grows.
					var n := noise.get_noise_2d(x, y)
					if n > MOSS_THRESHOLD:
						_spawn_moss(pos, n > RARE_THRESHOLD)
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

func _spawn_moss(pos: Vector2, rare: bool) -> void:
	var moss := MossScene.instantiate()
	moss.rare = rare
	moss.position = pos
	entities.add_child(moss)

func _spawn_critter(texture: Texture2D, display_name: String, pos: Vector2, lines: Array) -> void:
	var critter := CritterScene.instantiate()
	critter.texture = texture
	critter.display_name = display_name
	critter.lines = lines
	critter.position = pos
	entities.add_child(critter)

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

# --- Moss hunt loop ---------------------------------------------------------------

func _on_moss_logged(is_rare: bool) -> void:
	_samples_today += 1
	GameState.furufue_samples_total += 1
	var gain := DRIFT_PER_SAMPLE + (RARE_DRIFT_BONUS if is_rare else 0.0)
	GameState.furufue_drift = clampf(GameState.furufue_drift + gain, 0.0, 1.0)
	hud.set_surreal(GameState.furufue_drift)
	_update_stats()

	if is_rare:
		hud.toast("A rare one. You note it carefully.", 2.5)
	elif GameState.furufue_drift > 0.5 and randf() < 0.3:
		hud.toast(DRIFT_FRAGMENTS.pick_random(), 2.5)

	# Old man Samukawa and his grandson come by on day two.
	if GameState.day >= 2 and not GameState.furufue_samukawa_done and _samples_today >= 1:
		_samukawa_visit()

func _update_stats() -> void:
	hud.set_stats("Moss logged %d/%d" % [_samples_today, SAMPLES_GOAL])

# --- Events -----------------------------------------------------------------------

func _on_npc_talked(display_name: String) -> void:
	if display_name == "Aoyama" and not GameState.furufue_hunt_done \
			and _samples_today >= HUNT_SAMPLES_TRIGGER:
		_family_moss_hunt()

func _family_moss_hunt() -> void:
	GameState.furufue_hunt_done = true
	GameClock.stop()
	player.frozen = true

	# A small crowd of children, borrowed from whatever sheets we have.
	var kid_sheets := [
		preload("res://assets/sprites/npcs/kasumi_walk.png"),
		preload("res://assets/sprites/npcs/goto_walk.png"),
		preload("res://assets/sprites/npcs/itsumi_walk.png"),
	]
	var kids: Array[Node2D] = []
	for i in kid_sheets.size():
		var kid := NPCScene.instantiate()
		kid.display_name = "child"
		kid.walk_sheet = kid_sheets[i]
		kid.conversations = []
		kid.position = player.position + Vector2((i - 1) * TILE, TILE + 8)
		entities.add_child(kid)
		kids.append(kid)

	DialogueManager.start([
		"The staff's children arrive in a loud, delighted knot, nets and jars in hand.",
		{"speaker": "Furufue", "text": "This way. Mind the river. The green you see on the north wall — that's the oldest colony. Twelve years old."},
		{"speaker": "A child", "text": "Mister, is it true about the Forest Pantser?"},
		{"speaker": "Furufue", "text": "The Forest Pantser. Yes. A creature that waits in the deep moss and yanks down the trousers of anyone who wanders off alone. So — don't wander off alone."},
		{"speaker": "A child", "text": "That's not real!"},
		{"speaker": "Furufue", "text": "(Nothing here is quite real. But it keeps them close, and that's the job today.)"},
	])
	await DialogueManager.dialogue_ended

	for kid in kids:
		kid.queue_free()
	player.frozen = false
	if not _ending_started:
		GameClock.is_running = true
	hud.toast("The children troop off toward the bus. Quiet again.", 3.0)

func _samukawa_visit() -> void:
	GameState.furufue_samukawa_done = true
	GameClock.stop()
	player.frozen = true
	if DialogueManager.is_active:
		await DialogueManager.dialogue_ended

	var old_man := NPCScene.instantiate()
	old_man.display_name = "Old Man Samukawa"
	old_man.walk_sheet = preload("res://assets/sprites/npcs/captain_samukawa_walk.png")
	old_man.conversations = []
	old_man.position = player.position + Vector2(TILE, TILE)
	entities.add_child(old_man)
	var hikaru := NPCScene.instantiate()
	hikaru.display_name = "Hikaru"
	hikaru.walk_sheet = preload("res://assets/sprites/npcs/goto_walk.png")
	hikaru.conversations = []
	hikaru.position = player.position + Vector2(2 * TILE, TILE)
	entities.add_child(hikaru)

	DialogueManager.start([
		"An old man crosses the grounds with his grandson, a serious boy clutching a thick, hand-bound folder.",
		{"speaker": "Old Man Samukawa", "text": "My grandson's spent the whole year watching your factory's animals. Birds, lizards, the coypus. Wrote it all up."},
		{"speaker": "Hikaru", "text": "Shags that can't fly. Grey-headed gulls that never leave. I sent a copy to the document office, for the records."},
		{"speaker": "Furufue", "text": "(A child's fauna report, bound for a proofreader who will mark its commas and believe none of it. As I log moss no one reads. We are the same, the boy and I.)"},
	])
	await DialogueManager.dialogue_ended
	old_man.queue_free()
	hikaru.queue_free()
	player.frozen = false
	if not _ending_started:
		GameClock.is_running = true

# --- Day structure ----------------------------------------------------------------

func _on_bell(event_name: String) -> void:
	match event_name:
		"pre_start":
			hud.toast("Morning on the grounds.")
		"work_start":
			DialogueManager.start([
				"Nine o'clock. Mist burning off the river.",
				{"speaker": "Aoyama", "text": "(by phone) Furufue-san, morning. No news, no deadlines. Just the moss. Talk soon."},
			])
		"lunch_start":
			hud.toast("Noon. Tomatoes and rice at the house.")
		"pre_return":
			hud.toast("The afternoon stretches out.")
		"lunch_end":
			hud.toast("Back to the grounds.")
		"work_end":
			_end_day()

func _end_day() -> void:
	if _ending_started:
		return
	GameClock.stop()
	DialogueManager.start([
		"Dusk. The grounds go quiet; the moss keeps doing what moss does.",
		"%d samples logged today. You file them where no one will look." % _samples_today,
	])
	await DialogueManager.dialogue_ended
	if GameState.day >= DAYS_BEFORE_ENDING:
		_play_ending()
		return
	GameState.day += 1
	SceneTransition.change_scene(LEVEL_PATH)

func _play_ending() -> void:
	if _ending_started:
		return
	_ending_started = true
	GameClock.stop()
	player.frozen = true
	hud.set_surreal(1.0, 2.0)
	DialogueManager.start([
		"Aoyama finds you on the grounds as the light fails.",
		{"speaker": "Aoyama", "text": "Fifteen years, Furufue-san. Fifteen years of moss on the factory's roofs. I have to ask — what have you actually accomplished?"},
		{"speaker": "Furufue", "text": "..."},
		{"speaker": "Furufue", "text": "(I have no answer. I had a field, a house, a wage, a quiet life. The moss spread. The birds forgot to fly. The coypus multiplied.)"},
		"You look out at the grounds. Something moves in the deep green that you decide not to name.",
	])
	await DialogueManager.dialogue_ended
	GameState.reset_furufue()
	SceneTransition.change_scene(MENU_PATH)
