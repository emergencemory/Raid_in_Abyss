extends MarginContainer
class_name TutorialObjectives

#@onready var objectives_margin: MarginContainer = $ObjectivesMargin
#@onready var obj_background_panel_container: PanelContainer = $PanelContainer
@onready var checkbox_container: VBoxContainer = $ObjectivesContainer/PanelContainer3/CheckBoxContainer
@onready var list_container: PanelContainer = $ObjectivesContainer/PanelContainer3
@onready var minimize_list_button: Button = $ObjectivesContainer/PanelContainer2/ButtonContainer/PanelContainer2/MinimizeListButton
@onready var show_list_button: Button = $ObjectivesContainer/PanelContainer2/ButtonContainer/PanelContainer3/ShowListButton
@onready var hide_completed_button: CheckButton = $ObjectivesContainer/PanelContainer2/ButtonContainer/PanelContainer/HideCompletedButton
@onready var objective_1: CheckBox = $ObjectivesContainer/PanelContainer3/CheckBoxContainer/Objective1


func _ready() -> void:
	minimize_list_button.pressed.connect(_on_minimize_list_button_pressed)
	show_list_button.pressed.connect(_on_show_list_button_pressed)
	hide_completed_button.toggled.connect(_on_hide_completed_button_toggled)
	var checkbox : CheckBox = objective_1.duplicate()
	checkbox.text = objectives[1]
	checkbox.name = TutorialOverlay.OBJECTIVE_NAME_PREFIX + str(TutorialOverlay.current_objective)
	checkbox_container.add_child(checkbox)
	checkbox.visible = true
	MessageBus.tutorial_objective_completed.connect(_on_complete_objective)
	MessageBus.tutorial_minimize_list.connect(_on_tutorial_minimize_list)
	MessageBus.tutorial_show_list.connect(_on_tutorial_show_list)
	MessageBus.tutorial_hide_completed.connect(_on_tutorial_hide_completed)


func _on_minimize_list_button_pressed() -> void:
	MessageBus.tutorial_minimize_list.emit()

func _on_tutorial_minimize_list() -> void:
	list_container.visible = false
	minimize_list_button.visible = false
	hide_completed_button.visible = false
	show_list_button.visible = true
	self.size.y = 64
	

func _on_show_list_button_pressed() -> void:
	MessageBus.tutorial_show_list.emit()

func _on_tutorial_show_list() -> void:
	list_container.visible = true
	_on_hide_completed_button_toggled(hide_completed_button.button_pressed)
	show_list_button.visible = false
	minimize_list_button.visible = true
	hide_completed_button.visible = true

func _on_hide_completed_button_toggled(toggled: bool) -> void:
	MessageBus.tutorial_hide_completed.emit(toggled)

func _on_tutorial_hide_completed(toggled: bool) -> void:
	for child in checkbox_container.get_children():
		if child is CheckBox:
			if child.button_pressed:
				child.visible = not toggled

func _on_complete_objective(objective_number: int) -> void:
	var checkbox_name = TutorialOverlay.OBJECTIVE_NAME_PREFIX + str(objective_number)
	var checkbox : CheckBox = checkbox_container.get_node(checkbox_name)
	checkbox.button_pressed = true
	
	var new_checkbox : CheckBox = objective_1.duplicate()
	new_checkbox.text = objectives[TutorialOverlay.current_objective]
	new_checkbox.name = TutorialOverlay.OBJECTIVE_NAME_PREFIX + str(TutorialOverlay.current_objective)
	checkbox_container.add_child(new_checkbox)
	checkbox_container.move_child(new_checkbox, 0) #put at top
	new_checkbox.visible = true
	await get_tree().create_timer(0.5).timeout
	_on_tutorial_hide_completed(hide_completed_button.button_pressed)

## tutorial steps

const objectives : Dictionary = {
	1 : "Select a tile",
	2 : "Place the tile on your ship",
	3 : "Remove a tile from your ship",
	4 : "Rotate a ship weapon",
	5 : "Place a wall tile",
	6 : "Rename a crew member",
	7 : "Equip a weapon",
	8 : "Assign a role to a crew member",
	9 : "Put a member in the boarding party",
	10 : "Open the lobby browser",
	11 : "Create a match",
	12 : "Set a match name",
	13 : "Open a slot",
	14 : "Close a slot",
	15 : "Select a game mode",
	16 : "Start the match",
	17 : "Change the Zoom level",
	18 : "Move your vessel",
	19 : "Select a ship weapon",
	20 : "Fire a ship weapon",
	21 : "Initiate boarding action",
	22 : "Recall boarders",
	23 : "Capture an objective"
}
