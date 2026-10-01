class_name UI
extends RefCounted

const CYAN = Color("59f1df")
const GOLD = Color("f8ce7b")
const PINK = Color("ff697d")
const INK = Color("0a1020")
const MUTED = Color("95a6c1")
const WHITE = Color("ecf4ff")
const SURFACE = Color("111b30")
const EDGE = Color("283650")

static func font_title() -> Font:
	return preload("res://assets/fonts/Display.ttf")

static func font_body() -> Font:
	return preload("res://assets/fonts/Body.ttf")

static func panel(bg: Color = SURFACE, border: Color = EDGE, radius: int = 12) -> StyleBoxFlat:
	var box = StyleBoxFlat.new()
	box.bg_color = bg
	box.border_color = border
	box.set_border_width_all(1)
	box.set_corner_radius_all(radius)
	box.content_margin_left = 18
	box.content_margin_right = 18
	box.content_margin_top = 14
	box.content_margin_bottom = 14
	return box

static func label(value: String, font_size: int = 18, color: Color = WHITE) -> Label:
	var node = Label.new()
	node.text = value
	node.add_theme_font_override("font", font_body() if font_size < 26 else font_title())
	node.add_theme_font_size_override("font_size", font_size)
	node.add_theme_color_override("font_color", color)
	return node

static func button(value: String, callback: Callable = Callable(), primary: bool = false) -> Button:
	var node = Button.new()
	node.text = value
	node.custom_minimum_size = Vector2(0, 45)
	node.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	node.add_theme_font_override("font", font_title())
	node.add_theme_font_size_override("font_size", 21)
	var base = CYAN if primary else SURFACE
	node.add_theme_color_override("font_color", INK if primary else WHITE)
	node.add_theme_color_override("font_hover_color", INK if primary else CYAN)
	node.add_theme_color_override("font_pressed_color", INK if primary else CYAN)
	node.add_theme_color_override("font_focus_color", INK if primary else WHITE)
	node.add_theme_color_override("font_disabled_color", MUTED.darkened(0.3))
	node.add_theme_stylebox_override("normal", panel(base, CYAN if primary else EDGE, 8))
	node.add_theme_stylebox_override("hover", panel(base.lightened(0.12), CYAN, 8))
	node.add_theme_stylebox_override("pressed", panel(base.darkened(0.1), CYAN, 8))
	node.add_theme_stylebox_override("focus", panel(Color(base, 0.25), GOLD, 8))
	node.add_theme_stylebox_override("disabled", panel(INK, EDGE, 8))
	if callback.is_valid():
		node.pressed.connect(callback)
	return node

static func paragraph(value: String, font_size: int = 16, color: Color = MUTED) -> Label:
	var node = label(value, font_size, color)
	node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return node

static func theme() -> Theme:
	var result = Theme.new()
	result.default_font = font_body()
	result.default_font_size = 17
	result.set_color("font_color", "Label", WHITE)
	result.set_color("font_color", "CheckButton", WHITE)
	result.set_color("font_color", "CheckBox", WHITE)
	result.set_stylebox("panel", "PanelContainer", panel())
	result.set_stylebox("background", "ProgressBar", panel(INK, EDGE, 6))
	result.set_stylebox("fill", "ProgressBar", panel(CYAN, CYAN, 6))
	return result

static func margin(parent: Node, amount: int = 24) -> MarginContainer:
	var node = MarginContainer.new()
	for direction in ["left", "right", "top", "bottom"]:
		node.add_theme_constant_override("margin_" + direction, amount)
	parent.add_child(node)
	return node

static func vbox(parent: Node, spacing: int = 12) -> VBoxContainer:
	var node = VBoxContainer.new()
	node.add_theme_constant_override("separation", spacing)
	parent.add_child(node)
	return node

static func hbox(parent: Node, spacing: int = 12) -> HBoxContainer:
	var node = HBoxContainer.new()
	node.add_theme_constant_override("separation", spacing)
	parent.add_child(node)
	return node

static func spacer(parent: Node) -> Control:
	var node = Control.new()
	node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	node.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(node)
	return node
