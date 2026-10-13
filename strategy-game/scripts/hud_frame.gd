extends Control

@export_enum("Header", "Dock", "Tray") var variant := 0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	resized.connect(queue_redraw)


func _draw() -> void:
	var w := size.x
	var h := size.y
	var outline := PackedVector2Array()
	if variant == 0:
		outline = PackedVector2Array([Vector2(0, h / 2), Vector2(18, 4), Vector2(w - 18, 4), Vector2(w, h / 2), Vector2(w - 18, h - 4), Vector2(18, h - 4)])
	elif variant == 1:
		outline = PackedVector2Array([Vector2(0, 19), Vector2(14, 5), Vector2(w / 2 - 65, 5), Vector2(w / 2 - 51, 15), Vector2(w / 2 - 20, 15), Vector2(w / 2, 0), Vector2(w / 2 + 20, 15), Vector2(w / 2 + 51, 15), Vector2(w / 2 + 65, 5), Vector2(w - 14, 5), Vector2(w, 19), Vector2(w, h - 17), Vector2(w - 14, h - 4), Vector2(14, h - 4), Vector2(0, h - 17)])
	else:
		outline = PackedVector2Array([Vector2(0, 12), Vector2(12, 0), Vector2(w - 12, 0), Vector2(w, 12), Vector2(w, h - 12), Vector2(w - 12, h), Vector2(12, h), Vector2(0, h - 12)])
	draw_set_transform(Vector2(0, 3))
	draw_colored_polygon(outline, Color(0.08, 0.09, 0.07, 0.24))
	draw_set_transform(Vector2.ZERO)
	draw_colored_polygon(outline, Color("343b2c", 0.96))
	var closed := outline.duplicate()
	closed.append(outline[0])
	draw_polyline(closed, Color("19231e"), 3.0, true)
	draw_polyline(closed, Color("97977a", 0.75), 1.0, true)
	if variant == 0:
		draw_circle(Vector2(w / 2, h / 2), 29.0, Color("343b2c"), true, -1, true)
		draw_arc(Vector2(w / 2, h / 2), 28.0, 0, TAU, 64, Color("191f19"), 3.0, true)
		draw_arc(Vector2(w / 2, h / 2), 25.0, 0, TAU, 64, Color("97977a", 0.8), 1.0, true)
	elif variant == 1:
		var center := Vector2(w / 2, 17)
		var diamond := PackedVector2Array([center + Vector2(0, -8), center + Vector2(8, 0), center + Vector2(0, 8), center + Vector2(-8, 0), center + Vector2(0, -8)])
		draw_polyline(diamond, Color("b1ad87"), 1.0, true)
