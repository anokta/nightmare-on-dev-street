extends CharacterBody2D

@export var main: Node2D
@export var player: CharacterBody2D

@export var light: Light2D
@export var sprite: Sprite2D

@export var instrument: BarelyInstrument
@export var performer: BarelyPerformer

@export var light_energy_speed: float = 20.0
@export var light_intensity: float = 10.0

@export_range(1, 16, 1) var beat_count: int = 4

var _light_target_energy: float = 0.0
var _beat: int = 0


func _ready() -> void:
  var task = performer.tasks[0]
  task.connect("task_begin", Callable(self, "_on_task_begin"))
  task.connect("task_end", Callable(self, "_on_task_end"))

  performer.start()


func _physics_process(delta):
  light.energy = lerpf(light.energy, _light_target_energy, light_energy_speed * delta)

  var dist = position.distance_to(player.position)
  light.scale.x = 0.49 * dist
  look_at(player.position)

func _on_task_begin():
  if _beat == 0:
    instrument.set_note_on(0.0)
    light.energy = light_intensity
    _light_target_energy = light_intensity

  _beat = (_beat + 1) % beat_count


func _on_task_end():
  instrument.set_note_off(0.0)
  _light_target_energy = 0.0
