extends SceneTree

const FIELD = preload("res://scripts/battle_field.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(1152, 648)
	var battle = load("res://scenes/battle.tscn").instantiate()
	root.add_child(battle)
	await process_frame
	if battle.FIELD_SIZE != Vector2(2400, 1400) or battle.battle_camera.FIELD_SIZE != battle.FIELD_SIZE or battle.get_node("Terrain").FIELD_SIZE != battle.FIELD_SIZE:
		_fail("Terrain and camera do not share the expanded battlefield dimensions")
		return
	var squad: BattleSquad = battle.player_squads[0]
	battle._select_at(squad.units[0].global_position)
	for formation in [BattleSquad.Formation.LINE, BattleSquad.Formation.COLUMN, BattleSquad.Formation.SHIELD_WALL, BattleSquad.Formation.WEDGE]:
		squad.set_formation(formation)
		for point in [Vector2(-1000, -1000), Vector2(9999, 9999)]:
			battle._issue_move(point)
			for soldier in squad.units:
				if not FIELD.BLUE_DEPLOYMENT.has_point(soldier.destination):
					_fail("Deployment clamp lets a formation slot leave the blue placement zone")
					return
	battle._select_at(battle.player_general.global_position)
	battle._issue_move(Vector2(9999, -1000))
	if not FIELD.BLUE_DEPLOYMENT.has_point(battle.player_general.destination):
		_fail("General can leave its deployment placement zone")
		return
	battle._start_battle()
	battle._select_at(squad.units[0].global_position)
	battle._issue_move(Vector2(2200, 1250))
	if squad.ordered_center.distance_to(Vector2(2200, 1250)) > 1.0:
		_fail("An old hidden inner rectangle still blocks movement on the expanded map")
		return
	for soldier in squad.units:
		if not FIELD.UNIT_BOUNDS.has_point(soldier.destination):
			_fail("Battle movement places a formation outside the battlefield")
			return
	var camera: Camera2D = battle.battle_camera
	camera.pan_by_screen_delta(Vector2(100000, 0))
	var half_width := root.size.x / (2.0 * camera.zoom.x)
	if camera.position.x < FIELD.VIEW_BOUNDS.position.x + half_width - 1.0:
		_fail("Camera exposes ground outside the left scenery edge")
		return
	camera.pan_by_screen_delta(Vector2(-100000, 0))
	if camera.position.x > FIELD.VIEW_BOUNDS.end.x - half_width + 1.0:
		_fail("Camera exposes ground outside the right scenery edge")
		return
	print("Battlefield bounds passed: shared larger map, all four deployment formations, general limits, full battle movement, and camera edges.")
	quit()

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
