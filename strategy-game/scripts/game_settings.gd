class_name GameSettings
extends RefCounted

const SETTINGS_PATH := "user://battlefield_settings.cfg"


static func load_values(path: String = SETTINGS_PATH) -> Dictionary:
	var config := ConfigFile.new()
	if config.load(path) != OK:
		return {"volume": 80.0, "fullscreen": false}
	return {
		"volume": clampf(float(config.get_value("audio", "master_volume", 80.0)), 0.0, 100.0),
		"fullscreen": bool(config.get_value("display", "fullscreen", false))
	}


static func apply_values(values: Dictionary) -> void:
	var volume := clampf(float(values.get("volume", 80.0)), 0.0, 100.0)
	AudioServer.set_bus_volume_linear(AudioServer.get_bus_index("Master"), volume / 100.0)
	var desired_mode := DisplayServer.WINDOW_MODE_FULLSCREEN if bool(values.get("fullscreen", false)) else DisplayServer.WINDOW_MODE_WINDOWED
	if DisplayServer.window_get_mode() != desired_mode:
		DisplayServer.window_set_mode(desired_mode)


static func save_values(values: Dictionary, path: String = SETTINGS_PATH) -> int:
	var config := ConfigFile.new()
	config.set_value("audio", "master_volume", clampf(float(values.get("volume", 80.0)), 0.0, 100.0))
	config.set_value("display", "fullscreen", bool(values.get("fullscreen", false)))
	return config.save(path)
