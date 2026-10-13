extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1152, 648)
	var battle: Node2D = load("res://scenes/battle.tscn").instantiate()
	root.add_child(battle)
	await process_frame
	var modes: HBoxContainer = battle.get_node_or_null("CanvasLayer/PointerButtons")
	var zoom: HBoxContainer = battle.get_node_or_null("CanvasLayer/ZoomButtons")
	var dock: Control = battle.get_node("CanvasLayer/BottomDock")
	var tray: Control = battle.get_node("CanvasLayer/OrdersPanel")
	if modes == null or zoom == null:
		_fail("Touchpad action or zoom buttons are missing.")
		return
	if modes.get_node_or_null("Pan") != null:
		_fail("Panning should work by dragging without selecting a Pan mode.")
		return
	battle.get_node("CanvasLayer/OrdersToggle").emit_signal("pressed")
	if not tray.visible or not tray.get_global_rect().encloses(modes.get_global_rect()) or not dock.get_global_rect().encloses(zoom.get_global_rect()):
		_fail("Touchpad controls do not fit inside the Orders tray and dock.")
		return
	var blue: BattleSquad = battle.get("player_squads")[0]
	var red: BattleSquad = battle.get("enemy_squads")[0]
	battle.call("_select_at", blue.units[0].global_position)
	var move_button: Button = modes.get_node("Move")
	var target_button: Button = modes.get_node("Target")
	if move_button.disabled or target_button.disabled:
		_fail("Touchpad action buttons should enable after selecting a squad.")
		return
	move_button.emit_signal("pressed")
	if battle.get("pointer_mode") != 1:
		_fail("Move button did not activate left-click move mode.")
		return
	var destination := Vector2(720, 520)
	battle.call("_handle_primary_click", destination)
	if not blue.units[0].manual_move or battle.get("pointer_mode") != 0 or blue.target_squad != null:
		_fail("Left-click move did not order the selected squad and reset the mode.")
		return
	target_button.emit_signal("pressed")
	battle.call("_handle_primary_click", Vector2(800, 800))
	if battle.get("pointer_mode") != 2:
		_fail("Invalid target click should keep Target mode for retry.")
		return
	battle.call("_handle_primary_click", red.units[0].global_position)
	if blue.target_squad != red or battle.get("pointer_mode") != 0:
		_fail("Left-click target did not focus the enemy squad.")
		return
	battle.get_node("CanvasLayer/CommandButtons/FocusTarget").emit_signal("pressed")
	if battle.get("pointer_mode") != 2 or not battle.get_node("CanvasLayer/Status").text.contains("Left-click"):
		_fail("Focus Target did not provide a touchpad-friendly left-click prompt.")
		return
	modes.get_node("Select").emit_signal("pressed")
	if battle.get("pointer_mode") != 0:
		_fail("Select button did not cancel targeting.")
		return
	var camera: Camera2D = battle.get_node("Camera2D")
	var first_zoom := camera.zoom.x
	zoom.get_node("ZoomIn").emit_signal("pressed")
	if camera.zoom.x <= first_zoom:
		_fail("Zoom In button did not adjust the camera.")
		return
	zoom.get_node("ZoomOut").emit_signal("pressed")
	if not is_equal_approx(camera.zoom.x, first_zoom):
		_fail("Zoom Out button did not restore the camera.")
		return
	battle.get_node("CanvasLayer/OrdersToggle").emit_signal("pressed")
	blue.set_target(red, BattleSquad.Command.CHARGE)
	var unit_screen: Vector2 = blue.units[0].get_global_transform_with_canvas().origin
	var move_screen := unit_screen + Vector2(90, 38)
	var camera_before_move := camera.position
	var move_press := InputEventMouseButton.new()
	move_press.button_index = MOUSE_BUTTON_LEFT
	move_press.pressed = true
	move_press.position = unit_screen
	battle._input(move_press)
	var move_drag := InputEventMouseMotion.new()
	move_drag.relative = move_screen - unit_screen
	move_drag.position = move_screen
	move_drag.button_mask = MOUSE_BUTTON_MASK_LEFT
	battle._input(move_drag)
	if not battle.get("drag_moved") or battle.get("drag_action") != 1:
		_fail("Holding a selected squad did not start a move drag.")
		return
	move_press.pressed = false
	move_press.position = move_screen
	battle._input(move_press)
	var expected_move: Vector2 = battle.call("_screen_to_world", move_screen)
	if camera.position != camera_before_move or blue.ordered_center.distance_to(expected_move) > 2.0 or blue.target_squad != null or blue.command != BattleSquad.Command.ADVANCE:
		_fail("Selected-squad drag panned the camera or failed to issue Move.")
		return
	var general: BattleUnit = battle.get("player_general")
	battle.call("_select_at", general.global_position)
	var general_screen: Vector2 = general.get_global_transform_with_canvas().origin
	var general_goal := general_screen + Vector2(-70, 45)
	move_press.pressed = true
	move_press.position = general_screen
	battle._input(move_press)
	move_drag.relative = general_goal - general_screen
	move_drag.position = general_goal
	battle._input(move_drag)
	move_press.pressed = false
	move_press.position = general_goal
	battle._input(move_press)
	if not general.manual_move or general.destination.distance_to(battle.call("_screen_to_world", general_goal)) > 2.0:
		_fail("Selected General could not be repositioned by drag.")
		return
	var before_pan := camera.position
	var mouse_down := InputEventMouseButton.new()
	mouse_down.button_index = MOUSE_BUTTON_LEFT
	mouse_down.pressed = true
	mouse_down.position = Vector2(610, 300)
	battle._input(mouse_down)
	var mouse_drag := InputEventMouseMotion.new()
	mouse_drag.relative = Vector2(64, 0)
	mouse_drag.position = Vector2(674, 300)
	mouse_drag.button_mask = MOUSE_BUTTON_MASK_LEFT
	battle._input(mouse_drag)
	if camera.position.x >= before_pan.x:
		_fail("Left-button drag did not pan the camera automatically.")
		return
	mouse_down.pressed = false
	mouse_down.position = Vector2(674, 300)
	battle._input(mouse_down)
	camera.pan_by_screen_delta(Vector2(10000, 0))
	var half_view: float = battle.get_viewport_rect().size.x / (2.0 * camera.zoom.x)
	if camera.position.x < half_view - 1.0:
		_fail("Camera pan exposed the empty area left of the battlefield.")
		return
	camera.pan_by_screen_delta(Vector2(-10000, 0))
	if camera.position.x > 1600.0 - half_view + 1.0:
		_fail("Camera pan exposed the empty area right of the battlefield.")
		return
	print("Touchpad controls smoke passed: click actions, selected-squad drag move, empty-ground pan, and zoom.")
	quit()


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
