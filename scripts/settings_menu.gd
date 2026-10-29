extends Control
# Settings overlay, shared by the title screen and the pause menu.
# Left/right (or Enter / click) changes the focused setting.

signal closed

var _volume: Button
var _fullscreen: Button
var _effects: Button


func _ready() -> void:
  set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
  var box = UI.make_menu(self, 0.92)
  UI.add_title(box, "settings", 44)

  _volume = UI.add_button(box, "", _change.bind("volume", 1))
  _fullscreen = UI.add_button(box, "", _change.bind("fullscreen", 1))
  _effects = UI.add_button(box, "", _change.bind("effects", 1))
  _volume.set_meta("setting", "volume")
  _fullscreen.set_meta("setting", "fullscreen")
  _effects.set_meta("setting", "effects")
  UI.add_button(box, "back", close)

  _refresh()
  _volume.grab_focus()


func close() -> void:
  closed.emit()
  queue_free()


# Enter/click cycles through the values (wrap), left/right steps and stops at the ends.
func _change(setting: String, step: int, wrap: bool = true) -> void:
  match setting:
    "volume":
      var volume = snappedf(SaveData.get_volume() + 0.1 * step, 0.1)
      if wrap and volume > 1.0:
        volume = 0.0
      SaveData.set_volume(volume)
    "fullscreen":
      SaveData.set_fullscreen(!SaveData.is_fullscreen())
    "effects":
      SaveData.set_effects(SaveData.get_effects() + step)
  _refresh()


func _refresh() -> void:
  _volume.text = "volume   %d%%" % roundi(SaveData.get_volume() * 100)
  _fullscreen.text = "fullscreen   " + ("on" if SaveData.is_fullscreen() else "off")
  _effects.text = "screen effects   " + SaveData.EFFECTS_NAMES[SaveData.get_effects()]


func _input(event):
  if event.is_action_pressed("ui_cancel") or event.is_action_pressed("quit"):
    get_viewport().set_input_as_handled()
    close()
    return
  var focused = get_viewport().gui_get_focus_owner()
  if focused == null or not focused.has_meta("setting"):
    return
  var step = 0
  if event.is_action_pressed("ui_left", true):
    step = -1
  elif event.is_action_pressed("ui_right", true):
    step = 1
  if step != 0:
    get_viewport().set_input_as_handled()
    _change(focused.get_meta("setting"), step, false)
