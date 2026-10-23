extends Node

const PATH = "user://save.cfg"

var _config = ConfigFile.new()


func _ready() -> void:
  _config.load(PATH)


func get_level() -> int:
  return _config.get_value("progress", "level", 0)


func set_level(index: int) -> void:
  _config.set_value("progress", "level", index)
  _config.save(PATH)
