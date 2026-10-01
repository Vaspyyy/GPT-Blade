class_name RivalPortrait
extends Control
## Original vector character art. Painted at 280 x 180, then scaled uniformly
## to the available panel. Each authored rival has a distinct silhouette.

var rival: Dictionary = {}
const INK := Color("091222")
const PAPER := Color("e6edf3")
const STYLES := {
	"mika": {"hair": "spikes", "hair_color": "203148", "skin": "edb893", "width": 1.0, "eye": "bright", "uniform": 0, "number": "01"},
	"rook": {"hair": "crew", "hair_color": "9fadb8", "skin": "aa775c", "width": 1.16, "eye": "stern", "uniform": 1, "number": "02"},
	"iona": {"hair": "bob", "hair_color": "d5c5e9", "skin": "efc5b0", "width": 0.90, "eye": "soft", "uniform": 2, "number": "03"},
	"jax": {"hair": "swept", "hair_color": "db4d61", "skin": "deb191", "width": 0.97, "eye": "grin", "uniform": 0, "number": "04"},
	"sera": {"hair": "pony", "hair_color": "28475b", "skin": "c89773", "width": 0.91, "eye": "soft", "uniform": 2, "number": "05"},
	"nox": {"hair": "undercut", "hair_color": "dadfe8", "skin": "b58263", "width": 1.04, "eye": "stern", "uniform": 1, "number": "06"},
	"emi": {"hair": "twins", "hair_color": "b7432e", "skin": "e7ac81", "width": 0.92, "eye": "bright", "uniform": 0, "number": "07"},
	"vale": {"hair": "veil", "hair_color": "cbc2e3", "skin": "d6b7ab", "width": 0.94, "eye": "stern", "uniform": 3, "number": "08"},
	"kira": {"hair": "electric", "hair_color": "f2cc67", "skin": "cb956f", "width": 0.95, "eye": "grin", "uniform": 0, "number": "09"},
	"orin": {"hair": "slick", "hair_color": "49788c", "skin": "e0b598", "width": 1.0, "eye": "soft", "uniform": 1, "number": "10"},
	"rena": {"hair": "crown", "hair_color": "453449", "skin": "d6a584", "width": 0.92, "eye": "stern", "uniform": 2, "number": "11"},
	"atlas": {"hair": "ascend", "hair_color": "dbe4e8", "skin": "a56b4c", "width": 1.10, "eye": "stern", "uniform": 3, "number": "12"},
}


func initialize(value: Dictionary) -> void:
	rival = value.duplicate(true)
	queue_redraw()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)


func _poly(points: Array, color: Color, outline: bool = true, stroke: float = 2.0) -> void:
	var vertices := PackedVector2Array()
	for point in points:
		vertices.append(Vector2(point[0], point[1]))
	draw_colored_polygon(vertices, color)
	if outline:
		vertices.append(vertices[0])
		draw_polyline(vertices, INK, stroke, true)


func _face_point(x: float, y: float, width: float) -> Array:
	return [140 + (x - 140) * width, y]


func _draw() -> void:
	if size.x < 1 or size.y < 1:
		return
	var s := minf(size.x / 280.0, size.y / 180.0)
	var origin := Vector2((size.x - 280 * s) / 2, (size.y - 180 * s) / 2)
	draw_set_transform(origin, 0, Vector2(s, s))
	var accent: Color = rival.get("color", UI.CYAN)
	var style: Dictionary = STYLES.get(str(rival.get("id", "mika")), STYLES.mika)
	var hair := Color(str(style.hair_color))
	var skin := Color(str(style.skin))
	var width := float(style.width)
	var kind := str(style.hair)
	var expression := str(style.eye)
	# An airy graphic badge makes the silhouette readable against the dark room.
	draw_circle(Vector2(140, 96), 76, Color(accent, 0.075))
	draw_arc(Vector2(140, 96), 75, -2.8, 0.6, 52, Color(accent, 0.4), 1.5, true)
	draw_arc(Vector2(140, 96), 68, 0.4, 1.5, 32, Color(accent, 0.16), 1, true)
	for i in range(5):
		draw_line(Vector2(30 + i * 9, 70), Vector2(47 + i * 9, 45), Color(accent, 0.07), 2, true)
	draw_string(UI.font_title(), Vector2(13, 34), str(style.number), HORIZONTAL_ALIGNMENT_LEFT, -1, 33, Color(accent, 0.30))
	draw_string(UI.font_body(), Vector2(217, 31), "RIVAL", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(accent, 0.6))
	draw_line(Vector2(218, 39), Vector2(258, 39), Color(accent, 0.3), 1)
	_draw_back_hair(kind, hair, accent)
	# Neck and broad angular sports uniform.
	_poly([[121, 103], [157, 103], [162, 127], [140, 145], [117, 126]], skin.darkened(0.10))
	_poly([[73, 180], [79, 142], [100, 127], [118, 117], [140, 131], [163, 117], [184, 128], [204, 144], [210, 180]], accent.darkened(0.59))
	_poly([[73, 180], [79, 143], [101, 128], [111, 133], [98, 180]], accent.darkened(0.19), false)
	_poly([[179, 128], [203, 145], [210, 180], [185, 180], [173, 135]], accent.darkened(0.32), false)
	_poly([[111, 136], [119, 124], [140, 142], [161, 124], [172, 136], [164, 180], [116, 180]], PAPER.darkened(0.03) if int(style.uniform) == 2 else Color("202e43"))
	# Folded collar and hand-painted team insignia.
	_poly([[102, 126], [118, 114], [140, 131], [128, 144]], accent.lightened(0.20))
	_poly([[140, 131], [162, 114], [179, 127], [153, 145]], accent.darkened(0.03))
	draw_line(Vector2(140, 143), Vector2(140, 180), INK.lightened(0.08), 2)
	if int(style.uniform) in [1, 3]:
		_poly([[88, 150], [99, 143], [113, 150], [101, 158]], PAPER.darkened(0.1), false)
		_poly([[177, 149], [188, 143], [197, 150], [186, 158]], accent.lightened(0.3), false)
	else:
		draw_line(Vector2(90, 151), Vector2(106, 164), PAPER, 4, true)
		draw_line(Vector2(177, 163), Vector2(193, 151), PAPER, 4, true)
	_poly([[157, 156], [167, 153], [172, 158], [167, 167], [161, 165]], accent.lightened(0.20))
	draw_line(Vector2(163, 157), Vector2(165, 162), INK, 1.6)
	# Ears, face, one clean shadow plane and a forehead highlight.
	draw_circle(Vector2(105 - (width - 1) * 28, 85), 7, skin.darkened(0.12))
	draw_circle(Vector2(174 + (width - 1) * 28, 85), 7, skin.darkened(0.20))
	var face: Array = []
	for point in [[105, 65], [111, 46], [130, 38], [149, 40], [164, 49], [171, 68], [169, 93], [160, 111], [146, 121], [133, 122], [115, 112], [106, 94]]:
		face.append(_face_point(point[0], point[1], width))
	_poly(face, skin, true, 2.4)
	var shadow: Array = []
	for point in [[150, 41], [164, 49], [171, 68], [169, 93], [160, 111], [146, 121], [133, 122], [150, 108], [154, 83]]:
		shadow.append(_face_point(point[0], point[1], width))
	_poly(shadow, skin.darkened(0.13), false)
	_poly([[115, 57], [131, 49], [144, 51], [135, 64], [117, 65]], skin.lightened(0.08), false)
	_draw_eyes(width, accent, expression, str(rival.get("id", "")))
	# Small nose and expression read at thumbnail size.
	draw_polyline(PackedVector2Array([Vector2(142, 83), Vector2(145, 94), Vector2(139, 95)]), skin.darkened(0.32), 1.5, true)
	if expression in ["bright", "grin"]:
		_poly([[128, 103], [151, 103], [145, 109], [136, 110]], INK, false)
		draw_line(Vector2(131, 104), Vector2(148, 104), PAPER, 2.2, true)
	elif expression == "soft":
		draw_polyline(PackedVector2Array([Vector2(132, 105), Vector2(140, 107), Vector2(147, 105)]), INK, 1.5, true)
	else:
		draw_line(Vector2(133, 106), Vector2(148, 105), INK, 1.8, true)
		draw_line(Vector2(139, 111), Vector2(145, 111), skin.darkened(0.25), 1, true)
	_draw_front_hair(kind, hair, accent)
	if kind == "slick":
		# Orin's slim clear spectacles are part of his silhouette and personality.
		draw_style_box(UI.panel(Color(accent, 0.05), Color(accent, 0.8), 3), Rect2(109, 74, 25, 14))
		draw_style_box(UI.panel(Color(accent, 0.05), Color(accent, 0.8), 3), Rect2(146, 74, 25, 14))
		draw_line(Vector2(134, 78), Vector2(146, 78), accent.lightened(0.3), 1.5)
	if kind == "undercut":
		draw_line(Vector2(156, 88), Vector2(151, 100), skin.lightened(0.18), 2, true)
	if kind in ["electric", "twins"]:
		for side in [-1, 1]:
			draw_line(Vector2(140 + side * 22, 95), Vector2(140 + side * 18, 97), Color(accent, 0.5), 2, true)
	# Bound the illustration cleanly; no art bleeds into the launch controls.
	draw_line(Vector2(56, 179), Vector2(225, 179), Color(accent, 0.28), 1)
	draw_set_transform(Vector2.ZERO)


func _draw_eyes(width: float, accent: Color, expression: String, id: String) -> void:
	var slope := 2.0 if expression == "stern" else -1.0
	for side in [-1, 1]:
		var x: float = 140 + side * 20 * width
		var eye := PackedVector2Array([Vector2(x - 10, 78 - side * slope), Vector2(x - 3, 74), Vector2(x + 8, 76 + side * slope), Vector2(x + 6, 83), Vector2(x - 6, 83)])
		draw_colored_polygon(eye, PAPER)
		eye.append(eye[0])
		draw_polyline(eye, INK, 1.5, true)
		draw_circle(Vector2(x + 1, 79), 3.6, accent.darkened(0.46))
		draw_circle(Vector2(x + 1.5, 79), 1.7, INK)
		draw_circle(Vector2(x, 77.5), 1, PAPER)
		var brow_y := 69 if expression == "stern" else 68
		draw_line(Vector2(x - 10, brow_y - side * slope), Vector2(x + 8, brow_y + side * slope), INK, 2.7, true)
	if id == "rook":
		draw_line(Vector2(134, 73), Vector2(137, 70), skin_tone(id).darkened(0.30), 1.5)


func skin_tone(id: String) -> Color:
	return Color(str(STYLES.get(id, STYLES.mika).skin))


func _draw_back_hair(kind: String, hair: Color, accent: Color) -> void:
	if kind in ["bob", "veil"]:
		_poly([[96, 144], [89, 113], [91, 61], [99, 39], [121, 27], [151, 26], [177, 42], [185, 84], [183, 137], [166, 145], [164, 98], [113, 100], [112, 146]], hair.darkened(0.28))
	elif kind in ["pony", "crown"]:
		_poly([[170, 51], [190, 31], [209, 38], [206, 58], [193, 83], [197, 111], [211, 126], [192, 126], [174, 106], [175, 79]], hair.darkened(0.14))
		draw_line(Vector2(188, 45), Vector2(198, 51), accent, 5, true)
	elif kind == "twins":
		_poly([[105, 56], [88, 42], [72, 48], [71, 66], [85, 93], [76, 115], [95, 101], [111, 73]], hair.darkened(0.16))
		_poly([[174, 54], [192, 42], [208, 47], [211, 67], [195, 93], [206, 113], [185, 101], [171, 74]], hair.darkened(0.16))
		draw_line(Vector2(97, 52), Vector2(91, 59), accent.lightened(0.4), 5, true)
		draw_line(Vector2(182, 53), Vector2(190, 60), accent.lightened(0.4), 5, true)
	else:
		_poly([[99, 88], [97, 52], [109, 33], [143, 28], [169, 40], [183, 66], [175, 93], [163, 81], [115, 78]], hair.darkened(0.28))


func _draw_front_hair(kind: String, hair: Color, accent: Color) -> void:
	match kind:
		"spikes":
			_poly([[101, 73], [99, 44], [109, 38], [106, 25], [120, 36], [127, 21], [135, 33], [145, 16], [155, 36], [172, 28], [169, 46], [181, 48], [169, 64], [157, 54], [150, 69], [140, 52], [132, 68], [121, 56], [111, 75]], hair)
			_poly([[135, 33], [145, 16], [155, 36], [147, 53]], accent.darkened(0.04), false)
		"crew":
			_poly([[100, 66], [102, 47], [116, 35], [148, 35], [169, 47], [177, 66], [165, 68], [160, 56], [112, 56], [109, 67]], hair)
			draw_line(Vector2(112, 43), Vector2(160, 44), hair.lightened(0.3), 3, true)
		"bob":
			_poly([[94, 91], [93, 61], [104, 41], [126, 29], [151, 30], [174, 48], [181, 81], [169, 103], [166, 66], [155, 56], [147, 74], [138, 56], [128, 76], [117, 57], [107, 78], [105, 103]], hair)
			draw_line(Vector2(104, 47), Vector2(98, 76), hair.lightened(0.4), 3, true)
		"swept":
			_poly([[100, 70], [93, 48], [110, 42], [115, 27], [134, 34], [151, 17], [154, 32], [177, 24], [171, 42], [190, 46], [170, 62], [148, 53], [138, 69], [132, 53], [115, 68]], hair)
			_poly([[111, 42], [150, 29], [160, 33], [129, 55]], hair.lightened(0.23), false)
		"pony":
			_poly([[100, 80], [96, 56], [108, 35], [133, 28], [157, 33], [176, 50], [173, 71], [159, 52], [137, 45], [122, 68], [111, 59], [108, 92]], hair)
			_poly([[136, 30], [157, 33], [170, 48], [138, 43]], accent.darkened(0.4), false)
		"undercut":
			_poly([[101, 62], [98, 43], [112, 30], [133, 23], [158, 30], [178, 49], [169, 67], [155, 47], [139, 61], [124, 51], [115, 68]], hair)
			_poly([[106, 39], [134, 28], [151, 34], [114, 52]], hair.lightened(0.2), false)
		"twins":
			_poly([[103, 80], [96, 56], [105, 37], [125, 28], [147, 27], [168, 38], [179, 57], [170, 83], [160, 57], [150, 69], [140, 46], [132, 68], [122, 54], [109, 77]], hair)
			_poly([[119, 34], [136, 29], [140, 46], [127, 48]], accent.lightened(0.16), false)
		"veil":
			_poly([[98, 78], [94, 53], [103, 34], [126, 23], [151, 25], [176, 44], [180, 79], [161, 96], [142, 73], [154, 51], [139, 52], [119, 65], [107, 88]], hair)
			_poly([[127, 28], [151, 29], [173, 45], [160, 76], [144, 67], [152, 49]], hair.darkened(0.12), false)
		"electric":
			_poly([[102, 79], [90, 48], [112, 45], [105, 22], [127, 34], [141, 10], [148, 34], [175, 17], [170, 44], [188, 51], [171, 72], [155, 57], [147, 73], [139, 52], [126, 70], [116, 57]], hair)
			_poly([[102, 63], [122, 53], [151, 52], [173, 60], [170, 66], [149, 58], [124, 59], [106, 69]], accent.darkened(0.55))
		"slick":
			_poly([[100, 71], [98, 46], [111, 30], [134, 23], [157, 30], [179, 47], [172, 72], [158, 47], [139, 43], [119, 51], [110, 74]], hair)
			for i in range(3):
				draw_polyline(PackedVector2Array([Vector2(108 + i * 8, 44), Vector2(131 + i * 8, 31), Vector2(151 + i * 5, 37)]), hair.lightened(0.24), 2, true)
		"crown":
			_poly([[100, 87], [94, 54], [108, 34], [131, 27], [154, 31], [174, 49], [172, 87], [160, 66], [149, 48], [141, 69], [129, 53], [115, 68], [111, 89]], hair)
			_poly([[107, 50], [116, 39], [122, 46], [136, 32], [145, 45], [158, 35], [168, 52], [159, 57], [120, 54]], accent.lightened(0.23))
		"ascend":
			_poly([[99, 74], [97, 51], [110, 43], [106, 23], [123, 31], [130, 15], [142, 29], [156, 11], [158, 33], [177, 28], [171, 47], [183, 53], [172, 74], [156, 56], [149, 70], [140, 46], [127, 64], [117, 55], [109, 80]], hair)
			_poly([[139, 29], [156, 11], [158, 33], [149, 52]], PAPER, false)
			_poly([[103, 64], [119, 58], [120, 64], [108, 72]], accent.darkened(0.05), false)
