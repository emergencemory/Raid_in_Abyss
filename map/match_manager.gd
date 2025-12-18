extends Node
class_name MatchManager

const INPUT_PARSER : Script = preload("res://character/input_parser.gd")
const GAME_DATA : Script = preload("res://data/GameData.gd")

@onready var boss_scene : PackedScene = preload("res://character/boss/boss_model.tscn")
## orcs spawn with their sprites loaded by default
@onready var character_scene : PackedScene = preload("res://character/character_model.tscn")
#@onready var orc_spriteframes : SpriteFrames = preload("res://character/orc/orc_spriteframes.tres")
@onready var knight_spriteframes : SpriteFrames = preload("res://character/knight/knight_spriteframes.tres")
#@onready var round_shield_icon : Texture= preload("res://ui/round_shield_icon.png")
#@onready var axe_icon : Texture = preload("res://ui/axe_icon.png")
@onready var kite_shield_icon : Texture = preload("res://ui/kite_shield_icon_2.png")
@onready var sword_icon : Texture = preload("res://ui/sword_icon_2.png")
@onready var orc_outline_shader : ShaderMaterial = preload("res://character/orc_shader_material.tres")
@onready var knight_outline_shader : ShaderMaterial = preload("res://character/knight_shader_material.tres")
var player : CharacterBody2D
var hud_scene : PackedScene = preload("res://ui/hud.tscn")
var character_data : Dictionary
var _layer : int = 1
var wave: int = 0
var current_orcs : int = 0
var current_knights : int = 0
var boss_spawned : int = 0
var enemy_deaths : int = 0
var knight_deaths : int = 0
var your_deaths : int = -1
var knight_kills : int = 0
var your_kills : int = 0
var hud : CanvasLayer
var player_controller : INPUT_PARSER
var spawn_center : Vector2 = Vector2(0,0)
var spawning_wave_orc : bool = false
var spawning_wave_knight : bool = false
var spawn_attempts : int = 0
var endless_mode : bool = false

signal update_player_hud(layer, wave, current_orcs, your_kills, your_deaths, current_knights, knight_kills, knight_deaths)

func _ready() -> void:
	character_data = GAME_DATA.character_data.duplicate()
	player_controller = INPUT_PARSER.new()
	player_controller.name = "InputParser"
	add_child(player_controller)
	hud = hud_scene.instantiate()
	update_player_hud.connect(hud._on_update_player_hud)
	hud.touchscreen_toggled = get_parent().touchscreen_toggled
	SignalBus.touchscreen_toggled.connect(hud._on_touchscreen_toggled)
	SignalBus.touchscreen_toggled.connect(player_controller._on_touchscreen_toggled)
	player_controller.add_child(hud)
	SignalBus.health_signal.connect(hud._on_health_changed)
	SignalBus.request_reinforcements.connect(spawn_ai)
	SignalBus.console_kill_ai.connect(_on_console_kill_ai)
	SignalBus.player_move.connect(update_spawn_area)
	SignalBus.next_layer.connect(layer_cleared)
	SignalBus.boss_killed.connect(_on_endless_mode)
	SignalBus.cue_game_over.connect(_on_game_over)
	get_tree().create_timer(1.0).timeout.connect(spawn_player.bind(1))

func _on_game_over(highest_level: int) -> void:
	SignalBus.emit_signal("game_over", highest_level, _layer, your_kills, your_deaths, enemy_deaths, knight_deaths)
	for child in get_children():
		child.set_physics_process(false)
		if OS.get_name() != "Web":
			child.queue_free()


func layer_cleared() -> void:
	for orc in get_tree().get_nodes_in_group("orc"):
		#orc.remove_from_group("orc")
		#orc.remove_from_group("ai")
		orc.remove_from_group("boss")
		#orc.combat_audio_player.volume_db = -100.0
		#orc.add_to_group("dead")
		orc.die(true)
		orc.hide()
		orc.set_physics_process(false)
		if OS.get_name() != "Web":
			orc.queue_free()
	SignalBus.emit_signal("player_move", player.global_position)
	for knight in get_tree().get_nodes_in_group("knight"):
		if not knight.is_player:
			knight.position = await(get_valid_spawn(knight.team))
	endless_mode = false
	set_wave(0)
	set_layer(_layer + 1)
	set_orcs(0)
	update_hud()

func _on_console_kill_ai() -> void:
	set_physics_process(false)
	for character in get_tree().get_nodes_in_group("ai"):
		if character != null and not character.is_queued_for_deletion():
			print_debug("Killing AI: ", character.name)
			if character.is_in_group("orc"):
				enemy_deaths += 1
				set_orcs(current_orcs - 1)
				if character.is_boss:
					boss_spawned = 0
					SignalBus.emit_signal("boss_killed")
			elif character.is_in_group("knight"):
				knight_deaths += 1
				set_knights(current_knights - 1)
			character.remove_from_group("ai")
			character.remove_from_group(character.team)
			character.remove_from_group("boss")
			character.add_to_group("dead")
			for child in character.get_children():
				if child is CollisionShape2D:
					child.disabled = true
			character.position = Vector2i(-9000, -9000)
			character.hide()
			character.set_physics_process(false)
			if OS.get_name() != "Web":
				character.queue_free()
		else:
			print_debug("Invalid character for deletion")
	update_hud()
	spawning_wave_orc = false
	spawning_wave_knight = false
	set_physics_process(true)

func update_spawn_area(player_pos : Vector2) -> void:
	spawn_center = player_pos

func spawn_player(level:int) -> void:
	player = character_scene.instantiate()
	set_data(player)
	player.is_player = true
	add_child(player)
	player.add_to_group("knight")
	player.team = "knight"
	player.global_position = await(get_valid_spawn(player.team))
	player_controller.player = player
	player.attack_signal.connect(hud._on_attack_cooldown_started)
	player.block_signal.connect(hud._on_block_cooldown_started)
	player.move_signal.connect(hud._on_move_cooldown_started)
	player.kick_signal.connect(hud._on_kick_cooldown_started)
	player.killed_by_knight.connect(_on_knight_kill)
	player.killed_by_orc.connect(_on_orc_kill)
	player.killed_by_player.connect(_on_player_kill)
	player.level_up(level)
	var player_camera = Camera2D.new()
	player_camera.position_smoothing_enabled = true
	player.player_camera = player_camera
	player.character_sprite.add_child(player_camera)
	SignalBus.shake_screen.connect(player.shake_screen)
	SignalBus.emit_signal("reset_input")
	SignalBus.emit_signal("player_move", player.global_position)
	your_deaths += 1
	update_hud()
	player_camera.make_current()
	player.character_sprite.sprite_frames = knight_spriteframes
	player.shadow_sprite.sprite_frames = knight_spriteframes
	player.block_right_sprite.texture = kite_shield_icon
	player.block_left_sprite.texture = kite_shield_icon
	player.attack_from_right_sprite.texture = sword_icon
	player.attack_from_left_sprite.texture = sword_icon
	if current_orcs < 1:
		spawn_wave("orc")
	spawn_ai("knight")

func set_data(character:CharacterBody2D) -> void:
	character.base_attack_cooldown = character_data["attack_cooldown"]
	character.base_attack_damage = character_data["attack_damage"]
	character.base_attack_speed = character_data["attack_speed"]
	character.base_block_duration = character_data["block_duration"]
	character.base_block_cooldown = character_data["block_cooldown"]
	character.base_health = character_data["base_health"]
	character.base_speed = character_data["speed"]
	character.base_move_cooldown = character_data["move_cooldown"]
	character.base_kick_stun_duration = character_data["kick_stun"]
	character.base_kick_cooldown = character_data["kick_cooldown"]
	character.base_health_regen = character_data["health_regen"]
	character.current_xp = character_data["base_xp"]
	character.current_xp_to_next_level = character_data["base_xp_to_next_level"]
	character.base_xp_to_next_level_multiplier = character_data["base_xp_to_next_level_multiplier"]
	character.current_level = character_data["base_level"]
	character.level_up_multiplier = character_data["level_up_multiplier"]
	character.level_up_addition = character_data["level_up_addition"]

func spawn_ai(team:String) -> void:
	var character = character_scene.instantiate()
	set_data(character)
	character.team = team
	character.killed_by_knight.connect(_on_knight_kill)
	character.killed_by_orc.connect(_on_orc_kill)
	character.killed_by_player.connect(_on_player_kill)
	self.call_deferred("add_child",(character))
	character.add_to_group(team)
	character.position = await(get_valid_spawn(character.team))
	character.add_to_group("ai")
	if team == "orc":
		set_orcs(current_orcs + 1)
	if team == "knight":
		set_knights(current_knights + 1)
	update_hud()
	self.call_deferred("configure_ai_sprite", character, team)

func configure_ai_sprite(character: CharacterBody2D, team : String) -> void:
	if team == "orc":
		character.character_sprite.material = orc_outline_shader
	#	character.character_sprite.sprite_frames = orc_spriteframes
	#	character.shadow_sprite.sprite_frames = orc_spriteframes
	#	character.block_right_sprite.texture = round_shield_icon
	#	character.block_left_sprite.texture = round_shield_icon
	#	character.attack_from_right_sprite.texture = axe_icon
	#	character.attack_from_left_sprite.texture = axe_icon
	if team == "knight":
		character.character_sprite.sprite_frames = knight_spriteframes
		character.shadow_sprite.sprite_frames = knight_spriteframes
		character.block_right_sprite.texture = kite_shield_icon
		character.block_left_sprite.texture = kite_shield_icon
		character.attack_from_right_sprite.texture = sword_icon
		character.attack_from_left_sprite.texture = sword_icon
		character.character_sprite.material = knight_outline_shader
	character.level_up(randi_range(0, wave+((_layer-1)*7)))

func get_valid_spawn(team:String) -> Vector2:
	var spawn_pos : Vector2
	var valid_spawn : bool = false
	var attempts : int = 0
	var max_attempts : int = 50
	var current_y_range : int = 128
	var current_x_multiplier : float = 1.0
	while not valid_spawn and attempts < max_attempts:
		attempts += 1
		if team == "knight":
			# Spawn on the left side of the screen
			spawn_pos.x = randf_range(spawn_center.x - 1024*current_x_multiplier, spawn_center.x - 256)
		else: # orc
			# Spawn on the right side of the screen
			spawn_pos.x = randf_range(spawn_center.x + 768, spawn_center.x + 1540*current_x_multiplier)
		spawn_pos.y = randf_range(spawn_center.y - current_y_range, spawn_center.y + current_y_range)
		spawn_pos = spawn_pos.snapped(Vector2(128, 128))
		var collision_checker : RayCast2D = RayCast2D.new()
		collision_checker.global_position = spawn_pos
		collision_checker.target_position = Vector2(64,64)
		collision_checker.collide_with_areas = true
		collision_checker.collision_mask = 1
		collision_checker.hit_from_inside = true
		add_child(collision_checker)
		collision_checker.force_raycast_update()
		if collision_checker.is_colliding():
			collision_checker.queue_free()
			current_y_range += 128
			current_x_multiplier += 0.1
			await(get_tree().physics_frame)
			continue
		else:
			collision_checker.queue_free()
			valid_spawn = true
	if not valid_spawn:
		print_debug("Failed to find a valid spawn position after ", max_attempts, " attempts.")
	return spawn_pos

func set_layer(new_layer : int) -> void:
	_layer = new_layer
	boss_spawned = 0
	update_hud()

func set_wave(new_wave : int) -> void:
	wave = new_wave
	if new_wave >= 5:
		if boss_spawned < 1:
			boss_spawned += 1
			var boss = boss_scene.instantiate()
			boss.team = "orc"
			set_orcs(current_orcs + 1)
			boss.global_position = await(get_valid_spawn("orc"))
			boss.add_to_group("ai")
			boss.add_to_group("orc")
			boss.add_to_group("boss")
			boss.killed_by_knight.connect(_on_knight_kill)
			boss.killed_by_orc.connect(_on_orc_kill)
			boss.killed_by_player.connect(_on_player_kill)
			self.call_deferred("add_child",(boss))
			await(get_tree().physics_frame)
			boss.call_deferred("level_up", (_layer - 1))

	update_hud()

func _physics_process(delta: float) -> void:
	var ai_characters = get_tree().get_nodes_in_group("ai")
	if ai_characters.size() <= 1:
		spawn_attempts += 1
		set_orcs(current_orcs)
		set_knights(current_knights)
		return
	for character in ai_characters:
		if not is_instance_valid(character) or character.is_queued_for_deletion() or character.is_in_group("dead"):
			continue
		elif character.has_target == false or not is_instance_valid(character.target) or character.target.is_in_group("dead"):
			var target = get_target(character)
			if target != null:
				character.has_target = true
				character.cooldown_time_target = 1.0
				character.target = target
			else:
				character.has_target = false
				character.cooldown_time_target = 1.0
				character.target = null
		else:
			character.order_ticks -= delta
			if character.order_ticks > 0:
				continue
			else:
				ai_action(character)

func _on_endless_mode() -> void:
	endless_mode = true

func spawn_wave(team:String) -> void:
	var spawns_number : int = wave + _layer*2
	if team == "orc":
		spawns_number *= 2
	for i in range(spawns_number):
		spawn_ai(team)
		update_hud()
		print("spawning: " + str(i+1) + " of " + str(spawns_number) + " for " + team)
		if i == (spawns_number-1):
			if team == "orc":
				spawning_wave_orc = false
				print("done spawning orc wave")
			elif team == "knight":
				spawning_wave_knight = false
				print("done spawning knight wave")
		await(get_tree().physics_frame)
	spawn_attempts = 0	

func ai_action(character: CharacterBody2D) -> void:
	character.order_ticks = 0.5
	if character.is_boss:
		boss_ai(character)
		return
	var coin_flip = randi_range(0, 4)
	character.ray_cast_2d.force_raycast_update()
	if character.ray_cast_2d.is_colliding() and character.ray_cast_2d.get_collider() == character.target:
			if coin_flip == 0: 
				if character.is_preparing_attack == false:
					character.swing_from_right = true
					character.prepare_attack()
				else:
					character.attack()
			elif coin_flip == 1:
				if character.is_preparing_attack == false:
					character.swing_from_right = false
					character.prepare_attack()
				else:
					character.attack()
			elif coin_flip == 2:
				character.block_to_right = true
				character.block()
			elif coin_flip == 3:
				character.block_to_right = false
				character.block()
			else:
				character.kick()
	elif character.target.global_position.x < character.global_position.x:
		if coin_flip == 0 or coin_flip == 1:
			if character.facing_direction == character.DIR.WEST and character.ray_cast_2d.is_colliding():
				pass
			else:
				character.turn(character.DIR.WEST)
		elif coin_flip == 2:
			if character.facing_direction == character.DIR.NORTH and character.ray_cast_2d.is_colliding():
				pass
			else:
				character.turn(character.DIR.NORTH)
		elif coin_flip == 3:
			if character.facing_direction == character.DIR.SOUTH and character.ray_cast_2d.is_colliding():
				pass
			else:
				character.turn(character.DIR.SOUTH)
		else:
			if character.facing_direction == character.DIR.EAST and character.ray_cast_2d.is_colliding():
				pass
			else:
				character.turn(character.DIR.EAST)
	elif character.target.global_position.x > character.global_position.x:
		if coin_flip == 0 or coin_flip == 1:
			if character.facing_direction == character.DIR.EAST and character.ray_cast_2d.is_colliding():
				pass
			else:
				character.turn(character.DIR.EAST)
		elif coin_flip == 2:
			if character.facing_direction == character.DIR.NORTH and character.ray_cast_2d.is_colliding():
				pass
			else:
				character.turn(character.DIR.NORTH)
		elif coin_flip == 3:
			if character.facing_direction == character.DIR.SOUTH and character.ray_cast_2d.is_colliding():
				pass
			else:
				character.turn(character.DIR.SOUTH)
		else:
			if character.facing_direction == character.DIR.WEST and character.ray_cast_2d.is_colliding():
				pass
			else:
				character.turn(character.DIR.WEST)
	elif character.target.global_position.y < character.global_position.y:
		if coin_flip == 0 or coin_flip == 1:
			if character.facing_direction == character.DIR.NORTH and character.ray_cast_2d.is_colliding():
				pass
			else:
				character.turn(character.DIR.NORTH)
		elif coin_flip == 2:
			if character.facing_direction == character.DIR.EAST and character.ray_cast_2d.is_colliding():
				pass
			else:
				character.turn(character.DIR.EAST)
		elif coin_flip == 3:
			if character.facing_direction == character.DIR.WEST and character.ray_cast_2d.is_colliding():
				pass
			else:
				character.turn(character.DIR.WEST)
		else:
			if character.facing_direction == character.DIR.SOUTH and character.ray_cast_2d.is_colliding():
				pass
			else:
				character.turn(character.DIR.SOUTH)
	elif character.target.global_position.y > character.global_position.y:
		if coin_flip == 0 or coin_flip == 1:
			character.turn(character.DIR.SOUTH)
			if character.facing_direction == character.DIR.SOUTH and character.ray_cast_2d.is_colliding():
				pass
			else:
				character.turn(character.DIR.SOUTH)
		elif coin_flip == 2:
			if character.facing_direction == character.DIR.EAST and character.ray_cast_2d.is_colliding():
				pass
			else:
				character.turn(character.DIR.EAST)
		elif coin_flip == 3:
			if character.facing_direction == character.DIR.WEST and character.ray_cast_2d.is_colliding():
				pass
			else:
				character.turn(character.DIR.WEST)
		else:
			if character.facing_direction == character.DIR.NORTH and character.ray_cast_2d.is_colliding():
				pass
			else:
				character.turn(character.DIR.NORTH)

func get_target(character: CharacterBody2D) -> CharacterBody2D:
	var nearest_target = null
	if character.is_in_group("orc"):
		var potential_targets = get_tree().get_nodes_in_group("knight")
		if potential_targets.size() <= 0:
			set_knights(current_knights)
			spawn_attempts += 1
		for target in potential_targets:
			if not target.is_queued_for_deletion() and not target.is_in_group("dead"):
				if nearest_target == null or character.position.distance_to(target.position) < character.position.distance_to(nearest_target.position):
					nearest_target = target
	elif character.is_in_group("knight"):
		var potential_targets = get_tree().get_nodes_in_group("orc")
		if potential_targets.size() <= 0:
			set_orcs(current_orcs)
			spawn_attempts += 1
		for target in potential_targets:
			if not target.is_queued_for_deletion() and not target.is_in_group("dead"):
				if nearest_target == null or character.position.distance_to(target.position) < character.position.distance_to(nearest_target.position):
					nearest_target = target
	return nearest_target

func boss_ai(character: CharacterBody2D) -> void:
	character.ray_cast_2d_front.force_raycast_update()
	character.ray_cast_2d_front_2.force_raycast_update()
	character.ray_cast_2d_left.force_raycast_update()
	character.ray_cast_2d_right.force_raycast_update()
	if character.ray_cast_2d_front.is_colliding() and character.ray_cast_2d_front.get_collider() == character.target:
			if not character.stomp_on_cooldown: 
				character.stomp()
			elif not character.attack_from_right_on_cooldown:
				if character.is_preparing_attack == false:
					character.swing_from_right = true
					character.prepare_attack_from_right()
				else:
					character.attack_from_right()
			elif not character.attack_from_left_on_cooldown:
				if character.is_preparing_attack == false:
					character.swing_from_right = false
					character.prepare_attack_from_left()
				else:
					character.attack_from_left()
	elif character.ray_cast_2d_front_2.is_colliding() and character.ray_cast_2d_front_2.get_collider() == character.target:
			if not character.attack_from_right_on_cooldown:
				if character.is_preparing_attack == false:
					character.swing_from_right = true
					character.prepare_attack_from_right()
				else:
					character.attack_from_right()
	elif character.ray_cast_2d_left.is_colliding() and character.ray_cast_2d_left.get_collider() == character.target:
			if not character.stomp_on_cooldown: 
				character.stomp()
			else:
				character.turn(((character.facing_direction + 4) - 1) % 4)
	elif character.ray_cast_2d_right.is_colliding() and character.ray_cast_2d_right.get_collider() == character.target:
			if not character.stomp_on_cooldown: 
				character.stomp()
			else:
				character.turn(((character.facing_direction + 4) + 1) % 4)
	elif character.ray_cast_2d_front.is_colliding() and character.ray_cast_2d_front.get_collider().get_parent().is_in_group("cliff"):
		if character.ray_cast_2d_left.is_colliding() and character.ray_cast_2d_left.get_collider().get_parent().is_in_group("cliff"):
			character.turn(((character.facing_direction + 4) + 1) % 4)
		elif character.ray_cast_2d_right.is_colliding() and character.ray_cast_2d_right.get_collider().get_parent().is_in_group("cliff"):
			character.turn(((character.facing_direction + 4) - 1) % 4)
		else:
			character.turn(((character.facing_direction + 4) -2) % 4)
	var coin_flip = randi_range(0, 4)
	if character.target.global_position.x < character.global_position.x and coin_flip == 3:
		if character.facing_direction == character.DIR.WEST and not character.jump_on_cooldown:
			character.jump()
		else:
			character.turn(character.DIR.WEST)
	elif character.target.global_position.y < character.global_position.y and coin_flip == 0:
		if character.facing_direction == character.DIR.NORTH and not character.jump_on_cooldown:
			character.jump()
		else:
			character.turn(character.DIR.NORTH)
	elif character.target.global_position.y > character.global_position.y and coin_flip == 4:
		if character.facing_direction == character.DIR.SOUTH and not character.jump_on_cooldown:
			character.jump()
		else:
			character.turn(character.DIR.SOUTH)
	elif character.target.global_position.x > character.global_position.x and coin_flip == 1:
		if character.facing_direction == character.DIR.EAST and not character.jump_on_cooldown:
			character.jump()
		else:
			character.turn(character.DIR.EAST)

func _on_knight_kill(team: String) -> void:
	if team == "orc":
		set_orcs(current_orcs - 1)
		knight_kills += 1
		enemy_deaths += 1
	elif team == "knight":
		set_knights(current_knights - 1)
		knight_deaths += 1
	if spawn_attempts >= 60:
		spawn_wave(team)
	update_hud()

func set_orcs(value: int) -> void:
	current_orcs = value
	if current_orcs <= 1 and not spawning_wave_orc:
		spawning_wave_orc = true
		spawn_wave("orc")
		set_wave(wave + 1)
		update_hud()
	if endless_mode and current_orcs <= 10:
		for i in (_layer*2):
			spawn_ai("orc")

func _on_orc_kill(team: String) -> void:
	if team == "knight":
		set_knights(current_knights - 1)
		knight_deaths += 1
	elif team == "orc":
		set_orcs(current_orcs - 1)
		enemy_deaths += 1
	if spawn_attempts >= 60:
		spawn_wave(team)
	update_hud()

func set_knights(value: int) -> void:
	current_knights = value
	if current_knights <= 1 and not spawning_wave_knight:
		spawning_wave_knight = true
		spawn_wave("knight")
		update_hud()

func _on_player_kill(team: String) -> void:
	if team == "orc":
		set_orcs(current_orcs - 1)
		your_kills += 1
		enemy_deaths += 1
	elif team == "knight":
		set_knights(current_knights - 1)
		knight_deaths += 1
	if spawn_attempts >= 60:
		spawn_wave(team)
	update_hud()

func update_hud() -> void:
	emit_signal("update_player_hud", _layer, wave,current_orcs, your_kills, your_deaths, current_knights, knight_kills, knight_deaths)
