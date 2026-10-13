extends SceneTree

const MIN_BODY_DISTANCE := BattleUnit.BODY_RADIUS * 2.0 - 0.6


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	Engine.time_scale = 4.0
	var unit_scene: PackedScene = load("res://scenes/unit.tscn")
	var left := unit_scene.instantiate() as BattleUnit
	var right := unit_scene.instantiate() as BattleUnit
	left.position = Vector2(700, 450)
	right.position = Vector2(900, 450)
	root.add_child(left)
	root.add_child(right)
	left.move_to(Vector2(900, 450))
	right.move_to(Vector2(700, 450))
	for tick in range(180):
		await physics_frame
		if left.position.distance_to(right.position) < MIN_BODY_DISTANCE:
			_fail("Two moving soldiers pass through each other's bodies")
			return
		if not left.manual_move and not right.manual_move:
			break
	if left.manual_move or right.manual_move:
		_fail("Two soldiers avoid overlap but cannot pass and finish their move")
		return
	right.move_to(left.global_position)
	for tick in range(180):
		await physics_frame
		if left.position.distance_to(right.position) < MIN_BODY_DISTANCE:
			_fail("A move into an occupied destination penetrates the stationary body")
			return
		if not right.manual_move:
			break
	if right.manual_move or right.position.distance_to(left.position) > BattleUnit.PERSONAL_SPACE + 1.0:
		_fail("Occupied destination leaves a soldier walking forever instead of stopping at contact")
		return
	left.queue_free()
	right.queue_free()
	await process_frame
	await process_frame
	var squad: BattleSquad = load("res://scenes/squad.tscn").instantiate()
	squad.position = Vector2(800, 450)
	root.add_child(squad)
	for formation in [BattleSquad.Formation.COLUMN, BattleSquad.Formation.SHIELD_WALL, BattleSquad.Formation.WEDGE, BattleSquad.Formation.LINE]:
		squad.set_formation(formation)
		var settled := false
		for tick in range(240):
			await physics_frame
			if not _bodies_clear(squad.units):
				_fail("Soldiers overlap while assembling " + squad.get_formation_name())
				return
			settled = true
			for unit in squad.units:
				settled = settled and not unit.manual_move and unit.global_position.distance_to(unit.destination) < 1.0
			if settled:
				break
		if not settled or squad.get_center().distance_to(squad.ordered_center) > 2.0:
			_fail("Formation jams or gathers on one side instead of filling all its slots: " + squad.get_formation_name())
			return
	squad.queue_free()
	await process_frame
	await process_frame
	var blue: BattleSquad = load("res://scenes/squad.tscn").instantiate()
	var red: BattleSquad = load("res://scenes/squad.tscn").instantiate()
	blue.position = Vector2(650, 450)
	red.position = Vector2(950, 450)
	red.team = 1
	root.add_child(blue)
	root.add_child(red)
	for soldier in blue.units + red.units:
		soldier.attack_cooldown = 1000.0
	blue.begin_battle()
	red.begin_battle()
	var attacking := false
	for tick in range(180):
		await physics_frame
		if not _bodies_clear(blue.units + red.units):
			_fail("Opposing armies interpenetrate when their front ranks meet")
			return
		for soldier in blue.units + red.units:
			attacking = attacking or soldier.state == BattleUnit.State.ATTACKING
	if not attacking:
		_fail("Body collision stops soldiers outside their weapon reach")
		return
	print("Collision passed: soldiers pass around bodies, all four formations fill their slots, and armies make physical contact within weapon reach.")
	Engine.time_scale = 1.0
	quit()


func _bodies_clear(units: Array) -> bool:
	for first in range(units.size()):
		for second in range(first + 1, units.size()):
			if units[first].global_position.distance_to(units[second].global_position) < MIN_BODY_DISTANCE:
				print("Overlap: ", units[first].global_position, " / ", units[second].global_position, " distance ", units[first].global_position.distance_to(units[second].global_position))
				return false
	return true


func _fail(message: String) -> void:
	push_error(message)
	Engine.time_scale = 1.0
	quit(1)
