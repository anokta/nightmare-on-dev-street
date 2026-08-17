extends CharacterBody2D

@export var main: Node2D
@export var player: CharacterBody2D
@export var boss: CharacterBody2D

@export var light: Light2D
@export var sprite: Sprite2D

@export var instrument: BarelyInstrument
@export var performer: BarelyPerformer

@export var light_energy_speed: float = 20.0
@export var light_intensity: float = 10.0

@export var loop_length: float = 4.0
@export var speed: float = 20.0

@export_group("Boss Distance")
@export var min_boss_distance: float = 2.0
@export var min_boss_panic_distance: float = 20.0
@export var max_boss_distance: float = 40.0

@export_group("Player Distance")
@export var min_player_distance: float = 2.0
@export var max_player_distance: float = 40.0

var current_direction: Vector2 = Vector2.ZERO
var _light_target_energy: float = 0.0


func _ready() -> void:
  var task = performer.tasks[0]
  task.connect("task_begin", Callable(self, "_on_task_begin"))
  task.connect("task_end", Callable(self, "_on_task_end"))

  performer.start()


func _physics_process(delta):
  light.energy = lerpf(light.energy, _light_target_energy, light_energy_speed * delta)

  var from_player = position - player.position
  var player_dist = from_player.length()

  var min_dist = min_player_distance * main.tile_size
  var max_dist = max_player_distance * main.tile_size

  light.scale.x = 0.49 * player_dist
  look_at(player.position)

  instrument.stereo_pan = (
    sign(from_player.x) * clampf((abs(from_player.x) - min_dist) / (max_dist - min_dist), 0.0, 1.0)
  )

  var from_boss = position - boss.position
  var boss_dist = from_boss.length()

  var min_boss_dist = min_boss_distance * main.tile_size
  var max_boss_dist = max_boss_distance * main.tile_size

  var proximity = clampf((max_boss_dist - boss_dist) / (max_boss_dist - min_boss_dist), 0.0, 1.0)
  performer.loop_length = loop_length * max(1.0 - proximity, 0.02)
  current_direction = lerp(from_boss.normalized(), current_direction, proximity * delta)

  velocity = velocity.move_toward(current_direction * speed, (1.0 + 50 * proximity) * speed * delta)

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
  instrument.set_note_on(0.0)
  light.energy = light_intensity
  _light_target_energy = light_intensity
  choose_travel_direction()


func _on_task_end():
  instrument.set_note_off(0.0)
  _light_target_energy = 0.0
