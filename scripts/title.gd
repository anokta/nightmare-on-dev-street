extends Control

const SettingsMenu = preload("res://scripts/settings_menu.gd")

@export_file("*.tscn") var game_scene: String = "res://scenes/main.tscn"
@export_file("*.tscn") var credits_scene: String = "res://scenes/credits.tscn"

var _settings_button: Button


func _ready() -> void:
  var box = UI.make_menu(self)
  UI.add_title(box, "you should not be here")

  var first: Button
  if SaveData.get_level() > 0:
    first = UI.add_button(box, "Continue", _start.bind(false))
  var new_game = UI.add_button(box, "New game", _start.bind(true))
  _settings_button = UI.add_button(box, "Settings", _open_settings)
  UI.add_button(box, "Credits", get_tree().change_scene_to_file.bind(credits_scene))
  UI.add_button(box, "Quit", get_tree().quit)
  (first if first else new_game).grab_focus()


func _start(new_game: bool) -> void:
  if new_game:
    SaveData.set_level(0)
  get_tree().change_scene_to_file(game_scene)


func _open_settings() -> void:
  var settings = SettingsMenu.new()
  settings.closed.connect(_settings_button.grab_focus)
  add_child(settings)
