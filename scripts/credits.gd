extends Control

@export_file("*.tscn") var back_scene: String = "res://scenes/boot.tscn"

@export var scroll_speed: float = 600.0

const CREDITS = """[center][font_size=44]You Should Not Be Here[/font_size]

by Alper Gungormusler

Music and sound engine: barelymusician
Copyright (c) 2014 Alper Gungormusler, MIT License

Made with Godot Engine
[/center]"""

var _text: RichTextLabel


func _ready() -> void:
  var margin = MarginContainer.new()
  margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
  for side in ["left", "right", "top", "bottom"]:
    margin.add_theme_constant_override("margin_" + side, 96)
  add_child(margin)

  _text = RichTextLabel.new()
  _text.bbcode_enabled = true
  _text.scroll_following = false
  _text.add_theme_font_size_override("normal_font_size", 22)
  _text.text = CREDITS + "\n\n" + _godot_licenses()
  margin.add_child(_text)

  var hint = Label.new()
  hint.text = "Esc to go back"
  hint.modulate.a = 0.4
  hint.add_theme_font_size_override("font_size", 22)
  hint.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
  hint.position.y -= 48
  add_child(hint)


# Godot's license and its third-party notices, which shipped builds must include.
func _godot_licenses() -> String:
  var text = _heading("Godot Engine") + _escape(Engine.get_license_text())
  text += "\n\n" + _heading("Third-party components")
  for info in Engine.get_copyright_info():
    text += "\n" + _escape(info["name"])
    for part in info["parts"]:
      text += _escape("\n  " + ", ".join(part["copyright"]) + " (" + part["license"] + ")")
  text += "\n\n" + _heading("Licenses")
  var licenses = Engine.get_license_info()
  for license in licenses:
    text += "\n" + _escape(license + "\n\n" + licenses[license]) + "\n"
  return text


func _heading(title: String) -> String:
  return "[font_size=32]" + title + "[/font_size]\n\n"


# License texts can contain "[", which BBCode would read as a tag.
func _escape(text: String) -> String:
  return text.replace("[", "[lb]")


func _process(delta):
  var scroll = Input.get_axis("ui_up", "ui_down")
  if scroll != 0.0:
    var bar = _text.get_v_scroll_bar()
    bar.value += scroll * scroll_speed * delta


func _input(event):
  if event.is_action_pressed("quit") or event.is_action_pressed("ui_cancel"):
    get_tree().change_scene_to_file(back_scene)
