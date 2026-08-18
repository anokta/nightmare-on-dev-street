extends StaticBody2D

@export var sprite: Sprite2D
@export var collision_shape: CollisionShape2D

var _noise: Noise


func _ready():
  _noise = sprite.texture.noise


func _process(_delta):
  _noise.frequency = randf_range(0.02, 0.05)
