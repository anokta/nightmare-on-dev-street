extends Node2D

@export var tile_size: int = 64
@export var wall_scene: PackedScene


func _ready() -> void:
  load_level("res://level.txt")


func load_level(path: String) -> void:
  var file = FileAccess.open(path, FileAccess.READ)
  if not file:
    return

  var y = 0
  while not file.eof_reached():
    var line = file.get_line().strip_edges()
    if line.is_empty():
      y += 1
      continue

    for x in range(line.length()):
      var ch = line[x]
      if ch == "#":
        spawn_wall(x, y)
    y += 1


func spawn_wall(x: int, y: int) -> void:
  var wall = wall_scene.instantiate() as Node2D
  wall.position = Vector2(x * tile_size, y * tile_size)
  add_child(wall)
