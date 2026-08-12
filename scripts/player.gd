extends CharacterBody2D

@export var light: Light2D
@export var sprite: Sprite2D

@export var hummer: BarelyInstrument

@export var instrument: BarelyInstrument
@export var performer: BarelyPerformer

@export var tile_size: int = 45
@export var speed: float = 250.0
@export var snap_speed: float = 10.0

@export var rotation_speed: float = 3.0

@export_range(1, 16, 1) var beat_count: int = 4

@export var light_energy_speed: float = 20.0
@export var light_intensity: float = 10.0

@export var hum_lfo_freq: float = 0.1
@export var hum_lfo_range: float = 0.05

@export var hum_max_gain: float = 0.5
@export var hum_gain_speed: float = 8.0

var _light_target_energy: float = 0.0

var _hum_lfo_phase: float = 0.0
var _beat: int = 0


func _ready() -> void:
  var task = performer.tasks[0]
  task.connect("task_begin", Callable(self, "_on_task_begin"))
  task.connect("task_end", Callable(self, "_on_task_end"))

  hummer.gain = 0.0
  hummer.set_note_on(0.0)

  performer.start()


func _physics_process(delta: float) -> void:
  var direction: Vector2 = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")

  if direction != Vector2.ZERO:
    velocity = direction * speed
  else:  # snap to grid
    var closest_grid_position = position.snapped(Vector2.ONE * tile_size)
    position = position.move_toward(closest_grid_position, snap_speed * delta)
    velocity = Vector2.ZERO

  var unit_velocity = velocity / speed
  if unit_velocity != Vector2.ZERO:
    var delta_position = unit_velocity / tile_size
    var roll_direction = 1.0
    if delta_position.x < 0 or (delta_position.x == 0 and delta_position.y > 0):
      roll_direction = -1.0
    var rotation_amount = rotation_speed * delta_position.length() * roll_direction
    sprite.rotate(rotation_amount)

  hummer.gain = lerpf(hummer.gain, min(hum_max_gain, velocity.length()), hum_gain_speed * delta)
  hummer.pitch_shift = sin(_hum_lfo_phase * 2.0 * PI) * hum_lfo_range
  _hum_lfo_phase += delta * hum_lfo_freq

  _light_target_energy = light_intensity * min(unit_velocity.length(), 1.0)
  light.energy = lerpf(light.energy, _light_target_energy, light_energy_speed * delta)

  move_and_slide()


func _on_task_begin():
  # if _beat == 0:
  #   # instrument.set_note_on(0.0)
  #   light.energy = light_intensity

  _beat = (_beat + 1) % beat_count


func _on_task_end():
  # instrument.set_note_off(0.0)
  _light_target_energy = 0.0
