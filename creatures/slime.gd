extends "res://creatures/base_creature.gd"

# ═══════════════════════════════════════════════════════════════════════════════
# MeadowDeep — Slime
#
# Slime-specific setup only. All creature logic lives in BaseCreature.
# ═══════════════════════════════════════════════════════════════════════════════

func _on_ready_creature() -> void:
	var h := randf()
	var s := randf_range(0.5, 0.9)
	var v := randf_range(0.6, 1.0)
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://creatures/creature_tint.gdshader")
	mat.set_shader_parameter("tint_color", Color.from_hsv(h, s, v))
	_sprite.material = mat
