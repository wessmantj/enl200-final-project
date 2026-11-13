extends Node

signal dialogue_started
signal dialogue_ended
signal line_shown(speaker: String, text: String)

var _lines: Array[Dictionary] = []
var _index := 0
var is_active := false

func start(lines: Array[Dictionary]) -> void:
	_lines = lines
	_index = 0
	is_active = true
	emit_signal("dialogue_started")
	show_current()

func show_current() -> void:
	if _index >= _lines.size():
		end()
		return
	var line := _lines[_index]
	emit_signal("line_shown", line.get("speaker", ""), line.get("text", ""))

func advance() -> void:
	if not is_active:
		return
	_index += 1
	show_current()

func end() -> void:
	is_active = false
	emit_signal("dialogue_ended")
