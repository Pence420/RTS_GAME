extends Node

# CharacterBody motion is swept by Godot. Resolve the remaining moving-body
# contacts together after all soldiers move, so update order cannot compress
# the front rank into overlapping bodies when both armies advance.
func _ready() -> void:
	process_physics_priority = 100


func _physics_process(_delta: float) -> void:
	var units := get_tree().get_nodes_in_group("battle_units")
	var contacts: Array[Vector2i] = []
	var neighborhood := BattleUnit.BODY_RADIUS * 2.0 + 8.0
	for first in range(units.size()):
		if not units[first].is_alive():
			continue
		for second in range(first + 1, units.size()):
			if units[second].is_alive() and units[first].global_position.distance_squared_to(units[second].global_position) < neighborhood * neighborhood:
				contacts.append(Vector2i(first, second))
	for iteration in range(12):
		var corrected := false
		for pair in contacts:
			var first: BattleUnit = units[pair.x]
			var second: BattleUnit = units[pair.y]
			var offset := second.global_position - first.global_position
			var distance := offset.length()
			var gap := BattleUnit.BODY_RADIUS * 2.0 + 0.08 - distance
			if gap <= 0.01:
				continue
			var normal := offset / distance if distance > 0.001 else Vector2.RIGHT
			var first_mobile := first.manual_move or first.routing or first.state == BattleUnit.State.CHASING
			var second_mobile := second.manual_move or second.routing or second.state == BattleUnit.State.CHASING
			var first_share := 0.5 if first_mobile == second_mobile else (1.0 if first_mobile else 0.0)
			first.global_position -= normal * gap * first_share
			second.global_position += normal * gap * (1.0 - first_share)
			if not first.routing:
				first.global_position = first.global_position.clamp(BattleUnit.FIELD_BOUNDS.position, BattleUnit.FIELD_BOUNDS.end)
			if not second.routing:
				second.global_position = second.global_position.clamp(BattleUnit.FIELD_BOUNDS.position, BattleUnit.FIELD_BOUNDS.end)
			corrected = true
		if not corrected:
			break
	if units.is_empty():
		queue_free()
