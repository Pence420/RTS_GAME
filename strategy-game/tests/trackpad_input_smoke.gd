extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(1152, 648)
	var battle = load("res://scenes/battle.tscn").instantiate()
	root.add_child(battle)
	await process_frame
	await process_frame
	var squad: BattleSquad = battle.player_squads[0]
	var other: BattleSquad = battle.player_squads[1]
	var soldier := other.units[0]
	var frame := soldier.visual_sprite.sprite_frames.get_frame_texture(&"idle", 0)
	var rect := frame.get_image().get_used_rect()
	var local_head := Vector2(rect.position) + Vector2(rect.size) * Vector2(0.5, 0.3) - frame.get_size() * 0.5 + soldier.visual_sprite.offset
	var head := soldier.visual_sprite.get_global_transform_with_canvas() * local_head
	var select_click := InputEventMouseButton.new()
	select_click.button_index = MOUSE_BUTTON_LEFT
	select_click.position = head
	select_click.pressed = true
	root.push_input(select_click, true)
	select_click = select_click.duplicate()
	select_click.pressed = false
	root.push_input(select_click, true)
	if battle.selected_squad != other:
		push_error("A visible soldier head cannot be selected before giving a touchpad context order")
		quit(1)
		return
	for control_click in [false, true]:
		battle._select_at(squad.units[0].global_position)
		var point := Vector2(550, 500) if not control_click else Vector2(650, 550)
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT if control_click else MOUSE_BUTTON_RIGHT
		event.ctrl_pressed = control_click
		event.position = battle.get_global_transform_with_canvas() * point
		event.pressed = true
		root.push_input(event, true)
		event = event.duplicate()
		event.pressed = false
		event.ctrl_pressed = false # Modifier may be released before mouse-up.
		root.push_input(event, true)
		await process_frame
		if battle.selected_squad != squad or squad.ordered_center.distance_to(point) > 1.0 or not squad.units[0].manual_move:
			push_error("Trackpad context move fails through viewport input: Control-click=%s, selected=%s, goal=%s, expected=%s" % [control_click, battle.selected_squad, squad.ordered_center, point])
			quit(1)
			return
	var enemy: BattleSquad = battle.enemy_squads[0]
	var target := enemy.units[0]
	var enemy_frame := target.visual_sprite.sprite_frames.get_frame_texture(&"idle", 0)
	var enemy_rect := enemy_frame.get_image().get_used_rect()
	var enemy_head := Vector2(enemy_rect.position) + Vector2(enemy_rect.size) * Vector2(0.5, 0.3) - enemy_frame.get_size() * 0.5 + target.visual_sprite.offset
	if target.visual_sprite.flip_h:
		enemy_head.x = -enemy_head.x
	var attack := InputEventMouseButton.new()
	attack.button_index = MOUSE_BUTTON_RIGHT
	attack.pressed = true
	attack.position = target.visual_sprite.get_global_transform_with_canvas() * enemy_head
	root.push_input(attack, true)
	attack = attack.duplicate()
	attack.pressed = false
	root.push_input(attack, true)
	if squad.target_squad != enemy or squad.units[0].manual_move:
		push_error("Right-click on the visible enemy sprite fails to give an attack order")
		quit(1)
		return
	print("Trackpad input passed: secondary click and Control-click move the selected squad, and enemy sprite clicks attack through real viewport event dispatch.")
	quit()
