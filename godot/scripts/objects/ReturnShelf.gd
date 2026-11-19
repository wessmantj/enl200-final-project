extends StaticBody2D
## The tall filing cabinet / return shelf in the Document Division. Fresh
## proofreading packets are stacked here; finished (marked-up) packets come
## back here and are collected once a day. One packet per day may be the
## Samukawa boy's fauna report — set `report_pending` before it is taken.

signal packet_taken(is_report: bool)
signal packet_filed

@export var available := 0

@onready var count_label: Label = $CountLabel

var filed := 0
var report_pending := false

func _ready() -> void:
	_refresh()

func get_prompt(player: Node) -> String:
	if player.has_marked_packet():
		return "[E] File the finished packet on the return shelf"
	if not player.hands_free():
		return "Return shelf — finish the packet you're carrying first"
	if available > 0:
		return "[E] Take a packet to proofread (%d waiting)" % available
	return "Return shelf — nothing left to take. Collected at day's end."

func interact(player: Node) -> void:
	if player.has_marked_packet():
		player.take_marked_packet()
		filed += 1
		packet_filed.emit()
	elif player.hands_free() and available > 0:
		available -= 1
		var is_report := report_pending
		report_pending = false
		player.give_documents()
		packet_taken.emit(is_report)
	_refresh()

func stock(count: int) -> void:
	available += count
	_refresh()

func _refresh() -> void:
	count_label.text = "%d" % available if available > 0 else ""
