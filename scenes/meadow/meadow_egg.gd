class_name MeadowEgg
extends Node2D

# Map species_id → creature scene path
const CREATURE_SCENES := {
	"verdant":    "res://creatures/slime.tscn",
	"ember":      "res://creatures/fire_sprite.tscn",
	"tide":       "res://creatures/water_sprite.tscn",
	"stone":      "res://creatures/slime.tscn",
	"wisp":       "res://creatures/slime.tscn",
}

const SPLIT_DISTANCE := 28.0
const SPLIT_DURATION := 0.5
const DETECT_RANGE   := 48.0

@export var species_id: String = "ember"
@export var rarity: String = "common"

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var top_half: Sprite2D    = $TopHalf
@onready var bottom_half: Sprite2D = $BottomHalf

var _is_hatching     := false
var _player_in_range := false


func _ready() -> void:
	animated_sprite.play("idle")


func _process(_delta: float) -> void:
	if _is_hatching:
		return
	var player := _get_player()
	if not player:
		return
	var in_range := global_position.distance_to(player.global_position) < DETECT_RANGE
	if in_range and not _player_in_range:
		_player_in_range = true
		player.set("nearby_egg", self)
	elif not in_range and _player_in_range:
		_player_in_range = false
		if player.get("nearby_egg") == self:
			player.set("nearby_egg", null)


func begin_hatch() -> void:
	if _is_hatching:
		return
	_is_hatching = true
	_player_in_range = false
	var player := _get_player()
	if player and player.get("nearby_egg") == self:
		player.set("nearby_egg", null)
	animated_sprite.sprite_frames.set_animation_loop("hatching", false)
	animated_sprite.play("hatching")
	await animated_sprite.animation_finished

	animated_sprite.hide()
	top_half.show()
	bottom_half.show()
	var top_start    := top_half.position
	var bottom_start := bottom_half.position
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(top_half,    "position", top_start    + Vector2(0, -SPLIT_DISTANCE), SPLIT_DURATION).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(bottom_half, "position", bottom_start + Vector2(0,  SPLIT_DISTANCE), SPLIT_DURATION).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await tween.finished

	_spawn_creature()
	queue_free()


func _spawn_creature() -> void:
	var scene_path: String = CREATURE_SCENES.get(species_id, "res://creatures/slime.tscn")
	var scene := load(scene_path) as PackedScene
	if not scene:
		push_warning("MeadowEgg: failed to load scene for '%s'" % species_id)
		return
	var creature := scene.instantiate()
	creature.global_position = global_position
	var stats := CreatureData.create_creature_instance(species_id)
	if stats:
		creature.set("creature_stats", stats)
	else:
		push_warning("MeadowEgg: no creature data for '%s'" % species_id)
	get_parent().add_child(creature)
	print("[Egg] hatched: %s at %s" % [species_id, global_position])


func _get_player() -> Node2D:
	var players := get_tree().get_nodes_in_group("player")
	return players[0] if players.size() > 0 else null
