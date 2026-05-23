class_name MeadowEgg
extends Node2D

const BASE_CREATURE_SCENE := preload("res://creatures/base_creature.tscn")
const HATCH_ACTIONS: Array[String] = ["move_toward", "move_away"]
const HATCH_MAX_HEALTH := 20

const SPLIT_DISTANCE := 28.0
const SPLIT_DURATION := 0.5
const DETECT_RANGE   := 48.0

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

	_hatch_creature()
	queue_free()


func _hatch_creature() -> void:
	var creature: BaseCreature = BASE_CREATURE_SCENE.instantiate()
	creature.global_position = global_position
	creature.instance = _build_hatch_instance()
	get_parent().add_child(creature)
	creature.creature_skin_handler.randomize_skin.call_deferred()
	print("[Egg] hatched at %s" % global_position)


func _build_hatch_instance() -> CreatureInstance:
	var def := CreatureDef.new()
	def.creature_name = "Hatchling"
	def.max_health = HATCH_MAX_HEALTH

	var identity := CreatureIdentity.new()
	identity.randomize_grades()
	identity.known_actions = HATCH_ACTIONS.duplicate()

	var instance := CreatureInstance.new()
	instance.definition = def
	instance.identity = identity
	instance.health = def.max_health
	instance.block = 0
	instance.uid = "hatch_%d_%d" % [Time.get_unix_time_from_system(), RNG.instance.randi()]
	return instance


func _get_player() -> Node2D:
	var players := get_tree().get_nodes_in_group("player")
	return players[0] if players.size() > 0 else null
