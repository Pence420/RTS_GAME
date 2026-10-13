extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var battle: Node2D = load("res://scenes/battle.tscn").instantiate()
	root.add_child(battle)
	var player_squads: Array = battle.get("player_squads")
	var enemy_squads: Array = battle.get("enemy_squads")
	var front: BattleSquad = player_squads[0]
	var reserve: BattleSquad = player_squads[1]
	var red: BattleSquad = enemy_squads[0]
	var general: BattleUnit = battle.get("player_general")
	if not general.is_general or front.get_effective_morale() != 85.0 or reserve.get_effective_morale() != 85.0:
		_fail("The player General must give nearby squads +10 effective morale.")
		return
	var boosted_damage := front.units[1].calculate_damage_against(red.units[1])
	front.units[1].aura_attack_multiplier = 1.0
	var normal_damage := front.units[1].calculate_damage_against(red.units[1])
	front.units[1].aura_attack_multiplier = 1.05
	if boosted_damage <= normal_damage:
		_fail("The General aura must provide a real combat bonus.")
		return
	battle.call("_select_at", general.global_position)
	if battle.get("selected_general") != general:
		_fail("The player General must be selectable for movement orders.")
		return

	front.units[0].receive_damage(999)
	if front.morale != 63.0 or front.get_effective_morale() != 73.0:
		_fail("A soldier casualty must lower squad morale by 12.")
		return
	reserve.apply_morale_change(-30.0)
	if reserve.get_morale_state() != "Shaken" or reserve.routing:
		_fail("Morale 55 should be Shaken without routing.")
		return
	general.receive_damage(999)
	if battle.get("selected_general") != null or reserve.morale != 20.0 or not reserve.routing:
		_fail("General death must remove the aura, apply an army penalty, and trigger routing.")
		return
	if red.morale != 83.0:
		_fail("An enemy squad routing must raise opposing morale.")
		return
	for unit in reserve.units:
		if not unit.routing:
			_fail("Every soldier in a routing squad must flee.")
			return
	battle.call("_select_at", reserve.units[0].global_position)
	var hold_button: Button = battle.get_node("CanvasLayer/CommandButtons/Defend")
	if not hold_button.disabled:
		_fail("Routing squads must not accept new commands.")
		return
	var enemy_ai: EnemyArmyAI = battle.get_node("EnemyAI")
	enemy_ai.player_squads = player_squads
	if enemy_ai._nearest_player_squad(red.get_center()) == reserve:
		_fail("Enemy AI must ignore routing squads.")
		return
	var escape_seconds := 0.0
	for soldier in reserve.units:
		escape_seconds = maxf(escape_seconds, soldier.global_position.distance_to(soldier.destination) / (soldier.move_speed * 1.4))
	# Escape travel time grows with map size; retain two seconds of contact slack.
	for frame in range(ceili((escape_seconds + 2.0) * Engine.physics_ticks_per_second)):
		if not is_instance_valid(reserve) or not player_squads.has(reserve):
			break
		await physics_frame
	for squad in player_squads:
		if squad.squad_id == "Blue B":
			_fail("Routing soldiers did not leave the battlefield.")
			return
	print("Morale smoke passed: General aura, casualty loss, routing, and escape.")
	quit()


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
