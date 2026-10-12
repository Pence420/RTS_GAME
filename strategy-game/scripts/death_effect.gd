extends Node2D

const DURATION := 0.55

var team := 0
var remaining := DURATION


func _process(delta: float) -> void:
	remaining -= delta
	if remaining <= 0.0:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var progress := 1.0 - remaining / DURATION
	var alpha := remaining / DURATION
	var dust := Color(0.77, 0.71, 0.55, alpha * 0.48)
	draw_set_transform(Vector2(0, 8), 0.0, Vector2(1.4 + progress * 0.7, 0.45 + progress * 0.2))
	draw_circle(Vector2.ZERO, 10.0, dust)
	draw_set_transform(Vector2.ZERO)
	draw_circle(Vector2(-9 - progress * 11.0, -5 - progress * 5.0), 3.0 + progress * 3.0, dust)
	draw_circle(Vector2(8 + progress * 9.0, -9 - progress * 3.0), 3.0 + progress * 2.0, dust)
	var cloth := Color("4d8fb9") if team == 0 else Color("bf6b59")
	cloth.a = alpha * 0.75
	draw_colored_polygon(PackedVector2Array([
		Vector2(-3, 4), Vector2(6 + progress * 6.0, 4),
		Vector2(8 + progress * 5.0, 9), Vector2(-4, 9)
	]), cloth)
