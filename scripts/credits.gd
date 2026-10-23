extends Control

@export_file("*.tscn") var back_scene: String = "res://scenes/title.tscn"

@export var scroll_speed: float = 600.0

# In the game's lettering; the license texts below stay in a plain font to be readable.
const CREDITS = """[center][font=res://fonts/PermanentMarker-Regular.ttf][font_size=56][color=#db0000]you should not be here[/color][/font_size]

[font_size=30]by Alper Gungormusler

music and sound engine: barelymusician
copyright (c) 2014 Alper Gungormusler, MIT license

lettering: Permanent Marker by Font Diner, Apache License 2.0

made with Godot Engine[/font_size][/font]
[/center]"""

var _text: RichTextLabel


func _ready() -> void:
  theme = UI.make_theme()
  var backdrop = ColorRect.new()
  backdrop.color = Color.BLACK
  backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
  add_child(backdrop)
  UI.add_static(self)

  var margin = MarginContainer.new()
  margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
  for side in ["left", "right", "top", "bottom"]:
    margin.add_theme_constant_override("margin_" + side, 96)
  add_child(margin)

  _text = RichTextLabel.new()
  _text.bbcode_enabled = true
  _text.scroll_following = false
  _text.add_theme_font_override("normal_font", ThemeDB.fallback_font)
  _text.add_theme_font_size_override("normal_font_size", 22)
  _text.add_theme_color_override("default_color", Color(1.0, 1.0, 1.0, 0.6))
  _text.text = CREDITS + "\n\n" + _godot_licenses()
  margin.add_child(_text)

  var hint = Label.new()
  hint.text = "esc to go back"
  hint.modulate.a = 0.35
  hint.add_theme_font_size_override("font_size", 22)
  hint.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
  hint.position.y -= 48
  add_child(hint)
  UI.add_glitch(self, 0.3)


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
  return (
    "[font=res://fonts/PermanentMarker-Regular.ttf][font_size=32][color=#db0000]"
    + title.to_lower()
    + "[/color][/font_size][/font]\n\n"
  )


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
