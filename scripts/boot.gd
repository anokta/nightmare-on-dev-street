extends Control

@export_file("*.tscn") var next_scene: String = "res://scenes/title.tscn"

@export var fade_time: float = 1.0
@export var min_show_time: float = 1.5
@export var max_show_time: float = 8.0

var _elapsed = 0.0
var _leaving = false


func _ready() -> void:
  var box = VBoxContainer.new()
  box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
  box.alignment = BoxContainer.ALIGNMENT_CENTER
  box.add_theme_constant_override("separation", 32)
  add_child(box)

  _add_line(box, "PHOTOSENSITIVITY WARNING", 44)
  _add_line(
    box,
    "This game contains flashing lights and glitch effects\nthat may affect players with photosensitive epilepsy.",
    28
  )
  _add_line(box, "Best played with headphones.", 28)
  var hint = _add_line(box, "press any key", 22)
  hint.modulate.a = 0.4

  modulate.a = 0.0
  create_tween().tween_property(self, "modulate:a", 1.0, fade_time)


func _add_line(parent: Node, text: String, size: int) -> Label:
  var label = Label.new()
  label.text = text
  label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  label.add_theme_font_size_override("font_size", size)
  parent.add_child(label)
  return label


func _process(delta):
  _elapsed += delta
  if _elapsed >= max_show_time:
    _leave()


func _input(event):
  if _leaving or _elapsed < min_show_time:
    return
  if (
    (event is InputEventKey or event is InputEventJoypadButton or event is InputEventMouseButton)
    and event.is_pressed()
    and not event.is_echo()
  ):
    _leave()


func _leave():
  if _leaving:
    return
  _leaving = true
  var tween = create_tween()
  tween.tween_property(self, "modulate:a", 0.0, fade_time)
  tween.tween_callback(func(): get_tree().change_scene_to_file(next_scene))
