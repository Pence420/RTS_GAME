extends Control

const BATTLE_SCENE := "res://scenes/battle.tscn"
const MENU_TERRAIN: Texture2D = preload("res://assets/terrain/battlefield_smooth.png")
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
	draw_texture_rect(MENU_TERRAIN, Rect2(Vector2.ZERO, size), false)
	draw_rect(Rect2(Vector2.ZERO, size), Color("101c1b", 0.62))
