extends Node2D


@onready var particles = $GPUParticles2D
var is_raining = false

func start_rain():
	particles.emitting = true
	is_raining = true

func stop_rain():
	particles.emitting = false
	is_raining = false
