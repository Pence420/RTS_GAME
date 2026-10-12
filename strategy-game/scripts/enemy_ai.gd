class_name EnemyArmyAI
extends Node

const DECISION_INTERVAL := 1.0

var player_squads: Array[BattleSquad] = []
var enemy_squads: Array[BattleSquad] = []
var general: BattleUnit
var active := false
var decision_timer := 0.0


func begin_battle(players: Array[BattleSquad], enemies: Array[BattleSquad], army_general: BattleUnit) -> void:
	player_squads = players
	enemy_squads = enemies
	general = army_general
	active = true
	_issue_orders()
	decision_timer = DECISION_INTERVAL


func _process(delta: float) -> void:
	if not active:
		return
	decision_timer -= delta
	if decision_timer <= 0.0:
		_issue_orders()
		decision_timer = DECISION_INTERVAL


func _issue_orders() -> void:
	for enemy_squad in enemy_squads:
		if enemy_squad.routing:
			continue
		var target := _nearest_player_squad(enemy_squad.get_center())
		if target != null and enemy_squad.target_squad != target:
			enemy_squad.set_target(target, BattleSquad.Command.FOCUS_TARGET)
		elif target == null and enemy_squad.target_squad != null:
			enemy_squad.set_command(BattleSquad.Command.ADVANCE)
	_move_general()


func _move_general() -> void:
	if not is_instance_valid(general) or not general.is_alive():
		return
	var center := Vector2.ZERO
	var count := 0
	for squad in enemy_squads:
		if not squad.routing:
			center += squad.get_center()
			count += 1
	if count == 0:
		return
	var destination := center / count + Vector2(90, 0)
	if general.global_position.distance_to(destination) > 40.0:
		general.move_to(destination)


func _nearest_player_squad(point: Vector2) -> BattleSquad:
	var nearest := INF
	var closest: BattleSquad
	for squad in player_squads:
		if squad.routing:
			continue
		var distance := squad.get_center().distance_to(point)
		if distance < nearest:
			nearest = distance
			closest = squad
	return closest
