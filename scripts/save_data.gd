extends Node

const PATH = "user://save.cfg"

const EFFECTS_LEVELS = [1.0, 0.5, 0.0]
const EFFECTS_NAMES = ["Full", "Reduced", "Off"]

var _config = ConfigFile.new()


func _ready() -> void:
  _config.load(PATH)
  _apply_settings()


func get_level() -> int:
  return _config.get_value("progress", "level", 0)


func set_level(index: int) -> void:
  _config.set_value("progress", "level", index)
  _config.save(PATH)


func get_volume() -> float:
  return _config.get_value("settings", "volume", 1.0)


func set_volume(volume: float) -> void:
  _set_setting("volume", clampf(volume, 0.0, 1.0))


func is_fullscreen() -> bool:
  return _config.get_value(
    "settings", "fullscreen", ProjectSettings.get_setting("display/window/size/mode") >= 3
  )


func set_fullscreen(fullscreen: bool) -> void:
  _set_setting("fullscreen", fullscreen)


# Index into EFFECTS_LEVELS: how strong the glitch shader is (photosensitivity).
func get_effects() -> int:
  return _config.get_value("settings", "effects", 0)


func set_effects(index: int) -> void:
  _set_setting("effects", posmod(index, EFFECTS_LEVELS.size()))


func effects_scale() -> float:
  return EFFECTS_LEVELS[get_effects()]


func _set_setting(key: String, value) -> void:
  _config.set_value("settings", key, value)
  _config.save(PATH)
  _apply_settings()


func _apply_settings() -> void:
  var volume = get_volume()
  AudioServer.set_bus_mute(0, volume <= 0.0)
  AudioServer.set_bus_volume_db(0, linear_to_db(maxf(volume, 0.0001)))

  if DisplayServer.get_name() == "headless":
    return
  var fullscreen = DisplayServer.window_get_mode() >= DisplayServer.WINDOW_MODE_FULLSCREEN
  if is_fullscreen() != fullscreen:
    DisplayServer.window_set_mode(
      DisplayServer.WINDOW_MODE_FULLSCREEN if is_fullscreen() else DisplayServer.WINDOW_MODE_WINDOWED
    )
