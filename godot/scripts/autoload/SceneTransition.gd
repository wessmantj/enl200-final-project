extends CanvasLayer

@onready var _rect: ColorRect = $Rect
@onready var _tween: Tween

func _ready() -> void:
	_rect.color = Color.BLACK
	_rect.color.a = 0.0

func fade_to_black(duration := 0.5) -> void:
	_tween = create_tween()
	_tween.tween_property(_rect, "color:a", 1.0, duration)
	await _tween.finished

func fade_from_black(duration := 0.5) -> void:
	_tween = create_tween()
	_tween.tween_property(_rect, "color:a", 0.0, duration)
	await _tween.finished

func change_scene(path: String) -> void:
	await fade_to_black()
	get_tree().change_scene_to_file(path)
	await get_tree().process_frame
	await fade_from_black()
