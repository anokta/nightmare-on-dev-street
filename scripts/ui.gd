class_name UI
# Shared look for the menus: plain white text on black, the focused item lit up.

const DIM = Color(1.0, 1.0, 1.0, 0.4)


static func make_theme() -> Theme:
  var theme = Theme.new()
  theme.default_font_size = 32
  var empty = StyleBoxEmpty.new()
  for state in ["normal", "hover", "pressed", "disabled", "focus"]:
    theme.set_stylebox(state, "Button", empty)
  theme.set_color("font_color", "Button", DIM)
  for state in ["font_hover_color", "font_focus_color", "font_pressed_color", "font_hover_pressed_color"]:
    theme.set_color(state, "Button", Color.WHITE)
  return theme


# A full-screen backdrop with a centered column to put menu items in.
static func make_menu(parent: Control, backdrop_alpha: float = 1.0) -> VBoxContainer:
  parent.theme = make_theme()
  var backdrop = ColorRect.new()
  backdrop.color = Color(0.0, 0.0, 0.0, backdrop_alpha)
  backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
  parent.add_child(backdrop)

  var box = VBoxContainer.new()
  box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
  box.alignment = BoxContainer.ALIGNMENT_CENTER
  box.add_theme_constant_override("separation", 16)
  parent.add_child(box)
  return box


static func add_title(box: Control, text: String, size: int = 56) -> Label:
  var label = Label.new()
  label.text = text
  label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  label.add_theme_font_size_override("font_size", size)
  box.add_child(label)
  var spacer = Control.new()
  spacer.custom_minimum_size.y = 32
  box.add_child(spacer)
  return label


static func add_button(box: Control, text: String, on_pressed: Callable) -> Button:
  var button = Button.new()
  button.text = text
  button.flat = true
  button.pressed.connect(on_pressed)
  # mouse hover moves keyboard focus too, so only one item is ever lit
  button.mouse_entered.connect(button.grab_focus)
  box.add_child(button)
  return button
