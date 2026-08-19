extends CharacterBody2D

@export var main: Node2D

@export var light: Light2D
@export var sprite: Sprite2D

@export var instrument: BarelyInstrument
@export var performer: BarelyPerformer

@export var light_energy_speed: float = 20.0
@export var light_intensity: float = 1.0

@export var loop_length: float = 6.0
@export var speed: float = 40.0

@export_group("Boss Distance")
@export var min_boss_distance: float = 5.0
@export var max_boss_distance: float = 20.0

@export_group("Player Distance")
@export var min_player_distance: float = 2.0
@export var max_player_distance: float = 40.0

@export var scale_mult = 1.2

var current_direction: Vector2 = Vector2.ZERO
var _light_target_energy: float = 0.0

var _boss_proximity = 0.0
var _player_proximity = 0.0
var _initial_scale = Vector2()


func _ready() -> void:
  var task = performer.tasks[0]
  task.connect("task_begin", Callable(self, "_on_task_begin"))
  task.connect("task_end", Callable(self, "_on_task_end"))

  _initial_scale = scale

  performer.start()


func _on_area_2d_body_shape_entered(_body_rid, _body, _body_shape_index, _local_shape_index):
  main.change_level.call_deferred()


func _physics_process(delta):
  light.energy = lerpf(light.energy, _light_target_energy, light_energy_speed * delta)

  var from_player = position - main.player.position
  var player_dist = from_player.length()

  var min_dist = min_player_distance * main.tile_size
  var max_dist = max_player_distance * main.tile_size

  light.scale.x = max(player_dist, 2.0 * main.tile_size)
  light.scale.y = 20.0 + max(max_player_distance - player_dist, 0.0)

  look_at(main.player.position)

  _player_proximity = clampf((max_dist - player_dist) / (max_dist - min_dist), 0.0, 1.0)

  scale = lerp(scale, _initial_scale, 4 * delta)

  instrument.reverb_send = max(1.0 - pow(_player_proximity, 1.5), 0.25) + 0.5
  instrument.filter_cutoff = min(pow(_player_proximity + 0.2, 1.5), 0.75) + 0.1
  instrument.stereo_pan = (
    sign(from_player.x) * clampf((abs(from_player.x) - min_dist) / (max_dist - min_dist), 0.0, 1.0)
  )

  var min_boss_dist = min_boss_distance * main.tile_size
  var max_boss_dist = max_boss_distance * main.tile_size

  var from_boss = (position - main.boss.position) if main.boss != null else Vector2.ZERO
  var boss_dist = from_boss.length() if main.boss != null else max_boss_dist

  _boss_proximity = clampf((max_boss_dist - boss_dist) / (max_boss_dist - min_boss_dist), 0.0, 1.0)
  current_direction = lerp(from_boss.normalized(), current_direction, _boss_proximity * delta)

  velocity = velocity.move_toward(
    current_direction * speed, (1.0 + 100 * _boss_proximity) * speed * delta
  )
  position = lerp(position, position.snapped(Vector2.ONE * main.tile_size), delta)

  move_and_slide()


func choose_travel_direction() -> void:
  var tile = main.world_to_tile(position)
  var neighbors = main.get_neighbors(tile)

  if neighbors.is_empty():
    return

  var current_tile_direction := Vector2i(sign(current_direction.x), sign(current_direction.y))

  var candidates = neighbors.duplicate()
  if current_tile_direction != Vector2i.ZERO:
    var forward_tile = tile + current_tile_direction
    if not main.is_wall(forward_tile):
      candidates = [forward_tile]
      if randf() < 0.25:
        candidates = neighbors
  var next_tile = candidates.pick_random()

  current_direction = position.direction_to(main.tile_to_world(next_tile)).normalized()


func _on_task_begin():
  var prox = max(round(4 * pow(_player_proximity, 2)), 1)
  for i in range(0, prox):
    instrument.set_note_on(i / 4.0)
  light.energy = light_intensity
  _light_target_energy = light_intensity
  instrument.pitch_shift = randf_range(-0.0025, 0.0025)
  choose_travel_direction()

  scale = (1 + prox / 16.0) * scale_mult * _initial_scale
  performer.loop_length = loop_length * max(1.0 - _boss_proximity, 0.05)

  if main.boss != null:
    main.boss.ping()


func _on_task_end():
  for i in range(0, 3):
    instrument.set_note_off(i / 4.0)
  _light_target_energy = 0.0
