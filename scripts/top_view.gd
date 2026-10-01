class_name TopView
extends Control

var loadout: Dictionary = {}
var rotation_angle: float = 0.0
var animated: bool = true
var exploded: bool = false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if custom_minimum_size == Vector2.ZERO:
		custom_minimum_size = Vector2(200, 200)

func set_loadout(value: Dictionary) -> void:
	loadout = value.duplicate()
	queue_redraw()

func initialize(value: Dictionary) -> void:
	set_loadout(value)

func _process(delta: float) -> void:
	if animated:
		rotation_angle += delta * 0.38
		queue_redraw()

func _draw() -> void:
	var radius = minf(size.x * 0.34, size.y * 0.34)
	var col: Color = UI.CYAN
	var style = ""
	if not loadout.is_empty():
		var blade = Catalog.part(str(loadout.get("blade", "")))
		col = blade.get("color", UI.CYAN)
		style = str(loadout.get("blade", ""))
	var at = size * Vector2(0.5, 0.54)
	for i in range(3):
		ellipse(self, at + Vector2(0, radius * 0.42), Vector2(radius * (1.2 - i * 0.13), radius * 0.34), Color(col, 0.022 + i * 0.01))
	for i in range(48):
		var a = TAU * i / 48.0
		var p = at + Vector2(cos(a), sin(a) * 0.58) * radius * 1.32
		var q = at + Vector2(cos(a), sin(a) * 0.58) * radius * (1.35 if i % 4 == 0 else 1.33)
		draw_line(p, q, Color(col, 0.3), 1.2, true)
	paint(self, at, radius, col, rotation_angle, style, 0.0, 0.66)

static func ellipse(node: CanvasItem, at: Vector2, radii: Vector2, color: Color, filled: bool = true, width: float = 1.0) -> void:
	var points = PackedVector2Array()
	for i in range(65):
		var a = TAU * i / 64.0
		points.append(at + Vector2(cos(a) * radii.x, sin(a) * radii.y))
	if filled:
		node.draw_colored_polygon(points, color)
	else:
		node.draw_polyline(points, color, width, true)

static func paint(node: CanvasItem, at: Vector2, radius: float, color: Color, rot: float, style: String = "", energy: float = 0.0, squash: float = 0.68) -> void:
	var metallic = Color("bccbde")
	var teeth: int = 6 + (abs(style.hash()) % 3)
	# Contact shadow, driver, disc and steel lip give each top a physical silhouette.
	ellipse(node, at + Vector2(4, radius * 0.43), Vector2(radius * 1.07, radius * 0.39), Color(0, 0, 0, 0.5))
	ellipse(node, at + Vector2(0, radius * 0.38), Vector2(radius * 0.2, radius * 0.13), color.darkened(0.42))
	for i in range(5):
		var center = at + Vector2(0, radius * (0.29 - i * 0.037))
		var r = radius * (0.67 + i * 0.05)
		ellipse(node, center, Vector2(r, r * squash), metallic.darkened(0.5 - i * 0.045))
	ellipse(node, at, Vector2(radius, radius * squash), Color("283753"))
	ellipse(node, at - Vector2(0, radius * 0.05), Vector2(radius * 0.96, radius * squash * 0.96), metallic)
	# Sculpted radial blades, dark facets and narrow cutting edges.
	for i in range(teeth):
		var a = rot + TAU * i / teeth
		var points = PackedVector2Array()
		var facets = [[0.22, -0.13], [0.71, -0.23], [1.02, 0.015], [0.86, 0.29], [0.53, 0.38], [0.27, 0.22]]
		for f in facets:
			var p = Vector2(float(f[0]), float(f[1])).rotated(a) * radius
			p.y *= squash
			points.append(at + p - Vector2(0, radius * 0.065))
		node.draw_colored_polygon(points, color.darkened(0.12 if i % 2 == 0 else 0.31))
		node.draw_polyline(points, color.lightened(0.3), maxf(1, radius * 0.017), true)
		var highlight = PackedVector2Array()
		for f in [[0.6, -0.13], [0.85, -0.02], [0.69, 0.16], [0.43, 0.11]]:
			var p = Vector2(float(f[0]), float(f[1])).rotated(a) * radius
			p.y *= squash
			highlight.append(at + p - Vector2(0, radius * 0.065))
		node.draw_colored_polygon(highlight, Color(color.lightened(0.65), 0.52))
	ellipse(node, at - Vector2(0, radius * 0.06), Vector2(radius * 0.46, radius * 0.46 * squash), metallic.darkened(0.4))
	ellipse(node, at - Vector2(0, radius * 0.11), Vector2(radius * 0.36, radius * 0.36 * squash), Color("0b1730"))
	ellipse(node, at - Vector2(0, radius * 0.13), Vector2(radius * 0.3, radius * 0.3 * squash), color.darkened(0.3))
	var star = PackedVector2Array()
	for i in range(10):
		var a = rot * -0.5 + TAU * i / 10.0 - PI * 0.5
		var r = radius * (0.22 if i % 2 == 0 else 0.10)
		star.append(at + Vector2(cos(a), sin(a) * squash) * r - Vector2(0, radius * 0.15))
	node.draw_colored_polygon(star, Color("e9f9ff"))
	if energy > 60:
		ellipse(node, at, Vector2(radius * 1.22, radius * 1.22 * squash), Color(color, 0.25 + 0.15 * sin(rot)), false, 2)
