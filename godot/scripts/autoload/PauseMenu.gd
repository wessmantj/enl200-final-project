extends CanvasLayer
## Escape menu, available in every level. Pauses the game and offers Resume,
## Character Select (back to the main menu) and Quit. Builds its own UI so it
## can be a plain autoload with no .tscn. Processes while the tree is paused.

const MENU_PATH := "res://scenes/ui/MainMenu.tscn"

var _open := false
var _vbox: VBoxContainer
var _resume_btn: Button

func _ready() -> void:
	layer = 90  # below SceneTransition's fade (100)
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_build_ui()

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.72)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	_vbox = VBoxContainer.new()
	_vbox.add_theme_constant_override("separation", 6)
	center.add_child(_vbox)

	var title := Label.new()
	title.text = "Paused"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_vbox.add_child(title)

	_resume_btn = _add_button("Resume", _on_resume)
	_add_button("Character Select", _on_select)
	_add_button("Quit Game", _on_quit)

func _add_button(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(120, 0)
	b.pressed.connect(cb)
	_vbox.add_child(b)
	return b

func _input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return
	if _open:
		get_viewport().set_input_as_handled()
		_on_resume()
	elif _allowed():
		get_viewport().set_input_as_handled()
		_show()

## Not useful on the main menu itself.
func _allowed() -> bool:
	var cs := get_tree().current_scene
	return cs != null and not String(cs.scene_file_path).ends_with("MainMenu.tscn")

func _show() -> void:
	_open = true
	visible = true
	get_tree().paused = true
	_resume_btn.grab_focus()

func _hide_menu() -> void:
	_open = false
	visible = false
	get_tree().paused = false

func _on_resume() -> void:
	_hide_menu()

func _on_select() -> void:
	_hide_menu()
	SceneTransition.change_scene(MENU_PATH)

func _on_quit() -> void:
	get_tree().paused = false
	get_tree().quit()
