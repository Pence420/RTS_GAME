extends Camera2D

const PAN_SPEED := 550.0
const MIN_ZOOM := 0.6
const MAX_ZOOM := 2.0
const FIELD_SIZE := Vector2(1600, 900)
const HUD_TOP := 60.0
const HUD_BOTTOM := 94.0

var dragging := false


func _process(delta: float) -> void:
	var direction := Vector2(
		int(Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT)) - int(Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT)),
		int(Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN)) - int(Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP))
	).normalized()
	position += direction * PAN_SPEED * delta / zoom.x
	_clamp_position()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_MIDDLE:
			dragging = event.pressed
		elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom_in()
		elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom_out()
	elif event is InputEventMouseMotion and dragging:
		pan_by_screen_delta(event.relative)


func pan_by_screen_delta(relative: Vector2) -> void:
	position -= relative / zoom.x
	_clamp_position()


func zoom_in() -> void:
	_set_zoom(zoom.x * 1.15)


func zoom_out() -> void:
	_set_zoom(zoom.x / 1.15)


func _set_zoom(value: float) -> void:
	var fit_width := get_viewport_rect().size.x / FIELD_SIZE.x
	var level := clampf(value, maxf(MIN_ZOOM, fit_width), MAX_ZOOM)
	zoom = Vector2.ONE * level
	_clamp_position()


func _clamp_position() -> void:
	var viewport_size := get_viewport_rect().size
	var fit_width := viewport_size.x / FIELD_SIZE.x
	if zoom.x < fit_width:
		zoom = Vector2.ONE * fit_width
	var half_width := viewport_size.x / (2.0 * zoom.x)
	position.x = FIELD_SIZE.x / 2.0 if half_width >= FIELD_SIZE.x / 2.0 else clampf(position.x, half_width, FIELD_SIZE.x - half_width)
	var screen_center_y := viewport_size.y / 2.0
	var min_y := (screen_center_y - HUD_TOP) / zoom.y
	var max_y := FIELD_SIZE.y - (screen_center_y - HUD_BOTTOM) / zoom.y
	position.y = FIELD_SIZE.y / 2.0 if min_y > max_y else clampf(position.y, min_y, max_y)
