extends Node2D

@export var player_light: PointLight2D
@export var background: CanvasModulate
@export var postfx: CanvasLayer

@export var enable_light: bool = true
@export var enable_background: bool = true
@export var enable_postfx: bool = true


func _ready() -> void:
  BarelyEngine.delay_ping_pong = 1.0
  BarelyEngine.delay_time = 0.12
  BarelyEngine.delay_feedback = 0.25
  BarelyEngine.delay_lpf_cutoff = 0.5
  BarelyEngine.delay_reverb_send = 0.5
  BarelyEngine.reverb_damping = 0.2
  BarelyEngine.reverb_room_size = 0.4

func _input(event):
  if event is InputEventKey and event.pressed:
    if event.keycode == KEY_ESCAPE:
      get_tree().quit()
      return


func _process(_delta):
  player_light.visible = enable_light
  background.visible = enable_background
  postfx.visible = enable_postfx
