#enemy.gd
# Enemy creature in battle.
class_name Enemy
extends BattleActor

const ARROW_OFFSET := 20

@export var stats: EnemyStats : set = set_enemy_stats
@export var sprite_frames: SpriteFrames

@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var arrow: Sprite2D = $Arrow
@onready var stats_ui: Node = %StatsUI
@onready var animation_handler: Node = $AnimationHandler
@onready var name_container: Node = %NameContainer
@onready var unit_status_indicator: Node = %UnitStatusIndicator
@onready var status_handler: StatusHandler = $StatusHandler
@onready var modifier_handler: ModifierHandler = $ModifierHandler
@onready var projectile_spawn: Node2D = %ProjectileSpawn

var current_action: Node = null : set = set_current_action
var spawn_coords: Vector2

var last_damage_taken: int = 0

func _ready() -> void:
	add_to_group("enemies")
	super()
	await get_tree().process_frame

	if stats and stats.species_id != "" and stats.uid == "":
		var creature_data := CreatureData.get_creature_data(stats.species_id)
		if not creature_data.is_empty():
			stats.load_from_data(creature_data)
			if sprite_frames:
				animated_sprite_2d.sprite_frames = sprite_frames
				animated_sprite_2d.play("idle")
		else:
			push_warning("No creature data found for: " + stats.species_id)
	else:
		if stats:
			if sprite_frames:
				animated_sprite_2d.sprite_frames = sprite_frames
				animated_sprite_2d.play("idle")

	spawn_coords = global_position


func set_current_action(value: Node) -> void:
	current_action = value


func set_enemy_stats(value: EnemyStats) -> void:
	stats = value.create_instance() as EnemyStats
	if not stats.stats_changed.is_connected(update_stats):
		stats.stats_changed.connect(update_stats)
	update_enemy()


func update_stats() -> void:
	if stats_ui and stats_ui.has_method("update_stats"):
		stats_ui.update_stats(stats)


func update_action() -> void:
	pass


func update_enemy() -> void:
	if not stats is Stats:
		return
	if not is_inside_tree():
		await ready
	sprite_2d.texture = stats.art
	arrow.position = Vector2.UP * (sprite_2d.get_rect().size.y / 2 + ARROW_OFFSET)
	update_stats()


# ── BattleActor virtual hooks ─────────────────────────────────────────────────

func _get_target() -> Node2D:
	var creatures := get_tree().get_nodes_in_group("active_creatures")
	if creatures.is_empty():
		return null
	return creatures[0] as Node2D


func _get_action_interval() -> float:
	return stats.get_action_interval() if stats else 1.5


func _play_animation(anim_name: StringName) -> void:
	animated_sprite_2d.play(anim_name)


func _face_direction(vel: Vector2) -> void:
	animated_sprite_2d.scale.x = -1.0 if vel.x < 0 else 1.0


# ── Combat ────────────────────────────────────────────────────────────────────

func take_damage(damage: int, mod_type: Modifier.Type) -> void:
	if stats.health <= 0:
		return
	last_damage_taken = 0

	var modified_damage := modifier_handler.get_modified_value(damage, mod_type)

	if modified_damage > 0:
		var combat_scene = load("res://scenes/ui/combat_text_label.tscn")
		if combat_scene:
			var dmg_text = combat_scene.instantiate()
			add_child(dmg_text)
			if dmg_text.has_method("show_text"):
				dmg_text.show_text("%s" % modified_damage)
			var source := _get_target()
			if is_instance_valid(source):
				_apply_knockback(source.global_position)
		last_damage_taken = modified_damage
		
	var tween := create_tween()
	Shaker.shake(self, 25, 0.15)
	tween.tween_callback(stats.take_damage.bind(modified_damage))
	tween.tween_interval(0.17)
	tween.finished.connect(func():
		if stats.health <= 0:
			Events.enemy_fainted.emit(self)
	)


func heal(amount: int) -> void:
	if stats:
		var health_before := stats.health
		stats.heal(amount)
		var actual_heal := stats.health - health_before
		if actual_heal > 0:
			var combat_scene = load("res://scenes/ui/combat_text_label.tscn")
			if combat_scene:
				var label = combat_scene.instantiate()
				add_child(label)
				if label.has_method("show_text"):
					label.show_text("+ %s HP" % amount, Color.GREEN)
	print("%s healed for %d!" % [stats.species_id, amount])


func gain_block(block: int, mod_type: Modifier.Type) -> void:
	if stats.health <= 0:
		return
	var modified_block := modifier_handler.get_modified_value(block, mod_type)
	var tween := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	var start := self.global_position
	tween.tween_property(self, "position", start + Vector2(0, -10), 0.1)
	tween.tween_property(self, "position", start, 0.1)
	tween.tween_callback(stats.gain_block.bind(modified_block))
	tween.tween_interval(0.17)
