extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1152, 648)
	var battle: Node2D = load("res://scenes/battle.tscn").instantiate()
	root.add_child(battle)
	await process_frame
	var menu: Control = battle.get_node_or_null("CanvasLayer/GameMenu")
	var menu_button: Button = battle.get_node_or_null("CanvasLayer/MenuButton")
	if menu == null or menu_button == null:
		_fail("Game menu is missing from the HUD.")
		return
	menu_button.emit_signal("pressed")
	if not paused or not menu.visible:
		_fail("Opening the menu must pause the battle and show its content.")
		return
	var blue: Array = battle.get("player_squads")
	var type_selector: OptionButton = menu.get_node("Center/Card/ArmyPage/Rows/Row0/Type")
	if type_selector.item_count != 4 or type_selector.disabled:
		_fail("Deployment menu must offer four unit types for each squad.")
		return
	type_selector.select(BattleUnit.UnitType.ARCHER)
	type_selector.emit_signal("item_selected", BattleUnit.UnitType.ARCHER)
	if blue[0].unit_type != BattleUnit.UnitType.ARCHER or blue[0].units[0].max_hp != 24.0:
		_fail("Choosing Archer did not change the deployed squad.")
		return
	menu.get_node("Center/Card/GuideTab").emit_signal("pressed")
	var guide: Control = menu.get_node("Center/Card/GuidePage")
	if not guide.visible or not guide.get_node("GuideText").text.contains("ARCHER") or not guide.get_node("GuideText").text.contains("Drag"):
		_fail("Field guide must explain unit roles and controls.")
		return
	menu.get_node("Center/Card/ArmyTab").emit_signal("pressed")
	menu.get_node("Center/Card/ArmyPage/Rows/Row1/Select").emit_signal("pressed")
	if paused or menu.visible or battle.get("selected_squad") != blue[1]:
		_fail("Choosing a squad from the roster did not return to the battlefield with it selected.")
		return
	battle.get_node("CanvasLayer/StartBattle").emit_signal("pressed")
	menu_button.emit_signal("pressed")
	if not type_selector.disabled:
		_fail("Squad composition must be locked once battle starts.")
		return
	type_selector.emit_signal("item_selected", BattleUnit.UnitType.AXEMAN)
	if blue[0].unit_type != BattleUnit.UnitType.ARCHER:
		_fail("Squad composition changed during battle.")
		return
	menu.get_node("Center/Card/ContinueButton").emit_signal("pressed")
	if paused or menu.visible:
		_fail("Continue did not return to the battle.")
		return
	menu_button.emit_signal("pressed")
	var escape := InputEventKey.new()
	escape.keycode = KEY_ESCAPE
	escape.pressed = true
	menu._input(escape)
	if paused or menu.visible:
		_fail("Escape did not close the paused menu.")
		return
	print("Game menu smoke passed: pause, roster, composition, guide, and resume.")
	quit()


func _fail(message: String) -> void:
	push_error(message)
	paused = false
	quit(1)
