extends CharacterBody2D
class_name CharacterManager

enum DIR {
	NORTH,
	EAST,
	SOUTH,
	WEST
}

@onready var stun_particle: GPUParticles2D = $StunParticle
@onready var blood_particle: GPUParticles2D = $BloodParticle
@onready var spark_particle: GPUParticles2D = $SparkParticle
@onready var block_right_sprite: Sprite2D = $BlockRightSprite
@onready var block_left_sprite: Sprite2D = $BlockLeftSprite
@onready var attack_from_right_sprite: Sprite2D = $AttackFromRightSprite
@onready var attack_from_left_sprite: Sprite2D = $AttackFromLeftSprite
@onready var combat_audio_player: AudioStreamPlayer2D = $CombatAudio
@onready var movement_audio_player: AudioStreamPlayer2D = $MovementAudio
@onready var strike_shape: CollisionShape2D = $CharacterSprite/HitBox/StrikeShape
@onready var character_sprite: AnimatedSprite2D = $CharacterSprite
@onready var shadow_sprite: AnimatedSprite2D = $CharacterSprite/ShadowSprite
@onready var ray_cast_2d: RayCast2D = $CharacterCollider/RayCast2D

var is_boss: bool = false
var has_target: bool = false
var target: CharacterBody2D
var base_health: int
var base_attack_damage: int
var base_attack_cooldown : float 
var base_block_duration: float
var base_block_cooldown: float 
var base_speed: float 
var base_move_cooldown: float 
var base_kick_stun_duration: float 
var base_kick_cooldown: float
var current_health: int
var facing_direction: int = 0
var attack_direction: int = -1
var swing_from_right: bool = false :
	set(value):
		if value != swing_from_right:
			swing_from_right = value
			prepare_attack()
var current_attack_damage: int
var current_attack_cooldown: float
var attack_on_cooldown: bool = false
var block_direction: int = -1
var block_to_right: bool = false
var current_block_duration: float
var current_block_cooldown: float 
var block_on_cooldown: bool = false
var current_speed: float 
var current_move_cooldown: float 
var move_on_cooldown: bool = false
var is_kicking: bool = false
var current_kick_stun_duration: float
var current_kick_cooldown: float
var kick_on_cooldown: bool = false
var base_attack_speed
var current_attack_speed
var moving: bool = false
var is_player: bool = false
var team: String
var is_attacking: bool = false
var is_preparing_attack: bool = false
var attack_charge: float = 0.0
var base_health_regen: float
var current_health_regen: float
var is_turning: bool = false
var attack_windup: bool = false
var cooldown_time_attack: float = 0.0
var cooldown_time_block: float = 0.0
var cooldown_time_turn: float = 0.0
var cooldown_time_move: float = 0.0
var cooldown_time_moving: float = 0.0 
var cooldown_time_kick: float = 0.0
var cooldown_time_health_regen: float = 0.0
var cooldown_time_attack_area: float = 0.0
var cooldown_time_block_area: float = 0.0
var cooldown_time_attack_windup: float = 0.0
var cooldown_time_target: float = 0.0
var is_blocking: bool = false
var stun_on_cooldown: bool = false
var cooldown_time_stun: float = 0.0
var order_ticks : float = 0.0
var player_camera: Camera2D
var current_xp: float
var current_level: int
var current_xp_to_next_level: float
var base_xp_to_next_level_multiplier: float
var level_up_multiplier: float
var level_up_addition: int
var falling: bool = false
var fall_depth: float = 0.0
var recursion_index: int = 0
var steps_timer: float = 0.5

signal attack_signal(value: float)
signal block_signal(value: float)
signal move_signal(value: float)
signal kick_signal(value: float)
signal killed_by_player(team: String)
signal killed_by_knight(team: String)
signal killed_by_orc(team: String)


func _ready() -> void:
	current_attack_damage = base_attack_damage
	current_health = base_health
	current_attack_cooldown = base_attack_cooldown
	current_block_duration = base_block_duration
	current_block_cooldown = base_block_cooldown
	current_speed = base_speed
	current_move_cooldown = base_move_cooldown
	current_kick_stun_duration = base_kick_stun_duration
	current_kick_cooldown = base_kick_cooldown
	current_attack_speed = base_attack_speed
	current_health_regen = base_health_regen
	combat_audio_player["parameters/switch_to_clip"] = "Sword Draw"
	combat_audio_player.play()
	if is_player:
		SignalBus.emit_signal("health_signal", current_health, base_health, self)
		SignalBus.emit_signal("reset_input")

func _physics_process(delta) -> void:
	if is_in_group("dead") and not falling:
		set_physics_process(false)
		return
	elif falling:
		scale.x -= delta
		scale.y -= delta
		fall_depth +=  1
		if fall_depth >= 30:
			falling = false
			position = Vector2(-9000, -9000)
			self.hide()
			set_physics_process(false)
			if OS.get_name() != "Web":
				queue_free()
		return
	if stun_on_cooldown:
		if cooldown_time_stun > 0:
			cooldown_time_stun -= delta
		else:
			stun_on_cooldown = false
			stun_particle.emitting = false
	if attack_on_cooldown:
		if cooldown_time_attack > 0:
			cooldown_time_attack -= delta
		else:
			_on_attack_cooldown_timeout()
	if block_on_cooldown:
		if cooldown_time_block > 0:
			cooldown_time_block -= delta
		else:
			_on_block_cooldown_timeout()
	if is_turning:
		if cooldown_time_turn > 0:
			cooldown_time_turn -= delta
		else:
			is_turning = false
	if move_on_cooldown:	
		if cooldown_time_move > 0:
			cooldown_time_move -= delta
		else:
			_on_move_cooldown_timeout()
	if moving:
		if steps_timer > 0:
			steps_timer -= delta
		else:
			steps_timer = 0.3
			movement_audio_player["parameters/switch_to_clip"] = "Steps Armored"
			movement_audio_player.play()
		if cooldown_time_moving > 0:
			cooldown_time_moving -= delta
		else:
			_on_move_timeout()
	if kick_on_cooldown:
		if cooldown_time_kick > 0:
			cooldown_time_kick -= delta
		else:
			_on_kick_cooldown_timeout()
	if current_health < base_health:
		if cooldown_time_health_regen > 0:
			cooldown_time_health_regen -= delta
		else:
			_on_health_regen_timeout()
	if attack_windup:
		if cooldown_time_attack_windup > 0:
			cooldown_time_attack_windup -= delta
		else:
			_on_attack_begin()
	if is_attacking:
		if cooldown_time_attack_area > 0:
			cooldown_time_attack_area -= delta
		else:
			_on_attack_timeout()
	if is_kicking:
		if cooldown_time_attack_area > 0:
			cooldown_time_attack_area -= delta
		else:
			_on_kick_timeout()
	if is_blocking:
		if cooldown_time_block_area > 0:
			cooldown_time_block_area -= delta
		else:
			_on_block_timeout()
	if has_target:
		if cooldown_time_target > 0 and target != null and not target.is_in_group("dead"):
			cooldown_time_target -= delta
		else:
			_on_target_timeout()
	if current_xp >= current_xp_to_next_level:
		level_up(1)


func level_up(levels_to_gain: int):
	current_level += levels_to_gain
	SignalBus.emit_signal("leveled_up", self, current_level)
	character_sprite.self_modulate = Color(3, 3, 1, 1)
	var level_tween = create_tween()
	level_tween.tween_property(character_sprite, "self_modulate", Color((1 + float(current_level)/10), (1 + float(current_level)/10), 1, 1), 0.5)
	current_xp_to_next_level *= pow(base_xp_to_next_level_multiplier, levels_to_gain)
	base_health = level_up_addition*current_level
	current_health = base_health
	current_attack_damage = (level_up_addition*current_level)/2
	current_attack_cooldown /= pow(level_up_multiplier, levels_to_gain)
	current_block_duration *= pow(level_up_multiplier, levels_to_gain)
	current_block_cooldown /= pow(level_up_multiplier, levels_to_gain)
	current_move_cooldown /= pow(level_up_multiplier, levels_to_gain)
	current_kick_stun_duration *= pow(level_up_multiplier, levels_to_gain)
	current_kick_cooldown /= pow(level_up_multiplier, levels_to_gain)
	current_health_regen /= pow(level_up_multiplier, levels_to_gain)
	if is_player:
		SignalBus.emit_signal("request_reinforcements", team)

func prepare_attack() -> void:
	if is_attacking or attack_windup or is_kicking or attack_on_cooldown:
		return
	if swing_from_right:
		attack_from_right_sprite.show()
		attack_from_left_sprite.hide()
		attack_direction = ((facing_direction+4) + 1) % 4
	else:
		attack_from_right_sprite.hide()
		attack_from_left_sprite.show()
		attack_direction = ((facing_direction+4) - 1) % 4
	is_preparing_attack = true
	combat_audio_player["parameters/switch_to_clip"] = "Leather Buckle"
	combat_audio_player.play()

func attack() -> void:
	attack_from_left_sprite.hide()
	attack_from_right_sprite.hide()
	is_preparing_attack = false
	if attack_on_cooldown or is_attacking or moving or is_turning or is_kicking or attack_windup:
		return
	elif is_blocking:
		_on_block_timeout()
	if swing_from_right:
		character_sprite.play("attack_from_right")
		shadow_sprite.play("attack_from_right")
	else:
		character_sprite.play("attack_from_left")
		shadow_sprite.play("attack_from_left")
	cooldown_time_attack_windup = current_attack_speed/2
	attack_windup = true
	cooldown_time_attack = current_attack_cooldown
	attack_on_cooldown = true
	if is_player:
		emit_signal("attack_signal", current_attack_cooldown)

func block() -> void:
	if block_on_cooldown or is_attacking or moving or is_turning or attack_windup or is_kicking:
		return
	elif is_blocking:
		_on_block_timeout()
	combat_audio_player["parameters/switch_to_clip"] = "Shield Ready"
	combat_audio_player.call_deferred("play")
	block_direction = get_block_direction()
	character_sprite.play("block")
	shadow_sprite.play("block")
	cooldown_time_block = current_block_cooldown
	block_on_cooldown = true
	cooldown_time_block_area = current_block_duration
	is_blocking = true
	if is_player:
		emit_signal("block_signal", current_block_cooldown)

func kick() -> void:
	if moving or is_attacking or is_turning or attack_windup or is_turning or is_kicking or kick_on_cooldown:
		return
	elif is_blocking:
		_on_block_timeout()
	cooldown_time_kick = current_kick_cooldown
	kick_on_cooldown = true
	cooldown_time_attack_area = current_attack_speed/2
	is_kicking = true
	strike_shape.set_deferred("disabled", false)
	character_sprite.play("kick")
	shadow_sprite.play("kick")
	if is_player:
		emit_signal("kick_signal", current_kick_cooldown)
	
func move(direction: int) -> void:
	if direction != facing_direction and recursion_index < 10:
		recursion_index += 1
		turn(direction)
		return
	ray_cast_2d.force_raycast_update()
	if ray_cast_2d.is_colliding() or move_on_cooldown or is_attacking or attack_windup or is_kicking or is_turning or moving:
		return
	elif is_blocking:
		_on_block_timeout()
	movement_audio_player.pitch_scale = randf_range(0.1, 1.9)
	movement_audio_player.volume_db = randf_range(6.0, 9.0)
	movement_audio_player["parameters/switch_to_clip"] = "Steps Armored"
	movement_audio_player.play()
	steps_timer = 0.3
	moving = true
	character_sprite.play("walk")
	shadow_sprite.play("walk")
	var previous_position = global_position
	match direction:
		DIR.NORTH:
			global_position += Vector2(0, -128)
		DIR.EAST:
			global_position += Vector2(128, 0)
		DIR.SOUTH:
			global_position += Vector2(0, 128)
		DIR.WEST:
			global_position += Vector2(-128, 0)	
	character_sprite.global_position = previous_position
	var move_sprite = create_tween()
	move_sprite.tween_property(character_sprite, "global_position", global_position, (40/current_speed))
	cooldown_time_moving = 30/current_speed
	cooldown_time_move = current_move_cooldown
	move_on_cooldown = true
	recursion_index = 0
	if is_player:
		emit_signal("move_signal", current_move_cooldown)
		SignalBus.emit_signal("player_move", position)

func turn(direction : int) -> void:
	if is_attacking or moving or attack_windup or is_kicking:
		return
	elif is_blocking:
		_on_block_timeout()
	match direction:
		DIR.NORTH:
			if rotation_degrees == 0 or rotation_degrees == 360 or facing_direction == 0:
				move(DIR.NORTH)
			else:
				var turn_tween = create_tween()
				if rotation_degrees == 90 or facing_direction == 1:
					turn_tween.tween_property(self, "rotation_degrees", 0, 0.15)
				if rotation_degrees == 270 or facing_direction == 3:
					turn_tween.tween_property(self, "rotation_degrees", 360, 0.15)
				else:
					if team == "knight":
						turn_tween.tween_property(self, "rotation_degrees", 0, 0.15)
					else:
						turn_tween.tween_property(self, "rotation_degrees", 360, 0.15)
				is_turning = true
				facing_direction = 0
				cooldown_time_turn = 0.15
		DIR.EAST:
			if rotation_degrees == 90:
				move(DIR.EAST)
			else:
				is_turning = true
				var turn_tween = create_tween()
				turn_tween.tween_property(self, "rotation_degrees", 90, 0.15)
				facing_direction = 1
				cooldown_time_turn = 0.15
		DIR.SOUTH:
			if rotation_degrees == 180:
				move(DIR.SOUTH)
			else:
				is_turning = true
				var turn_tween = create_tween()
				turn_tween.tween_property(self, "rotation_degrees", 180, 0.15)
				facing_direction = 2
				cooldown_time_turn = 0.15
		DIR.WEST:
			if rotation_degrees == 270:
				move(DIR.WEST)
			else:
				is_turning = true
				var turn_tween = create_tween()
				turn_tween.tween_property(self, "rotation_degrees", 270, 0.15)
				facing_direction = 3
				cooldown_time_turn = 0.15

func _on_move_timeout() -> void:
	moving = false
	await get_tree().create_timer(0.15).timeout
	if !moving and !is_attacking and !is_kicking and !is_blocking and not is_in_group("dead"):
		character_sprite.play("idle")
		shadow_sprite.play("idle")

func _on_target_timeout() -> void:
	has_target = false

func _on_attack_cooldown_timeout() -> void:
	attack_on_cooldown = false

func _on_attack_timeout() -> void:
	strike_shape.set_deferred("disabled", true)
	is_attacking = false
	attack_direction = -1
	character_sprite.play("idle")
	shadow_sprite.play("idle")

func _on_attack_begin() -> void:
	strike_shape.set_deferred("disabled", false)
	attack_windup = false
	cooldown_time_attack_area = current_attack_speed/2
	is_attacking = true
	ray_cast_2d.force_raycast_update()
	if ray_cast_2d.is_colliding() and ray_cast_2d.get_collider().is_in_group("wall"):
		SignalBus.wall_hit.emit(self.position)

func _on_block_timeout() -> void:
	is_blocking = false
	block_direction = -1
	block_right_sprite.hide()
	block_left_sprite.hide()

func _on_block_cooldown_timeout() -> void:
	block_on_cooldown = false

func _on_move_cooldown_timeout() -> void:
	move_on_cooldown = false
	#if !moving:
	#	character_sprite.play("idle")
	#	shadow_sprite.play("idle")

func _on_kick_timeout() -> void:
	is_kicking = false
	strike_shape.set_deferred("disabled", true)
	character_sprite.play("idle")
	shadow_sprite.play("idle")

func _on_kick_cooldown_timeout() -> void:
	kick_on_cooldown = false

func get_block_direction() -> int:
	if block_to_right:
		block_right_sprite.show()
		block_left_sprite.hide()
		var block_dir = ((facing_direction + 1) + 4) % 4
		return block_dir
	else:
		block_right_sprite.hide()
		block_left_sprite.show()
		var block_dir =((facing_direction - 1)+4) % 4
		return block_dir

func kicked(kicker : CharacterBody2D, enemy_facing_dir : int) -> void:
	var stun_duration: float = (kicker.current_kick_stun_duration / current_level)
	stun_particle.emitting = true
	var log_string : String = "Kicked! Stunned for " + str(stun_duration) + " seconds"
	character_sprite.play("hit")
	shadow_sprite.play("hit")
	_on_block_timeout()
	_on_attack_timeout()
	attack_windup = false
	is_turning = true
	cooldown_time_turn += stun_duration
	stun_on_cooldown = true
	cooldown_time_stun = stun_duration
	attack_on_cooldown = true
	cooldown_time_attack += stun_duration
	block_on_cooldown = true
	cooldown_time_block += stun_duration
	move_on_cooldown = true
	cooldown_time_move += stun_duration
	kick_on_cooldown = true
	cooldown_time_kick += stun_duration
	cooldown_time_health_regen += stun_duration
	if is_player:
		emit_signal("kick_signal", stun_duration)
		emit_signal("attack_signal", stun_duration)
		emit_signal("block_signal", stun_duration)
		emit_signal("move_signal", stun_duration)
	var _old_rotation = rotation_degrees
	if not moving:
		match enemy_facing_dir:
			DIR.NORTH:
				rotation_degrees = 0
				ray_cast_2d.force_raycast_update()
				if ray_cast_2d.is_colliding() and ray_cast_2d.get_collider().is_in_group("cliff"):
					global_position += Vector2(0, -128)
					log_string = str(team) + " is falling off cliff!"
					falling = true
					killed(kicker)
					die()
				elif not ray_cast_2d.is_colliding():
					global_position += Vector2(0, -128)
				rotation_degrees = _old_rotation
				character_sprite.global_position = global_position
			DIR.EAST:
				rotation_degrees = 90
				ray_cast_2d.force_raycast_update()
				if ray_cast_2d.is_colliding() and ray_cast_2d.get_collider().is_in_group("cliff"):
					global_position += Vector2(128, 0)
					log_string = str(team) + " is falling off cliff!"
					falling = true
					killed(kicker)
					die()	
				elif not ray_cast_2d.is_colliding():
					global_position += Vector2(128, 0)
				rotation_degrees = _old_rotation
				character_sprite.global_position = global_position
			DIR.SOUTH:
				rotation_degrees = 180
				ray_cast_2d.force_raycast_update()
				if ray_cast_2d.is_colliding() and ray_cast_2d.get_collider().is_in_group("cliff"):
					global_position += Vector2(0, 128)
					log_string = str(team) + " is falling off cliff!"
					falling = true
					killed(kicker)
					die()
				elif not ray_cast_2d.is_colliding():
					global_position += Vector2(0, 128)
				rotation_degrees = _old_rotation
				character_sprite.global_position = global_position
			DIR.WEST:
				rotation_degrees = 270
				ray_cast_2d.force_raycast_update()
				if ray_cast_2d.is_colliding() and ray_cast_2d.get_collider().is_in_group("cliff"):
					global_position += Vector2(-128, 0)
					log_string = str(team) + " is falling off cliff!"
					falling = true
					killed(kicker)
					die()
				elif not ray_cast_2d.is_colliding():
					global_position += Vector2(-128, 0)
				rotation_degrees = _old_rotation
				character_sprite.global_position = global_position
	SignalBus.combat_log_entry.emit(log_string)

func killed(attacker : CharacterBody2D) -> void:
	if attacker != null and attacker.team != team:
		attacker.current_xp += current_level*100
	if attacker.is_player and not is_player:
		emit_signal("killed_by_player", team)
		SignalBus.combat_log_entry.emit("Player killed " + str(self.team))		
	if attacker.team == "knight" and not attacker.is_player:
		emit_signal("killed_by_knight", team)
		SignalBus.combat_log_entry.emit(str(attacker.team) + " killed " + str(self.team))
	elif attacker.team == "orc" and not is_player:
		emit_signal("killed_by_orc", team)
		SignalBus.combat_log_entry.emit(str(attacker.team) + " killed " + str(self.team))
	elif is_player:
		SignalBus.combat_log_entry.emit("You were killed by " + str(attacker.team))

func hit(attacker:CharacterBody2D, incoming_damage: int) -> void:
	current_health -= incoming_damage
	blood_particle.restart()
	blood_particle.emitting = true
	var flash_tween = create_tween()
	character_sprite.self_modulate = Color(3, 3, 3, 1)
	flash_tween.tween_property(character_sprite, "self_modulate", Color(1, 1, 1, 1), 0.1)
	SignalBus.emit_signal("health_signal", current_health, base_health, self)
	if current_health <= 0:
		killed(attacker)
		die()
	else:
		var log_string : String
		if not attacker.is_boss:
			if not is_player:
				log_string = str(self.team) + " hit by " + str(attacker.team) + " for " + str(incoming_damage) + " damage!"
			else:
				log_string = "Player hit by " + str(attacker.team) + " for " + str(incoming_damage) + " damage!"
			SignalBus.combat_log_entry.emit(log_string)
		cooldown_time_health_regen += current_health_regen
		character_sprite.play("hit")
		shadow_sprite.play("hit")

func die(_mute : bool = false) -> void:
	if not _mute:
		combat_audio_player["parameters/switch_to_clip"] = "Player Death"
		combat_audio_player.volume_db = 1.0
		combat_audio_player.pitch_scale = randf_range(0.3, 1.7)
		combat_audio_player.play()
	add_to_group("dead")
	remove_from_group(team)
	remove_from_group("ai")
	if player_camera:
		player_camera.reparent(self)
	for child in get_children():
		if not child.name == "BloodParticle" and not child == player_camera and not child == combat_audio_player:
			child.queue_free()
		else:
			get_tree().create_timer(10.0).timeout.connect(child.queue_free)
	character_sprite = AnimatedSprite2D.new()
	character_sprite.sprite_frames = ResourceLoader.load("res://character/" + team + "/" + team + "_spriteframes.tres")
	add_child(character_sprite)
	z_index = -1
	character_sprite.play("die")
	var new_tween = create_tween()
	new_tween.tween_property(character_sprite, "self_modulate", Color(1.5, 1.5, 1.5, 0.8), 5.0)
	#remove_from_group(team)
	if is_player:
		is_player = false
		get_tree().create_timer(2.0).timeout.connect(get_parent().spawn_player.bind(current_level/2))
	
func _on_health_regen_timeout() -> void:
	current_health += 1
	if current_health > base_health:
		current_health = base_health
	cooldown_time_health_regen += current_health_regen
	SignalBus.emit_signal("health_signal", current_health, base_health, self)

func _on_attack_area_entered(area: Area2D) -> void:
	var _target = area.get_parent()
	var log_string : String
	if _target is CharacterBody2D:
		if is_kicking:
			_target.kicked(self, facing_direction)
			combat_audio_player["parameters/switch_to_clip"] = "Impact Body"
			combat_audio_player.play()
			strike_shape.set_deferred("disabled" , true)
			return
		elif _target.team == team:
			return
		elif _target.block_direction == attack_direction and _target.is_blocking:
			log_string = str(_target.team) + " blocked " + str(self.team) + " attack from direction: " + str(attack_direction)
			SignalBus.combat_log_entry.emit(log_string)
			combat_audio_player["parameters/switch_to_clip"] = "Impact Wooden"
			combat_audio_player.play()
			spark_particle.emitting = true
		elif _target.attack_direction == attack_direction and _target.is_preparing_attack:
			log_string = str(_target.team) + " parried " + str(self.team) + " attack from direction: " + str(attack_direction)
			SignalBus.combat_log_entry.emit(log_string)
			combat_audio_player["parameters/switch_to_clip"] = "Impact Metal Armour"
			combat_audio_player.play()
			spark_particle.emitting = true
			_target.hit(self, current_attack_damage/2)
		else:
			_target.hit(self, current_attack_damage)
			combat_audio_player["parameters/switch_to_clip"] = "Impact Sword And Swipe"
			combat_audio_player.play()

func shake_screen() -> void:
	if player_camera != null:
		var original_offset = player_camera.offset
		var strength = randf_range(1.0, 10.0)
		var duration = randf_range(0.1, 0.5)
		var direction = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0))
		player_camera.offset += Vector2(direction.x*strength, direction.y*strength)
		var shake_tween = create_tween()
		shake_tween.tween_property(player_camera, "offset", original_offset, duration)
