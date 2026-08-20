extends Node2D

enum GState { RUNNING, LEVEL_CHANGE, OVER }

@export var background: CanvasModulate
@export var postfx: CanvasLayer
@export var shader: ColorRect
@export var dead_anim: AnimatedSprite2D

@export var level_root: Node2D

@export var player_scene: PackedScene
@export var target_scene: PackedScene
@export var boss_scene: PackedScene
@export var wall_scene: PackedScene

@export var tile_size: int = 45
@export var empty_alpha = 0.03

@export var initial_tempo: float = 100.0

@export var enable_background: bool = true
@export var enable_postfx: bool = true
@export var enable_light: bool = true

@export var glitch_interp_speed = 1.0

@export var levels: Array[String] = []

var player: CharacterBody2D
var target: CharacterBody2D
var boss: CharacterBody2D

var _level_index = 0

var _initial_color_split = 0.0
var _initial_glitch_intensity = 0.0
var _shader: ShaderMaterial

var _tiles: Array = []
var _width: int = 0
var _height: int = 0

var _state: GState = GState.RUNNING
var _level_change_timer = 0.0


func change_level(level_change_time = 3.0, restart = false):
  if boss != null:
    boss.performer.stop()
  target.performer.stop()
  level_root.process_mode = Node.PROCESS_MODE_DISABLED

  dead_anim.visible = false

  _state = GState.LEVEL_CHANGE
  _level_change_timer = level_change_time

  if !restart:
    _level_index = (_level_index + 1) % levels.size()


func game_over():
  _state = GState.OVER

  boss.visible = false
  target.visible = false

  player.visible = false
  player.hummer.set_note_off(0.0)

  dead_anim.play_backwards()
  dead_anim.visible = true


func is_game_over():
  return _state == GState.OVER


func set_glitch_intensity(intensity):
  _shader.set_shader_parameter("glitch_intensity", intensity)


func set_glitch_color_split(color_split):
  _shader.set_shader_parameter("color_split", color_split)


func is_wall(tile) -> bool:
  return (
    tile.x < 0
    or tile.x >= _width
    or tile.y < 0
    or tile.y >= _height
    or _tiles[_width * tile.y + tile.x]
  )


func world_to_tile(pos: Vector2) -> Vector2i:
  return Vector2i(floor(pos.x / tile_size), floor(pos.y / tile_size))


func tile_to_world(tile: Vector2i) -> Vector2:
  return Vector2(tile.x * tile_size, tile.y * tile_size)


func get_neighbors(tile: Vector2i) -> Array[Vector2i]:
  var result: Array[Vector2i] = []
  var directions: Array = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
  for direction in directions:
    var neighbor = tile + direction
    if not is_wall(neighbor):
      result.append(neighbor)
  return result


func get_random_tile() -> Vector2i:
  var candidates: Array[Vector2i] = []
  for y in _height:
    for x in _width:
      var tile: Vector2i = Vector2i(x, y)
      if not is_wall(tile):
        candidates.append(tile)
  return candidates.pick_random()


func _ready() -> void:
  BarelyEngine.delay_ping_pong = 1.0
  BarelyEngine.delay_time = 0.12
  BarelyEngine.delay_feedback = 0.25
  BarelyEngine.delay_lpf_cutoff = 0.5
  BarelyEngine.delay_reverb_send = 0.5
  BarelyEngine.reverb_damping = 0.2
  BarelyEngine.reverb_room_size = 0.4
  BarelyEngine.sidechain_mix = 1.0
  BarelyEngine.sidechain_attack = 0.0
  BarelyEngine.sidechain_release = 0.1
  BarelyEngine.sidechain_ratio = 0.5
  BarelyEngine.sidechain_threshold = 0.2

  BarelyEngine.lookahead = 0.15
  BarelyEngine.tempo = initial_tempo

  _shader = shader.material
  _initial_glitch_intensity = _shader.get_shader_parameter("glitch_intensity")
  _initial_color_split = _shader.get_shader_parameter("color_split")

  _load_level(levels[_level_index])


func _input(event):
  if event is InputEventKey and event.pressed:
    if event.keycode == KEY_ESCAPE:
      get_tree().quit()
      return


func _process(delta):
  player.light.visible = enable_light
  target.light.visible = enable_light

  background.visible = (
    (enable_background and _state == GState.RUNNING)
    or (!dead_anim.visible and _state == GState.OVER)
  )
  postfx.visible = enable_postfx

  if boss != null:
    boss.light.visible = enable_light

  _shader.set_shader_parameter(
    "color_split",
    lerp(
      _shader.get_shader_parameter("color_split"), _initial_color_split, delta * glitch_interp_speed
    )
  )
  _shader.set_shader_parameter(
    "glitch_intensity",
    lerp(
      _shader.get_shader_parameter("glitch_intensity"),
      _initial_glitch_intensity,
      delta * glitch_interp_speed
    )
  )

  if _state == GState.LEVEL_CHANGE:
    if _level_change_timer > 0.0:
      _level_change_timer -= delta
    else:
      for child in level_root.get_children():
        child.queue_free()
      _load_level(levels[_level_index])


func _load_level(path: String) -> void:
  var file = FileAccess.open("res://levels/" + path + ".txt", FileAccess.READ)
  if not file:
    return

  _width = 0
  _height = 0

  var y = 0
  while not file.eof_reached():
    var line = file.get_line().strip_edges()
    if line.is_empty():
      y += 1
      continue

    if _width > 0 and _width != line.length():
      printerr("Level width must match: ", _width, " vs ", line.length())
    _width = line.length()

    _height = y + 1
    _tiles.resize(_width * _height)

    for x in range(line.length()):
      var ch = line[x]
      if ch == "#":
        _spawn(wall_scene, x, y)
        _tiles[y * line.length() + x] = true
      else:
        _tiles[y * line.length() + x] = false

        var empty = _spawn(wall_scene, x, y)
        empty.modulate.a = empty_alpha
        empty.collision_shape.disabled = true

        if ch == "P":
          player = _spawn(player_scene, x, y)
        elif ch == "T":
          target = _spawn(target_scene, x, y)
        elif ch == "B":
          boss = _spawn(boss_scene, x, y)

    y += 1

  level_root.process_mode = PROCESS_MODE_INHERIT
  _state = GState.RUNNING


func _spawn(prefab_scene: PackedScene, x: int, y: int) -> Node2D:
  var prefab = prefab_scene.instantiate() as Node2D
  prefab.position = tile_to_world(Vector2i(x, y))
  if prefab is CharacterBody2D:
    prefab.main = self
  level_root.add_child(prefab)
  return prefab
