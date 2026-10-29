extends Control

const SettingsMenu = preload("res://scripts/settings_menu.gd")

# The painted lettering from the death screen, reused as the logo.
const LOGO_FRAMES = [
  preload("res://art/you-should-not-be-here/Paint Layer 1.PNG"),
  preload("res://art/you-should-not-be-here/Paint Layer 2.PNG"),
  preload("res://art/you-should-not-be-here/Paint Layer 3.PNG"),
  preload("res://art/you-should-not-be-here/Paint Layer 4.PNG"),
  preload("res://art/you-should-not-be-here/Paint Layer 5.PNG"),
]

@export_file("*.tscn") var game_scene: String = "res://scenes/main.tscn"
@export_file("*.tscn") var credits_scene: String = "res://scenes/credits.tscn"

var _settings_button: Button
var _logo: TextureRect
var _flicker_left = 0
var _next_frame = 0.0


func _ready() -> void:
  var box = UI.make_menu(self)

  _logo = TextureRect.new()
  _logo.texture = LOGO_FRAMES[0]
  _logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
  _logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
  _logo.custom_minimum_size = Vector2(0, 460)
  box.add_child(_logo)

  var first: Button
  if SaveData.get_level() > 0:
    first = UI.add_button(box, "continue", _start.bind(false))
  var new_game = UI.add_button(box, "new game", _start.bind(true))
  _settings_button = UI.add_button(box, "settings", _open_settings)
  UI.add_button(box, "credits", get_tree().change_scene_to_file.bind(credits_scene))
  UI.add_button(box, "quit", get_tree().quit)
  (first if first else new_game).grab_focus()

  UI.add_glitch(self, 0.5)


# Mostly the first painted frame, with short bursts through the others.
func _process(delta):
  _next_frame -= delta
  if _next_frame > 0.0:
    return
  if _flicker_left > 0:
    _flicker_left -= 1
    _logo.texture = LOGO_FRAMES[randi_range(1, LOGO_FRAMES.size() - 1)]
    _next_frame = 0.07
  else:
    _logo.texture = LOGO_FRAMES[0]
    _flicker_left = randi_range(1, 4)
    _next_frame = randf_range(1.0, 3.5)


func _start(new_game: bool) -> void:
  if new_game:
    SaveData.set_level(0)
  get_tree().change_scene_to_file(game_scene)


func _open_settings() -> void:
  var settings = SettingsMenu.new()
  settings.closed.connect(_settings_button.grab_focus)
  add_child(settings)
