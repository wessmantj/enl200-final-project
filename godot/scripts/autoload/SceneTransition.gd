extends CanvasLayer
## Full-screen fade used between scenes. Builds its own ColorRect so it can be
## autoloaded as a plain script (no .tscn needed).

var _rect: ColorRect
var _tween: Tween

func _ready() -> void:
	layer = 100
	_rect = ColorRect.new()
	_rect.color = Color(0, 0, 0, 0)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_rect)

func fade_to_black(duration := 0.5) -> void:
	await _fade(1.0, duration)

func fade_from_black(duration := 0.5) -> void:
	await _fade(0.0, duration)

func _fade(alpha: float, duration: float) -> void:
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(_rect, "color:a", alpha, duration)
	await _tween.finished

func change_scene(path: String) -> void:
	await fade_to_black()
	get_tree().change_scene_to_file(path)
	await get_tree().process_frame
	await fade_from_black()
