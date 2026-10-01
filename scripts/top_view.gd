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
	paint(self, at, radius, col, rotation_angle, style, 0.0, 0.66, loadout)

static func ellipse(node: CanvasItem, at: Vector2, radii: Vector2, color: Color, filled: bool = true, width: float = 1.0) -> void:
	var points = PackedVector2Array()
	for i in range(65):
		var a = TAU * i / 64.0
		points.append(at + Vector2(cos(a) * radii.x, sin(a) * radii.y))
	if filled:
		node.draw_colored_polygon(points, color)
	else:
		node.draw_polyline(points, color, width, true)

static func paint(node: CanvasItem, at: Vector2, radius: float, color: Color, rot: float, style: String = "", energy: float = 0.0, squash: float = 0.68, parts: Dictionary = {}) -> void:
	var metallic = Color("bccbde")
	var teeth: int = {"comet": 6, "fang": 3, "talon": 3, "bastion": 5, "lotus": 8, "scythe": 2, "meteor": 4, "mirror": 6, "leviathan": 8, "monarch": 4}.get(style, 6)
	var disc = str(parts.get("disc", "halo"))
	var disc_factor: float = {"halo": 0.86, "anvil": 0.99, "feather": 0.7, "gyre": 0.93, "split": 0.8, "keel": 0.88, "reactor": 0.78, "crown": 1.03}.get(disc, 0.86)
	# Contact shadow, driver, disc and steel lip give each top a physical silhouette.
	ellipse(node, at + Vector2(4, radius * 0.43), Vector2(radius * 1.07, radius * 0.39), Color(0, 0, 0, 0.5))
	ellipse(node, at + Vector2(0, radius * 0.38), Vector2(radius * 0.2, radius * 0.13), color.darkened(0.42))
	for i in range(5):
		var center = at + Vector2(0, radius * (0.29 - i * 0.037))
		var r = radius * (disc_factor - 0.19 + i * 0.047)
		ellipse(node, center, Vector2(r, r * squash), metallic.darkened(0.5 - i * 0.045))
	ellipse(node, at, Vector2(radius, radius * squash), Color("283753"))
	ellipse(node, at - Vector2(0, radius * 0.05), Vector2(radius * 0.96, radius * squash * 0.96), metallic)
	# Sculpted radial blades, dark facets and narrow cutting edges.
	for i in range(teeth):
		var a = rot + TAU * i / teeth
		var points = PackedVector2Array()
		var facets = [[0.22, -0.13], [0.71, -0.23], [1.02, 0.015], [0.86, 0.29], [0.53, 0.38], [0.27, 0.22]]
		match style:
			"fang", "talon": facets = [[0.22, -0.12], [0.83, -0.47], [1.16, -0.06], [0.96, 0.2], [0.52, 0.4], [0.24, 0.24]]
			"bastion": facets = [[0.24, -0.15], [0.76, -0.4], [0.94, -0.15], [0.94, 0.28], [0.65, 0.45], [0.24, 0.25]]
			"lotus", "leviathan": facets = [[0.27, -0.10], [0.74, -0.18], [0.95, 0.01], [0.86, 0.25], [0.59, 0.33], [0.27, 0.18]]
			"scythe": facets = [[0.22, -0.11], [0.62, -0.45], [1.12, -0.11], [0.99, 0.37], [0.74, 0.51], [0.69, 0.05], [0.3, 0.23]]
			"meteor": facets = [[0.23, -0.1], [0.54, -0.18], [0.86, -0.49], [1.02, -0.22], [1.02, 0.35], [0.66, 0.39], [0.27, 0.18]]
			"monarch": facets = [[0.2, -0.12], [0.81, -0.4], [1.2, 0.02], [0.75, 0.16], [0.97, 0.37], [0.35, 0.31]]
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
	var core = str(parts.get("core", "nova"))
	var star = PackedVector2Array()
	for i in range(10):
		var a = rot * -0.5 + TAU * i / 10.0 - PI * 0.5
		var r = radius * (0.22 if i % 2 == 0 else 0.10)
		star.append(at + Vector2(cos(a), sin(a) * squash) * r - Vector2(0, radius * 0.15))
	if core in ["aegis", "zenith"]:
		star = PackedVector2Array()
		for p in [Vector2(-0.19, -0.14), Vector2(0, -0.22), Vector2(0.19, -0.14), Vector2(0.16, 0.13), Vector2(0, 0.24), Vector2(-0.16, 0.13)]:
			star.append(at + Vector2(p.x, p.y * squash) * radius - Vector2(0, radius * 0.15))
	elif core in ["phoenix", "eclipse"]:
		star = PackedVector2Array()
		for p in [Vector2(0, -0.15), Vector2(0.23, -0.21), Vector2(0.15, 0.04), Vector2(0.05, 0.2), Vector2(0, 0.05), Vector2(-0.05, 0.2), Vector2(-0.15, 0.04), Vector2(-0.23, -0.21)]:
			star.append(at + Vector2(p.x, p.y * squash) * radius - Vector2(0, radius * 0.15))
	elif core == "thunder":
		star = PackedVector2Array()
		for p in [Vector2(0.04, -0.24), Vector2(-0.16, 0.04), Vector2(-0.01, 0.04), Vector2(-0.04, 0.23), Vector2(0.16, -0.04), Vector2(0.01, -0.04)]:
			star.append(at + Vector2(p.x, p.y * squash) * radius - Vector2(0, radius * 0.15))
	node.draw_colored_polygon(star, Color("e9f9ff"))
	if energy > 60:
		ellipse(node, at, Vector2(radius * 1.22, radius * 1.22 * squash), Color(color, 0.25 + 0.15 * sin(rot)), false, 2)
