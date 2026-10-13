class_name BattleSquad
extends Node2D

signal roster_changed(squad: BattleSquad)
signal health_changed(squad: BattleSquad)
signal morale_changed(squad: BattleSquad)
signal routed(squad: BattleSquad)

const UNIT_SCENE: PackedScene = preload("res://scenes/unit.tscn")
const SOLDIERS_PER_SQUAD := 10
const PICK_RADIUS := 22.0
const SLOT_SPACING := Vector2(42, 50)
const CASUALTY_MORALE_LOSS := 12.0
const GENERAL_MORALE_BONUS := 10.0

enum Formation { LINE, COLUMN, SHIELD_WALL, WEDGE }
const FORMATION_NAMES := ["Line", "Column", "Shield Wall", "Wedge"]
enum Command { HOLD, ADVANCE, CHARGE, DEFEND, FOCUS_TARGET }
const COMMAND_NAMES := ["Hold", "Advance", "Charge", "Defend", "Focus Target"]

var squad_id := ""
var team := 0
var unit_type := BattleUnit.UnitType.SWORDSMAN
var selected := false
var formation := Formation.LINE
var command := Command.ADVANCE
var target_squad: BattleSquad
var general: BattleUnit
var morale := 75.0
var routing := false
var general_in_range := false
var aura_check_timer := 0.0
var ordered_center := Vector2.ZERO
var units: Array[BattleUnit] = []
var slots: Dictionary[BattleUnit, Vector2] = {}
var slot_indices: Dictionary[BattleUnit, int] = {}


func _ready() -> void:
	ordered_center = global_position
	for index in range(SOLDIERS_PER_SQUAD):
		var unit := UNIT_SCENE.instantiate() as BattleUnit
		var slot := _slot_for(index)
		unit.team = team
		unit.idle_phase = index
		unit.configure_type(unit_type)
		unit.position = slot
		add_child(unit)
		unit.died.connect(_on_soldier_died)
		unit.escaped.connect(_on_soldier_escaped)
		unit.health_changed.connect(_on_health_changed)
		units.append(unit)
		slots[unit] = slot
		slot_indices[unit] = index


func _process(delta: float) -> void:
	if selected:
		queue_redraw()
	aura_check_timer -= delta
	if aura_check_timer <= 0.0:
		_refresh_general_aura()
		aura_check_timer = 0.25


func move_to(center: Vector2) -> void:
	if routing:
		return
	_assign_formation_slots(center)
	var minimum := Vector2.ZERO
	var maximum := Vector2.ZERO
	for unit in units:
		minimum = minimum.min(slots[unit])
		maximum = maximum.max(slots[unit])
	center = center.clamp(BattleUnit.FIELD_BOUNDS.position - minimum, BattleUnit.FIELD_BOUNDS.end - Vector2.ONE - maximum)
	ordered_center = center
	for unit in units:
		unit.move_to(center + slots[unit])


func _assign_formation_slots(center: Vector2) -> void:
	var count := units.size()
	if count == 0:
		return
	var offsets: Array[Vector2] = []
	var mean := Vector2.ZERO
	for index in range(count):
		var offset := _slot_for(index)
		offsets.append(offset)
		mean += offset
	mean /= count
	for index in range(count):
		offsets[index] -= mean
	# Exact minimum-travel matching for at most ten soldiers (1024 subsets).
	# Each destination belongs to one soldier; reforming does not blindly send
	# old slot numbers through the opposite side of the squad.
	var costs := PackedFloat64Array()
	var choices := PackedInt32Array()
	costs.resize(1 << count)
	choices.resize(1 << count)
	costs.fill(INF)
	costs[0] = 0.0
	for mask in range(1 << count):
		var soldier_index := 0
		for bit in range(count):
			if mask & (1 << bit):
				soldier_index += 1
		if soldier_index == count:
			continue
		for slot_index in range(count):
			if mask & (1 << slot_index):
				continue
			var next := mask | (1 << slot_index)
			var cost := costs[mask] + units[soldier_index].global_position.distance_squared_to(center + offsets[slot_index])
			if cost < costs[next]:
				costs[next] = cost
				choices[next] = slot_index
	var mask := (1 << count) - 1
	for soldier_index in range(count - 1, -1, -1):
		var slot_index := choices[mask]
		slots[units[soldier_index]] = offsets[slot_index]
		slot_indices[units[soldier_index]] = slot_index
		mask ^= 1 << slot_index


func begin_battle() -> void:
	for unit in units:
		unit.combat_enabled = true


func set_unit_type(value: int) -> void:
	if value < BattleUnit.UnitType.SWORDSMAN or value > BattleUnit.UnitType.ARCHER:
		return
	if unit_type == value:
		return
	unit_type = value
	for unit in units:
		unit.configure_type(value)
	health_changed.emit(self)


func set_general(value: BattleUnit) -> void:
	general = value
	_refresh_general_aura()


func get_effective_morale() -> float:
	return minf(100.0, morale + (GENERAL_MORALE_BONUS if general_in_range else 0.0))


func get_morale_state() -> String:
	if morale <= 0.0 or units.is_empty():
		return "Broken"
	if routing:
		return "Routing"
	if get_effective_morale() < 60.0:
		return "Shaken"
	return "Stable"


func apply_morale_change(amount: float) -> void:
	if routing and amount > 0.0:
		return
	morale = clampf(morale + amount, 0.0, 100.0)
	morale_changed.emit(self)
	_check_routing()


func _refresh_general_aura() -> void:
	var in_range := is_instance_valid(general) and general.is_alive() and get_center().distance_to(general.global_position) <= BattleUnit.GENERAL_RADIUS
	if in_range == general_in_range:
		return
	general_in_range = in_range
	for unit in units:
		unit.aura_attack_multiplier = 1.05 if in_range else 1.0
	morale_changed.emit(self)
	_check_routing()


func _check_routing() -> void:
	if routing or units.is_empty() or get_effective_morale() >= 30.0:
		return
	routing = true
	target_squad = null
	for unit in units:
		var exit_x := 16.0 if team == 0 else 1584.0
		unit.start_routing(Vector2(exit_x, clampf(unit.global_position.y, 16.0, 884.0)))
	routed.emit(self)


func set_command(value: int) -> void:
	if routing:
		return
	if value < Command.HOLD or value > Command.FOCUS_TARGET:
		return
	command = value
	target_squad = null
	for unit in units:
		unit.set_command(value)


func set_target(enemy_squad: BattleSquad, value: int) -> void:
	if routing:
		return
	if enemy_squad == null or enemy_squad.units.is_empty():
		return
	if value != Command.CHARGE and value != Command.FOCUS_TARGET:
		return
	set_command(value)
	target_squad = enemy_squad
	for unit in units:
		unit.set_focus_targets(enemy_squad.units)


func get_command_name() -> String:
	return COMMAND_NAMES[command]


func get_unit_type_name() -> String:
	return BattleUnit.TYPE_NAMES[unit_type]


func set_formation(value: int) -> void:
	if routing:
		return
	if value < Formation.LINE or value > Formation.WEDGE:
		return
	if formation == value:
		return
	var center := ordered_center if _has_manual_move() else get_center()
	formation = value
	for unit in units:
		unit.formation_attack_multiplier = 1.1 if formation == Formation.WEDGE else 1.0
		unit.formation_damage_taken_multiplier = 0.85 if formation == Formation.SHIELD_WALL else (1.1 if formation == Formation.WEDGE else 1.0)
		unit.formation_speed_multiplier = 0.8 if formation == Formation.SHIELD_WALL else 1.0
	move_to(center)


func get_formation_name() -> String:
	return FORMATION_NAMES[formation]


func _has_manual_move() -> bool:
	for unit in units:
		if unit.manual_move:
			return true
	return false


func _slot_for(index: int) -> Vector2:
	match formation:
		Formation.COLUMN:
			return Vector2((index % 2 - 0.5) * SLOT_SPACING.x, (floori(index / 2.0) - 2) * SLOT_SPACING.y)
		Formation.SHIELD_WALL:
			return Vector2(0.0, (index - 4.5) * SLOT_SPACING.x)
		Formation.WEDGE:
			var row := 0
			var position_in_row := 0
			if index >= 6:
				row = 3
				position_in_row = index - 6
			elif index >= 3:
				row = 2
				position_in_row = index - 3
			elif index >= 1:
				row = 1
				position_in_row = index - 1
			var forward := 1.0 if team == 0 else -1.0
			return Vector2(forward * (54.0 - row * SLOT_SPACING.y), (position_in_row - row / 2.0) * SLOT_SPACING.x)
		_:
			return Vector2((index % 5 - 2) * SLOT_SPACING.x, (floori(index / 5.0) - 0.5) * SLOT_SPACING.y)


func set_selected(value: bool) -> void:
	selected = value
	for unit in units:
		unit.set_selected(false)
	queue_redraw()


func _draw() -> void:
	if not selected or units.is_empty():
		return
	var minimum := Vector2(INF, INF)
	var maximum := Vector2(-INF, -INF)
	for unit in units:
		var point := to_local(unit.global_position)
		minimum = minimum.min(point)
		maximum = maximum.max(point)
	minimum -= Vector2(18, 17)
	maximum += Vector2(18, 17)
	var color := Color("f2d780")
	var length := 13.0
	for x in [minimum.x, maximum.x]:
		var inward_x := length if x == minimum.x else -length
		for y in [minimum.y, maximum.y]:
			var inward_y := length if y == minimum.y else -length
			draw_line(Vector2(x, y), Vector2(x + inward_x, y), color, 2.0)
			draw_line(Vector2(x, y), Vector2(x, y + inward_y), color, 2.0)
	draw_rect(Rect2(minimum, maximum - minimum), Color(0.99, 0.83, 0.48, 0.045))


func distance_to_point(point: Vector2) -> float:
	var nearest := INF
	for unit in units:
		nearest = minf(nearest, unit.global_position.distance_to(point))
	return nearest


func get_center() -> Vector2:
	if units.is_empty():
		return global_position
	var sum := Vector2.ZERO
	for unit in units:
		sum += unit.global_position
	return sum / units.size()


func get_health_ratio() -> float:
	if units.is_empty():
		return 0.0
	var total_hp := 0.0
	for unit in units:
		total_hp += unit.current_hp
	return float(total_hp) / float(units.size() * units[0].max_hp)


func _on_soldier_died(unit: BattleUnit) -> void:
	_remove_unit(unit)
	if not units.is_empty():
		apply_morale_change(-CASUALTY_MORALE_LOSS)
	roster_changed.emit(self)


func _on_soldier_escaped(unit: BattleUnit) -> void:
	_remove_unit(unit)
	if units.is_empty():
		morale = 0.0
	roster_changed.emit(self)


func _remove_unit(unit: BattleUnit) -> void:
	units.erase(unit)
	slots.erase(unit)
	slot_indices.erase(unit)


func _on_health_changed(_unit: BattleUnit) -> void:
	health_changed.emit(self)
