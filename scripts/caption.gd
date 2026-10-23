extends CanvasLayer
# Fading text over the game: a story line and/or a smaller, dimmer hint.

@export var fade_time: float = 1.0
@export var hold_time: float = 4.0

var _box: VBoxContainer
var _tween: Tween


func _ready() -> void:
  layer = 50
  _box = VBoxContainer.new()
  _box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
  _box.alignment = BoxContainer.ALIGNMENT_END
  _box.offset_bottom = -160
  _box.add_theme_constant_override("separation", 12)
  _box.mouse_filter = Control.MOUSE_FILTER_IGNORE
  _box.modulate.a = 0.0
  add_child(_box)


# Either line can be empty. hold <= 0 keeps the text up until hide_now().
func show_text(story: String, hint: String = "", hold: float = hold_time) -> void:
  hide_now()
  if story.is_empty() and hint.is_empty():
    return
  if !story.is_empty():
    _add_label(story, 36, 1.0)
  if !hint.is_empty():
    _add_label(hint, 24, 0.5)

  _tween = create_tween()
  _tween.tween_property(_box, "modulate:a", 1.0, fade_time)
  if hold > 0.0:
    _tween.tween_interval(hold)
    _tween.tween_property(_box, "modulate:a", 0.0, fade_time)


func _add_label(text: String, size: int, alpha: float) -> void:
  var label = Label.new()
  label.text = text
  label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  label.add_theme_font_size_override("font_size", size)
  label.modulate.a = alpha
  _box.add_child(label)


func hide_now() -> void:
  if _tween:
    _tween.kill()
  _box.modulate.a = 0.0
  for child in _box.get_children():
    child.queue_free()
