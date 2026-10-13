extends RefCounted

const SIZE := Vector2(2400, 1400)
const VIEW_BOUNDS := Rect2(Vector2(-576, -384), SIZE + Vector2(1152, 768))
const UNIT_BOUNDS := Rect2(Vector2(64, 64), SIZE - Vector2(128, 128))
const BLUE_DEPLOYMENT := Rect2(UNIT_BOUNDS.position, Vector2(SIZE.x / 2.0 - 60.0 - UNIT_BOUNDS.position.x, UNIT_BOUNDS.size.y))
const RED_DEPLOYMENT := Rect2(Vector2(SIZE.x / 2.0 + 60.0, UNIT_BOUNDS.position.y), Vector2(UNIT_BOUNDS.end.x - SIZE.x / 2.0 - 60.0, UNIT_BOUNDS.size.y))
# Keep the existing skirmish distances and readable starting camera framing.
const START_OFFSET := (SIZE - Vector2(1600, 900)) / 2.0
