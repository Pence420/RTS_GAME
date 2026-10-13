extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1152, 648)
	var battle: Node2D = load("res://scenes/battle.tscn").instantiate()
	root.add_child(battle)
	var blue: Array = battle.get("player_squads")
	var red: Array = battle.get("enemy_squads")
	await process_frame
	if blue.size() != 4 or red.size() != 4:
		_fail("Expected four typed squads per army.")
		return
	for army in [blue, red]:
		var types: Dictionary = {}
		for squad in army:
			if squad.units.size() != 10:
				_fail("Every squad must start with ten soldiers.")
				return
			var type_name: String = squad.call("get_unit_type_name")
			types[type_name] = true
			for unit in squad.units:
				if unit.get("unit_type") != squad.get("unit_type"):
					_fail("Squad has a soldier of the wrong type.")
					return
		if types.size() != 4:
			_fail("Army must contain four distinct unit types.")
			return
	var dock: Control = battle.get_node("CanvasLayer/BottomDock")
	var command_rect := dock.get_global_rect().grow(8.0)
	for squad in blue + red:
		for unit in squad.units:
			if command_rect.has_point(unit.get_global_transform_with_canvas().origin):
				_fail("A starting soldier overlaps the visible bottom dock.")
				return
	for squad in blue:
		battle.call("_select_at", squad.units[0].global_position)
		if battle.get("selected_squad") != squad or not battle.get_node("CanvasLayer/Status").text.contains(squad.get_unit_type_name()):
			_fail("A unit type cannot be selected or identified in the status panel.")
			return
		battle.call("_on_formation_pressed", BattleSquad.Formation.COLUMN)
		battle.call("_issue_right_click", squad.get_center() + Vector2(40, 0))
		if squad.formation != BattleSquad.Formation.COLUMN or not squad.units[0].manual_move:
			_fail("A typed squad did not accept formation and movement orders.")
			return
	var sword: BattleUnit = blue[0].units[0]
	var spear: BattleUnit = blue[1].units[0]
	var axe: BattleUnit = blue[2].units[0]
	var archer: BattleUnit = blue[3].units[0]
	if spear.attack_range <= sword.attack_range or axe.damage <= sword.damage:
		_fail("Spearman reach or Axeman damage is missing.")
		return
	if archer.attack_range < 150.0 or archer.max_hp >= sword.max_hp:
		_fail("Archer does not have a ranged, fragile profile.")
		return
	var sword_vs_spear := sword.calculate_damage_against(spear)
	spear.unit_type = BattleUnit.UnitType.SWORDSMAN
	var sword_without_counter := sword.calculate_damage_against(spear)
	spear.unit_type = BattleUnit.UnitType.SPEARMAN
	if sword_vs_spear <= sword_without_counter:
		_fail("Swordsman counter against Spearman is missing.")
		return
	var axe_vs_sword := axe.calculate_damage_against(sword)
	sword.unit_type = BattleUnit.UnitType.AXEMAN
	var axe_without_counter := axe.calculate_damage_against(sword)
	sword.unit_type = BattleUnit.UnitType.SWORDSMAN
	if axe_vs_sword <= axe_without_counter:
		_fail("Axeman counter against Swordsman is missing.")
		return
	var spear_damage_normal := sword.calculate_damage_against(spear)
	spear.set_command(BattleUnit.Command.HOLD)
	var spear_damage_defending := sword.calculate_damage_against(spear)
	if spear_damage_defending >= spear_damage_normal:
		_fail("Spearman defense while holding is missing.")
		return
	sword.set_command(BattleUnit.Command.CHARGE)
	var charge_into_brace := sword.calculate_damage_against(spear)
	spear.set_command(BattleUnit.Command.ADVANCE)
	var charge_into_open_spear := sword.calculate_damage_against(spear)
	if charge_into_brace >= charge_into_open_spear * 0.7:
		_fail("Braced Spearman should blunt a charge substantially.")
		return
	var spear_vs_charge := spear.calculate_damage_against(sword)
	sword.set_command(BattleUnit.Command.ADVANCE)
	var spear_vs_advance := spear.calculate_damage_against(sword)
	if spear_vs_charge <= spear_vs_advance:
		_fail("Spearman should counter charging infantry.")
		return
	var archer_vs_axe := archer.calculate_damage_against(axe)
	axe.unit_type = BattleUnit.UnitType.SWORDSMAN
	var archer_without_counter := archer.calculate_damage_against(axe)
	axe.unit_type = BattleUnit.UnitType.AXEMAN
	if archer_vs_axe <= archer_without_counter:
		_fail("Archer pressure against slow Axemen is missing.")
		return
	var foe: BattleUnit = red[0].units[0]
	foe.global_position = archer.global_position + Vector2(140, 0)
	archer.set_command(BattleUnit.Command.HOLD)
	if archer._find_nearest_enemy() != foe:
		_fail("Archer on Hold cannot acquire a ranged target.")
		return
	archer.combat_enabled = true
	var hp_before: float = foe.current_hp
	for frame in range(120):
		await physics_frame
		if foe.current_hp < hp_before:
			break
	if foe.current_hp >= hp_before:
		_fail("Archer did not deal ranged damage.")
		return
	print("Unit types smoke passed: four squads per army and ranged combat.")
	paused = false
	quit()


func _fail(message: String) -> void:
	push_error(message)
	paused = false
	quit(1)
