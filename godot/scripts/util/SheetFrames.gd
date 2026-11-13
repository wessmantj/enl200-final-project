class_name SheetFrames
extends RefCounted
## Builds SpriteFrames from the sheets made by generate_sprites.py.
## Sheet layout: one row, 8 frames of 64px — front×2, left×2, back×2, right×2.
## Produces idle_<dir>, walk_<dir> and (if a work sheet is given) work_<dir>,
## where <dir> is down / left / up / right.

const FRAME_W := 64
const DIRS: Array[String] = ["down", "left", "up", "right"]

static func build(walk_sheet: Texture2D, work_sheet: Texture2D = null) -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	_add_set(frames, walk_sheet, "walk", 6.0, true)
	if work_sheet:
		_add_set(frames, work_sheet, "work", 5.0, false)
	return frames

static func _add_set(frames: SpriteFrames, sheet: Texture2D, prefix: String, fps: float, make_idle: bool) -> void:
	var h := sheet.get_height()
	for i in DIRS.size():
		var dir := DIRS[i]
		var anim := prefix + "_" + dir
		frames.add_animation(anim)
		frames.set_animation_speed(anim, fps)
		for f in 2:
			frames.add_frame(anim, _region(sheet, (i * 2 + f) * FRAME_W, h))
		if make_idle:
			var idle := "idle_" + dir
			frames.add_animation(idle)
			frames.add_frame(idle, _region(sheet, i * 2 * FRAME_W, h))

static func _region(sheet: Texture2D, x: int, h: int) -> AtlasTexture:
	var t := AtlasTexture.new()
	t.atlas = sheet
	t.region = Rect2(x, 0, FRAME_W, h)
	return t

static func facing_from(dir: Vector2) -> String:
	if abs(dir.x) > abs(dir.y):
		return "right" if dir.x > 0 else "left"
	return "down" if dir.y > 0 else "up"
