extends CanvasLayer

signal squad_chosen(squad: BattleSquad)
signal general_chosen

const VISUALS = preload("res://scripts/unit_visuals.gd")
const TRAY_NODES := ["OrdersPanel", "FormationTitle", "FormationButtons", "CommandTitle", "CommandButtons", "PointerTitle", "PointerButtons"]
const ORDER_ICONS := {
	"FormationButtons/Line": ["line", "Line · Balanced two-rank formation"],
	"FormationButtons/Column": ["column", "Column · Narrow formation, five ranks"],
	"FormationButtons/ShieldWall": ["shield_wall", "Shield Wall · Less damage taken, slower movement"],
	"FormationButtons/Wedge": ["wedge", "Wedge · More attack damage, less protection"],
	"CommandButtons/FullAttack": ["charge", "Full Attack · Aggressive pursuit and charges; right-click an enemy to choose the target"],
	"CommandButtons/Defend": ["defend", "Defend · Guard the formation, counter nearby enemies, and retain protection while repositioning"],
	"PointerButtons/Select": ["select", "Select · Click a blue squad; hold and drag it to move"],
	"PointerButtons/Move": ["move", "Move · Click a destination for the selected squad or General"],
	"PointerButtons/Target": ["target", "Target · Click a red squad to choose an enemy"],
}

var squads: Dictionary = {}
var general: BattleUnit
var orders_open := false
var portrait_cache: Dictionary = {}


func _ready() -> void:
	for path in ORDER_ICONS:
		var button: Button = get_node(path)
		button.text = ""
		button.icon = load("res://assets/ui/orders/%s.svg" % ORDER_ICONS[path][0])
		button.tooltip_text = ORDER_ICONS[path][1]
		button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.expand_icon = true
		button.add_theme_constant_override("icon_max_width", 26)
		button.custom_minimum_size = Vector2(46, 46)
	$OrdersToggle.pressed.connect(_toggle_orders)
	$GeneralSlot.pressed.connect(func(): general_chosen.emit())
	$GeneralSlot.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	for letter in ["A", "B", "C", "D"]:
		var button: Button = get_node("SquadSlots/" + letter)
		button.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		button.pressed.connect(_choose_squad.bind(letter))
		var badge := Label.new()
		badge.text = letter
		badge.position = Vector2(5, 2)
		badge.add_theme_font_size_override("font_size", 10)
		badge.add_theme_color_override("font_color", Color("ded8b9"))
		badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(badge)
	$CommandButtons.move_child($CommandButtons/Defend, 0)
	set_orders_open(false)


func bind_army(army: Array[BattleSquad], commander: BattleUnit) -> void:
	for squad in army:
		squads[squad.squad_id.get_slice(" ", 1)] = squad
	general = commander
	$GeneralSlot.icon = _portrait(0, true)


func refresh(selected: BattleSquad, selected_commander: BattleUnit, blue_count: int, red_count: int) -> void:
	$BlueStrength.value = blue_count
	$RedStrength.value = red_count
	for letter in ["A", "B", "C", "D"]:
		var button: Button = get_node("SquadSlots/" + letter)
		var squad = squads.get(letter)
		button.disabled = not is_instance_valid(squad) or squad.units.is_empty() or squad.routing
		button.button_pressed = is_instance_valid(squad) and squad == selected
		if is_instance_valid(squad):
			button.icon = _portrait(squad.unit_type, false)
			button.tooltip_text = "%s · %s\n%d/10 soldiers · HP %d%%\nMorale %d · %s\n%s · %s" % [squad.squad_id, squad.get_unit_type_name(), squad.units.size(), roundi(squad.get_health_ratio() * 100.0), roundi(squad.get_effective_morale()), squad.get_morale_state(), squad.get_command_name(), squad.get_formation_name()]
		else:
			button.tooltip_text = "Blue %s · Lost" % letter
	$GeneralSlot.disabled = not is_instance_valid(general) or not general.is_alive()
	$GeneralSlot.button_pressed = is_instance_valid(general) and general == selected_commander
	$GeneralSlot.tooltip_text = "General · Rally aura\n+10 morale · +5% damage" if is_instance_valid(general) else "General · Lost"


func set_orders_open(value: bool) -> void:
	orders_open = value
	for node_name in TRAY_NODES:
		get_node(node_name).visible = value
	$OrdersToggle.button_pressed = value


func blocks_point(point: Vector2) -> bool:
	for node_name in ["TopBar", "BottomDock", "MenuButton", "StartBattle"]:
		var control: Control = get_node(node_name)
		var hit_rect := control.get_global_rect()
		if node_name == "TopBar":
			hit_rect = hit_rect.grow(8.0) # Include the medallion above and below its frame.
		if control.visible and hit_rect.has_point(point):
			return true
	return orders_open and $OrdersPanel.get_global_rect().has_point(point)


func _toggle_orders() -> void:
	set_orders_open(not orders_open)


func _choose_squad(letter: String) -> void:
	var squad = squads.get(letter)
	if is_instance_valid(squad) and not squad.units.is_empty() and not squad.routing:
		squad_chosen.emit(squad)


func _portrait(unit_type: int, is_general: bool) -> Texture2D:
	var key := 4 if is_general else unit_type
	if portrait_cache.has(key):
		return portrait_cache[key]
	var frame := VISUALS.frames_for(unit_type, 0, is_general).get_frame_texture(&"idle", 0) as AtlasTexture
	var bounds := frame.get_image().get_used_rect()
	var portrait := AtlasTexture.new()
	portrait.atlas = frame.atlas
	portrait.region = Rect2(frame.region.position + Vector2(bounds.position), Vector2(bounds.size))
	portrait.filter_clip = true
	portrait_cache[key] = portrait
	return portrait
