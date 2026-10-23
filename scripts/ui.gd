class_name UI
# Shared look for the menus and captions, taken from the game itself: black,
# marker lettering like the painted death screen, its red for focus and danger,
# and the same glitch shader over the top.

const RED = Color(0.86, 0.0, 0.0)
const WHITE = Color(0.92, 0.92, 0.92)
const DIM = Color(1.0, 1.0, 1.0, 0.35)

const FONT = preload("res://fonts/PermanentMarker-Regular.ttf")
const GLITCH = preload("res://shaders/glitch.gdshader")


static func make_theme() -> Theme:
  var theme = Theme.new()
  theme.default_font = FONT
  theme.default_font_size = 32
  theme.set_color("font_color", "Label", WHITE)
  var empty = StyleBoxEmpty.new()
  for state in ["normal", "hover", "pressed", "disabled", "focus"]:
    theme.set_stylebox(state, "Button", empty)
  theme.set_color("font_color", "Button", DIM)
  for state in ["font_hover_color", "font_focus_color", "font_pressed_color", "font_hover_pressed_color"]:
    theme.set_color(state, "Button", RED)
  return theme


# The game's glitch pass, for screens outside main.tscn. It glitches everything
# on lower canvas layers, scaled by strength and the Screen effects setting.
static func add_glitch(parent: Node, strength: float = 1.0, layer: int = 90) -> void:
  var canvas = CanvasLayer.new()
  canvas.layer = layer
  var rect = ColorRect.new()
  rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
  rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
  var material = ShaderMaterial.new()
  material.shader = GLITCH
  var effects = SaveData.effects_scale() * strength
  # main.tscn's Glitcher values, with intensity up so text visibly breaks up at strength 1
  material.set_shader_parameter("glitch_speed", 4.0)
  material.set_shader_parameter("glitch_intensity", 0.004 * effects)
  material.set_shader_parameter("block_count", 20.0)
  material.set_shader_parameter("color_split", 0.007 * effects)
  rect.material = material
  canvas.add_child(rect)
  parent.add_child(canvas)


# Faint TV static like the walls' noise, behind the menus.
static func add_static(parent: Control, alpha: float = 0.06) -> void:
  alpha *= SaveData.effects_scale()
  if alpha <= 0.0:
    return
  var noise = FastNoiseLite.new()
  noise.noise_type = FastNoiseLite.TYPE_VALUE
  noise.frequency = 0.5
  var texture = NoiseTexture2D.new()
  texture.width = 240
  texture.height = 135
  texture.noise = noise

  var rect = TextureRect.new()
  rect.texture = texture
  rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
  rect.stretch_mode = TextureRect.STRETCH_SCALE
  rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
  rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
  rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
  rect.modulate.a = alpha
  parent.add_child(rect)

  var timer = Timer.new()
  timer.wait_time = 0.08
  timer.autostart = true
  timer.timeout.connect(func(): noise.seed = randi())
  rect.add_child(timer)


# Story lines drift from white to the painted red as the game goes on.
static func story_color(progress: float) -> Color:
  return WHITE.lerp(RED, smoothstep(0.35, 0.95, progress))


# A full-screen backdrop with a centered column to put menu items in.
static func make_menu(parent: Control, backdrop_alpha: float = 1.0) -> VBoxContainer:
  parent.theme = make_theme()
  var backdrop = ColorRect.new()
  backdrop.color = Color(0.0, 0.0, 0.0, backdrop_alpha)
  backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
  parent.add_child(backdrop)
  add_static(parent)

  var box = VBoxContainer.new()
  box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
  box.alignment = BoxContainer.ALIGNMENT_CENTER
  box.add_theme_constant_override("separation", 12)
  parent.add_child(box)
  return box


static func add_title(box: Control, text: String, size: int = 56) -> Label:
  var label = Label.new()
  label.text = text
  label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  label.add_theme_font_size_override("font_size", size)
  label.add_theme_color_override("font_color", RED)
  box.add_child(label)
  var spacer = Control.new()
  spacer.custom_minimum_size.y = 24
  box.add_child(spacer)
  return label


static func add_button(box: Control, text: String, on_pressed: Callable) -> Button:
  var button = Button.new()
  button.text = text
  button.flat = true
  button.pressed.connect(on_pressed)
  # moving the mouse over an item moves keyboard focus too, so only one item is ever lit
  # (not mouse_entered: that also fires when a menu opens under a resting cursor)
  button.gui_input.connect(
    func(event):
      if event is InputEventMouseMotion and not button.has_focus():
        button.grab_focus()
  )
  box.add_child(button)
  return button
