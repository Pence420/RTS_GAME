extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var scene: PackedScene = load("res://scenes/unit.tscn")
	var actor := scene.instantiate() as BattleUnit
	actor.position = Vector2(500, 450)
	root.add_child(actor)
	var sprite := actor.visual_sprite
	var ready_pose := sprite.sprite_frames.get_frame_texture(&"idle", 0)
	var local_boot := Vector2(0, ready_pose.get_image().get_used_rect().end.y - ready_pose.get_height() / 2.0 + sprite.offset.y)
	var boot_y := (sprite.global_transform * local_boot).y
	for frame in range(30):
		await physics_frame
		if actor.global_position != Vector2(500, 450):
			_fail("Stationary soldier drifted in world space")
			return
		if sprite.animation != &"idle" or not sprite.is_playing():
			_fail("Idle soldier does not play the authored MiniFolks idle animation")
			return
		if absf((sprite.global_transform * local_boot).y - boot_y) > 0.2:
			_fail("Idle breathing lifts the soldier's boots off the ground")
			return
	actor.state = BattleUnit.State.CHASING
	actor.velocity = Vector2.ZERO
	actor.call("_update_visual_animation")
	if sprite.animation != &"idle":
		_fail("Stationary chase state plays a walk animation")
		return
	var enemy := scene.instantiate() as BattleUnit
	enemy.team = 1
	enemy.position = actor.position + Vector2(20, 0)
	root.add_child(enemy)
	actor.combat_enabled = true
	actor.current_target = enemy
	actor.attack_fx_timer = 0.18
	actor.attack_cooldown = 0.5
	actor.move_to(actor.position + Vector2(-100, 0))
	var initial_x := actor.position.x
	var enemy_hp := enemy.current_hp
	await physics_frame
	await physics_frame
	if actor.position.x >= initial_x or enemy.current_hp != enemy_hp:
		_fail("An explicit move cannot disengage from an enemy in attack range")
		return
	actor.call("_update_visual_animation")
	if not sprite.flip_h or sprite.animation != &"walk" or actor.attack_cooldown >= 0.5:
		_fail("Moving left did not turn the soldier or play walking")
		return
	actor.combat_enabled = false
	actor.position = Vector2(500, 450)
	# Keep the exact-arrival destination clear of the enemy body.
	enemy.position = Vector2(600, 450)
	var normal_tick_rate := Engine.physics_ticks_per_second
	Engine.physics_ticks_per_second = 10
	actor.move_to(Vector2(505, 450))
	await physics_frame
	await physics_frame
	Engine.physics_ticks_per_second = normal_tick_rate
	if actor.position.distance_to(Vector2(505, 450)) > 0.15 or actor.manual_move or actor.velocity != Vector2.ZERO:
		_fail("A slow frame overshoots a short move or leaves stale moving state")
		return
	actor.combat_enabled = true
	actor.set_command(BattleUnit.Command.ADVANCE)
	enemy.position = actor.position + Vector2(150, 0)
	var other := scene.instantiate() as BattleUnit
	other.team = 1
	other.position = actor.position + Vector2(140, 0)
	root.add_child(other)
	actor.current_target = enemy
	actor.target_scan_timer = 0.0
	actor._physics_process(1.0 / 60.0)
	if actor.current_target != enemy:
		_fail("A small enemy distance change switches a valid target and jitters the chase")
		return
	print("Unit motion passed: calm idle, stationary animation, responsive disengage, facing, exact arrival, and stable target.")
	quit()


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
