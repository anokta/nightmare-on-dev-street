extends CanvasLayer
# Pause overlay. Pausing the tree also pauses barelymusician's engine node and
# audio player, so the beat clock stops with the game and picks up on resume.

signal give_up

const SettingsMenu = preload("res://scripts/settings_menu.gd")

@export_file("*.tscn") var title_scene: String = "res://scenes/title.tscn"

var can_give_up = true

var _resume: Button
var _settings_button: Button


func _ready() -> void:
  layer = 100
  process_mode = Node.PROCESS_MODE_ALWAYS

  var root = Control.new()
  root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
  add_child(root)
  var box = UI.make_menu(root, 0.85)
  UI.add_title(box, "paused", 44)
  _resume = UI.add_button(box, "resume", close)
  if can_give_up:
    UI.add_button(box, "give up", _give_up)
  _settings_button = UI.add_button(box, "settings", _open_settings.bind(root))
  UI.add_button(box, "quit to title", _quit_to_title)

  UI.add_glitch(self, 0.5, layer + 1)

  get_tree().paused = true
  _resume.grab_focus()


func close() -> void:
  get_tree().paused = false
  queue_free()


func _give_up() -> void:
  close()
  give_up.emit()


func _quit_to_title() -> void:
  get_tree().paused = false
  get_tree().change_scene_to_file(title_scene)


func _open_settings(root: Control) -> void:
  var settings = SettingsMenu.new()
  settings.closed.connect(_settings_button.grab_focus)
  root.add_child(settings)


func _input(event):
  if event.is_action_pressed("quit") or event.is_action_pressed("ui_cancel"):
    get_viewport().set_input_as_handled()
    close()
