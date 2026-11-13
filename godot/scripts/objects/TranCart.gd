extends StaticBody2D
## The TRAN cart by the south door. TRAN workers drop document containers
## here and haul away the full shred bags left on it.

signal bag_loaded

@export var containers := 0

@onready var count_label: Label = $CountLabel

var bags_waiting := 0

func _ready() -> void:
	_refresh()

func get_prompt(player: Node) -> String:
	if player.has_full_bag():
		return "[E] Load the full bag onto the TRAN cart"
	if not player.hands_free():
		return "TRAN cart — your hands are full"
	if containers > 0:
		return "[E] Take a document container (%d left)" % containers
	return "TRAN cart — empty. Deliveries at 10:00 and 15:00."

func interact(player: Node) -> void:
	if player.has_full_bag():
		player.take_full_bag()
		bags_waiting += 1
		bag_loaded.emit()
	elif player.hands_free() and containers > 0:
		containers -= 1
		player.give_documents()
	_refresh()

func deliver(count: int) -> int:
	## Adds containers, collects waiting bags. Returns bags collected.
	containers += count
	var collected := bags_waiting
	bags_waiting = 0
	_refresh()
	return collected

func _refresh() -> void:
	count_label.text = "%d" % containers if containers > 0 else ""
