extends CanvasLayer
## Clock, carried item, stats, interaction prompt and toast messages.

@onready var clock_label: Label = $ClockLabel
@onready var carry_label: Label = $CarryLabel
@onready var stats_label: Label = $StatsLabel
@onready var prompt_label: Label = $PromptLabel
@onready var toast_label: Label = $ToastLabel
@onready var surreal_overlay: ColorRect = $SurrealOverlay
@onready var black_fade: ColorRect = $BlackFade

var _toast_tween: Tween

func _ready() -> void:
	toast_label.modulate.a = 0.0
	prompt_label.text = ""
	carry_label.text = ""

func _process(_delta: float) -> void:
	var ff := "  >>" if GameClock.is_fast_forwarding() else ""
	clock_label.text = "Day %d  %s%s" % [GameState.day, GameClock.get_time_string(), ff]

func set_prompt(text: String) -> void:
	prompt_label.text = text

func set_carry(text: String) -> void:
	carry_label.text = text

func set_stats(text: String) -> void:
	stats_label.text = text

func toast(text: String, seconds := 3.0) -> void:
	toast_label.text = text
	if _toast_tween:
		_toast_tween.kill()
	_toast_tween = create_tween()
	_toast_tween.tween_property(toast_label, "modulate:a", 1.0, 0.25)
	_toast_tween.tween_interval(seconds)
	_toast_tween.tween_property(toast_label, "modulate:a", 0.0, 0.6)

func set_surreal(amount: float, duration := 1.0) -> void:
	var target := Color(0.02, 0.0, 0.08, clampf(amount, 0.0, 1.0) * 0.45)
	create_tween().tween_property(surreal_overlay, "color", target, duration)

## Fades the screen to/from black (the Narrator nodding off and waking).
func fade_to_black(duration := 1.0) -> void:
	var tween := create_tween()
	tween.tween_property(black_fade, "color", Color(0, 0, 0, 1), duration)
	await tween.finished

func fade_from_black(duration := 1.0) -> void:
	var tween := create_tween()
	tween.tween_property(black_fade, "color", Color(0, 0, 0, 0), duration)
	await tween.finished
