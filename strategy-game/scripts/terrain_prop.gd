extends Node2D

var prop_kind := 0
var prop_texture: Texture2D
var pixel_art := false
var animation_frames: Array[Texture2D] = []
var animation_clock := 0.0
var sprite: Sprite2D
var display_height := 120.0
var shadow_width := 20.0
var wind_clock := 0.0
var wind_phase := 0.0
var pivot: Node2D


func _ready() -> void:
	add_to_group("scenery_props")
	z_index = 1
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST if pixel_art else CanvasItem.TEXTURE_FILTER_LINEAR
	pivot = Node2D.new()
	pivot.name = "WindPivot"
	add_child(pivot)
	sprite = Sprite2D.new()
	sprite.name = "Sprite2D"
	sprite.texture = prop_texture
	sprite.scale = Vector2.ONE * display_height / prop_texture.get_height()
	sprite.position.y = -display_height / 2.0
	pivot.add_child(sprite)
	shadow_width = prop_texture.get_width() * sprite.scale.x * 0.36
	wind_phase = fmod(position.x * 0.017 + position.y * 0.013, TAU)
	# Pixel silhouettes use authored tree frames rather than subpixel rotation.
	set_process(not animation_frames.is_empty() or (not pixel_art and (prop_kind == 0 or prop_kind == 1 or prop_kind == 2)))
	queue_redraw()


func _process(delta: float) -> void:
	if pixel_art:
		if animation_frames.is_empty():
			return
		animation_clock += delta
		# Authored foliage frames keep trunks rooted and pixel edges sharp.
		sprite.texture = animation_frames[int(animation_clock * 6.0 + wind_phase) % animation_frames.size()]
		return
	wind_clock += delta
	# Rotate from the root contact point rather than sliding the whole prop.
	pivot.rotation = sin(wind_clock * 0.9 + wind_phase) * 0.006


func _draw() -> void:
	if prop_kind == 4:
		return
	draw_set_transform(Vector2(5, 3), 0.0, Vector2(1.0, 0.3))
	draw_circle(Vector2.ZERO, shadow_width, Color(0.18, 0.25, 0.15, 0.09), true, -1, true)
	draw_circle(Vector2.ZERO, shadow_width * 0.7, Color(0.18, 0.24, 0.14, 0.11), true, -1, true)
	draw_set_transform(Vector2.ZERO)
