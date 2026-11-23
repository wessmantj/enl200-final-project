extends Node2D
## The Narrator's level — the Document Division proofreading office.
## Yoshiko's unemployed brother, a temp, marks errors in packets he doesn't
## understand, dozes at his desk, and slowly loses the edge between sleep and
## waking. The room is built from LAYOUT so it can be edited as text.

const LEVEL_PATH := "res://scenes/levels/NarratorLevel.tscn"
const MENU_PATH := "res://scenes/ui/MainMenu.tscn"
const TILE := 64

# Legend:
#   #  wall / partition   .  office floor      P  player start
#   D  your proof desk    F  return shelf      J  coworker desk (scenery)
#   B  filing cabinet     H  phone             N  window (look outside)
#   K  Kasumi             I  Irinoi            G  Glasses
#   O  Goto               U  shuttle stop
const LAYOUT: Array[String] = [
	"######################",
	"#....................#",
	"#..B..B.........N.N..#",
	"#....................#",
	"#..DJ.......K........#",
	"#..P#................#",
	"#...........O........#",
	"#..J#..J.....I.......#",
	"#..##..#.............#",
	"#..J...J.............#",
	"#..........G.........#",
	"#.......H.......F..U.#",
	"#....................#",
	"######################",
]

# Atlas coords in assets/sprites/tilesets/_sheet_tileset.png
const TILE_OFFICE_FLOOR := Vector2i(0, 0)
const TILE_WALL := Vector2i(2, 0)

const PACKETS_PER_DAY := 6
const HAZE_PER_PACKET := 0.06
const HAZE_PER_SLEEP := 0.15
const DAYS_BEFORE_ENDING := 3

# Idle this long (real seconds, clock running) and the narrator nods off.
const IDLE_SLEEP_SECONDS := 14.0

const ReturnShelfScene := preload("res://scenes/objects/ReturnShelf.tscn")
const ProofDeskScene := preload("res://scenes/objects/ProofDesk.tscn")
const NPCScene := preload("res://scenes/actors/NPC.tscn")
const PropScene := preload("res://scenes/objects/Prop.tscn")
const BusStopScene := preload("res://scenes/objects/BusStop.tscn")

const PROPS := {
	"J": {
		"texture": preload("res://assets/sprites/objects/desk.png"),
		"examine": "Look at the desk",
		"lines": ["A coworker's desk, hemmed in by partitions. From here you can't see a face, only the top of a head."],
	},
	"B": {
		"texture": preload("res://assets/sprites/objects/filing_cabinet.png"),
		"examine": "Open the filing cabinet",
		"lines": ["Drawers of packets waiting their turn. Booklets, blueprints, manuals, manuscripts. No order you can find."],
	},
	"H": {
		"texture": preload("res://assets/sprites/objects/desk.png"),
		"examine": "Look at the phone",
		"lines": [
			"The office phone. Your girlfriend set this job up through her agency.",
			{"speaker": "Narrator", "text": "A personal connection got me hired. I try not to think about that, and think about it constantly."},
		],
	},
	"N": {
		"texture": preload("res://assets/sprites/objects/filing_cabinet.png"),
		"examine": "Look out the window",
		"lines": ["Grey light over the factory grounds. The river, the bridge, a bus pulling away. It goes on forever out there."],
	},
}

var NPCS := {
	"K": {
		"name": "Kasumi",
		"walk": preload("res://assets/sprites/npcs/kasumi_walk.png"),
		"patrol": [Vector2.ZERO, Vector2(3 * TILE, 0)],
		"conversations": [
			[
				{"speaker": "Kasumi", "text": "You're the new temp? Same agency as me. Don't look so nervous."},
				"The work is simple. Take a packet from the shelf, mark the errors, bring it back. That's the whole day.",
				"No one signs for anything. No one traces a mistake to you. Honestly, no one reads it after us at all.",
				{"speaker": "Narrator", "text": "(She smells faintly of peach candy. It's the kindest thing in this building.)"},
			],
			["If your eyes go heavy, let them. The partitions hide you. Everyone sleeps a little down here."],
		],
	},
	"I": {
		"name": "Irinoi",
		"walk": preload("res://assets/sprites/npcs/itsumi_walk.png"),
		"conversations": [
			[
				{"speaker": "Irinoi", "text": "Brownish perm, roughened voice — yes, that's me. Been temping longer than you've been shaving."},
				"Advice? Don't try to understand the documents. That way lies trouble. Just mark what's wrong and move on.",
				"Half of it's fiction anyway. Reports on birds, on moss, on things that can't be real. You'll see.",
			],
			["Still here? Good. Steady hands, empty head. That's the trick."],
		],
	},
	"G": {
		"name": "Glasses",
		"walk": preload("res://assets/sprites/npcs/goto_walk.png"),
		"conversations": [
			[
				{"speaker": "Glasses", "text": "..."},
				{"speaker": "", "text": "The young one with the blue glasses only nods. He listens to everything and offers nothing."},
			],
			[{"speaker": "", "text": "Glasses glances at your packet, then back at his. He has heard every word in this room."}],
		],
	},
	"O": {
		"name": "Goto",
		"walk": preload("res://assets/sprites/npcs/goto_walk.png"),
		"patrol": [Vector2.ZERO, Vector2(3 * TILE, 0)],
		"conversations": [
			[
				{"speaker": "Goto", "text": "Ah, the proofreading floor! Yes. I look in on this division too. And Print Services. And the grounds."},
				{"speaker": "Narrator", "text": "(I've seen this man somewhere. Or someone exactly like him. The factory is full of him.)"},
				{"speaker": "Goto", "text": "Mark the errors, file the packets. Don't trouble yourself over what any of it means. That's rather the spirit of the place."},
			],
			[{"speaker": "Goto", "text": "Still here? Good, good. Catch the bridge shuttle at lunch if you need air."}],
		],
	},
}

const HAZE_FRAGMENTS := [
	"How long have you been sitting here?",
	"The words slide off the page.",
	"Was that your name, or the hum of the lights?",
	"The red marks aren't all yours.",
	"Awake. Probably awake.",
]

@onready var floor_layer: TileMapLayer = $Floor
@onready var entities: Node2D = $Entities
@onready var player: CharacterBody2D = $Entities/Player
@onready var hud: CanvasLayer = $HUD

var shelf: StaticBody2D
var _packets_today := 0
var _carrying_report := false
var _idle_time := 0.0
var _sleeping := false
var _ending_started := false
var _bus_pos := Vector2.ZERO

func _ready() -> void:
	GameState.current_character = "narrator"
	_build_level()

	player.prompt_changed.connect(hud.set_prompt)
	player.carrying_changed.connect(hud.set_carry)
	hud.set_carry("")
	shelf.packet_taken.connect(_on_packet_taken)
	shelf.packet_filed.connect(_on_packet_filed)
	for desk in get_tree().get_nodes_in_group("proof_desks"):
		desk.proofed.connect(_on_proofed)
	GameClock.bell_rang.connect(_on_bell)

	# The Samukawa boy's fauna report turns up from day two, once per playthrough.
	shelf.stock(PACKETS_PER_DAY)
	if GameState.day >= 2 and not GameState.narrator_read_report:
		shelf.report_pending = true

	hud.set_surreal(GameState.narrator_haze, 0.01)

	if GameState.returning_from_bridge:
		_resume_from_bridge()
	else:
		_update_stats()
		GameClock.start_day()
		hud.toast("Day %d. Document Division, proofreading floor." % GameState.day, 3.0)

func _resume_from_bridge() -> void:
	GameState.returning_from_bridge = false
	var p := GameState.take_day_progress()
	_packets_today = p.get("packets", 0)
	GameState.restore_clock()
	player.position = _bus_pos + Vector2(0, -TILE)
	_update_stats()
	hud.toast("Back from the bridge. The shelf is full again.", 3.0)

## Stash the day's tally before the shuttle leaves (WorldTravel pauses the clock).
func on_board_bus() -> void:
	GameState.save_day_progress({"packets": _packets_today})

# --- Level construction ---------------------------------------------------------

func _build_level() -> void:
	for y in LAYOUT.size():
		var row := LAYOUT[y]
		for x in row.length():
			var ch := row[x]
			var cell := Vector2i(x, y)
			var pos := Vector2(x * TILE + TILE / 2.0, y * TILE + TILE / 2.0)

			var tile := TILE_OFFICE_FLOOR
			if ch == "#":
				tile = TILE_WALL
			floor_layer.set_cell(cell, 0, tile)

			match ch:
				"P":
					player.position = pos
				"U":
					_bus_pos = pos
					var stop := BusStopScene.instantiate()
					stop.position = pos
					entities.add_child(stop)
				"D":
					var d := ProofDeskScene.instantiate()
					d.add_to_group("proof_desks")
					d.position = pos
					entities.add_child(d)
				"F":
					shelf = ReturnShelfScene.instantiate()
					shelf.position = pos
					entities.add_child(shelf)
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

# --- Sleep mechanic ---------------------------------------------------------------

func _process(delta: float) -> void:
	if _sleeping or _ending_started or not GameClock.is_running:
		return
	if DialogueManager.is_active or player.frozen:
		_idle_time = 0.0
		return
	# Any movement resets the drowsiness.
	if player.velocity.length() > 1.0:
		_idle_time = 0.0
		return
	_idle_time += delta
	if _idle_time >= IDLE_SLEEP_SECONDS:
		_fall_asleep()

func _fall_asleep() -> void:
	_sleeping = true
	_idle_time = 0.0
	player.frozen = true
	await hud.fade_to_black(1.2)

	# Time slips away while he's out.
	GameClock.skip(randi_range(40, 90))
	GameState.narrator_haze = clampf(GameState.narrator_haze + HAZE_PER_SLEEP, 0.0, 1.0)
	hud.set_surreal(GameState.narrator_haze, 0.5)

	await hud.fade_from_black(1.2)
	DialogueManager.start([
		"You jerk awake. The clock has moved and you did not.",
		{"speaker": "Narrator", "text": "There are red marks on the page I don't remember making. They're not wrong, exactly."},
	])
	await DialogueManager.dialogue_ended
	player.frozen = false
	_sleeping = false

	if GameState.narrator_haze >= 1.0 and GameState.day >= DAYS_BEFORE_ENDING:
		_play_ending()
	elif not GameClock.is_running:
		# He slept clean through to the end of the day.
		_end_day()

# --- Proofreading loop ------------------------------------------------------------

func _on_packet_taken(is_report: bool) -> void:
	_carrying_report = is_report

func _on_proofed() -> void:
	GameState.narrator_haze = clampf(GameState.narrator_haze + HAZE_PER_PACKET, 0.0, 1.0)
	hud.set_surreal(GameState.narrator_haze)
	if _carrying_report:
		_read_fauna_report()
	elif GameState.narrator_haze > 0.5 and randf() < 0.35:
		hud.toast(HAZE_FRAGMENTS.pick_random(), 2.5)

func _on_packet_filed() -> void:
	_packets_today += 1
	GameState.narrator_packets_total += 1
	if _carrying_report:
		GameState.narrator_read_report = true
		_carrying_report = false
	_update_stats()
	# Working the floor, he finally catches sight of his sister.
	if not GameState.narrator_saw_yoshiko and GameState.day >= 2 and _packets_today >= 2:
		_spot_yoshiko()

func _read_fauna_report() -> void:
	DialogueManager.start([
		"This packet is a child's report — a year of observations on the factory's animals.",
		"Factory shags that can't truly fly. Coypus spreading from the drains. Grey-headed gulls that never leave.",
		{"speaker": "Narrator", "text": "Signed Hikaru Samukawa. A boy's fantasy, surely. Birds that don't fly. Nonsense."},
		{"speaker": "Narrator", "text": "(I mark the typography and nothing else. It isn't my job to believe it.)"},
	])

func _spot_yoshiko() -> void:
	GameState.narrator_saw_yoshiko = true
	GameClock.stop()
	player.frozen = true
	if DialogueManager.is_active:
		await DialogueManager.dialogue_ended
	DialogueManager.start([
		"Through the glass, out on the grounds, a woman in a grey apron crosses toward the river.",
		{"speaker": "Narrator", "text": "That walk. The set of her shoulders. That's... Yoshiko. My sister works here?"},
		{"speaker": "Narrator", "text": "A black bird lifts off the sill and settles again. When I look back, she's gone."},
	])
	await DialogueManager.dialogue_ended
	player.frozen = false
	if not _ending_started:
		GameClock.is_running = true

func _update_stats() -> void:
	hud.set_stats("Packets filed %d/%d" % [_packets_today, PACKETS_PER_DAY])

# --- Day structure ----------------------------------------------------------------

func _on_bell(event_name: String) -> void:
	match event_name:
		"pre_start":
			hud.toast("The bell. Five minutes to nine.")
		"work_start":
			DialogueManager.start([
				"Nine o'clock. The office settles into its papery quiet.",
				{"speaker": "Kasumi", "text": "Morning. Packets on the shelf, red pen in the drawer. Pace yourself."},
			])
		"lunch_start":
			hud.toast("Noon bell. Lunch, if you can call it that.")
		"pre_return":
			hud.toast("Five minutes.")
		"lunch_end":
			hud.toast("One o'clock. Back to the packets.")
		"work_end":
			_end_day()

func _end_day() -> void:
	if _ending_started or _sleeping:
		return
	GameClock.stop()
	var lines: Array = [
		"5:30. The shelf is emptied; the day's packets are carried off by someone you never see.",
		"%d packets today. You never find out if any of it mattered." % _packets_today,
	]
	DialogueManager.start(lines)
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
	var lines: Array = [
		"The days have stopped keeping themselves apart.",
	]
	if GameState.narrator_saw_yoshiko:
		lines.append({"speaker": "Narrator", "text": "My sister is somewhere in this building, feeding paper to a machine. Or I dreamed her. I can't say which."})
	if GameState.narrator_read_report:
		lines.append({"speaker": "Narrator", "text": "Birds that can't fly. Maybe the boy was right. Maybe I'm one of them now."})
	lines.append("You take a packet from the shelf. You sit. You cannot tell if you are awake.")
	DialogueManager.start(lines)
	await DialogueManager.dialogue_ended
	GameState.reset_narrator()
	SceneTransition.change_scene(MENU_PATH)
