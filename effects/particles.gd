class_name Particles
extends Node2D

@export var gpu_particles_2d: GPUParticles2D

var duration: float = 1.0

func _process(delta: float) -> void:
	duration -= delta
	if duration <= 0.0:
		self.queue_free() 

func emit_particles() -> void:
	gpu_particles_2d.emitting = true
