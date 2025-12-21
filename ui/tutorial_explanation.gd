extends MarginContainer
class_name TutorialExplanation

#@onready var explanation_margin: MarginContainer = $ExplanationMargin
#@onready var expl_background_panel_container: PanelContainer = $PanelContainer
@onready var quit_tutorial_button: Button = $ExplanationContainer/PanelContainer2/ButtonContainer/PanelContainer/QuitTutorialButton
@onready var hide_explanation_button: Button = $ExplanationContainer/PanelContainer2/ButtonContainer/PanelContainer2/HideExplanationButton
@onready var show_explanation_button: Button = $ExplanationContainer/PanelContainer2/ButtonContainer/PanelContainer3/ShowExplanationButton
@onready var tutorial_label: Label = $ExplanationContainer/PanelContainer/TutorialLabel
@onready var explanation_container: PanelContainer = $ExplanationContainer/PanelContainer
@onready var back_button: Button = $ExplanationContainer/PanelContainer2/ButtonContainer/PanelContainer4/PrevButton
@onready var forward_button: Button = $ExplanationContainer/PanelContainer2/ButtonContainer/PanelContainer5/NextButton

func _ready() -> void:
	quit_tutorial_button.pressed.connect(_on_quit_tutorial_button_pressed)
	hide_explanation_button.pressed.connect(_on_hide_explanation_button_pressed)
	show_explanation_button.pressed.connect(_on_show_explanation_button_pressed)
	back_button.pressed.connect(_on_back_button_pressed)
	forward_button.pressed.connect(_on_forward_button_pressed)
	tutorial_label.text = explanations[1]
	explanation_container.visible = true
	MessageBus.tutorial_objective_completed.connect(_on_complete_objective)
	MessageBus.tutorial_hide_explanation.connect(_on_tutorial_hide_explanation)
	MessageBus.tutorial_show_explanation.connect(_on_tutorial_show_explanation)

func _on_quit_tutorial_button_pressed() -> void:
	MessageBus.tutorial_quit_requested.emit()

func _on_show_explanation_button_pressed() -> void:
	MessageBus.tutorial_show_explanation.emit()

func _on_tutorial_show_explanation() -> void:
	explanation_container.visible = true
	#tutorial_label.visible = true
	show_explanation_button.visible = false
	hide_explanation_button.visible = true

func _on_hide_explanation_button_pressed() -> void:
	MessageBus.tutorial_hide_explanation.emit()

func _on_tutorial_hide_explanation() -> void:
	explanation_container.visible = false
	hide_explanation_button.visible = false
	show_explanation_button.visible = true
	self.size_flags_vertical = Control.SIZE_SHRINK_END

func _on_back_button_pressed() -> void:
	MessageBus.tutorial_navigate_backward.emit()

func _on_forward_button_pressed() -> void:
	MessageBus.tutorial_navigate_forward.emit()

func _on_complete_objective(_objective_number: int) -> void:
	tutorial_label.text = explanations[TutorialOverlay.current_objective]


const explanations : Dictionary = {
	1 : "Welcome to the tutorial!
	This game features customizable ships and crewmembers.
	Use the ship design interface to select and place tiles.",
	2 : "Your ship's layout will determine how you fight.
	You can place up the the maximum number of each
	tile indicated on their icon (current/maximum).",
	3 : "Right-click deselects your selected tile.
	Select the remove tool (trash can icon) to remove tiles
	starting at the top layer (weapons) and working down.",
	4 : "When placing a cannon, it starts facing right.
	With the same weapon selected, clicking an already
	placed weapon rotates it 90 degrees clockwise.",
	5 : "Placing vertical or horizontal walls provides
	cover for your crew, hull, and cannons, but won't
	block movement.  Wood floors can be destroyed without them.",
	6 : "Each crew member starts at level one and has
	a randomly generated name. To rename a crew member,
	select the asterisk next to their name",
	7 : "You should equip your crew members with weapons
	that maximize their effectiveness based on their role
	and stats. Expand the weapon list and hover over to see details.",
	8 : "Crew member roles provide benefits in combat.
	Cannoneers reload your ship weapons, skirmishers keep
	enemies at range, and front line charge into melee.",
	9 : "Boarding parties can defeat enemy crews and
	capture objectives from their ship.  Front line crew
	members with melee weapons are most effective in boarding.",
	10 : "While quickstart jumps into the first available match
	or creates one with default settings, the lobby browser
	gives more control over match settings and opponents.",
	11 : "You can see match name, mode, players, whether
	it is in progress, or password protected in this list.
	Create your own match to continue the tutorial.",
	12 : "Set a match name to help your friends identify it.
	Optionally, setting a password and making it private can
	help you reserve open slots for specific people to join",
	13 : "By default, all slots are filled with AI players
	which are replaced by human players as they join.
	Setting a slot to open removes the current occupant.",
	14 : "Closing a slot will prevent any player from
	joining that slot. This can be useful to set up
	specific match formats like 1v1 or block certain spawns",
	15 : "Different game modes could have different objectives
	in the future, but for now free-for-all and tutorial
	are the available options. Select tutorial to continue.",
	16 : "Matches start when either all joined players ready up
	or when the match creator clicks launch. Players can join in
	progress matches so don't worry about waiting for a full lobby",
	17 : "Use the mouse wheel to change the camera zoom level.
	Zooming out can give better situational awareness,
	and zooming in can help with precision aiming or maneuvering.",
	18 : "You can move your vessel using rebindable keys or
	touchscreen controls.  This is how you aim your ship weapons,
	capture objectives, and position your ship for boarding actions.",
	19 : "The bottom left panel displays weapon status and selection,
	Your weapons show a red targetting arc when selected and loaded
	Spacebar (default) cycles through groups based on facing direction.",
	20 : "Fire your selected ship weapon using the attack key 
	(left click default).  Cycle through weapons in a group by using
	that group's hotkey or switch weapon key (1-4, right click default) .",
	21 : "It takes some time for level 1 canonneers to reload
	your ship weapons.  Sending crew members to board a ship is
	higher risk, but can quickly turn the tide of battle.",
	22 : "Recall your boarding party if they capture the objective,
	defeat the enemy crew, or are in danger of being eliminated.
	Remember to keep your ship close enough for them to return!",
	23 : "With the objective in your possession, you can win
	the match by taking it to the enemy's starting location.
	Eliminating all enemy crews also results in victory.
	Keep your crew alive to increase their level for future matches!
	This is the end of the tutorial. Good luck!"
}