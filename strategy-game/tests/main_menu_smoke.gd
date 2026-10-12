extends SceneTree

const SETTINGS = preload("res://scripts/game_settings.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1152, 648)
	var project_main: String = ProjectSettings.get_setting("application/run/main_scene")
	if project_main != "res://scenes/main_menu.tscn":
		_fail("Game does not open at the main menu.")
		return
	var menu: Control = load(project_main).instantiate()
	root.add_child(menu)
	current_scene = menu
	await process_frame
	if not menu.get_node("MainButtons").visible or menu.get_node("OptionsPanel").visible:
		_fail("Main menu buttons are not visible at launch.")
		return
	root.size = Vector2i(1440, 900)
	await process_frame
	var card: Control = menu.get_node("MenuCard")
	if absf(card.get_global_rect().get_center().y - menu.size.y / 2.0) > 2.0:
		_fail("Main menu card is not centered in a larger window.")
		return
	root.size = Vector2i(1152, 648)
	await process_frame
	menu.get_node("MainButtons/OptionsButton").emit_signal("pressed")
	if not menu.get_node("OptionsPanel").visible or menu.get_node("MainButtons").visible:
		_fail("Options did not open.")
		return
	var config_path := "res://tests/.settings_smoke.cfg"
	var save_error: int = SETTINGS.save_values({"volume": 35.0, "fullscreen": true}, config_path)
	if save_error != OK:
		_fail("Settings could not be saved for the persistence check.")
		return
	var saved: Dictionary = SETTINGS.load_values(config_path)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(config_path))
	if saved.volume != 35.0 or not saved.fullscreen:
		_fail("Saved options were not loaded correctly.")
		return
	menu.get_node("OptionsPanel/BackButton").emit_signal("pressed")
	if menu.get_node("OptionsPanel").visible or not menu.get_node("MainButtons").visible:
		_fail("Back did not return to the main menu.")
		return
	menu.call("_start_game")
	await process_frame
	if current_scene == null or current_scene.name != "Battle":
		_fail("Start Game did not open the battlefield.")
		return
	current_scene.get_node("CanvasLayer/MenuButton").emit_signal("pressed")
	if not paused:
		_fail("Battle menu did not pause before returning to title.")
		return
	current_scene.get_node("CanvasLayer/GameMenu/Center/Card/MainMenuButton").emit_signal("pressed")
	await process_frame
	if paused or current_scene == null or current_scene.name != "MainMenu":
		_fail("Main Menu did not return from battle cleanly.")
		return
	print("Main menu smoke passed: launch, options, persistence, Start Game, and return.")
	quit()


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
