extends Node2D
class_name MapManager

@onready var wall_layer: TileMapLayer = $WallLayer
@onready var ground_layer: TileMapLayer = $GroundLayer
@onready var cliff_layer: TileMapLayer = $CliffLayer
@onready var splat_1: Texture = preload("res://map/effects/blood_1.png")
@onready var splat_2: Texture = preload("res://map/effects/blood_2.png")
@onready var splat_3: Texture = preload("res://map/effects/blood_3.png")
@onready var blood_pool: Texture = preload("res://character/effects/blood.png")
@onready var shadow_layer: TileMapLayer = $ShadowLayer
@onready var rubble_particle_1: GPUParticles2D = $RubbleParticle1
@onready var rubble_particle_2: GPUParticles2D = $RubbleParticle2
@onready var rubble_particle_3: GPUParticles2D = $RubbleParticle3
@onready var rubble_particle_4: GPUParticles2D = $RubbleParticle4
@onready var rubble_particle_5: GPUParticles2D = $RubbleParticle5
@onready var rubble_particle_6: GPUParticles2D = $RubbleParticle6
@onready var rubble_particle_7: GPUParticles2D = $RubbleParticle7
@onready var rubble_particle_8: GPUParticles2D = $RubbleParticle8
@onready var environment_audio: AudioStreamPlayer2D = $EnvironmentAudio

@onready var particle_init: Node2D = $Node2D

var rubble_emitters: Array = []
var emitter_index : int = 0
var chunk_height: int = 16   
var chunk_width: int = 32
var tile_size: int = 128  
var texture_library: Dictionary = {}  
var noise : FastNoiseLite   
var player : CharacterBody2D

func _ready() -> void:
	SignalBus.health_signal.connect(spawn_blood)
	SignalBus.player_move.connect(generate_chunk)
	SignalBus.console_flush_map.connect(_on_flush_map)
	SignalBus.wall_hit.connect(destroy_wall)
	SignalBus.boss_health_signal.connect(spawn_boss_blood)
	SignalBus.shockwave.connect(_on_shockwave)
	SignalBus.next_layer.connect(_on_next_layer)
	noise = FastNoiseLite.new()
	noise.seed = randi()
	noise.frequency = .2
	generate_chunk(Vector2(0,0))
	spawn_shadows()
	rubble_emitters = [
		rubble_particle_1,
		rubble_particle_2,
		rubble_particle_3,
		rubble_particle_4,
		rubble_particle_5,
		rubble_particle_6,
		rubble_particle_7,
		rubble_particle_8
	]
	#init_particles()

func init_particles() -> void:
	for child in particle_init.get_children():
		child.emitting = true
	get_tree().create_timer(5.0).timeout.connect(particle_init.queue_free)

func _on_shockwave(char_pos: Vector2) -> void:
	var shockwave_pos : Vector2i = ground_layer.local_to_map(char_pos)
	spawn_rubble(shockwave_pos)

func _on_next_layer() -> void:
	_on_flush_map()
	unload_corpses(Vector2i(-9000, -9000))
	unload_textures(Vector2i(-9000, -9000))

func destroy_wall(char_pos : Vector2) -> void:
	## Destroys the wall and spawns rubble
	var tile_pos = wall_layer.local_to_map(char_pos)
	environment_audio.position = char_pos
	environment_audio.volume_db =  17
	environment_audio.pitch_scale = randf_range(0.3, 1.7)
	environment_audio.play()
	for x_range in range(tile_pos.x -1, tile_pos.x +2):
		for y_range in range(tile_pos.y -2, tile_pos.y +2):
			var check_tile = Vector2(x_range, y_range)
			if wall_layer.get_cell_source_id(check_tile) != -1:
				wall_layer.erase_cell(check_tile)
				spawn_rubble(check_tile)
				ground_layer.set_cell(check_tile, 0, Vector2i(0,0))
			if shadow_layer.get_cell_source_id(check_tile) != -1:
				shadow_layer.erase_cell(check_tile)

func spawn_rubble(check_tile : Vector2i):
	var _rubble_particle : GPUParticles2D = rubble_emitters[emitter_index]
	emitter_index = (emitter_index + 1) % rubble_emitters.size()
	_rubble_particle.position = ground_layer.map_to_local(check_tile)
	_rubble_particle.restart()
	_rubble_particle.emitting = true

func _on_flush_map() -> void:
	var cliff_tiles = cliff_layer.get_used_cells()
	var wall_tiles = wall_layer.get_used_cells()
	var ground_tiles = ground_layer.get_used_cells()
	var shadow_tiles = shadow_layer.get_used_cells()
	for tile in shadow_tiles:
		shadow_layer.erase_cell(tile)
	for tile in cliff_tiles:
		cliff_layer.erase_cell(tile)
	for tile in wall_tiles:
		wall_layer.erase_cell(tile)
	for tile in ground_tiles:
		ground_layer.erase_cell(tile)

func spawn_shadows() -> void:
	var wall_tiles = wall_layer.get_used_cells()
	for tile in wall_tiles:
		if shadow_layer.get_cell_source_id(tile) != -1:
			continue
		else:
			shadow_layer.set_cell(tile, 0, Vector2i(0,0))
			await(get_tree().physics_frame)

func spawn_label(label_string: String, _position : Vector2, _color : Color) -> void:
	var _label : Label = Label.new()
	_label.text = label_string
	_label.position = _position
	_label.self_modulate = _color
	_label.z_index = 2
	add_child(_label)
	get_tree().create_timer(1.1).timeout.connect(_label.queue_free)

func spawn_blood(value: int, _base_value: int, character: CharacterBody2D) -> void:
	## spawns blood textures and spawns damage label
	var label_string : String = str(value) + " / " + str(_base_value) + " HP"
	if value == _base_value:
		spawn_label(label_string, character.global_position, Color(.5,3,.5,1))
		return
	var blood_effect :Sprite2D = Sprite2D.new()
	blood_effect.global_position = character.global_position + Vector2(randf_range(24, 84), randf_range(-30, 30)) 
	blood_effect.scale = Vector2(randf_range(0.5, 1.5), randf_range(0.5, 1.5))
	blood_effect.rotation_degrees = randf_range(0, 360)
	blood_effect.self_modulate = Color(0.5, 0.5, 0.5, 0.8)
	blood_effect.z_index = -1
	add_child(blood_effect)
	if value > 0:
		spawn_label(label_string, character.global_position, Color(3,.5,.5,1))
		var roll = randi_range(0,2)
		match roll:
			0:
				blood_effect.texture = splat_1
			1:
				blood_effect.texture = splat_2
			2:
				blood_effect.texture = splat_3
	else:
		label_string =  "0  / " + str(_base_value) + " HP - DEAD"
		spawn_label(label_string, character.global_position, Color(.5,.5,.5,1))
		blood_effect.texture = blood_pool
	var tween = create_tween()
	tween.tween_property(blood_effect, "scale", Vector2(9,9), 20.0)
	texture_library[blood_effect] = ground_layer.local_to_map(blood_effect.position)

#only difference with above is blood color, can be combined to optimize
func spawn_boss_blood(value: int, _base_value: int, character: CharacterBody2D) -> void:
	var label_string : String = str(value) + " / " + str(_base_value) + " HP"
	if value == _base_value:
		spawn_label(label_string, character.global_position, Color(.5,3,.5,1))
		return
	var blood_effect :Sprite2D = Sprite2D.new()
	blood_effect.global_position = character.global_position + Vector2(randf_range(24, 84), randf_range(-30, 30)) 
	blood_effect.scale = Vector2(randf_range(0.5, 1.5), randf_range(0.5, 1.5))
	blood_effect.rotation_degrees = randf_range(0, 360)
	blood_effect.self_modulate = Color(0.0, 0.0, 0.0, 0.8)
	add_child(blood_effect)
	if value > 0:
		spawn_label(label_string, character.global_position, Color(3,.5,.5,1))
		var roll = randi_range(0,2)
		match roll:
			0:
				blood_effect.texture = splat_1
			1:
				blood_effect.texture = splat_2
			2:
				blood_effect.texture = splat_3
	else:
		label_string =  "0  / " + str(_base_value) + " HP - DEAD"
		spawn_label(label_string, character.global_position, Color(.5,.5,.5,1))
		blood_effect.texture = blood_pool
	var tween = create_tween()
	tween.tween_property(blood_effect, "scale", Vector2(9,9), 20.0)
	texture_library[blood_effect] = ground_layer.local_to_map(blood_effect.position)

func generate_chunk(chunk_position: Vector2) -> void:
	## Generate terrain as the player moves
	var tile_pos = wall_layer.local_to_map(chunk_position)
	for y in range(chunk_height):
		for x in range(chunk_width):
			var world_x = tile_pos.x - (chunk_width / 2) + x
			var world_y = tile_pos.y - (chunk_height / 2) + y
			if wall_layer.get_cell_source_id(Vector2i(world_x, world_y)) != -1:
				continue
			if cliff_layer.get_cell_source_id(Vector2i(world_x, world_y)) != -1:
				continue
			if ground_layer.get_cell_source_id(Vector2i(world_x, world_y)) != -1:
				continue
			if y >= 15:
				cliff_layer.set_cell(Vector2i(world_x, world_y), 0, Vector2i(0,0))
				continue
			if y <= 2:
				wall_layer.set_cell(Vector2i(world_x, world_y), 0, Vector2i(0,0))
				continue
			var value = noise.get_noise_2d(world_x, world_y)*10
			if value > 1.5 and y > 10 or value > 5:
				cliff_layer.set_cell(Vector2i(world_x, world_y), 0, Vector2i(0,0))
			if value < -1.5 and y < 6 or value < -5:
				wall_layer.set_cell(Vector2i(world_x, world_y), 0, Vector2i(0,0))
			else:
				ground_layer.set_cell(Vector2i(world_x, world_y), 0, Vector2i(0,0))
	unload_chunks(tile_pos)
	unload_corpses(tile_pos)
	unload_textures(tile_pos)
	spawn_shadows()

func unload_chunks(player_position: Vector2i) -> void:
	var cliff_tiles = cliff_layer.get_used_cells()
	var wall_tiles = wall_layer.get_used_cells()
	var ground_tiles = ground_layer.get_used_cells()
	var shadow_tiles = shadow_layer.get_used_cells()
	for tile in shadow_tiles:
		if abs(tile.x - player_position.x) >= 30 or abs(tile.y - player_position.y) >= 30:
			shadow_layer.erase_cell(tile)
	for tile in cliff_tiles:
		if abs(tile.x - player_position.x) >= 30 or abs(tile.y - player_position.y) >= 30:
			cliff_layer.erase_cell(tile)
	for tile in wall_tiles:
		if abs(tile.x - player_position.x) >= 30 or abs(tile.y - player_position.y) >= 30:
			wall_layer.erase_cell(tile)
	for tile in ground_tiles:
		if abs(tile.x - player_position.x) >= 30 or abs(tile.y - player_position.y) >= 30:
			ground_layer.erase_cell(tile)

func unload_corpses(player_position: Vector2i) -> void:
	for corpse in get_tree().get_nodes_in_group("dead"):
		var corpse_position: Vector2i = ground_layer.local_to_map(corpse.position)
		var distance: Vector2i = abs(corpse_position - player_position)
		if distance.x >= 30 or distance.y >= 30:
			corpse.remove_from_group("dead")
			corpse.hide()
			for child in corpse.get_children():
				if child is CollisionShape2D:
					child.disabled = true
			corpse.position = Vector2(-9000, -9000)
			if OS.get_name() != "Web":
				corpse.queue_free()

func unload_textures(player_position: Vector2i) -> void:
	for texture in texture_library.keys():
		var distance: Vector2i = abs(texture_library[texture] - player_position)
		if distance.x >= 30 or distance.y >= 30:
			texture.hide()
			texture_library.erase(texture)
			texture.queue_free()
