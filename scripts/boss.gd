extends CharacterBody2D

@export var main: Node2D
@export var player: CharacterBody2D

@export var light: Light2D
@export var sprite: Sprite2D

@export var instrument: BarelyInstrument
@export var performer: BarelyPerformer

@export var light_energy_speed: float = 20.0
@export var light_intensity: float = 10.0

@export var rotation_speed: float = 20.0

@export_group("Player Distance")
@export var min_player_distance: float = 2.0
@export var max_player_distance: float = 40.0

@export_range(1, 16, 1) var beat_count: int = 4

var _light_target_energy: float = 0.0
var _beat: int = 0


func _ready() -> void:
  var task = performer.tasks[0]
  task.connect("task_begin", Callable(self, "_on_task_begin"))
  task.connect("task_end", Callable(self, "_on_task_end"))

  # performer.start()


func _physics_process(delta):
  velocity = Vector2.ZERO

  light.energy = lerpf(light.energy, _light_target_energy, light_energy_speed * delta)

  var from_player = position - player.position
  var player_dist = from_player.length()

  var min_dist = min_player_distance * main.tile_size
  var max_dist = max_player_distance * main.tile_size

  instrument.stereo_pan = (
    sign(from_player.x) * clampf((abs(from_player.x) - min_dist) / (max_dist - min_dist), 0.0, 1.0)
  )

  var proximity = clampf((max_dist - player_dist) / (max_dist - min_dist), 0.0, 1.0)
  instrument.filter_cutoff = pow(proximity, 2.0)
  instrument.distortion_mix = pow(max(0.5, proximity) - 0.5, 2.0)
  instrument.crush_rate = pow(0.5 * proximity, 1.5)
  instrument.crush_depth = pow(0.9 * (max(0.25, proximity) - 0.25), 1.0)
  instrument.osc_mix = pow(max(0.75, proximity) - 0.75, 2.0)

  sprite.rotate(rotation_speed * (2.0 * randf() - 1.0) * delta)

  move_and_slide()


func _on_task_begin():
  if _beat == 0:
    instrument.set_note_on(0.0)
    light.energy = light_intensity
    _light_target_energy = light_intensity

  _beat = (_beat + 1) % beat_count


func _on_task_end():
  instrument.set_note_off(0.0)
  _light_target_energy = 0.0
