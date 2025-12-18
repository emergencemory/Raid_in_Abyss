extends CanvasLayer
class_name ParticleCache

var blood_char = preload("res://character/effects/blood_particle.tres")
var blood_boss = preload("res://character/effects/boss_blood_particle.tres")
var explosion_boss = preload("res://character/effects/explosion.tres")
var fire_boss = preload("res://character/effects/boss_fire_2.tres")
var smoke_boss = preload("res://character/effects/boss_smoke_1.tres")
var spark_char = preload("res://character/effects/spark_particle.tres")
var spark_boss = preload("res://character/effects/boss_spark_particle.tres")
var stun_char = preload("res://character/effects/stun_particle.tres")
var stun_boss = preload("res://character/effects/boss_stun_particle.tres")
var rubble_particle = preload("res://map/effects/rubble_particle.tres")

var particle_array : Array = [
	blood_char,
	blood_boss,
	explosion_boss,
	fire_boss,
	smoke_boss,
	spark_char,
	spark_boss,
	stun_char,
	stun_boss,
	rubble_particle
]

func _ready():
	for particle in particle_array:
		var particle_instance = GPUParticles2D.new()
		particle_instance.set_process_material(particle)
		particle_instance.set_modulate(Color(1, 1, 1, 0))
		self.add_child(particle_instance)
		particle_instance.emitting = true
	#TODO queue free