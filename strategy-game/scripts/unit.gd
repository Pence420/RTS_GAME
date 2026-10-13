class_name BattleUnit
extends CharacterBody2D

const FIELD = preload("res://scripts/battle_field.gd")

signal died(unit: BattleUnit)
signal health_changed(unit: BattleUnit)
signal escaped(unit: BattleUnit)

const BODY_RADIUS := 16.0
const PERSONAL_SPACE := 36.0

const MOVE_SPEED := 145.0
const ARRIVAL_DISTANCE := 0.15
const DETECTION_RANGE := 230.0
const ATTACK_RANGE := 27.0
const ATTACK_INTERVAL := 0.8
const GENERAL_RADIUS := 270.0
const ARCHER_RETREAT_RANGE := 90.0
const ARCHER_SAFE_RANGE := 120.0
const TARGET_SWITCH_MARGIN := 40.0
const COHESION_LIMIT := 155.0
const FIELD_BOUNDS := FIELD.UNIT_BOUNDS
const BODY_CONTACTS = preload("res://scripts/body_contacts.gd")
const DEATH_EFFECT = preload("res://scripts/death_effect.gd")
const UNIT_VISUALS = preload("res://scripts/unit_visuals.gd")

enum State { IDLE, MOVING, CHASING, ATTACKING, HOLDING, ROUTING, DEAD }
enum Command { HOLD, ADVANCE, CHARGE, DEFEND, FOCUS_TARGET, GUARD }
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
var idle_phase := 0
var visual_base_scale := UNIT_VISUALS.DISPLAY_SCALE
var blocked_time := 0.0
var arrival_wait_timer := 0.0
var retreat_target: BattleUnit
var squad_center := Vector2.ZERO
var squad_attached := false
var autonomous_order := false
var regrouping := false
var guarded_allies: Array[BattleUnit] = []
var guard_anchor := Vector2.ZERO
var stance_defending := false
var travel_speed_multiplier := 1.0
var visual_pick_rect := Rect2()

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
	guard_anchor = global_position
	visual_base_scale = visual_sprite.scale
	add_to_group("team_%d" % team)
	add_to_group("battle_units")
	if not get_tree().root.has_meta("body_contact_solver") or not is_instance_valid(get_tree().root.get_meta("body_contact_solver")):
		var contacts := BODY_CONTACTS.new()
		get_tree().root.set_meta("body_contact_solver", contacts)
		get_tree().root.add_child.call_deferred(contacts)
	_configure_visuals()
	queue_redraw()


func _configure_visuals() -> void:
	visual_sprite.sprite_frames = UNIT_VISUALS.frames_for(unit_type, team, is_general)
	visual_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	visual_sprite.material = UNIT_VISUALS.material_for(team)
	visual_sprite.scale = UNIT_VISUALS.DISPLAY_SCALE
	visual_base_scale = visual_sprite.scale
	visual_sprite.offset = UNIT_VISUALS.SPRITE_OFFSET
	visual_sprite.position = UNIT_VISUALS.GROUND_POSITION
	visual_sprite.visible = visual_sprite.sprite_frames != null
	visual_sprite.flip_h = team == 1
	if visual_sprite.visible:
		visual_sprite.play(&"idle")
		var frame := visual_sprite.sprite_frames.get_frame_texture(&"idle", 0)
		var used := frame.get_image().get_used_rect()
		visual_pick_rect = Rect2(Vector2(used.position) - frame.get_size() * 0.5 + visual_sprite.offset, Vector2(used.size))
		visual_sprite.frame = idle_phase % 4


func pick_distance(point: Vector2) -> float:
	var local_point := visual_sprite.to_local(point)
	if visual_sprite.flip_h:
		local_point.x = -local_point.x
	var distance := global_position.distance_to(point)
	# Pick the visible character rather than only its ground/physics anchor.
	# A distance tie-break prefers the nearer body where silhouettes overlap.
	return distance * 0.1 if visual_pick_rect.has_point(local_point) else distance


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
	visual_sprite.scale = visual_base_scale
	visual_sprite.position = UNIT_VISUALS.GROUND_POSITION


func _update_visual_animation() -> void:
	if visual_sprite.sprite_frames == null:
		return
	var wanted: StringName = &"idle"
	var finishing_attack := visual_sprite.animation == &"attack" and visual_sprite.is_playing() and velocity.length_squared() <= 1.0 and not manual_move
	if attack_fx_timer > 0.0 or finishing_attack:
		wanted = &"attack"
	elif velocity.length_squared() > 1.0:
		wanted = &"walk"
	if wanted == &"attack" and _target_is_valid():
		var target_direction := current_target.global_position.x - global_position.x
		if absf(target_direction) > 1.0:
			visual_sprite.flip_h = target_direction < 0.0
	elif absf(velocity.x) > 1.0:
		visual_sprite.flip_h = velocity.x < 0.0
	visual_sprite.speed_scale = clampf(velocity.length() / move_speed, 0.45, 1.5) if wanted == &"walk" else 1.0
	if wanted == &"attack":
		var duration := visual_sprite.sprite_frames.get_frame_count(&"attack") / 10.0
		visual_sprite.speed_scale = maxf(1.0, duration / (attack_interval * 0.9))
	visual_sprite.offset = UNIT_VISUALS.SPRITE_OFFSET
	if visual_sprite.animation != wanted or (wanted != &"attack" and not visual_sprite.is_playing()):
		visual_sprite.play(wanted)


func move_to(point: Vector2, running: bool = false) -> void:
	if routing:
		return
	destination = point
	travel_speed_multiplier = 1.35 if running else 1.0
	manual_move = true
	blocked_time = 0.0
	arrival_wait_timer = 0.0
	attack_fx_timer = 0.0


func set_command(value: int) -> void:
	if routing:
		return
	command_mode = value
	guard_anchor = global_position
	travel_speed_multiplier = 1.0
	autonomous_order = false
	regrouping = false
	retreat_target = null
	current_target = null
	target_scan_timer = 0.0
	focus_targets = []
	charge_bonus_ready = value == Command.CHARGE
	charge_bonus_timer = 0.0
	command_damage_taken_multiplier = 0.8 if value == Command.DEFEND or stance_defending else 1.0
	command_speed_multiplier = 0.8 if value == Command.DEFEND or stance_defending else (1.35 if value == Command.CHARGE else 1.0)
	if value == Command.HOLD or value == Command.DEFEND or value == Command.CHARGE or value == Command.FOCUS_TARGET or value == Command.GUARD:
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
		effect.body_scale = visual_sprite.scale
		effect.body_offset = visual_sprite.offset
		effect.body_flip_h = visual_sprite.flip_h
		effect.body_frames = visual_sprite.sprite_frames
		effect.body_material = visual_sprite.material
		var world: Node = get_parent().get_parent() if get_parent() is BattleSquad else get_parent()
		var ground: Node = world.get_node_or_null("GroundEffects")
		(ground if ground != null else world).add_child(effect)
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
		_move_with_bodies(delta)
		return
	attack_cooldown = maxf(0.0, attack_cooldown - delta)
	charge_bonus_timer = maxf(0.0, charge_bonus_timer - delta)
	if manual_move:
		state = State.MOVING
		_move_toward(destination, delta)
		_move_with_bodies(delta)
		var arrived := global_position.distance_to(destination) <= ARRIVAL_DISTANCE
		if global_position.distance_to(destination) < PERSONAL_SPACE and _destination_occupied():
			arrival_wait_timer += delta
		else:
			arrival_wait_timer = 0.0
		var occupied := arrival_wait_timer > 0.6
		if arrived or occupied:
			if arrived:
				global_position = destination
			manual_move = false
			guard_anchor = global_position
			travel_speed_multiplier = 1.0
			velocity = Vector2.ZERO
			state = State.HOLDING if command_mode == Command.HOLD or command_mode == Command.DEFEND else State.IDLE
		# A player's move takes priority over autonomous attacks and retreat.
		return
	if not combat_enabled:
		state = State.HOLDING if command_mode == Command.HOLD or command_mode == Command.DEFEND else State.IDLE
		velocity = Vector2.ZERO
		_move_with_bodies(delta)
		return
	target_scan_timer -= delta
	if target_scan_timer <= 0.0 or (current_target != null and not _target_is_valid()):
		var candidate := _find_nearest_enemy()
		if not _can_keep_target():
			current_target = candidate
		elif candidate != null and candidate != current_target and global_position.distance_to(current_target.global_position) > get_contact_reach():
			# Reconsider a chase only for a substantial improvement. Preserve an
			# active fight and avoid jitter between nearly equivalent opponents.
			if _target_score(candidate, {}) + TARGET_SWITCH_MARGIN < _target_score(current_target, {}):
				current_target = candidate
		target_scan_timer = 0.4

	var threat := _nearby_melee_threat() if unit_type == UnitType.ARCHER and not manual_move and command_mode != Command.HOLD and command_mode != Command.DEFEND else null
	if _target_is_valid() and global_position.distance_to(current_target.global_position) <= get_contact_reach():
		state = State.ATTACKING
		if threat == null:
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
			_retreat_from(threat, delta)
	elif threat != null:
		state = State.CHASING
		_retreat_from(threat, delta)
	elif _target_is_valid() and command_mode != Command.HOLD:
		state = State.CHASING
		var may_regroup := squad_attached and (command_mode == Command.ADVANCE or autonomous_order)
		if may_regroup and global_position.distance_to(squad_center) > COHESION_LIMIT:
			regrouping = true
		if not may_regroup or global_position.distance_to(squad_center) < 110.0:
			regrouping = false
		var goal := squad_center if regrouping else current_target.global_position
		if _guards_position():
			var leash := 60.0 if command_mode == Command.DEFEND else 95.0
			goal = guard_anchor + (goal - guard_anchor).limit_length(leash)
		_move_toward(goal, delta)
	elif _guards_position() and global_position.distance_to(guard_anchor) > 1.0:
		state = State.MOVING
		_move_toward(guard_anchor, delta)
	else:
		state = State.HOLDING if command_mode == Command.HOLD or command_mode == Command.DEFEND else State.IDLE
		velocity = Vector2.ZERO
	_move_with_bodies(delta)


func _movement_speed() -> float:
	# Full Attack accelerates combat pursuit. Ground movement still obeys
	# the player's walk/run choice, without stacking two charge bonuses.
	var command_factor := command_speed_multiplier
	if manual_move and command_mode == Command.CHARGE and not stance_defending:
		command_factor = 1.0
	return move_speed * formation_speed_multiplier * command_factor * (travel_speed_multiplier if manual_move else 1.0)


func _move_toward(point: Vector2, delta: float) -> void:
	var offset := point - global_position
	var distance := offset.length()
	if distance <= ARRIVAL_DISTANCE:
		velocity = Vector2.ZERO
		return
	var speed := _movement_speed()
	var accelerating_speed := move_toward(velocity.length(), speed, move_speed * 8.0 * delta)
	# Limit the final step to the remaining distance, including on slow frames.
	velocity = offset / distance * minf(accelerating_speed, distance / maxf(delta, 0.0001))


func _move_with_bodies(delta: float) -> void:
	var requested := velocity
	var steering := Vector2.ZERO
	var direction := requested.normalized()
	var side := Vector2(-direction.y, direction.x)
	for node in get_tree().get_nodes_in_group("battle_units"):
		var other := node as BattleUnit
		if other == self or not other.is_alive():
			continue
		var offset := other.global_position - global_position
		var distance := offset.length()
		if distance > 80.0:
			continue
		# A small personal-space buffer settles crowded allies without moving
		# soldiers that already have comfortable formation spacing.
		if other.team == team and distance < PERSONAL_SPACE and distance > 0.01:
			steering -= offset / distance * (PERSONAL_SPACE - distance) * 5.0
		if requested.length_squared() < 1.0 or other == current_target and not manual_move:
			continue
		var ahead := offset.dot(direction)
		var lateral := offset.dot(side)
		var lookahead := PERSONAL_SPACE + requested.length() * maxf(0.25, delta * 1.5)
		if ahead > 0.0 and ahead < lookahead and absf(lateral) < PERSONAL_SPACE:
			# Both head-on soldiers pass on their own right. Off-centre bodies
			# are passed on the nearer free side, instead of pushing through.
			var pass_side := -signf(lateral) if absf(lateral) > 3.0 else 1.0
			var weight := (1.0 - ahead / lookahead) * (1.0 - absf(lateral) / PERSONAL_SPACE)
			steering += side * pass_side * requested.length() * weight * 2.5
	velocity += steering
	var maximum_speed := _movement_speed() * (1.4 if routing else 1.0)
	velocity = velocity.limit_length(maximum_speed)
	var before := global_position
	move_and_slide()
	if not routing:
		global_position = global_position.clamp(FIELD_BOUNDS.position, FIELD_BOUNDS.end)
	var displacement := global_position - before
	velocity = displacement / maxf(delta, 0.0001)
	if requested.length() > 10.0 and velocity.length() < 8.0:
		blocked_time += delta
	else:
		blocked_time = 0.0
	if blocked_time > 0.6 and state == State.CHASING:
		current_target = null
		target_scan_timer = 0.0
		blocked_time = 0.0


func _destination_occupied() -> bool:
	for node in get_tree().get_nodes_in_group("battle_units"):
		var other := node as BattleUnit
		if other != self and other.is_alive() and not other.manual_move and other.global_position.distance_to(destination) < BODY_RADIUS * 2.0:
			return true
	return false


func _nearby_melee_threat() -> BattleUnit:
	# Keep retreating to a safe firing distance instead of alternating walk
	# and attack on every crossing of the original panic threshold.
	if is_instance_valid(retreat_target) and retreat_target.is_alive() and not retreat_target.routing and global_position.distance_to(retreat_target.global_position) < ARCHER_SAFE_RANGE:
		return retreat_target
	retreat_target = null
	var closest: BattleUnit
	var nearest := ARCHER_RETREAT_RANGE
	for node in get_tree().get_nodes_in_group("team_%d" % (1 - team)):
		var enemy := node as BattleUnit
		if enemy == null or not enemy.is_alive() or enemy.routing or (enemy.unit_type == UnitType.ARCHER and not enemy.is_general):
			continue
		var distance := global_position.distance_to(enemy.global_position)
		if distance < nearest:
			nearest = distance
			closest = enemy
	retreat_target = closest
	return closest


func _retreat_from(enemy: BattleUnit, delta: float) -> void:
	state = State.CHASING
	var direction := (global_position - enemy.global_position).normalized()
	for node in get_tree().get_nodes_in_group("team_%d" % (1 - team)):
		var threat := node as BattleUnit
		if threat == enemy or not threat.is_alive() or threat.routing or threat.unit_type == UnitType.ARCHER:
			continue
		var offset := global_position - threat.global_position
		if offset.length() < ARCHER_SAFE_RANGE and offset.length() > 0.01:
			direction += offset.normalized() * (1.0 - offset.length() / ARCHER_SAFE_RANGE)
	direction = direction.normalized()
	if direction == Vector2.ZERO:
		direction = Vector2.LEFT if team == 0 else Vector2.RIGHT
	var retreat_point := global_position + direction * 100.0
	retreat_point = retreat_point.clamp(FIELD_BOUNDS.position, FIELD_BOUNDS.end)
	if retreat_point.distance_to(global_position) < 4.0:
		var tangent := Vector2(-direction.y, direction.x)
		retreat_point = (global_position + tangent * 100.0).clamp(FIELD_BOUNDS.position, FIELD_BOUNDS.end)
		if retreat_point.distance_to(global_position) < 4.0:
			retreat_point = (global_position - tangent * 100.0).clamp(FIELD_BOUNDS.position, FIELD_BOUNDS.end)
	_move_toward(retreat_point, delta)


func get_contact_reach() -> float:
	# A sword can reach the opposing body at contact. Its old centre-based
	# range must not leave enlarged colliders holding melee attackers apart.
	return attack_range if unit_type == UnitType.ARCHER else maxf(attack_range, BODY_RADIUS * 2.0 + 3.0)


func _target_is_valid() -> bool:
	return is_instance_valid(current_target) and current_target.is_alive() and not current_target.routing


func _can_keep_target() -> bool:
	if not _target_is_valid():
		return false
	if command_mode == Command.FOCUS_TARGET or (command_mode == Command.CHARGE and not focus_targets.is_empty()):
		return focus_targets.has(current_target)
	if _guards_position() and guard_anchor.distance_to(current_target.global_position) > _guard_detection_range():
		return false
	var range_limit := get_contact_reach() if command_mode == Command.HOLD else (_guard_detection_range() if _guards_position() else maxf(DETECTION_RANGE, attack_range) + 24.0)
	return global_position.distance_to(current_target.global_position) <= range_limit


func _find_nearest_enemy() -> BattleUnit:
	var closest: BattleUnit
	var nearest_distance := get_contact_reach() if command_mode == Command.HOLD else (_guard_detection_range() if _guards_position() else maxf(DETECTION_RANGE, attack_range))
	var candidates: Array[Node] = get_tree().get_nodes_in_group("team_%d" % (1 - team))
	if command_mode == Command.FOCUS_TARGET or (command_mode == Command.CHARGE and not focus_targets.is_empty()):
		candidates.assign(focus_targets)
		nearest_distance = INF
	var range_limit := nearest_distance
	nearest_distance = INF
	var claims := {}
	guarded_allies.clear()
	for ally_node in get_tree().get_nodes_in_group("team_%d" % team):
		var ally := ally_node as BattleUnit
		if ally.is_alive() and not ally.routing and (ally.unit_type == UnitType.ARCHER or ally.is_general):
			guarded_allies.append(ally)
		if ally != self and ally._target_is_valid():
			claims[ally.current_target] = claims.get(ally.current_target, 0) + 1
	for node in candidates:
		var enemy := node as BattleUnit
		if enemy == null or not enemy.is_alive() or enemy.routing:
			continue
		if _guards_position() and guard_anchor.distance_to(enemy.global_position) > _guard_detection_range():
			continue
		var distance := global_position.distance_to(enemy.global_position)
		var score := _target_score(enemy, claims)
		if distance <= range_limit and score < nearest_distance:
			nearest_distance = score
			closest = enemy
	return closest


func _guards_position() -> bool:
	return command_mode == Command.GUARD or command_mode == Command.DEFEND


func _guard_detection_range() -> float:
	return maxf(attack_range, 90.0 if command_mode == Command.DEFEND else 130.0)


func _target_score(enemy: BattleUnit, claims: Dictionary) -> float:
	var distance := global_position.distance_to(enemy.global_position)
	var score := distance + float(claims.get(enemy, 0)) * 18.0
	# Match existing damage counters. Distance still dominates a distant
	# opportunity, and explicit focus restricts the candidate list first.
	if unit_type == UnitType.SWORDSMAN and enemy.unit_type == UnitType.SPEARMAN:
		score -= 36.0
	elif unit_type == UnitType.AXEMAN and enemy.unit_type == UnitType.SWORDSMAN:
		score -= 36.0
	elif unit_type == UnitType.ARCHER and enemy.unit_type == UnitType.AXEMAN:
		score -= 36.0
	elif unit_type == UnitType.SPEARMAN and enemy.command_mode == Command.CHARGE:
		score -= 40.0
	if unit_type != UnitType.ARCHER and distance <= get_contact_reach() + 4.0:
		score -= 90.0 # Deal with someone at the shield before a distant matchup.
	if unit_type != UnitType.ARCHER and enemy.unit_type != UnitType.ARCHER:
		for ally in guarded_allies:
			if is_instance_valid(ally) and ally.is_alive() and not ally.routing and ally.global_position.distance_to(enemy.global_position) < 100.0:
				score -= 40.0
				break
	score -= (1.0 - enemy.current_hp / enemy.max_hp) * 12.0
	return score


func _draw() -> void:
	var facing := -1.0 if visual_sprite.flip_h else 1.0
	# A soft ground shadow anchors the character sprite to the field.
	draw_set_transform(Vector2(1, 10), 0.0, Vector2(1.35, 0.38))
	draw_circle(Vector2.ZERO, 16.0, Color(0.13, 0.19, 0.12, 0.09))
	draw_circle(Vector2.ZERO, 10.0, Color(0.12, 0.17, 0.11, 0.16))
	draw_set_transform(Vector2.ZERO)
	if is_general and selected:
		draw_arc(Vector2.ZERO, GENERAL_RADIUS, 0.0, TAU, 64, Color(0.95, 0.77, 0.38, 0.25), 2.0)
	if selected:
		draw_set_transform(Vector2(0, 9), 0.0, Vector2(1.0, 0.45))
		draw_arc(Vector2.ZERO, 21.0, 0.0, TAU, 28, Color("f6df85"), 2.5)
		draw_set_transform(Vector2.ZERO)
	if attack_fx_timer > 0.0 and unit_type != UnitType.ARCHER:
		draw_arc(Vector2(facing * 18.0, -8), 12.0, -1.6, 0.6, 12, Color(0.96, 0.88, 0.68, attack_fx_timer / 0.19 * 0.72), 1.7)
	if shot_trace_timer > 0.0:
		var start := Vector2(facing * 16.0, -8.0)
		var direction := (shot_trace_end - start).normalized()
		var tip := shot_trace_end
		var side := Vector2(-direction.y, direction.x)
		var alpha := shot_trace_timer / 0.12
		draw_line(start, tip, Color(0.91, 0.85, 0.67, alpha * 0.8), 1.6)
		draw_colored_polygon(PackedVector2Array([tip, tip - direction * 8.0 + side * 2.5, tip - direction * 8.0 - side * 2.5]), Color(0.94, 0.9, 0.75, alpha * 0.8))
	if hit_flash_timer > 0.0:
		draw_arc(Vector2(0, -7), 15.0 + (0.18 - hit_flash_timer) * 30.0, 0.0, TAU, 20, Color(0.98, 0.88, 0.68, hit_flash_timer / 0.18 * 0.45), 1.5)
	if routing:
		draw_arc(Vector2(0, 9), 16.0, 0.0, TAU, 20, Color("ded7bd"), 1.5)
	if selected or is_general or current_hp < max_hp:
		_draw_health_bar()


func _draw_health_bar() -> void:
	draw_rect(Rect2(-13, -54, 26, 4), Color("24312e"))
	draw_rect(Rect2(-12, -53, 24.0 * current_hp / max_hp, 2), Color("a8d47d") if team == 0 else Color("e6aa7a"))
