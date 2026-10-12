extends Control

signal close_requested
signal restart_requested
signal main_menu_requested
signal squad_selected(index: int)
signal unit_type_changed(index: int, unit_type: int)

const TYPE_ROLES := [
	"Balanced melee · dependable front line",
	"Long reach · brace to stop charges",
	"Heavy strikes · breaks armored lines",
	"Ranged fire · pressures slow axemen"
]

@onready var army_page: Control = $Center/Card/ArmyPage
@onready var guide_page: Control = $Center/Card/GuidePage
@onready var rows: VBoxContainer = $Center/Card/ArmyPage/Rows
@onready var army_tab: Button = $Center/Card/ArmyTab
@onready var guide_tab: Button = $Center/Card/GuideTab
@onready var phase_note: Label = $Center/Card/PhaseNote


func _ready() -> void:
	$Center/Card/ContinueButton.pressed.connect(func() -> void: close_requested.emit())
	$Center/Card/RestartButton.pressed.connect(func() -> void: restart_requested.emit())
	$Center/Card/MainMenuButton.pressed.connect(func() -> void: main_menu_requested.emit())
	army_tab.pressed.connect(_show_army)
	guide_tab.pressed.connect(_show_guide)
	for index in range(4):
		var row := rows.get_child(index)
		var selector: OptionButton = row.get_node("Type")
		for unit_type in range(BattleUnit.TYPE_NAMES.size()):
			selector.add_item(BattleUnit.TYPE_NAMES[unit_type], unit_type)
		selector.item_selected.connect(_type_selected.bind(index))
		row.get_node("Select").pressed.connect(_select_squad.bind(index))
	_show_army()


func _input(event: InputEvent) -> void:
	if visible and event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		close_requested.emit()
		get_viewport().set_input_as_handled()


func show_menu(squads: Array[BattleSquad], battle_started: bool) -> void:
	phase_note.text = "SQUAD TYPES LOCKED · battle in progress" if battle_started else "CHOOSE YOUR FOUR SQUADS · before battle"
	for index in range(4):
		var row := rows.get_child(index)
		var present := index < squads.size()
		row.visible = present
		if not present:
			continue
		var squad := squads[index]
		row.get_node("Name").text = squad.squad_id.to_upper()
		var selector: OptionButton = row.get_node("Type")
		selector.select(squad.unit_type)
		selector.disabled = battle_started
		row.get_node("Role").text = TYPE_ROLES[squad.unit_type]
		row.get_node("Select").disabled = squad.routing
	_show_army()
	show()


func _type_selected(unit_type: int, index: int) -> void:
	var selector: OptionButton = rows.get_child(index).get_node("Type")
	if selector.disabled:
		return
	rows.get_child(index).get_node("Role").text = TYPE_ROLES[unit_type]
	unit_type_changed.emit(index, unit_type)


func _select_squad(index: int) -> void:
	squad_selected.emit(index)


func _show_army() -> void:
	army_page.show()
	guide_page.hide()
	army_tab.button_pressed = true
	guide_tab.button_pressed = false


func _show_guide() -> void:
	army_page.hide()
	guide_page.show()
	army_tab.button_pressed = false
	guide_tab.button_pressed = true
