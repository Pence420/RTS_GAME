class_name EnemyArmyAI
extends Node

const DECISION_INTERVAL := 1.0
const REASSIGN_MARGIN := 65.0
const COMMITMENT_TIME := 2.5

var player_squads: Array[BattleSquad] = []
var enemy_squads: Array[BattleSquad] = []
var general: BattleUnit
var active := false
var decision_timer := 0.0
var commitments: Dictionary = {}


func begin_battle(players: Array[BattleSquad], enemies: Array[BattleSquad], army_general: BattleUnit) -> void:
	player_squads = players
	enemy_squads = enemies
	general = army_general
	active = true
	commitments.clear()
	_issue_orders()
	decision_timer = DECISION_INTERVAL


func _process(delta: float) -> void:
	if not active:
		return
	decision_timer -= delta
	if decision_timer <= 0.0:
		for squad in commitments:
			commitments[squad] = maxf(0.0, commitments[squad] - DECISION_INTERVAL)
		_issue_orders()
		decision_timer = DECISION_INTERVAL


func _available(squad: BattleSquad) -> bool:
	return is_instance_valid(squad) and not squad.is_queued_for_deletion() and not squad.routing and not squad.units.is_empty()


func _issue_orders() -> void:
	var assignments := {}
	for squad in enemy_squads:
		if _available(squad) and _available(squad.target_squad):
			assignments[squad.target_squad] = assignments.get(squad.target_squad, 0) + 1
	for squad in enemy_squads:
		if not _available(squad):
			continue
		var old := squad.target_squad
		if _available(old):
			assignments[old] -= 1
		var target := _choose_target(squad, assignments)
		# A valid commitment persists unless a materially better plan appears.
		# Invalid/routed targets are replaced immediately, including mid-fight.
		if _available(old) and target != old:
			if commitments.get(squad, 0.0) > 0.0 or _target_score(squad, old, assignments) <= _target_score(squad, target, assignments) + REASSIGN_MARGIN:
				target = old
		if target != null:
			assignments[target] = assignments.get(target, 0) + 1
			if old != target:
				squad.set_target(target, BattleSquad.Command.FOCUS_TARGET)
				commitments[squad] = COMMITMENT_TIME
			for unit in squad.units:
				unit.autonomous_order = true
		elif old != null:
			squad.set_command(BattleSquad.Command.ADVANCE)
	_move_general()


func _choose_target(squad: BattleSquad, assignments: Dictionary) -> BattleSquad:
	var best := INF
	var chosen: BattleSquad
	for candidate in player_squads:
		if not _available(candidate):
			continue
		var score := _target_score(squad, candidate, assignments)
		if score < best:
			best = score
			chosen = candidate
	return chosen


func _target_score(attacker: BattleSquad, defender: BattleSquad, assignments: Dictionary) -> float:
	if not _available(defender):
		return INF
	var score := attacker.get_center().distance_to(defender.get_center())
	score += float(assignments.get(defender, 0)) * 75.0
	if attacker.unit_type == BattleUnit.UnitType.SWORDSMAN and defender.unit_type == BattleUnit.UnitType.SPEARMAN:
		score -= 60.0
	elif attacker.unit_type == BattleUnit.UnitType.AXEMAN and defender.unit_type == BattleUnit.UnitType.SWORDSMAN:
		score -= 60.0
	elif attacker.unit_type == BattleUnit.UnitType.ARCHER and defender.unit_type == BattleUnit.UnitType.AXEMAN:
		score -= 60.0
	elif attacker.unit_type == BattleUnit.UnitType.SPEARMAN and defender.command == BattleSquad.Command.CHARGE:
		score -= 75.0
	score -= (1.0 - defender.get_health_ratio()) * 25.0
	# Infantry intercepts threats to its own archers rather than all walking
	# past a melee squad that is about to hit the back line.
	if attacker.unit_type != BattleUnit.UnitType.ARCHER and defender.unit_type != BattleUnit.UnitType.ARCHER:
		for ally in enemy_squads:
			if _available(ally) and ally.unit_type == BattleUnit.UnitType.ARCHER and ally.get_center().distance_to(defender.get_center()) < 180.0:
				score -= 90.0
				break
	return score


func _move_general() -> void:
	if not is_instance_valid(general) or not general.is_alive():
		return
	var center := Vector2.ZERO
	var count := 0
	for squad in enemy_squads:
		if _available(squad) and squad.unit_type != BattleUnit.UnitType.ARCHER:
			center += squad.get_center()
			count += 1
	if count == 0:
		for squad in enemy_squads:
			if _available(squad):
				center += squad.get_center()
				count += 1
	if count == 0:
		return
	center /= count
	var enemy := _nearest_player_squad(center)
	var back := (center - enemy.get_center()).normalized() if enemy != null else Vector2.RIGHT
	if back == Vector2.ZERO:
		back = Vector2.RIGHT
	var destination := center + back * 125.0
	var threat: BattleUnit
	var closest := 100.0
	for node in get_tree().get_nodes_in_group("team_0"):
		var unit := node as BattleUnit
		if not unit.is_alive() or unit.routing or unit.unit_type == BattleUnit.UnitType.ARCHER:
			continue
		var distance := general.global_position.distance_to(unit.global_position)
		if distance < closest:
			closest = distance
			threat = unit
	if threat != null:
		destination = general.global_position + (general.global_position - threat.global_position).normalized() * 100.0
	destination = destination.clamp(BattleUnit.FIELD_BOUNDS.position, BattleUnit.FIELD_BOUNDS.end)
	if general.global_position.distance_to(destination) > 40.0:
		general.move_to(destination)


func _nearest_player_squad(point: Vector2) -> BattleSquad:
	var nearest := INF
	var closest: BattleSquad
	for squad in player_squads:
		if not _available(squad):
			continue
		var distance := squad.get_center().distance_to(point)
		if distance < nearest:
			nearest = distance
			closest = squad
	return closest
