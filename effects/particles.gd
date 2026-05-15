class_name Particles
extends Node2D

@onready var gpu_particles_2d: GPUParticles2D = $GPUParticles2D


func emit_particles() -> void:
	gpu_particles_2d.emitting = true
