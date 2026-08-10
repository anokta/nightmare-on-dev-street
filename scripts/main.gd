extends Node2D

@export var player_light: PointLight2D
@export var background: CanvasModulate
@export var postfx: CanvasLayer

@export var enable_light: bool = true
@export var enable_background: bool = true
@export var enable_postfx: bool = true


func _input(event):
  if event is InputEventKey and event.pressed:
    if event.keycode == KEY_ESCAPE:
      get_tree().quit()
      return


func _process(delta):
  player_light.visible = enable_light
  background.visible = enable_background
  postfx.visible = enable_postfx
