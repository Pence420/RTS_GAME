extends Control

const BATTLE_SCENE := "res://scenes/battle.tscn"
const SETTINGS = preload("res://scripts/game_settings.gd")

var settings: Dictionary

@onready var main_buttons: VBoxContainer = $MainButtons
@onready var options_panel: Panel = $OptionsPanel
@onready var volume_slider: HSlider = $OptionsPanel/VolumeSlider
@onready var volume_value: Label = $OptionsPanel/VolumeValue
@onready var fullscreen_check: CheckButton = $OptionsPanel/FullscreenCheck


func _ready() -> void:
	get_window().min_size = Vector2i(1152, 648)
	resized.connect(queue_redraw)
	settings = SETTINGS.load_values()
	SETTINGS.apply_values(settings)
	volume_slider.set_value_no_signal(settings.volume)
	fullscreen_check.set_pressed_no_signal(settings.fullscreen)
	_update_volume_label()
	$MainButtons/StartButton.pressed.connect(_start_game)
	$MainButtons/OptionsButton.pressed.connect(_open_options)
	$MainButtons/QuitButton.pressed.connect(_quit_game)
	$OptionsPanel/BackButton.pressed.connect(_close_options)
	volume_slider.value_changed.connect(_on_volume_changed)
	fullscreen_check.toggled.connect(_on_fullscreen_toggled)
	queue_redraw()


func _start_game() -> void:
	get_tree().change_scene_to_file(BATTLE_SCENE)


func _open_options() -> void:
	main_buttons.hide()
	options_panel.show()
	$OptionsPanel/BackButton.grab_focus()


func _close_options() -> void:
	options_panel.hide()
	main_buttons.show()
	$MainButtons/OptionsButton.grab_focus()


func _quit_game() -> void:
	get_tree().quit()


func _on_volume_changed(value: float) -> void:
	settings.volume = value
	SETTINGS.apply_values(settings)
	_save_settings()
	_update_volume_label()


func _on_fullscreen_toggled(enabled: bool) -> void:
	settings.fullscreen = enabled
	SETTINGS.apply_values(settings)
	_save_settings()


func _save_settings() -> void:
	var error: int = SETTINGS.save_values(settings)
	if error != OK:
		push_warning("Unable to save game settings: %s" % error_string(error))


func _update_volume_label() -> void:
	volume_value.text = "%d%%" % roundi(volume_slider.value)


func _unhandled_input(event: InputEvent) -> void:
	if options_panel.visible and event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_close_options()
		get_viewport().set_input_as_handled()


func _draw() -> void:
	var size := get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, size), Color("101c20"))
	# A simple map behind the menu makes this screen feel connected to the battle.
	for row in range(7):
		for column in range(14):
			var cell := Rect2(column * 88.0, row * 96.0, 88.0, 96.0)
			var tint := Color("283b35") if (column + row) % 3 == 0 else Color("30443a")
			draw_rect(cell, tint)
	for index in range(15):
		var origin := Vector2(40.0 + index * 83.0, 105.0 + float((index * 139) % 430))
		draw_rect(Rect2(origin, Vector2(50, 17)), Color("566a49", 0.28))
	draw_line(Vector2(0, size.y * 0.72), Vector2(size.x, size.y * 0.26), Color("c5ad73", 0.23), 74.0)
	draw_line(Vector2(0, size.y * 0.72), Vector2(size.x, size.y * 0.26), Color("f4dfac", 0.17), 2.0)
	for row in range(3):
		for column in range(7):
			var blue := Vector2(80 + column * 24, 380 + row * 27)
			var red := Vector2(size.x - 440 + column * 24, 180 + row * 27)
			draw_rect(Rect2(blue, Vector2(13, 17)), Color("4a8abb"))
			draw_rect(Rect2(red, Vector2(13, 17)), Color("c46b5b"))
	draw_rect(Rect2(0, 0, size.x, size.y), Color("071116", 0.47))
