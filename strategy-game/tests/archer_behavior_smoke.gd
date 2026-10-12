extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var unit_scene: PackedScene = load("res://scenes/unit.tscn")
	var archer: BattleUnit = unit_scene.instantiate()
	archer.team = 0
	archer.configure_type(BattleUnit.UnitType.ARCHER)
	archer.position = Vector2(300, 450)
	root.add_child(archer)
	var foe: BattleUnit = unit_scene.instantiate()
	foe.team = 1
	foe.position = Vector2(340, 450)
	root.add_child(foe)
	archer.combat_enabled = true
	var starting_distance := archer.global_position.distance_to(foe.global_position)
	var starting_hp := foe.current_hp
	for frame in range(30):
		await physics_frame
	if archer.global_position.distance_to(foe.global_position) <= starting_distance:
		_fail("Archer did not retreat from a nearby melee unit.")
		return
	if foe.current_hp >= starting_hp:
		_fail("Archer did not fire while retreating.")
		return
	archer.global_position = Vector2(22, 450)
	foe.global_position = Vector2(42, 450)
	for frame in range(30):
		await physics_frame
	if archer.global_position.x < 19.0 or archer.global_position.x > 1581.0:
		_fail("Archer retreated outside the battlefield.")
		return
	print("Archer behavior smoke passed: ranged attack and bounded retreat.")
	quit()


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
