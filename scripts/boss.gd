extends CharacterBody2D

@export var main: Node2D

@export var light: Light2D
@export var sprite: Sprite2D

@export var instrument: BarelyInstrument
@export var performer: BarelyPerformer

@export var light_energy_speed: float = 6.0
@export var light_intensity: float = 10.0

@export var rotation_speed: float = 20.0

@export_group("Player Distance")
@export var min_player_distance: float = 2.0
@export var max_player_distance: float = 50.0

@export var min_wait_beats: int = 4
@export var max_wait_beats: int = 8
@export var min_beat_interval: int = 1
@export var max_beat_interval: int = 5
@export var min_beat_repeat: int = 1
@export var max_beat_repeat: int = 4

@export var boss_movement_radius: float = 4
@export var boss_movement_angle: float = 30
@export var boss_target_lerp_speed: float = 2.0

var player_proximity = 0.0

var _light_target_energy: float = 0.0

var _wait_beats = min_wait_beats
var _beat_interval = min_beat_interval
var _repeat_beats = min_beat_repeat

var _target_pos = Vector2.ZERO
var _attacking = false

func ping():
  _target_pos = main.player.position


func _ready() -> void:
  var task = performer.tasks[0]
  task.connect("task_begin", Callable(self, "_on_task_begin"))
  task.connect("task_end", Callable(self, "_on_task_end"))

  if main.target != null:
    _target_pos = main.target.position

  performer.position = -4.0
  performer.start()


func _input(event):
  if !main.is_game_over():
    return

  if event is InputEventKey and event.pressed and not event.echo:
    if event.keycode == KEY_SPACE and !main.quitting:
      instrument.set_note_on(0.0)
      if main.is_last_level():
        main.dead_anim.visible = !main.dead_anim.visible
        main.increment_glitch()
        instrument.set_note_off(0.0)
        return
      # light.energy = light_intensity
      main.change_level(true)
      if main.target != null:
        main.target.performer.stop()


func _physics_process(delta):
  velocity = Vector2.ZERO
  light.energy = lerpf(light.energy, _light_target_energy, light_energy_speed * delta)

  var from_player = position - main.player.position
  var player_dist = from_player.length()

  var min_dist = min_player_distance * main.tile_size
  var max_dist = max_player_distance * main.tile_size

  instrument.stereo_pan = (
    sign(from_player.x) * clampf((abs(from_player.x) - min_dist) / (max_dist - min_dist), 0.0, 1.0)
  )

  player_proximity = clampf((max_dist - player_dist) / (max_dist - min_dist), 0.0, 1.0)
  instrument.filter_cutoff = pow(player_proximity, 2.0)
  instrument.distortion_mix = pow(max(0.5, player_proximity) - 0.5, 2.0)
  instrument.crush_rate = pow(0.5 * player_proximity, 1.5)
  instrument.crush_depth = pow(0.9 * (max(0.25, player_proximity) - 0.25), 1.0)
  instrument.osc_mix = pow(max(0.75, player_proximity) - 0.75, 2.0)

  sprite.rotate(rotation_speed * (2.0 * randf() - 1.0) * delta)

  if main.is_game_over() or main.target == null:
    _target_pos = main.player.position
  else:
    _target_pos = (lerp(_target_pos, main.target.position, boss_target_lerp_speed * delta))

  if _attacking and player_proximity >= 1.0 and main.player.velocity != Vector2.ZERO:
    main.game_over()

  move_and_slide()


func _pick_next_tile() -> Vector2:
  var current_tile = main.world_to_tile(position)

  var candidates: Array[Vector2i] = []

  for y in range(-boss_movement_radius, boss_movement_radius + 1):
    for x in range(-boss_movement_radius, boss_movement_radius + 1):
      var offset = Vector2i(x, y)
      if offset == Vector2i.ZERO or offset.length() > boss_movement_radius:
        continue
      var tile = current_tile + offset

      if main.is_wall(tile):
        continue

      if (
        abs((main.tile_to_world(tile) - position).angle_to(_target_pos - position))
        > deg_to_rad(boss_movement_angle)
      ):
        continue

      candidates.append(tile)
  if candidates.is_empty():
    return global_position
  var chosen_tile = candidates.pick_random()

  return main.tile_to_world(chosen_tile).snapped(Vector2.ONE * main.tile_size)


func _on_task_begin():
  if _wait_beats > 0:
    _wait_beats -= 1
    return

  if _beat_interval > 0:
    _beat_interval -= 1

  if main.is_restart and !main.is_running() and !main.is_game_over():
    main.should_start_level = true
    return

  if _repeat_beats == 0 and (!main.is_game_over() or main.dead_anim.visible):
    _wait_beats = randi_range(min_wait_beats, max_wait_beats)
    _repeat_beats = randi_range(min_beat_repeat, max_beat_repeat)
    return

  _repeat_beats = max(_repeat_beats - 1, 0)
  _beat_interval = randi_range(min_beat_interval, max_beat_interval)

  position = _pick_next_tile()

  main.set_glitch_intensity(pow(player_proximity, 4) * (0.0075 if main.is_game_over() else 0.005))
  main.set_glitch_color_split(pow(player_proximity, 4) * (0.075 if main.is_game_over() else 0.05))

  instrument.set_note_on(0.0)
  light.energy = light_intensity

  if main.is_game_over():
    # if !main.dead_anim.visible or randf() < 0.1:
    main.dead_anim.visible = !main.dead_anim.visible
  else:
    _attacking = true


func _on_task_end():
  instrument.set_note_off(0.0)
  _light_target_energy = 0.0

  _attacking = false
  if main.is_restart and !main.is_running() and !main.is_game_over():
    main.should_start_level = true
  if main.should_start_level:
    performer.stop()
