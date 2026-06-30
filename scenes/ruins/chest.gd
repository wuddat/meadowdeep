class_name Chest
extends Node2D

# Same world-item scene the LootHandler spawns — keeps chest loot and battle loot identical.
const ITEM_SCENE: PackedScene = preload("uid://bqr0k0qv2mv3m")

const LID_RISE := Vector2(0, -50)        # how far the lid flies up
const SQUASH := Vector2(1.25, 0.7)       # anticipation pose (wide + short)
const STRETCH := Vector2(0.9, 1.15)      # pop pose (narrow + tall)
const TOSS_DIST := Vector2(50.0, 10.0)   # min/max ground spread of spawned loot
const TOSS_ARC := Vector2(80.0, 80.0)    # min/max apex height of the loot arc
const PARTICLES = preload("uid://d03ef5edxdj2c")
const POKEBALL_RELEASE = preload("uid://csshcg24qkapn")
const COINGAIN = preload("uid://bfisceugvchnq")
const LOOT_SPAWN_DELAY := 0.15


@export var loot_table: LootTable

@onready var chest_bottom: Sprite2D = $ChestBottom
@onready var chest_top: Sprite2D = $ChestTop
@onready var collision_area: Area2D = %CollisionArea

var _loot: Array[InventoryEntry] = []
var _player_in_range: bool = false
var _opened: bool = false


func _ready() -> void:
	_generate_loot()
	collision_area.body_entered.connect(_on_body_entered)
	collision_area.body_exited.connect(_on_body_exited)


func _unhandled_input(event: InputEvent) -> void:
	if _opened or not _player_in_range:
		return
	if event.is_action_pressed("interact"):
		_open_chest()


func _generate_loot() -> void:
	if loot_table:
		_loot = loot_table.roll_drops()


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_in_range = true


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_in_range = false


func _open_chest() -> void:
	_opened = true
	collision_area.set_deferred("monitoring", false)
	var burst: Particles = PARTICLES.instantiate()
	add_child(burst)
	burst.emit_particles()
	# Anticipation: both halves squash together. Nothing else fires until this finishes.
	var t := create_tween()
	t.tween_property(chest_bottom, "scale", SQUASH, 0.10) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(chest_top, "scale", SQUASH, 0.10) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	# Squash done → jettison the lid, then the body pops (stretch) and settles.
	t.tween_callback(_jettison_lid)
	SFXPlayer.play(POKEBALL_RELEASE)
	t.tween_property(chest_bottom, "scale", STRETCH, 0.12) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(chest_bottom, "scale", Vector2.ONE, 0.10) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)


# Fired once the squash completes: lid stretches as it flies up and fades, particles burst, loot spills.
func _jettison_lid() -> void:
	var lid := create_tween().set_parallel(true)
	lid.tween_property(chest_top, "scale", STRETCH, 0.12) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	lid.tween_property(chest_top, "position", chest_top.position + LID_RISE, 0.35) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	lid.tween_property(chest_top, "modulate:a", 0.0, 0.35)
	_spawn_loot()


func _spawn_loot() -> void:
	for entry: InventoryEntry in _loot:
		for _i in entry.qty:
			_spawn_item(entry.item)
			SFXPlayer.play(COINGAIN)
			await get_tree().create_timer(LOOT_SPAWN_DELAY).timeout


func _spawn_item(item_data: ItemDef) -> void:
	var item: WorldItemBase = ITEM_SCENE.instantiate()
	item.item_data = item_data
	get_parent().add_child(item)
	item.global_position = global_position

	# Random arc out of the chest: rise to an apex, then fall to a resting point with a bounce.
	var rest := global_position + Vector2.RIGHT.rotated(randf_range(0.0, TAU)) * randf_range(TOSS_DIST.x, TOSS_DIST.y)
	var apex := global_position.lerp(rest, 0.5) + Vector2(0.0, -randf_range(TOSS_ARC.x, TOSS_ARC.y))

	var arc := item.create_tween()
	arc.tween_property(item, "global_position", apex, 0.22) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	arc.tween_property(item, "global_position", rest, 0.45) \
		.set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
