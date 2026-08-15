extends Node2D

@export var background: CanvasModulate
@export var postfx: CanvasLayer

@export var player_scene: PackedScene
@export var target_scene: PackedScene
@export var boss_scene: PackedScene
@export var wall_scene: PackedScene

@export var tile_size: int = 45

@export var level_path: String = "level.txt"

@export var enable_background: bool = true
@export var enable_postfx: bool = true
@export var enable_light: bool = true

@export var enable_boss: bool = true
@export var enable_target: bool = true

var _player: CharacterBody2D
var _target: CharacterBody2D
var _boss: CharacterBody2D


func _ready() -> void:
  BarelyEngine.delay_ping_pong = 1.0
  BarelyEngine.delay_time = 0.12
  BarelyEngine.delay_feedback = 0.25
  BarelyEngine.delay_lpf_cutoff = 0.5
  BarelyEngine.delay_reverb_send = 0.5
  BarelyEngine.reverb_damping = 0.2
  BarelyEngine.reverb_room_size = 0.4

  BarelyEngine.lookahead = 0.15
  BarelyEngine.tempo = 140

  _load_level("res://" + level_path)
  _boss.player = _player
  _target.player = _player


func _input(event):
  if event is InputEventKey and event.pressed:
    if event.keycode == KEY_ESCAPE:
      get_tree().quit()
      return


func _process(_delta):
  _player.light.visible = enable_light
  background.visible = enable_background
  postfx.visible = enable_postfx
  _boss.visible = enable_boss
  _target.visible = enable_target


func _load_level(path: String) -> void:
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
        _spawn(wall_scene, x, y)
      elif ch == "P":
        _player = _spawn(player_scene, x, y)
        _player.main = self
      elif ch == "T":
        _target = _spawn(target_scene, x, y)
        _target.main = self
      elif ch == "B":
        _boss = _spawn(boss_scene, x, y)
        _boss.main = self

    y += 1


func _spawn(prefab_scene: PackedScene, x: int, y: int) -> Node2D:
  var prefab = prefab_scene.instantiate() as Node2D
  prefab.position = Vector2(x * tile_size, y * tile_size)
  add_child(prefab)
  return prefab
