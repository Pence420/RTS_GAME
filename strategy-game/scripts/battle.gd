extends Node2D

const SQUAD_SCENE: PackedScene = preload("res://scenes/squad.tscn")
const UNIT_SCENE: PackedScene = preload("res://scenes/unit.tscn")
const FIELD_SIZE := Vector2(1600, 900)
const TERRAIN_TEXTURE: Texture2D = preload("res://assets/terrain/battlefield_smooth.png")
enum PointerMode { SELECT, MOVE, TARGET }
enum DragAction { PAN, MOVE }
const DRAG_THRESHOLD := 8.0

var selected_squad: BattleSquad
var selected_general: BattleUnit
var player_general: BattleUnit
var enemy_general: BattleUnit
var player_squads: Array[BattleSquad] = []
var enemy_squads: Array[BattleSquad] = []
var pending_focus_target := false
var pointer_mode := PointerMode.SELECT
var drag_active := false
var drag_moved := false
var drag_start := Vector2.ZERO
var drag_action := DragAction.PAN
var drag_destination := Vector2.ZERO
var battle_started := false
var battle_result := ""

@onready var status_label: Label = $CanvasLayer/Status
@onready var phase_label: Label = $CanvasLayer/Phase
@onready var blue_count_label: Label = $CanvasLayer/BlueCount
@onready var red_count_label: Label = $CanvasLayer/RedCount
@onready var start_button: Button = $CanvasLayer/StartBattle
@onready var menu_button: Button = $CanvasLayer/MenuButton
@onready var game_menu: Control = $CanvasLayer/GameMenu
@onready var battle_camera: Camera2D = $Camera2D
@onready var enemy_ai: EnemyArmyAI = $EnemyAI
@onready var result_overlay: Control = $CanvasLayer/ResultOverlay
@onready var result_title: Label = $CanvasLayer/ResultOverlay/Center/Content/ResultTitle
@onready var result_detail: Label = $CanvasLayer/ResultOverlay/Center/Content/ResultDetail
@onready var restart_button: Button = $CanvasLayer/ResultOverlay/Center/Content/RestartButton
@onready var formation_buttons: Array[Button] = [
	$CanvasLayer/FormationButtons/Line,
	$CanvasLayer/FormationButtons/Column,
	$CanvasLayer/FormationButtons/ShieldWall,
	$CanvasLayer/FormationButtons/Wedge
]
@onready var command_buttons: Array[Button] = [
	$CanvasLayer/CommandButtons/Hold,
	$CanvasLayer/CommandButtons/Advance,
	$CanvasLayer/CommandButtons/Charge,
	$CanvasLayer/CommandButtons/Defend,
	$CanvasLayer/CommandButtons/FocusTarget
]
@onready var pointer_buttons: Array[Button] = [
	$CanvasLayer/PointerButtons/Select,
	$CanvasLayer/PointerButtons/Move,
	$CanvasLayer/PointerButtons/Target
]
@onready var zoom_in_button: Button = $CanvasLayer/ZoomButtons/ZoomIn
@onready var zoom_out_button: Button = $CanvasLayer/ZoomButtons/ZoomOut
@onready var bottom_dock: Control = $CanvasLayer/BottomDock


func _ready() -> void:
	get_window().min_size = Vector2i(1152, 648)
	for index in range(formation_buttons.size()):
		formation_buttons[index].pressed.connect(_on_formation_pressed.bind(index))
	for index in range(command_buttons.size()):
		command_buttons[index].pressed.connect(_on_command_pressed.bind(index))
	for index in range(pointer_buttons.size()):
		pointer_buttons[index].pressed.connect(_on_pointer_mode_pressed.bind(index))
	zoom_in_button.pressed.connect(Callable(battle_camera, "zoom_in"))
	zoom_out_button.pressed.connect(Callable(battle_camera, "zoom_out"))
	start_button.pressed.connect(_start_battle)
	menu_button.pressed.connect(_open_menu)
	game_menu.close_requested.connect(_close_menu)
	game_menu.restart_requested.connect(_restart_battle)
	game_menu.main_menu_requested.connect(_return_to_main_menu)
	game_menu.squad_selected.connect(_on_menu_squad_selected)
	game_menu.unit_type_changed.connect(_on_menu_unit_type_changed)
	restart_button.pressed.connect(_restart_battle)
	$CanvasLayer/ResultOverlay/Center/Content/MainMenuButton.pressed.connect(_return_to_main_menu)
	_spawn_squad(0, "Blue A", BattleUnit.UnitType.SWORDSMAN, Vector2(630, 380))
	_spawn_squad(0, "Blue B", BattleUnit.UnitType.SPEARMAN, Vector2(400, 600))
	_spawn_squad(0, "Blue C", BattleUnit.UnitType.AXEMAN, Vector2(570, 470))
	_spawn_squad(0, "Blue D", BattleUnit.UnitType.ARCHER, Vector2(300, 760))
	_spawn_squad(1, "Red A", BattleUnit.UnitType.SWORDSMAN, Vector2(970, 380))
	_spawn_squad(1, "Red B", BattleUnit.UnitType.SPEARMAN, Vector2(1200, 600))
	_spawn_squad(1, "Red C", BattleUnit.UnitType.AXEMAN, Vector2(1030, 470))
	_spawn_squad(1, "Red D", BattleUnit.UnitType.ARCHER, Vector2(1300, 760))
	player_general = _spawn_general(0, Vector2(460, 440))
	enemy_general = _spawn_general(1, Vector2(1140, 440))
	for squad in player_squads:
		squad.set_general(player_general)
	for squad in enemy_squads:
		squad.set_general(enemy_general)
	_select_at(player_squads[0].units[0].global_position)
	_update_status()
	_update_formation_buttons()
	_update_command_buttons()
	_update_pointer_buttons()
	queue_redraw()


func _open_menu() -> void:
	if result_overlay.visible:
		return
	drag_active = false
	drag_moved = false
	queue_redraw()
	game_menu.show_menu(player_squads, battle_started)
	get_tree().paused = true


func _close_menu() -> void:
	game_menu.hide()
	get_tree().paused = false


func _on_menu_unit_type_changed(index: int, unit_type: int) -> void:
	if battle_started or index < 0 or index >= player_squads.size():
		return
	player_squads[index].set_unit_type(unit_type)
	_update_status()


func _on_menu_squad_selected(index: int) -> void:
	if index < 0 or index >= player_squads.size():
		return
	var squad := player_squads[index]
	if selected_squad != null:
		selected_squad.set_selected(false)
	if selected_general != null:
		selected_general.set_selected(false)
	selected_general = null
	selected_squad = squad
	squad.set_selected(true)
	_set_pointer_mode(PointerMode.SELECT)
	_update_formation_buttons()
	_update_command_buttons()
	_close_menu()


func _start_battle() -> void:
	if battle_started:
		return
	battle_started = true
	for squad in player_squads:
		squad.begin_battle()
	for squad in enemy_squads:
		squad.begin_battle()
	if is_instance_valid(player_general):
		player_general.combat_enabled = true
	if is_instance_valid(enemy_general):
		enemy_general.combat_enabled = true
	enemy_ai.begin_battle(player_squads, enemy_squads, enemy_general)
	start_button.hide()
	_update_status()
	_evaluate_battle_result()


func _evaluate_battle_result() -> void:
	if not battle_started or not battle_result.is_empty():
		return
	var player_defeated := _army_defeated(player_squads)
	var enemy_defeated := _army_defeated(enemy_squads)
	if player_defeated and enemy_defeated:
		_finish_battle("DRAW")
	elif enemy_defeated:
		_finish_battle("VICTORY")
	elif player_defeated:
		_finish_battle("DEFEAT")


func _army_defeated(squads: Array[BattleSquad]) -> bool:
	for squad in squads:
		if not squad.routing:
			return false
	return true


func _finish_battle(result: String) -> void:
	battle_result = result
	enemy_ai.active = false
	result_title.text = result
	result_title.add_theme_color_override("font_color", Color("e9bb70") if result == "VICTORY" else Color("e17a70"))
	var blue_count := _soldier_count(player_squads)
	var red_count := _soldier_count(enemy_squads)
	result_detail.text = "Fighting squads — Blue: %d    Red: %d\nSoldiers on field — Blue: %d    Red: %d" % [
		_active_squad_count(player_squads), _active_squad_count(enemy_squads), blue_count, red_count
	]
	result_overlay.show()
	get_tree().paused = true


func _restart_battle() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func _return_to_main_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


func _soldier_count(squads: Array[BattleSquad]) -> int:
	var count := 0
	for squad in squads:
		count += squad.units.size()
	return count


func _active_squad_count(squads: Array[BattleSquad]) -> int:
	var count := 0
	for squad in squads:
		if not squad.routing:
			count += 1
	return count


func _spawn_squad(team: int, squad_id: String, unit_type: int, start_position: Vector2) -> void:
	var squad := SQUAD_SCENE.instantiate() as BattleSquad
	squad.team = team
	squad.squad_id = squad_id
	squad.unit_type = unit_type
	squad.position = start_position
	add_child(squad)
	squad.roster_changed.connect(_on_soldier_removed)
	squad.health_changed.connect(_on_squad_health_changed)
	squad.morale_changed.connect(_on_squad_morale_changed)
	squad.routed.connect(_on_squad_routed)
	if team == 0:
		player_squads.append(squad)
	else:
		enemy_squads.append(squad)


func _spawn_general(team: int, start_position: Vector2) -> BattleUnit:
	var general := UNIT_SCENE.instantiate() as BattleUnit
	general.team = team
	general.is_general = true
	general.max_hp = 70.0
	general.current_hp = 70.0
	general.damage = 10.0
	general.armor = 3.0
	general.position = start_position
	add_child(general)
	general.set_command(BattleUnit.Command.HOLD)
	general.died.connect(_on_general_died)
	return general


func _on_soldier_removed(squad: BattleSquad) -> void:
	if squad.units.is_empty():
		if selected_squad == squad:
			selected_squad = null
			pending_focus_target = false
			pointer_mode = PointerMode.SELECT
		if squad.team == 0:
			player_squads.erase(squad)
		else:
			enemy_squads.erase(squad)
		squad.queue_free()
		_clear_targets_for(squad)
	_update_status()
	_update_formation_buttons()
	_update_command_buttons()
	_update_pointer_buttons()
	_evaluate_battle_result()


func _on_squad_health_changed(_squad: BattleSquad) -> void:
	_update_status()


func _on_squad_morale_changed(_squad: BattleSquad) -> void:
	_update_status()


func _on_squad_routed(squad: BattleSquad) -> void:
	if selected_squad == squad:
		pending_focus_target = false
		pointer_mode = PointerMode.SELECT
	_clear_targets_for(squad)
	var opponents := enemy_squads if squad.team == 0 else player_squads
	for opponent in opponents:
		if not opponent.routing:
			opponent.apply_morale_change(8.0)
	_update_status()
	_update_command_buttons()
	_update_formation_buttons()
	_update_pointer_buttons()
	_evaluate_battle_result()


func _clear_targets_for(squad: BattleSquad) -> void:
	for ally in player_squads:
		if ally.target_squad == squad:
			ally.set_command(BattleSquad.Command.ADVANCE)
	for ally in enemy_squads:
		if ally.target_squad == squad:
			ally.set_command(BattleSquad.Command.ADVANCE)


func _on_general_died(general: BattleUnit) -> void:
	if selected_general == general:
		selected_general = null
		pointer_mode = PointerMode.SELECT
	var affected := player_squads if general.team == 0 else enemy_squads
	for squad in affected:
		squad.set_general(null)
		squad.apply_morale_change(-25.0)
	if general.team == 0:
		player_general = null
	else:
		enemy_general = null
	_update_status()
	_update_command_buttons()
	_update_formation_buttons()
	_update_pointer_buttons()


func _update_status() -> void:
	var blue_count := _soldier_count(player_squads)
	var red_count := _soldier_count(enemy_squads)
	phase_label.text = "BATTLE" if battle_started else "DEPLOYMENT"
	blue_count_label.text = "BLUE  %02d" % blue_count
	red_count_label.text = "RED  %02d" % red_count
	var detail := "Select a blue squad\nDrag empty ground to pan."
	if selected_general != null:
		detail = "GENERAL\nHP %d/%d\nAura  +10 morale  /  +5%% damage" % [roundi(selected_general.current_hp), roundi(selected_general.max_hp)]
		if pointer_mode == PointerMode.MOVE:
			detail += "\nLeft-click destination to move"
	elif selected_squad != null:
		var order_detail := "Hold + drag squad to move"
		if pointer_mode == PointerMode.MOVE:
			order_detail = "Left-click destination to move"
		elif pointer_mode == PointerMode.TARGET or pending_focus_target:
			order_detail = "Left-click a red squad to focus"
		elif selected_squad.target_squad != null:
			order_detail = "%s  →  %s" % [selected_squad.get_command_name(), selected_squad.target_squad.squad_id]
		detail = "%s  /  %s\n%d/10 soldiers    HP %d%%\nMorale %d  ·  %s\n%s" % [
			selected_squad.squad_id,
			selected_squad.get_unit_type_name(),
			selected_squad.units.size(),
			roundi(selected_squad.get_health_ratio() * 100.0),
			roundi(selected_squad.get_effective_morale()),
			selected_squad.get_morale_state(),
			order_detail
		]
	status_label.text = detail


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if game_menu.visible:
			_close_menu()
		elif not result_overlay.visible:
			_open_menu()
		return
	if game_menu.visible:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			drag_active = _is_gameplay_point(event.position)
			drag_moved = false
			drag_start = event.position
			if drag_active:
				drag_action = DragAction.MOVE if pointer_mode == PointerMode.SELECT and _is_selected_at(_screen_to_world(event.position)) else DragAction.PAN
				drag_destination = _screen_to_world(event.position)
		elif drag_active:
			if _is_gameplay_point(event.position):
				if drag_moved and drag_action == DragAction.MOVE:
					_issue_move(_screen_to_world(event.position))
				elif not drag_moved:
					_handle_primary_click(_screen_to_world(event.position))
			drag_active = false
			drag_moved = false
			queue_redraw()
	elif event is InputEventMouseMotion and drag_active:
		if not event.button_mask & MOUSE_BUTTON_MASK_LEFT:
			drag_active = false
			drag_moved = false
			queue_redraw()
			return
		if drag_moved or event.position.distance_to(drag_start) >= DRAG_THRESHOLD:
			drag_moved = true
			if drag_action == DragAction.MOVE:
				drag_destination = _screen_to_world(event.position)
				queue_redraw()
			else:
				battle_camera.call("pan_by_screen_delta", event.relative)


func _screen_to_world(point: Vector2) -> Vector2:
	return get_global_transform_with_canvas().affine_inverse() * point


func _is_selected_at(point: Vector2) -> bool:
	if selected_general != null and selected_general.is_alive():
		return selected_general.global_position.distance_to(point) <= BattleSquad.PICK_RADIUS + 8.0
	return selected_squad != null and not selected_squad.routing and selected_squad.distance_to_point(point) <= BattleSquad.PICK_RADIUS + 12.0


func _is_gameplay_point(point: Vector2) -> bool:
	return point.x >= 0.0 and point.x < get_viewport_rect().size.x and point.y >= 66.0 and point.y < bottom_dock.get_global_rect().position.y and not result_overlay.visible and not game_menu.visible


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT and (selected_squad != null or selected_general != null):
		_issue_right_click(get_global_mouse_position())


func _handle_primary_click(point: Vector2) -> void:
	match pointer_mode:
		PointerMode.SELECT:
			_select_at(point)
		PointerMode.MOVE:
			if _issue_move(point):
				_set_pointer_mode(PointerMode.SELECT)
		PointerMode.TARGET:
			if _issue_target(point, BattleSquad.Command.FOCUS_TARGET):
				_set_pointer_mode(PointerMode.SELECT)


func _issue_right_click(point: Vector2) -> void:
	if selected_general != null:
		_issue_move(point)
		_set_pointer_mode(PointerMode.SELECT)
		return
	if selected_squad == null:
		return
	var enemy := _enemy_squad_at(point)
	if enemy != null:
		var command := BattleSquad.Command.CHARGE if selected_squad.command == BattleSquad.Command.CHARGE and not pending_focus_target else BattleSquad.Command.FOCUS_TARGET
		_issue_target(point, command)
		_set_pointer_mode(PointerMode.SELECT)
	elif not pending_focus_target:
		_issue_move(point)
		_set_pointer_mode(PointerMode.SELECT)


func _issue_move(point: Vector2) -> bool:
	if selected_general != null:
		selected_general.move_to(Vector2(
			clampf(point.x, 20.0, FIELD_SIZE.x - 20.0),
			clampf(point.y, 20.0, FIELD_SIZE.y - 20.0)
		))
		return true
	if selected_squad == null or selected_squad.routing:
		return false
	if selected_squad.target_squad != null or selected_squad.command == BattleSquad.Command.HOLD or selected_squad.command == BattleSquad.Command.FOCUS_TARGET or selected_squad.command == BattleSquad.Command.CHARGE:
		selected_squad.set_command(BattleSquad.Command.ADVANCE)
	selected_squad.move_to(Vector2(
		clampf(point.x, 160.0, FIELD_SIZE.x - 160.0),
		clampf(point.y, 170.0, FIELD_SIZE.y - 170.0)
	))
	_update_status()
	_update_command_buttons()
	return true


func _issue_target(point: Vector2, command: int) -> bool:
	if selected_squad == null or selected_squad.routing:
		return false
	var enemy := _enemy_squad_at(point)
	if enemy == null:
		return false
	selected_squad.set_target(enemy, command)
	pending_focus_target = false
	_update_status()
	_update_command_buttons()
	return true


func _enemy_squad_at(point: Vector2) -> BattleSquad:
	var nearest := BattleSquad.PICK_RADIUS
	var closest: BattleSquad
	for squad in enemy_squads:
		if squad.routing:
			continue
		var distance := squad.distance_to_point(point)
		if distance < nearest:
			nearest = distance
			closest = squad
	return closest


func _nearest_enemy_squad(point: Vector2) -> BattleSquad:
	var nearest := INF
	var closest: BattleSquad
	for squad in enemy_squads:
		if squad.routing:
			continue
		var distance := squad.get_center().distance_to(point)
		if distance < nearest:
			nearest = distance
			closest = squad
	return closest


func _on_command_pressed(index: int) -> void:
	if selected_squad == null or selected_squad.routing:
		return
	if index == BattleSquad.Command.FOCUS_TARGET:
		_set_pointer_mode(PointerMode.TARGET)
		return
	elif index == BattleSquad.Command.CHARGE:
		var enemy := _nearest_enemy_squad(selected_squad.get_center())
		if enemy != null:
			selected_squad.set_target(enemy, BattleSquad.Command.CHARGE)
		else:
			selected_squad.set_command(BattleSquad.Command.CHARGE)
	else:
		selected_squad.set_command(index)
	_set_pointer_mode(PointerMode.SELECT)


func _on_pointer_mode_pressed(index: int) -> void:
	if index == PointerMode.MOVE and selected_squad == null and selected_general == null:
		return
	if index == PointerMode.TARGET and (selected_squad == null or selected_squad.routing):
		return
	_set_pointer_mode(index)


func _set_pointer_mode(value: int) -> void:
	pointer_mode = value
	pending_focus_target = value == PointerMode.TARGET
	_update_status()
	_update_command_buttons()
	_update_pointer_buttons()


func _update_pointer_buttons() -> void:
	for index in range(pointer_buttons.size()):
		pointer_buttons[index].disabled = (index == PointerMode.MOVE and selected_squad == null and selected_general == null) or (index == PointerMode.TARGET and (selected_squad == null or selected_squad.routing))
		pointer_buttons[index].button_pressed = index == pointer_mode


func _update_command_buttons() -> void:
	for index in range(command_buttons.size()):
		command_buttons[index].disabled = selected_squad == null or selected_squad.routing
		command_buttons[index].button_pressed = selected_squad != null and (index == BattleSquad.Command.FOCUS_TARGET if pending_focus_target else selected_squad.command == index)


func _on_formation_pressed(index: int) -> void:
	if selected_squad == null or selected_squad.routing:
		return
	selected_squad.set_formation(index)
	_update_status()
	_update_formation_buttons()


func _update_formation_buttons() -> void:
	for index in range(formation_buttons.size()):
		formation_buttons[index].disabled = selected_squad == null or selected_squad.routing
		formation_buttons[index].button_pressed = selected_squad != null and selected_squad.formation == index


func _select_at(point: Vector2) -> void:
	pending_focus_target = false
	pointer_mode = PointerMode.SELECT
	if selected_squad != null:
		selected_squad.set_selected(false)
	selected_squad = null
	if selected_general != null:
		selected_general.set_selected(false)
	selected_general = null
	if is_instance_valid(player_general) and player_general.is_alive() and player_general.global_position.distance_to(point) < BattleSquad.PICK_RADIUS:
		selected_general = player_general
		selected_general.set_selected(true)
		_update_status()
		_update_formation_buttons()
		_update_command_buttons()
		_update_pointer_buttons()
		return
	var nearest := BattleSquad.PICK_RADIUS
	for squad in player_squads:
		var distance := squad.distance_to_point(point)
		if distance < nearest:
			nearest = distance
			selected_squad = squad
	if selected_squad != null:
		selected_squad.set_selected(true)
	_update_status()
	_update_formation_buttons()
	_update_command_buttons()
	_update_pointer_buttons()


func _draw() -> void:
	draw_texture_rect(TERRAIN_TEXTURE, Rect2(Vector2.ZERO, FIELD_SIZE), false)
	if drag_active and drag_moved and drag_action == DragAction.MOVE and (is_instance_valid(selected_general) or is_instance_valid(selected_squad)):
		var origin := selected_general.global_position if selected_general != null else selected_squad.get_center()
		var destination := drag_destination.clamp(Vector2(20, 20), FIELD_SIZE - Vector2(20, 20))
		draw_line(origin, destination, Color("f4dc93", 0.85), 3.0)
		draw_arc(destination, 16.0, 0.0, TAU, 24, Color("f4dc93"), 2.0)
		draw_circle(destination, 4.0, Color("f4dc93"))
