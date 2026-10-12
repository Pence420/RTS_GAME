class_name BattleUnit
extends CharacterBody2D

signal died(unit: BattleUnit)
signal health_changed(unit: BattleUnit)
signal escaped(unit: BattleUnit)

const MOVE_SPEED := 145.0
const ARRIVAL_DISTANCE := 3.0
const DETECTION_RANGE := 230.0
const ATTACK_RANGE := 27.0
const ATTACK_INTERVAL := 0.8
const GENERAL_RADIUS := 270.0
const ARCHER_RETREAT_RANGE := 75.0
const FIELD_BOUNDS := Rect2(20.0, 20.0, 1560.0, 860.0)
const DEATH_EFFECT = preload("res://scripts/death_effect.gd")
const UNIT_VISUALS = preload("res://scripts/unit_visuals.gd")

enum State { IDLE, MOVING, CHASING, ATTACKING, HOLDING, ROUTING, DEAD }
enum Command { HOLD, ADVANCE, CHARGE, DEFEND, FOCUS_TARGET }
enum UnitType { SWORDSMAN, SPEARMAN, AXEMAN, ARCHER }
const TYPE_NAMES := ["Swordsman", "Spearman", "Axeman", "Archer"]

var team := 0
var is_general := false
var unit_type := UnitType.SWORDSMAN
var routing := false
var combat_enabled := false
var selected := false
var destination := Vector2.ZERO
var manual_move := false
var max_hp := 40.0
var current_hp := 40.0
var damage := 8.0
var armor := 2.0
var move_speed := MOVE_SPEED
var attack_range := ATTACK_RANGE
var attack_interval := ATTACK_INTERVAL
var formation_attack_multiplier := 1.0
var aura_attack_multiplier := 1.0
var formation_damage_taken_multiplier := 1.0
var formation_speed_multiplier := 1.0
var command_mode := Command.ADVANCE
var command_damage_taken_multiplier := 1.0
var command_speed_multiplier := 1.0
var focus_targets: Array[BattleUnit] = []
var charge_bonus_ready := false
var charge_bonus_timer := 0.0
var state := State.IDLE
var current_target: BattleUnit
var attack_cooldown := 0.0
var target_scan_timer := 0.0
var hit_flash_timer := 0.0
var shot_trace_timer := 0.0
var shot_trace_end := Vector2.ZERO
var attack_fx_timer := 0.0

@onready var visual_sprite: AnimatedSprite2D = $AnimatedSprite2D


func configure_type(value: int) -> void:
	unit_type = clampi(value, UnitType.SWORDSMAN, UnitType.ARCHER)
	match unit_type:
		UnitType.SPEARMAN:
			max_hp = 38.0
			damage = 6.5
			armor = 3.0
			move_speed = 135.0
			attack_range = 42.0
			attack_interval = 0.85
		UnitType.AXEMAN:
			max_hp = 42.0
			damage = 11.0
			armor = 1.0
			move_speed = 130.0
			attack_range = 27.0
			attack_interval = 1.15
		UnitType.ARCHER:
			max_hp = 24.0
			damage = 6.0
			armor = 0.0
			move_speed = 125.0
			attack_range = 190.0
			attack_interval = 1.25
		_:
			max_hp = 40.0
			damage = 8.0
			armor = 2.0
			move_speed = MOVE_SPEED
			attack_range = ATTACK_RANGE
			attack_interval = ATTACK_INTERVAL
	current_hp = max_hp
	if is_node_ready():
		_configure_visuals()
	queue_redraw()


func get_type_name() -> String:
	return TYPE_NAMES[unit_type]


func _ready() -> void:
	destination = global_position
	add_to_group("team_%d" % team)
	_configure_visuals()
	queue_redraw()


func _configure_visuals() -> void:
	visual_sprite.sprite_frames = UNIT_VISUALS.frames_for(unit_type, team, is_general)
	visual_sprite.visible = visual_sprite.sprite_frames != null
	visual_sprite.flip_h = team == 1
	if visual_sprite.visible:
		visual_sprite.play(&"idle")


func _process(delta: float) -> void:
	var needs_redraw := false
	if hit_flash_timer > 0.0:
		hit_flash_timer = maxf(0.0, hit_flash_timer - delta)
		needs_redraw = true
	if shot_trace_timer > 0.0:
		shot_trace_timer = maxf(0.0, shot_trace_timer - delta)
		needs_redraw = true
	if attack_fx_timer > 0.0:
		attack_fx_timer = maxf(0.0, attack_fx_timer - delta)
		needs_redraw = true
	if needs_redraw:
		queue_redraw()
	visual_sprite.modulate = Color.WHITE.lerp(Color(1.0, 0.65, 0.58), hit_flash_timer / 0.18)
	_update_visual_animation()


func _update_visual_animation() -> void:
	if visual_sprite.sprite_frames == null:
		return
	var wanted: StringName = &"idle"
	if attack_fx_timer > 0.0:
		wanted = &"attack"
	elif velocity.length_squared() > 25.0 or state == State.MOVING or state == State.CHASING or state == State.ROUTING:
		wanted = &"walk"
	if visual_sprite.animation != wanted or (wanted != &"attack" and not visual_sprite.is_playing()):
		visual_sprite.play(wanted)


func move_to(point: Vector2) -> void:
	if routing:
		return
	destination = point
	manual_move = true


func set_command(value: int) -> void:
	if routing:
		return
	command_mode = value
	current_target = null
	target_scan_timer = 0.0
	focus_targets = []
	charge_bonus_ready = value == Command.CHARGE
	charge_bonus_timer = 0.0
	command_damage_taken_multiplier = 0.8 if value == Command.DEFEND else 1.0
	command_speed_multiplier = 0.8 if value == Command.DEFEND else (1.35 if value == Command.CHARGE else 1.0)
	if value == Command.HOLD or value == Command.DEFEND or value == Command.CHARGE or value == Command.FOCUS_TARGET:
		manual_move = false
		destination = global_position
		velocity = Vector2.ZERO


func set_focus_targets(targets: Array[BattleUnit]) -> void:
	focus_targets = targets
	current_target = null
	target_scan_timer = 0.0


func set_selected(value: bool) -> void:
	selected = value
	queue_redraw()


func start_routing(exit_point: Vector2) -> void:
	if routing or not is_alive():
		return
	routing = true
	current_target = null
	manual_move = false
	destination = exit_point
	queue_redraw()


func is_alive() -> bool:
	return current_hp > 0


func receive_damage(amount: float) -> void:
	if not is_alive():
		return
	current_hp = maxf(0.0, current_hp - amount)
	hit_flash_timer = 0.18
	queue_redraw()
	health_changed.emit(self)
	if current_hp == 0.0:
		state = State.DEAD
		velocity = Vector2.ZERO
		var effect := DEATH_EFFECT.new() as Node2D
		effect.team = team
		get_parent().add_child(effect)
		effect.global_position = global_position
		died.emit(self)
		queue_free()


func calculate_damage_against(defender: BattleUnit) -> float:
	var charge_multiplier := 1.25 if charge_bonus_timer > 0.0 else 1.0
	var counter_multiplier := 1.0
	if unit_type == UnitType.SWORDSMAN and defender.unit_type == UnitType.SPEARMAN:
		counter_multiplier = 1.2
	elif unit_type == UnitType.AXEMAN and defender.unit_type == UnitType.SWORDSMAN:
		counter_multiplier = 1.25
	elif unit_type == UnitType.SPEARMAN and defender.command_mode == Command.CHARGE:
		counter_multiplier = 1.25
	elif unit_type == UnitType.ARCHER and defender.unit_type == UnitType.AXEMAN:
		counter_multiplier = 1.25
	var after_armor := maxf(1.0, damage * formation_attack_multiplier * aura_attack_multiplier * charge_multiplier * counter_multiplier - defender.armor)
	var spear_defense := 0.85 if defender.unit_type == UnitType.SPEARMAN and (defender.command_mode == Command.HOLD or defender.command_mode == Command.DEFEND) else 1.0
	var brace_against_charge := 0.75 if defender.unit_type == UnitType.SPEARMAN and (defender.command_mode == Command.HOLD or defender.command_mode == Command.DEFEND) and command_mode == Command.CHARGE else 1.0
	return maxf(1.0, after_armor * defender.formation_damage_taken_multiplier * defender.command_damage_taken_multiplier * spear_defense * brace_against_charge)


func _physics_process(delta: float) -> void:
	if not is_alive():
		return
	if routing:
		state = State.ROUTING
		var escape_vector := destination - global_position
		if escape_vector.length() <= 8.0:
			escaped.emit(self)
			queue_free()
			return
		velocity = escape_vector.normalized() * move_speed * 1.4
		move_and_slide()
		return
	if not combat_enabled:
		if manual_move:
			state = State.MOVING
			_move_toward(destination)
			if global_position.distance_to(destination) <= ARRIVAL_DISTANCE:
				manual_move = false
		else:
			state = State.HOLDING if command_mode == Command.HOLD or command_mode == Command.DEFEND else State.IDLE
			velocity = Vector2.ZERO
		move_and_slide()
		return
	attack_cooldown = maxf(0.0, attack_cooldown - delta)
	charge_bonus_timer = maxf(0.0, charge_bonus_timer - delta)
	target_scan_timer -= delta
	if target_scan_timer <= 0.0:
		current_target = _find_nearest_enemy()
		target_scan_timer = 0.25

	var threat := _nearby_melee_threat() if unit_type == UnitType.ARCHER and not manual_move and command_mode != Command.HOLD and command_mode != Command.DEFEND else null
	if _target_is_valid() and global_position.distance_to(current_target.global_position) <= attack_range:
		state = State.ATTACKING
		velocity = Vector2.ZERO
		if charge_bonus_ready:
			charge_bonus_timer = 2.0
			charge_bonus_ready = false
		if attack_cooldown <= 0.0:
			attack_fx_timer = 0.19
			queue_redraw()
			if unit_type == UnitType.ARCHER:
				shot_trace_end = to_local(current_target.global_position)
				shot_trace_timer = 0.12
				queue_redraw()
			current_target.receive_damage(calculate_damage_against(current_target))
			attack_cooldown = attack_interval
		if threat != null:
			_retreat_from(threat)
	elif threat != null:
		state = State.CHASING
		_retreat_from(threat)
	elif manual_move:
		state = State.MOVING
		_move_toward(destination)
		if global_position.distance_to(destination) <= ARRIVAL_DISTANCE:
			manual_move = false
	elif _target_is_valid() and command_mode != Command.HOLD and command_mode != Command.DEFEND:
		state = State.CHASING
		_move_toward(current_target.global_position)
	else:
		state = State.HOLDING if command_mode == Command.HOLD or command_mode == Command.DEFEND else State.IDLE
		velocity = Vector2.ZERO
	move_and_slide()


func _move_toward(point: Vector2) -> void:
	var offset := point - global_position
	velocity = Vector2.ZERO if offset.length() <= ARRIVAL_DISTANCE else offset.normalized() * move_speed * formation_speed_multiplier * command_speed_multiplier


func _nearby_melee_threat() -> BattleUnit:
	var closest: BattleUnit
	var nearest := ARCHER_RETREAT_RANGE
	for node in get_tree().get_nodes_in_group("team_%d" % (1 - team)):
		var enemy := node as BattleUnit
		if enemy == null or not enemy.is_alive() or enemy.routing:
			continue
		var distance := global_position.distance_to(enemy.global_position)
		if distance < nearest:
			nearest = distance
			closest = enemy
	return closest


func _retreat_from(enemy: BattleUnit) -> void:
	var direction := (global_position - enemy.global_position).normalized()
	if direction == Vector2.ZERO:
		direction = Vector2.LEFT if team == 0 else Vector2.RIGHT
	var retreat_point := global_position + direction * 100.0
	retreat_point = retreat_point.clamp(FIELD_BOUNDS.position, FIELD_BOUNDS.end)
	_move_toward(retreat_point)


func _target_is_valid() -> bool:
	return is_instance_valid(current_target) and current_target.is_alive() and not current_target.routing


func _find_nearest_enemy() -> BattleUnit:
	var closest: BattleUnit
	var nearest_distance := attack_range if command_mode == Command.HOLD or command_mode == Command.DEFEND else maxf(DETECTION_RANGE, attack_range)
	var candidates: Array[Node] = get_tree().get_nodes_in_group("team_%d" % (1 - team))
	if command_mode == Command.FOCUS_TARGET or (command_mode == Command.CHARGE and not focus_targets.is_empty()):
		candidates.assign(focus_targets)
		nearest_distance = INF
	for node in candidates:
		var enemy := node as BattleUnit
		if enemy == null or not enemy.is_alive() or enemy.routing:
			continue
		var distance := global_position.distance_to(enemy.global_position)
		if distance < nearest_distance:
			nearest_distance = distance
			closest = enemy
	return closest


func _draw() -> void:
	var facing := 1.0 if team == 0 else -1.0
	# A soft ground shadow anchors the character sprite to the field.
	draw_set_transform(Vector2(1, 10), 0.0, Vector2(1.35, 0.38))
	draw_circle(Vector2.ZERO, 15.0, Color(0.08, 0.16, 0.13, 0.12))
	draw_circle(Vector2.ZERO, 11.0, Color(0.08, 0.16, 0.13, 0.2))
	draw_set_transform(Vector2.ZERO)
	if is_general and selected:
		draw_arc(Vector2.ZERO, GENERAL_RADIUS, 0.0, TAU, 64, Color(0.95, 0.77, 0.38, 0.25), 2.0)
	if selected:
		draw_set_transform(Vector2(0, 9), 0.0, Vector2(1.0, 0.45))
		draw_arc(Vector2.ZERO, 21.0, 0.0, TAU, 28, Color("f6df85"), 2.5)
		draw_set_transform(Vector2.ZERO)
	if attack_fx_timer > 0.0 and unit_type != UnitType.ARCHER:
		draw_arc(Vector2(facing * 18.0, -8), 12.0, -1.6, 0.6, 12, Color(1.0, 0.91, 0.62, attack_fx_timer / 0.19), 2.5)
	if shot_trace_timer > 0.0:
		var start := Vector2(facing * 16.0, -8.0)
		var direction := (shot_trace_end - start).normalized()
		var tip := shot_trace_end
		var side := Vector2(-direction.y, direction.x)
		var alpha := shot_trace_timer / 0.12
		draw_line(start, tip, Color(0.99, 0.87, 0.58, alpha), 2.0)
		draw_colored_polygon(PackedVector2Array([tip, tip - direction * 8.0 + side * 3.0, tip - direction * 8.0 - side * 3.0]), Color(1.0, 0.94, 0.72, alpha))
	if hit_flash_timer > 0.0:
		draw_arc(Vector2(0, -7), 15.0 + (0.18 - hit_flash_timer) * 30.0, 0.0, TAU, 20, Color(1.0, 0.91, 0.61, hit_flash_timer / 0.18 * 0.7), 2.0)
	if routing:
		draw_arc(Vector2(0, 9), 16.0, 0.0, TAU, 20, Color("ded7bd"), 1.5)
	if selected or is_general or current_hp < max_hp:
		_draw_health_bar()


func _draw_health_bar() -> void:
	draw_rect(Rect2(-13, -45, 26, 4), Color("24312e"))
	draw_rect(Rect2(-12, -44, 24.0 * current_hp / max_hp, 2), Color("a8d47d") if team == 0 else Color("e6aa7a"))
