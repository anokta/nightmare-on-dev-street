extends CanvasLayer
# Text over the game: a story line that writes itself out, and/or a smaller hint.
# main.gd puts this under its PostFx layer, so the glitch runs over the text too.

@export var fade_time: float = 1.0
@export var hold_time: float = 4.0
@export var write_speed: float = 24.0  # characters per second

var _box: VBoxContainer
var _tween: Tween


func _ready() -> void:
  _box = VBoxContainer.new()
  _box.theme = UI.make_theme()
  _box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
  _box.alignment = BoxContainer.ALIGNMENT_END
  _box.offset_bottom = -150
  _box.add_theme_constant_override("separation", 8)
  _box.mouse_filter = Control.MOUSE_FILTER_IGNORE
  _box.modulate.a = 0.0
  add_child(_box)


# Either line can be empty. hold <= 0 keeps the text up until hide_now().
func show_text(
  story: String, hint: String = "", hold: float = hold_time, color: Color = UI.WHITE
) -> void:
  hide_now()
  if story.is_empty() and hint.is_empty():
    return
  _tween = create_tween()
  _tween.tween_property(_box, "modulate:a", 1.0, fade_time * 0.5)
  if !story.is_empty():
    var label = _add_label(story, 40, color)
    label.visible_ratio = 0.0
    _tween.tween_property(label, "visible_ratio", 1.0, story.length() / write_speed)
  if !hint.is_empty():
    var label = _add_label(hint, 24, Color(1.0, 1.0, 1.0, 0.45))
    label.modulate.a = 0.0
    _tween.tween_property(label, "modulate:a", 1.0, fade_time * 0.5)
  if hold > 0.0:
    _tween.tween_interval(hold)
    _tween.tween_property(_box, "modulate:a", 0.0, fade_time)


func _add_label(text: String, size: int, color: Color) -> Label:
  var label = Label.new()
  label.text = text
  label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  label.add_theme_font_size_override("font_size", size)
  label.add_theme_color_override("font_color", color)
  _box.add_child(label)
  return label


func hide_now() -> void:
  if _tween:
    _tween.kill()
  _box.modulate.a = 0.0
  for child in _box.get_children():
    child.queue_free()
