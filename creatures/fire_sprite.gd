extends "res://creatures/base_creature.gd"

# ═══════════════════════════════════════════════════════════════════════════════
# MeadowDeep — Fire Sprite
#
# Fire-specific setup only. All creature logic lives in BaseCreature.
# ═══════════════════════════════════════════════════════════════════════════════

func _on_ready_creature() -> void:
	var rand := AudioStreamRandomizer.new()
	rand.add_stream(0, preload("res://art/game_art/sfx/woosh1.wav"))
	rand.add_stream(1, preload("res://art/game_art/sfx/woosh2.wav"))
	rand.add_stream(2, preload("res://art/game_art/sfx/woosh3.wav"))
	move_sfx.stream = rand


func _on_sprite_animation_looped() -> void:
	pass
