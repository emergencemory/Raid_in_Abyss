extends CharacterBody2D
class_name BossManager

const GAME_DATA : Script = preload("res://data/GameData.gd")

enum DIR {
	NORTH,
	EAST,
	SOUTH,
	WEST
}

@onready var stun_particle: GPUParticles2D = $StunParticle
@onready var blood_particle: GPUParticles2D = $BloodParticle
@onready var spark_particle: GPUParticles2D = $SparkParticle
@onready var attack_from_right_sprite: Sprite2D = $AttackFromRightSprite
@onready var attack_from_left_sprite: Sprite2D = $AttackFromLeftSprite
@onready var strike_shape_front: CollisionShape2D = $CharacterSprite/HitBoxFront/StrikeShapeFront
@onready var strike_shape_front_2: CollisionShape2D = $CharacterSprite/HitBoxFront2/StrikeShapeFront2
@onready var strike_shape_left: CollisionShape2D = $CharacterSprite/HitBoxLeft/StrikeShapeLeft
@onready var strike_shape_right: CollisionShape2D = $CharacterSprite/HitBoxRight/StrikeShapeRight
@onready var character_sprite: AnimatedSprite2D = $CharacterSprite
@onready var shadow_sprite: AnimatedSprite2D = $ShadowSprite
@onready var ray_cast_2d_front: RayCast2D = $CharacterCollider/RayCast2DFront
@onready var ray_cast_2d_front_2: RayCast2D = $CharacterCollider/RayCast2DFront2
@onready var ray_cast_2d_left: RayCast2D = $CharacterCollider/RayCast2DLeft
@onready var ray_cast_2d_right: RayCast2D = $CharacterCollider/RayCast2DRight
@onready var combat_audio_player: AudioStreamPlayer2D = $CombatAudioPlayer
@onready var movement_audio: AudioStreamPlayer2D = $MovementAudio
@onready var boss_audio: AudioStreamPlayer2D = $BossAudio
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var explosion_1: GPUParticles2D = $CharacterSprite/HitBoxFront2/StrikeShapeFront2/Explosion1
@onready var explosion_light_1: Sprite2D = $CharacterSprite/HitBoxFront2/StrikeShapeFront2/ExplosionLight1

var block_direction: int = -1
var is_blocking: bool = false

var recursion_index: int = 0
var has_target: bool = false
var is_player: bool = false
var is_boss: bool = true
var target: CharacterBody2D
var cooldown_time_target: float = 0.0
var team: String = "orc"
var order_ticks : float = 0.0
var current_xp: float
var current_level: int
#var current_xp_to_next_level: float
#var base_xp_to_next_level_multiplier: float
var level_up_multiplier: float
var level_up_addition: int

var base_health: int
var is_bleeding: bool = false
var bleed_cooldown: float = 0.0
var current_health: int
var stun_on_cooldown: bool = false
var cooldown_time_stun: float = 0.0

var facing_direction: int = 0
var is_turning: bool = false
var moving: bool = false
var current_speed: float 
var current_move_cooldown: float 
var move_on_cooldown: bool = false
var cooldown_time_turn: float = 0.0
var cooldown_time_move: float = 0.0
var movement_time: float = 0.0 
var steps_timer: float = 0.0

var is_preparing_attack: bool = false
var attack_direction: int = -1
var swing_from_right: bool = false

var attack_from_right_windup: bool = false
var right_windup_time: float = 0.0
var is_attacking_from_right: bool = false
var current_attack_from_right_damage: int
var current_attack_from_right_speed: float
var current_attack_from_right_cooldown: float
var attack_from_right_on_cooldown: bool = false
var cooldown_time_attack_from_right: float = 0.0
var attack_from_right_area_time: float = 0.0

var attack_from_left_windup: bool = false
var left_windup_time: float = 0.0
var is_attacking_from_left: bool = false
var current_attack_from_left_damage: int
var current_attack_from_left_speed: float
var current_attack_from_left_cooldown: float
var attack_from_left_on_cooldown: bool = false
var cooldown_time_attack_from_left: float = 0.0
var attack_from_left_area_time: float = 0.0

var is_stomping: bool = false
var current_stomp_damage: int
var current_stomp_speed: float
var current_kick_stun_duration: float
var current_stomp_cooldown: float
var stomp_on_cooldown: bool = false
var cooldown_time_stomp: float = 0.0
var stomp_area_time: float = 0.0
var is_starting_stomp: bool = false
var stomp_windup: float = 0.0

var is_jumping: bool = false
var current_jump_damage: int
var current_jump_speed: float
var current_jump_cooldown: float
var jump_on_cooldown: bool = false
var cooldown_time_jump: float = 0.0
var jump_area_time: float = 0.0
var is_landing: bool = false
var jump_land_area_time: float = 0.0

signal attack_signal(value: float)
signal jump_signal(value: float)
signal move_signal(value: float)
signal stomp_signal(value: float)
signal killed_by_player(team: String)
signal killed_by_knight(team: String)
signal killed_by_orc(team: String)

func _ready() -> void:
	current_level = GAME_DATA.boss_data["base_level"]
	current_xp = GAME_DATA.boss_data["base_xp"]
	#current_xp_to_next_level = GAME_DATA.boss_data["base_xp_to_next_level"]
	#base_xp_to_next_level_multiplier = GAME_DATA.boss_data["base_xp_to_next_level_multiplier"]
	level_up_multiplier = GAME_DATA.boss_data["level_up_multiplier"]
	level_up_addition = GAME_DATA.boss_data["level_up_addition"]

	base_health = GAME_DATA.boss_data["base_health"]
	current_health = base_health
	current_speed = GAME_DATA.boss_data["base_speed"]
	current_move_cooldown = GAME_DATA.boss_data["move_cooldown"]

	current_attack_from_left_damage = GAME_DATA.boss_data["attack_from_left_damage"]
	current_attack_from_left_speed = GAME_DATA.boss_data["attack_from_left_speed"]
	current_attack_from_left_cooldown = GAME_DATA.boss_data["attack_from_left_cooldown"]

	current_attack_from_right_damage = GAME_DATA.boss_data["attack_from_right_damage"]
	current_attack_from_right_speed = GAME_DATA.boss_data["attack_from_right_speed"]
	current_attack_from_right_cooldown = GAME_DATA.boss_data["attack_from_right_cooldown"]
	
	current_kick_stun_duration = GAME_DATA.boss_data["stomp_stun_duration"]
	current_stomp_speed = GAME_DATA.boss_data["stomp_speed"]
	current_stomp_cooldown = GAME_DATA.boss_data["stomp_cooldown"]
	current_stomp_damage = GAME_DATA.boss_data["stomp_damage"]

	current_jump_cooldown = GAME_DATA.boss_data["jump_cooldown"]
	current_jump_damage = GAME_DATA.boss_data["jump_damage"]
	current_jump_speed = GAME_DATA.boss_data["jump_speed"]
	
	animation_player.play("boss_idle")

	if is_player:
		SignalBus.emit_signal("health_signal", current_health, base_health, self)

func level_up(levels_to_gain: int = 1) -> void:
	if levels_to_gain == 0:
		return
	current_level += levels_to_gain
	SignalBus.emit_signal("leveled_up", self, current_level)
	
	#current_xp_to_next_level *= pow(base_xp_to_next_level_multiplier , levels_to_gain)
	
	base_health = level_up_addition*current_level
	current_health = base_health
	current_move_cooldown /= pow(level_up_multiplier , levels_to_gain)

	current_attack_from_left_damage = (level_up_addition*current_level)/2
	current_attack_from_left_cooldown /=  pow(level_up_multiplier , levels_to_gain)
	
	current_attack_from_right_damage = (level_up_addition*current_level)/2
	current_attack_from_right_cooldown /= pow(level_up_multiplier , levels_to_gain)

	current_stomp_damage = (level_up_addition*current_level)/2
	current_stomp_cooldown /= pow(level_up_multiplier , levels_to_gain)
	current_kick_stun_duration *=  pow(level_up_multiplier , levels_to_gain)

	current_jump_damage = (level_up_addition*current_level)/2
	current_jump_cooldown /= pow(level_up_multiplier , levels_to_gain)
	
	if is_player:
		SignalBus.emit_signal("request_reinforcements", team)

func _on_target_timeout() -> void:
	has_target = false

func _physics_process(delta) -> void:
	if is_in_group("dead"):
		set_physics_process(false)
		return
	if is_bleeding:
		if bleed_cooldown > 0:
			bleed_cooldown -= delta
		else:
			is_bleeding = false
			blood_particle.emitting = false
	if stun_on_cooldown:
		if cooldown_time_stun > 0:
			cooldown_time_stun -= delta
		else:
			stun_on_cooldown = false
			stun_particle.emitting = false
	if ray_cast_2d_front.is_colliding() and ray_cast_2d_front.get_collider().is_in_group("wall") and not is_jumping:
		SignalBus.wall_hit.emit(self.position)
	if ray_cast_2d_right.is_colliding() and ray_cast_2d_right.get_collider().is_in_group("wall") and not is_jumping:
		SignalBus.wall_hit.emit(self.position)
	if ray_cast_2d_left.is_colliding() and ray_cast_2d_left.get_collider().is_in_group("wall") and not is_jumping:
		SignalBus.wall_hit.emit(self.position)
	if attack_from_left_on_cooldown:
		if cooldown_time_attack_from_left > 0:
			cooldown_time_attack_from_left -= delta
		else:
			_on_attack_from_left_cooldown_timeout()
	if attack_from_right_on_cooldown:
		if cooldown_time_attack_from_right > 0:
			cooldown_time_attack_from_right -= delta
		else:
			_on_attack_from_right_cooldown_timeout()
	if jump_on_cooldown:
		if cooldown_time_jump > 0:
			cooldown_time_jump -= delta
		else:
			_on_jump_cooldown_timeout()
	if is_landing:
		if jump_land_area_time > 0:
			jump_land_area_time -= delta
		else:
			strike_shape_front.set_deferred("disabled", true)
			is_landing = false
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
		if movement_time > 0:
			movement_time -= delta
		else:
			_on_move_timeout()
		if steps_timer > 0:
			steps_timer -= delta
		else:
			movement_audio.play()
			SignalBus.emit_signal("shake_screen")
			steps_timer = 0.4
	if stomp_on_cooldown:
		if cooldown_time_stomp > 0:
			cooldown_time_stomp -= delta
		else:
			_on_stomp_cooldown_timeout()
	if attack_from_left_windup:
		if left_windup_time > 0:
			left_windup_time -= delta
		else:
			_on_attack_from_left_begin()
	if attack_from_right_windup:
		if right_windup_time > 0:
			right_windup_time -= delta
		else:
			_on_attack_from_right_begin()
	if is_attacking_from_left:
		if attack_from_left_area_time > 0:
			attack_from_left_area_time -= delta
		else:
			_on_attack_from_left_timeout()
	if is_attacking_from_right:
		if attack_from_right_area_time > 0:
			attack_from_right_area_time -= delta
		else:
			_on_attack_from_right_timeout()
	if is_jumping:
		if jump_area_time > 0:
			jump_area_time -= delta
		else:
			_on_jump_timeout()
	if is_starting_stomp:
		if stomp_windup > 0:
			stomp_windup -= delta
		else:
			stomp_lands()
	if is_stomping:
		if stomp_area_time > 0:
			stomp_area_time -= delta
		else:
			_on_stomp_timeout()
	if has_target:
		if cooldown_time_target > 0 and target != null and not target.is_in_group("dead"):
			cooldown_time_target -= delta
		else:
			_on_target_timeout()
	#if current_xp >= current_xp_to_next_level:
	#	level_up(1)


func prepare_attack_from_left() -> void:
	if is_attacking_from_left or is_attacking_from_right or attack_from_left_windup or attack_from_right_windup or is_stomping or is_starting_stomp or is_jumping or is_landing or attack_from_left_on_cooldown:
		return
	else:	
		attack_from_right_sprite.hide()
		attack_from_left_sprite.show()
		attack_direction = ((facing_direction+4) - 1) % 4
		is_preparing_attack = true
		

func attack_from_left() -> void:
	attack_from_left_sprite.hide()
	attack_from_right_sprite.hide()
	is_preparing_attack = false
	if attack_from_left_on_cooldown or is_attacking_from_left or is_attacking_from_right or moving or is_turning or is_stomping or is_starting_stomp or is_jumping or is_landing or attack_from_right_windup or attack_from_left_windup:
		return
	else:
		animation_player.play("boss_attack_from_left")
		shadow_sprite.play("attack_from_left")
		left_windup_time = current_attack_from_left_speed/2
		attack_from_left_windup = true
		cooldown_time_attack_from_left = current_attack_from_left_cooldown
		attack_from_left_on_cooldown = true
		if is_player:
			emit_signal("attack_signal", current_attack_from_left_cooldown)

func _on_attack_from_left_begin() -> void:
	strike_shape_front.set_deferred("disabled", false)
	attack_from_left_windup = false
	attack_from_left_area_time = current_attack_from_left_speed/2
	is_attacking_from_left = true

func _on_attack_from_left_timeout() -> void:
	strike_shape_front.set_deferred("disabled", true)
	is_attacking_from_left = false
	attack_direction = -1
	animation_player.play("boss_idle")
	shadow_sprite.play("idle")

func _on_attack_from_left_cooldown_timeout() -> void:
	attack_from_left_on_cooldown = false

func prepare_attack_from_right() -> void:
	if is_attacking_from_left or is_attacking_from_right or attack_from_left_windup or attack_from_right_windup or is_stomping or is_starting_stomp or is_jumping or is_landing or attack_from_right_on_cooldown:
		return
	else:
		attack_from_left_sprite.hide()
		attack_from_right_sprite.show()
		attack_direction = ((facing_direction+4) + 1) % 4
		is_preparing_attack = true

func attack_from_right() -> void:
	attack_from_left_sprite.hide()
	attack_from_right_sprite.hide()
	is_preparing_attack = false
	if attack_from_right_on_cooldown or is_attacking_from_left or is_attacking_from_right or moving or is_turning or is_stomping or is_starting_stomp or is_jumping or is_landing or attack_from_left_windup or attack_from_right_windup:
		return
	else:
		boss_audio["parameters/switch_to_clip"] = "Flame Sword"
		boss_audio.play()
		animation_player.play("boss_attack_from_right")
		shadow_sprite.play("attack_from_right")
		right_windup_time = current_attack_from_right_speed/2.5
		attack_from_right_windup = true
		if is_player:
			emit_signal("attack_signal", current_attack_from_right_cooldown)

func _on_attack_from_right_begin() -> void:
	strike_shape_front.set_deferred("disabled", false)
	strike_shape_front_2.set_deferred("disabled", false)
	attack_from_right_windup = false
	attack_from_right_area_time = current_attack_from_right_speed/2
	is_attacking_from_right = true
	cooldown_time_attack_from_right = current_attack_from_right_cooldown
	attack_from_right_on_cooldown = true

func _on_attack_from_right_timeout() -> void:
	strike_shape_front.set_deferred("disabled", true)
	strike_shape_front_2.set_deferred("disabled", true)
	is_attacking_from_right = false
	attack_direction = -1

func _on_attack_from_right_cooldown_timeout() -> void:
	attack_from_right_on_cooldown = false

func jump() -> void:
	if jump_on_cooldown or not has_target or is_attacking_from_left or is_attacking_from_right or moving or is_turning or attack_from_left_windup or attack_from_right_windup or is_stomping or is_starting_stomp:
		return
	if target != null and not target.is_in_group("dead"):
		var old_position = global_position
		match facing_direction:
			DIR.NORTH:
				global_position = target.global_position + Vector2(0, 128)
			DIR.EAST:
				global_position = target.global_position + Vector2(-128, 0)
			DIR.SOUTH:
				global_position = target.global_position + Vector2(0, -128)
			DIR.WEST:
				global_position = target.global_position + Vector2(128, 0)
		character_sprite.global_position = old_position
		var sprite_tween = create_tween()
		sprite_tween.tween_property(character_sprite, "global_position", global_position, current_jump_speed)
	else:
		return
	boss_audio["parameters/switch_to_clip"] = "Boss Jump"
	boss_audio.play()
	animation_player.play("boss_jump")
	SignalBus.emit_signal("shake_screen")
	shadow_sprite.play("jump")
	jump_area_time = current_jump_speed
	is_jumping = true
	if is_player:
		emit_signal("jump_signal", current_jump_cooldown)

func _on_jump_timeout() -> void:
	boss_audio["parameters/switch_to_clip"] = "Boss Stomp"
	boss_audio.play()
	strike_shape_front.set_deferred("disabled", false)
	jump_land_area_time = current_jump_speed/2
	cooldown_time_jump = current_jump_cooldown
	is_jumping = false
	jump_on_cooldown = true
	is_landing = true
	SignalBus.emit_signal("shake_screen")
	SignalBus.emit_signal("shockwave", self.position)

func _on_jump_cooldown_timeout() -> void:
	jump_on_cooldown = false

func stomp() -> void:
	if stomp_on_cooldown or is_attacking_from_left or is_attacking_from_right or is_turning or attack_from_left_windup or attack_from_right_windup or is_jumping or is_landing or moving:
		return
	boss_audio["parameters/switch_to_clip"] = "Aoe Stomp"
	boss_audio.play()
	animation_player.play("boss_stomp")
	shadow_sprite.play("stomp")
	stomp_windup = current_stomp_speed
	cooldown_time_stomp = current_stomp_cooldown
	stomp_on_cooldown = true
	is_starting_stomp = true
	if is_player:
		emit_signal("stomp_signal", current_stomp_cooldown)

func stomp_lands() -> void:
	is_starting_stomp = false
	stomp_area_time = current_stomp_speed/2
	is_stomping = true
	strike_shape_front.set_deferred("disabled", false)
	strike_shape_left.set_deferred("disabled", false)
	strike_shape_right.set_deferred("disabled", false)
	SignalBus.emit_signal("shake_screen")
	SignalBus.emit_signal("shockwave", self.position)


func _on_stomp_timeout() -> void:
	is_stomping = false
	strike_shape_front.set_deferred("disabled", true)
	strike_shape_left.set_deferred("disabled", true)
	strike_shape_right.set_deferred("disabled", true)

func _on_stomp_cooldown_timeout() -> void:
	stomp_on_cooldown = false

func move(direction: int) -> void:
	if direction != facing_direction and recursion_index < 10:
		recursion_index += 1
		turn(direction)
		return
	ray_cast_2d_front.force_raycast_update()
	if ray_cast_2d_front.is_colliding() or move_on_cooldown or is_attacking_from_left or is_attacking_from_right or attack_from_left_windup or attack_from_right_windup or is_stomping or is_starting_stomp or is_turning or moving or is_jumping or is_landing:
		return
	moving = true
	steps_timer = 0.4

	animation_player.play("boss_walk")
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
	shadow_sprite.global_position = previous_position
	var move_sprite = create_tween()
	move_sprite.tween_property(character_sprite, "global_position", global_position, (30/current_speed))
	var shadow_sprite_tween = create_tween()
	shadow_sprite_tween.tween_property(shadow_sprite, "global_position", global_position, (30/current_speed))
	movement_time = 30/current_speed
	cooldown_time_move = current_move_cooldown
	move_on_cooldown = true
	recursion_index = 0
	if is_player:
		emit_signal("move_signal", current_move_cooldown)
		SignalBus.emit_signal("player_move", position)

func _on_move_timeout() -> void:
	moving = false
	animation_player.play("boss_idle")
	shadow_sprite.play("idle")

func _on_move_cooldown_timeout() -> void:
	move_on_cooldown = false

func turn(direction : int) -> void:
	if is_attacking_from_left or is_attacking_from_right or moving or attack_from_left_windup or attack_from_right_windup or is_stomping or is_starting_stomp or is_jumping or is_landing:
		return
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

func kicked(kicker : CharacterBody2D, enemy_facing_dir : int) -> void:
	var stun_duration: float = kicker.current_kick_stun_duration
	stun_particle.emitting = true
	var log_string : String = "Kicked! Stunned for " + str(stun_duration/(level_up_multiplier*2)) + " seconds"
	_on_stomp_timeout()
	#_on_jump_timeout()
	_on_attack_from_left_timeout()
	_on_attack_from_right_timeout()
	attack_from_left_windup = false
	attack_from_right_windup = false
	cooldown_time_turn += stun_duration/(current_level*level_up_multiplier*2)
	stun_on_cooldown = true
	cooldown_time_stun = stun_duration/(current_level*level_up_multiplier*2)
	attack_from_left_on_cooldown = true
	cooldown_time_attack_from_left += stun_duration/(current_level*level_up_multiplier*2)
	attack_from_right_on_cooldown = true
	cooldown_time_attack_from_right += stun_duration/(current_level*level_up_multiplier*2)
	jump_on_cooldown = true
	cooldown_time_jump += stun_duration/(current_level*level_up_multiplier*2)
	move_on_cooldown = true
	cooldown_time_move += stun_duration/(current_level*level_up_multiplier*2)
	stomp_on_cooldown = true
	cooldown_time_stomp += stun_duration/(current_level*level_up_multiplier*2)
	if is_player:
		emit_signal("stomp_signal", stun_duration)
		emit_signal("attack_signal", stun_duration)
		emit_signal("jump_signal", stun_duration)
		emit_signal("move_signal", stun_duration)
	SignalBus.combat_log_entry.emit(log_string)

func killed(attacker : CharacterBody2D) -> void:
	if attacker != null:
		attacker.current_xp += current_level*1000
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

func hit(attacker:CharacterBody2D, incoming_damage : int) -> void:
	bleed_cooldown += 1.0
	is_bleeding = true
	blood_particle.emitting = true
	current_health -= incoming_damage
	SignalBus.emit_signal("boss_health_signal", current_health, base_health, self)
	if current_health <= 0:
		killed(attacker)
		die()
	else:
		var flash_tween = create_tween()
		character_sprite.self_modulate = Color(3, 3, 3, 1)
		flash_tween.tween_property(character_sprite, "self_modulate", Color(1, 1, 1, 1), 0.1)
		var log_string : String
		if not is_player:
			log_string = str(self.team) + " hit by " + str(attacker.team) + " for " + str(incoming_damage) + " damage!"
			SignalBus.combat_log_entry.emit(log_string)
		else:
			log_string = "Player hit by " + str(attacker.team) + " for " + str(incoming_damage) + " damage!"
			SignalBus.combat_log_entry.emit(log_string)

func die() -> void:
	SignalBus.emit_signal("boss_killed")
	boss_audio["parameters/switch_to_clip"] = "Boss Death"
	boss_audio.play()
	add_to_group("dead")
	remove_from_group(team)
	remove_from_group("ai")
	remove_from_group("boss")
	z_index = 0
	animation_player.play("boss_die")
	shadow_sprite.play("die")
	for child in get_children():
		if not child is AudioStreamPlayer2D and not child is GPUParticles2D and not child is AnimatedSprite2D and not child is AnimationPlayer:
			child.queue_free()
		elif not child == character_sprite:
			get_tree().create_timer(10.0).timeout.connect(child.queue_free)
	strike_shape_front.queue_free()
	strike_shape_front_2.queue_free()
	strike_shape_left.queue_free()
	strike_shape_right.queue_free()
	SignalBus.emit_signal("shake_screen")
	character_sprite.material = null
	var new_tween = create_tween()
	new_tween.tween_property(character_sprite, "self_modulate", Color(0.3, 0.3, 0.3, 0.9), 10.0)
	blood_particle.emitting = false
	if is_player:
		is_player = false
		get_tree().create_timer(2.0).timeout.connect(get_parent().spawn_player)

func _on_attack_area_entered(area: Area2D) -> void:
	var _target = area.get_parent()
	var log_string : String
	if _target is CharacterBody2D:
		if is_stomping or is_starting_stomp:
			log_string = "Boss stomped on " + str(_target.team) + " for " + str(current_stomp_damage) + " damage!"
			SignalBus.combat_log_entry.emit(log_string)
			combat_audio_player["parameters/switch_to_clip"] = "Impact Body"
			SignalBus.emit_signal("shake_screen")
			combat_audio_player.play()
			_target.kicked(self, randi_range(0,3))
		elif is_jumping or is_landing:
			log_string = "Boss jumped on " + str(_target.team) + " for " + str(current_jump_damage) + " damage!"
			SignalBus.combat_log_entry.emit(log_string)
			combat_audio_player["parameters/switch_to_clip"] = "Impact Body"
			SignalBus.emit_signal("shake_screen")
			combat_audio_player.play()
			_target.hit(self, current_jump_damage)
		elif is_attacking_from_right:
			log_string = "Boss attacked " + str(_target.team) + " from the right for " + str(current_attack_from_right_damage) + " damage!"
			SignalBus.combat_log_entry.emit(log_string)
			SignalBus.emit_signal("shake_screen")
			combat_audio_player["parameters/switch_to_clip"] = "Impact Sword and Swipe"
			combat_audio_player.play()
			explosion_1.emitting = true
			explosion_light_1.modulate = Color(1.0, 1.0, 1.0, 0.5)
			var light_1_tween = create_tween()
			light_1_tween.tween_property(explosion_light_1, "modulate", Color(1.0, 1.0, 1.0, 0.0), 0.5)
			_target.hit(self, current_attack_from_right_damage)
		elif _target.is_blocking:
			log_string = "Boss attack on " + str(_target.team) + " from the left was partially blocked for " + str(current_attack_from_left_damage/2) + " damage!"
			SignalBus.combat_log_entry.emit(log_string)
			spark_particle.emitting = true
			_target.hit(self, current_attack_from_left_damage/2)
			combat_audio_player["parameters/switch_to_clip"] = "Impact Body"
			combat_audio_player.play()
		elif _target.is_preparing_attack:
			log_string = "Boss attack on " + str(_target.team) + " from the left was partially parried for " + str(current_attack_from_left_damage/2) + " damage!"
			SignalBus.combat_log_entry.emit(log_string)
			_target.hit(self, current_attack_from_left_damage/2)
			spark_particle.emitting = true
			combat_audio_player["parameters/switch_to_clip"] = "Impact Metal Armour"
			combat_audio_player.play()
		else:
			log_string = "Boss attacked " + str(_target.team) + " from the left for " + str(current_attack_from_left_damage) + " damage!"
			SignalBus.combat_log_entry.emit(log_string)
			_target.hit(self, current_attack_from_left_damage)
			combat_audio_player["parameters/switch_to_clip"] = "Impact Body"
			combat_audio_player.play()
