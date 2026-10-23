extends Node2D

enum GState { RUNNING, LEVEL_CHANGE, OVER }

const PauseMenu = preload("res://scripts/pause_menu.gd")
const Caption = preload("res://scripts/caption.gd")

@export var background: CanvasModulate
@export var postfx: CanvasLayer
@export var shader: ColorRect
@export var dead_anim: AnimatedSprite2D

@export var dead_sfx: AudioStreamPlayer2D
@export var done_sfx: AudioStreamPlayer2D

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

var quitting = false

var player: CharacterBody2D
var target: CharacterBody2D
var boss: CharacterBody2D

var should_start_level = false
var is_restart = false

var _level_index = 0

var _initial_color_split = 0.0
var _initial_glitch_intensity = 0.0
var _shader: ShaderMaterial

var _tiles: Array = []
var _width: int = 0
var _height: int = 0

var _state: GState = GState.RUNNING

var _caption: Caption


func is_last_level():
  return _level_index == levels.size() - 1


func change_level(restart = false):
  if boss != null and !restart:
    boss.performer.stop()
    boss.visible = false
  level_root.process_mode = Node.PROCESS_MODE_DISABLED

  dead_anim.visible = false
  _caption.hide_now()

  if target != null and !restart:
    target.performer.stop()
    target.performer.position = 0.0
    target.performer.start()

  player.hummer.set_note_off(0.0)

  _state = GState.LEVEL_CHANGE
  should_start_level = (restart and boss == null)

  if !restart:
    _level_index = (_level_index + 1) % levels.size()
    SaveData.set_level(_level_index)

  is_restart = restart


func game_over():
  _state = GState.OVER

  if boss != null:
    boss.visible = false
  if target != null:
    target.visible = false

  player.visible = false
  player.hummer.set_note_off(0.0)

  dead_anim.play_backwards()
  dead_anim.visible = true

  _caption.show_text("", "space to try again", 0.0)


func is_game_over():
  return _state == GState.OVER


func is_running():
  return _state == GState.RUNNING


func set_glitch_intensity(intensity):
  _shader.set_shader_parameter("glitch_intensity", intensity * SaveData.effects_scale())


func set_glitch_color_split(color_split):
  _shader.set_shader_parameter("color_split", color_split * SaveData.effects_scale())


func increment_glitch():
  _shader.set_shader_parameter(
    "glitch_speed", min(30.0, _shader.get_shader_parameter("glitch_speed") * 1.5)
  )
  _shader.set_shader_parameter(
    "block_count", min(50.0, _shader.get_shader_parameter("block_count") * 1.5)
  )
  boss.instrument.pitch_shift = boss.instrument.pitch_shift - randf_range(0.0, 0.5)
  if boss.instrument.pitch_shift < -3.5:
    dead_sfx.play()
    quitting = true
    # the game is finished, so the next launch starts from the beginning
    SaveData.set_level(0)


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
  BarelyEngine.reverb_stereo_width = 1.0
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

  # same canvas layer as PostFx but before it in the tree, so the glitch runs over the text
  _caption = Caption.new()
  _caption.layer = postfx.layer
  add_child(_caption)
  move_child(_caption, postfx.get_index())

  _level_index = clampi(SaveData.get_level(), 0, levels.size() - 1)
  _load_level(levels[_level_index])


func _input(event):
  if event.is_action_pressed("quit") and !quitting:
    get_viewport().set_input_as_handled()
    var menu = PauseMenu.new()
    menu.can_give_up = is_running()
    menu.give_up.connect(game_over)
    add_child(menu)
    return
  if event.is_action_pressed("restart") and is_game_over() and boss == null and !quitting:
    target.performer.stop()
    change_level(true)


func _process(delta):
  if player == null:
    return

  if quitting:
    if dead_sfx.playing:
      dead_sfx.pitch_scale += randf_range(0.0, 0.5) * delta
    else:
      get_tree().quit()
      return

  player.light.visible = enable_light
  if target != null:
    target.light.visible = enable_light

  background.visible = (
    (enable_background and _state == GState.RUNNING)
    or (!dead_anim.visible and _state == GState.OVER)
    or ((is_restart or should_start_level) and _state == GState.LEVEL_CHANGE)
  )
  postfx.visible = enable_postfx

  if boss != null:
    boss.light.visible = enable_light

  var effects = SaveData.effects_scale()
  _shader.set_shader_parameter(
    "color_split",
    lerp(
      _shader.get_shader_parameter("color_split"),
      _initial_color_split * effects,
      delta * glitch_interp_speed
    )
  )
  _shader.set_shader_parameter(
    "glitch_intensity",
    lerp(
      _shader.get_shader_parameter("glitch_intensity"),
      _initial_glitch_intensity * effects,
      delta * glitch_interp_speed
    )
  )

  if _state == GState.LEVEL_CHANGE and should_start_level:
    if target != null:
      target.performer.stop()
    for child in level_root.get_children():
      child.queue_free()
    var arrived = !is_restart
    should_start_level = false
    is_restart = false
    _load_level(levels[_level_index], arrived)


# Lines starting with ";" at the top of a level file are its caption:
# the first is a story line, the second an optional hint.
func _load_level(path: String, show_caption: bool = true) -> void:
  var file = FileAccess.open("res://levels/" + path + ".txt", FileAccess.READ)
  if not file:
    return

  _width = 0
  _height = 0

  var caption: PackedStringArray = []
  var y = 0
  while not file.eof_reached():
    var line = file.get_line().strip_edges()
    if line.begins_with(";"):
      caption.append(line.substr(1).strip_edges())
      continue
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

  if show_caption:
    caption.resize(2)
    var progress = float(_level_index) / maxf(levels.size() - 1, 1)
    _caption.show_text(caption[0], caption[1], _caption.hold_time, UI.story_color(progress))
  else:
    _caption.hide_now()


func _spawn(prefab_scene: PackedScene, x: int, y: int) -> Node2D:
  var prefab = prefab_scene.instantiate() as Node2D
  prefab.position = tile_to_world(Vector2i(x, y))
  if prefab is CharacterBody2D:
    prefab.main = self
  level_root.add_child(prefab)
  return prefab
