extends StaticBody2D
## The narrator's own desk — a red pen, three dictionaries, a proofreader's
## handbook, and no computer. Sit with a fresh packet to proofread it by hand;
## it comes away marked up, to be carried to the return shelf.

signal proofed

const PROOF_SECONDS := 3.0

@onready var sprite: Sprite2D = $Sprite2D

func get_prompt(player: Node) -> String:
	if player.has_documents():
		return "[E] Sit and proofread the packet"
	if player.has_marked_packet():
		return "Your desk — take the marked packet to the return shelf"
	if not player.hands_free():
		return "Your desk — your hands are full"
	return "Your desk. A red pen and three dictionaries. No computer."

func interact(player: Node) -> void:
	if player.has_documents():
		player.face_toward(global_position)
		await player.do_work(PROOF_SECONDS)
		player.give_marked_packet()
		proofed.emit()
	elif player.has_marked_packet():
		DialogueManager.start(["The packet is marked. It goes to the return shelf."])
	else:
		DialogueManager.start([
			"A Japanese dictionary, an English dictionary, a character dictionary, a proofreader's handbook.",
			{"speaker": "Narrator", "text": "No one checks the work. No one signs for it. And still I reach for the right mark."},
		])
