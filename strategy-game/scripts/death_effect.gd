extends Node2D

const DURATION := 3.5
const SPLASH_DURATION := 0.38

var team := 0
var remaining := DURATION
var body_scale := Vector2(3, 3)
var body_offset := Vector2(0, -15)
var body_frames: SpriteFrames
var body_material: Material
var body_flip_h := false
var body: AnimatedSprite2D
var stain := PackedVector2Array()
var droplets: Array[Vector2] = []


func _ready() -> void:
	var random := RandomNumberGenerator.new()
	random.randomize()
	for index in range(15):
		var angle := TAU * index / 15.0
		var radius := random.randf_range(7.0, 14.0)
		stain.append(Vector2(cos(angle) * radius, 8.0 + sin(angle) * radius * 0.42))
	for index in range(7):
		var angle := random.randf_range(-PI, 0.0)
		droplets.append(Vector2(cos(angle) * random.randf_range(16.0, 35.0), sin(angle) * random.randf_range(22.0, 38.0)))
	if body_frames != null:
		body = AnimatedSprite2D.new()
		body.sprite_frames = body_frames
		body.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		body.material = body_material
		body.scale = body_scale
		body.offset = body_offset
		body.flip_h = body_flip_h
		body.position = Vector2(0, 8)
		add_child(body)
		body.play(&"death")
	queue_redraw()


func _process(delta: float) -> void:
	remaining -= delta
	if remaining <= 0.0:
		queue_free()
		return
	var elapsed := DURATION - remaining
	if body != null:
		var death_duration := body_frames.get_frame_count(&"death") / body_frames.get_animation_speed(&"death")
		body.modulate = Color(0.86, 0.82, 0.77, clampf(1.0 - maxf(0.0, elapsed - death_duration - 0.3) / 0.6, 0.0, 1.0))
	queue_redraw()


func _draw() -> void:
	if stain.is_empty():
		return
	var elapsed := DURATION - remaining
	var fade := clampf(remaining / 1.2, 0.0, 1.0)
	var bloom := clampf(elapsed / 0.12, 0.0, 1.0)
	var blood := Color("782e2d", fade * 0.82)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE * (0.55 + bloom * 0.45))
	draw_colored_polygon(stain, blood)
	draw_set_transform(Vector2.ZERO)
	for index in range(droplets.size()):
		var velocity := droplets[index]
		var splash := minf(elapsed / SPLASH_DURATION, 1.0)
		var spot := Vector2(velocity.x * splash, 8.0 + velocity.y * splash + 32.0 * splash * splash)
		var radius := 1.2 + float(index % 3) * 0.5
		var drop_color := Color("a54b3e", fade * (0.9 if splash < 1.0 else 0.65))
		draw_set_transform(spot, velocity.angle(), Vector2(1.5 if splash < 1.0 else 1.0, 0.65))
		draw_circle(Vector2.ZERO, radius, drop_color, true, -1, true)
		draw_set_transform(Vector2.ZERO)
