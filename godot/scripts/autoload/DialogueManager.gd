extends Node
## Global dialogue queue. Each line is either a String (narration, no speaker)
## or a Dictionary {"speaker": String, "text": String}.

signal dialogue_started
signal dialogue_ended
signal line_shown(speaker: String, text: String)

var _lines: Array = []
var _index := 0
var is_active := false

func start(lines: Array) -> void:
	if lines.is_empty():
		return
	_lines = lines.duplicate()
	_index = 0
	is_active = true
	dialogue_started.emit()
	show_current()

func show_current() -> void:
	if _index >= _lines.size():
		end()
		return
	var line = _lines[_index]
	if line is Dictionary:
		line_shown.emit(line.get("speaker", ""), line.get("text", ""))
	else:
		line_shown.emit("", str(line))

func advance() -> void:
	if not is_active:
		return
	_index += 1
	show_current()

func end() -> void:
	is_active = false
	dialogue_ended.emit()
