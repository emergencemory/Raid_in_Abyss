extends CanvasLayer
class_name TutorialOverlay
 
const OBJECTIVE_NAME_PREFIX : String = "Objective_"
@onready var tutorial_animation_player: AnimationPlayer = $TutorialAnimationPlayer
@onready var indicator: Node2D = $Indicator
@onready var tutorial_sprite_1: Sprite2D = $Indicator/TutorialSprite1



var float_up : bool = true
static var current_objective : int = 1

func _ready() -> void:
	tutorial_sprite_1.modulate = Color(1, 1, 1, 0.3)
	## objective completion signals
	MessageBus.tutorial_tile_selected.connect(_on_complete_objective.bind(1))
	MessageBus.tutorial_tile_placed.connect(_on_complete_objective.bind(2))
	MessageBus.tutorial_tile_removed.connect(_on_complete_objective.bind(3))
	MessageBus.tutorial_weapon_rotated.connect(_on_complete_objective.bind(4))
	MessageBus.tutorial_wall_placed.connect(_on_complete_objective.bind(5))
	MessageBus.tutorial_crew_renamed.connect(_on_complete_objective.bind(6))
	MessageBus.tutorial_weapon_equipped.connect(_on_complete_objective.bind(7))
	MessageBus.tutorial_role_assigned.connect(_on_complete_objective.bind(8))
	MessageBus.tutorial_boarding_party_assigned.connect(_on_complete_objective.bind(9))
	MessageBus.tutorial_lobby_browser_opened.connect(_on_complete_objective.bind(10))
	MessageBus.tutorial_match_created.connect(_on_complete_objective.bind(11))
	MessageBus.tutorial_match_name_set.connect(_on_complete_objective.bind(12))
	MessageBus.tutorial_slot_opened.connect(_on_complete_objective.bind(13))
	MessageBus.tutorial_slot_closed.connect(_on_complete_objective.bind(14))
	MessageBus.tutorial_game_mode_selected.connect(_on_complete_objective.bind(15))
	MessageBus.tutorial_match_started.connect(_on_complete_objective.bind(16))
	MessageBus.tutorial_zoom_changed.connect(_on_complete_objective.bind(17))
	MessageBus.tutorial_vessel_moved.connect(_on_complete_objective.bind(18))
	MessageBus.select_weapon.connect(_on_existing_signal.bind(19))
	MessageBus.ship_weapon_fired.connect(_on_existing_signal.bind(20))
	MessageBus.crew_stance_attack.connect(_on_existing_signal.bind(21))
	#MessageBus.crew_stance_attack.connect(_on_complete_objective.bind(22)) #check bool
	MessageBus.tutorial_objective_captured.connect(_on_complete_objective.bind(23))

	if tutorial_animation_player.get_animation_list().has(OBJECTIVE_NAME_PREFIX + str(current_objective)):
		tutorial_animation_player.play(OBJECTIVE_NAME_PREFIX + str(current_objective))

	MessageBus.tutorial_quit_requested.connect(_on_quit_tutorial_button_pressed)
	MessageBus.tutorial_navigate_backward.connect(_on_back_button_pressed)
	MessageBus.tutorial_navigate_forward.connect(_on_forward_button_pressed)
	MessageBus.tutorial_hide_explanation.connect(_on_hide_explanation_button_pressed)
	MessageBus.tutorial_show_explanation.connect(_on_show_explanation_button_pressed)

##button functions

func _on_quit_tutorial_button_pressed() -> void:
	queue_free()


func _on_hide_explanation_button_pressed() -> void:
	indicator.visible = false


	
func _on_show_explanation_button_pressed() -> void:
	indicator.visible = true



func _physics_process(delta: float) -> void:
	if float_up:
		tutorial_sprite_1.position.y -= 3 * delta
		tutorial_sprite_1.modulate += Color(10, 10, 10) * delta
		if tutorial_sprite_1.position.y <= -2:
			float_up = false
	else:
		tutorial_sprite_1.position.y += 3 * delta
		tutorial_sprite_1.modulate -= Color(10, 10, 10) * delta
		if tutorial_sprite_1.position.y >= 0:
			float_up = true

## objective management

func _on_back_button_pressed() -> void:
	if current_objective <= 2:
		return
	current_objective -= 2
	_on_complete_objective(current_objective)

func _on_forward_button_pressed() -> void:
	if current_objective >= TutorialObjectives.objectives.size():
		return
	_on_complete_objective(current_objective)

func _on_complete_objective(objective_number: int) -> void:
	if objective_number != current_objective:
		return #ignore out of order completions
	print("Objective " + str(objective_number) + " completed.")
	current_objective += 1
	if objective_number >= TutorialObjectives.objectives.size():
		print("Tutorial completed!")
		await get_tree().create_timer(0.5).timeout
		_on_quit_tutorial_button_pressed()
		return
	if tutorial_animation_player.get_animation_list().has(OBJECTIVE_NAME_PREFIX + str(current_objective)):
		tutorial_animation_player.play(OBJECTIVE_NAME_PREFIX + str(current_objective))
	MessageBus.tutorial_objective_completed.emit(objective_number)
	

func _on_existing_signal(_arg1: Variant, _arg2: Variant, objective: int) -> void:
	if _arg2 is bool and _arg2 == false:
		objective += 1 #crew stance recall
	_on_complete_objective(objective)
