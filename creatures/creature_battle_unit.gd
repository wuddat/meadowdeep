#creature_battle_unit.gd
# The in-battle representation of a creature. One node per active creature on screen.
class_name CreatureBattleUnit
extends BattleActor

@export var stats: CreatureStats : set = set_creature_stats
@export var spawn_position: String
@export var sprite_frames: SpriteFrames

@onready var creature_textures: CreatureTextures = $CreatureTextures
@onready var stats_ui: HBoxContainer = $StatsUI
@onready var status_handler: StatusHandler = $StatusHandler
@onready var modifier_handler: ModifierHandler = $ModifierHandler
@onready var unit_status_indicator: Node = %UnitStatusIndicator
@onready var action_timer: Panel = %ActionTimer
@onready var action_name: Label = %ActionName
@onready var projectile_spawn: Marker2D = %ProjectileSpawn
@onready var hitbox: Area2D = %Hitbox

var health_bar_ui: Node = null
var _queued_health_bar_ui: Node = null

var is_wild_creature: bool = false
var last_damage_taken: int = 0

var _action_fill: ColorRect = null
var _enemy: Enemy

const FOLLOW_DISTANCE := 48.0
const ACTION_INTERVAL: float = 0.4
var _following_player: bool = false


func _ready() -> void:
	super()
	add_to_group("active_creatures")
	status_handler.status_owner = self
	status_handler.statuses_applied.connect(_on_statuses_applied)

	if _queued_health_bar_ui != null:
		set_health_bar_ui(_queued_health_bar_ui)

	# Default behavior outside combat: follow the player.
	start_following_player()


func start_combat() -> void:
	_action_fill = action_timer.get_node("Fill")
	action_name.text = ""
	_following_player = false
	action_queue.clear()
	super()


func stop_combat() -> void:
	super()
	start_following_player()


# ── Out-of-combat follow ──────────────────────────────────────────────────────

func start_following_player() -> void:
	if stats and stats.health <= 0:
		return
	_following_player = true
	if not action_queue.contains(&"seek"):
		action_queue.enqueue(&"seek", {"distance": FOLLOW_DISTANCE})


func stop_following_player() -> void:
	_following_player = false
	base_velocity = Vector2.ZERO
	action_queue.remove(&"seek")


func _physics_process(delta: float) -> void:
	if _in_combat:
		super(delta)
		return
	if not _following_player:
		return
	_tick_current_action(delta)
	_decay_knockback(delta)
	velocity = base_velocity + knockback_velocity
	move_and_slide()


func _tick_current_action(delta: float) -> void:
	var current := action_queue.peek()
	if not current.is_empty() and current["id"] == &"seek":
		_tick_seek_player(current["data"], delta)
		return
	super(delta)


func _on_action_start(id: StringName, data: Dictionary) -> void:
	match id:
		&"seek":       _play_animation(&"idle")
		&"strike":     _run_one_shot_action(data)
		_:             super(id, data)
	

func _run_one_shot_action(data: Dictionary) -> void:
	var anim: String = data.get("animation_string", "")
	var effects: Array[Effect] = data.get("effects", [] as Array[Effect])
	if not creature_animation_handler or anim == "":
		return
	creature_animation_handler.play(anim)
	await creature_animation_handler.damage_frame
	var hits := hitbox.get_overlapping_bodies()
	for body in hits:
		if body != self:
			if is_instance_valid(body) and not effects.is_empty():
				EffectExecutor.run(effects, [body], self)

func _tick_seek_player(data: Dictionary, _delta: float) -> void:
	var player := _get_player()
	var follow_dist: float = data.get("distance", FOLLOW_DISTANCE)
	if not is_instance_valid(player):
		base_velocity = Vector2.ZERO
		_play_animation(&"idle")
		return
	var to_player: Vector2 = player.global_position - global_position
	var dist := to_player.length()
	if dist <= follow_dist:
		base_velocity = Vector2.ZERO
		_play_animation(&"idle")
		return
	base_velocity = to_player.normalized() * move_speed
	_play_animation(&"run")
	_face_direction(base_velocity)

func _tick_strike(data: Dictionary, delta: float) -> void:
	if data.has("min_duration"):
		data["min_duration"] -= delta
		if data["min_duration"] >= 0.0:
			return
	action_queue.done()


func _get_player() -> Node2D:
	var players := get_tree().get_nodes_in_group("player")
	return players[0] as Node2D if not players.is_empty() else null

# ── BattleActor virtual hooks ─────────────────────────────────────────────────

func _get_target() -> Node2D:
	if not is_instance_valid(_enemy):
		var enemies := get_tree().get_nodes_in_group("enemies")
		if enemies.is_empty():
			return null
		_enemy = enemies[0] as Enemy
	return _enemy


func _get_action_interval() -> float:
	return stats.get_action_interval() if stats else ACTION_INTERVAL


func _play_animation(anim_name: StringName) -> void:
	play_animation(anim_name)


func _face_direction(vel: Vector2) -> void:
	creature_textures.scale.x = -1.0 if vel.x < 0 else 1.0


func _update_action_timer_ui(remaining: float) -> void:
	if _action_fill:
		_action_fill.size.x = action_timer.size.x * (1.0 - remaining / _get_action_interval())


# ── Public API ────────────────────────────────────────────────────────────────

func set_creature_stats(value: CreatureStats) -> void:
	stats = value
	if not stats.stats_changed.is_connected(update_stats):
		stats.stats_changed.connect(update_stats)
	update_creature()


func update_creature() -> void:
	if not stats is CreatureStats: return
	if not is_inside_tree(): await ready
	var frames_to_use: SpriteFrames = stats.frames if stats.frames else sprite_frames
	if frames_to_use:
		creature_textures.sprite_frames = frames_to_use
		creature_textures.play("idle")
	update_stats()


func play_animation(anim_name: StringName) -> void:
	if creature_textures and creature_textures.sprite_frames:
		if creature_textures.sprite_frames.has_animation(anim_name):
			creature_textures.play(anim_name)


func update_stats() -> void:
	if stats_ui and stats_ui.has_method("update_stats"):
		stats_ui.update_stats(stats)


func gain_block(block: int, _mod_type: Modifier.Type) -> void:
	if stats.health <= 0:
		return
	var tween := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	var start := self.global_position
	var up_position := start + Vector2(0, -10)
	tween.tween_property(self, "position", up_position, 0.1)
	tween.tween_property(self, "position", start, 0.1)
	tween.tween_callback(stats.gain_block.bind(block))
	tween.tween_interval(0.17)


func take_damage(damage: int, mod_type: Modifier.Type) -> void:
	if stats.health <= 0: return
	last_damage_taken = 0

	var modified_damage := modifier_handler.get_modified_value(damage, mod_type)
	
	if modified_damage > 0:
		show_combat_text("%s" % modified_damage)
		last_damage_taken = modified_damage
		var source := _get_target()
		if is_instance_valid(source):
			_apply_knockback(source.global_position)
		var tween := create_tween()
		Shaker.shake(self, 25, 0.15)
		tween.tween_callback(stats.take_damage.bind(modified_damage))
		tween.tween_interval(0.17)
		tween.finished.connect(func():
			if stats.health <= 0:
				Events.party_creature_fainted.emit(self)
				hide()
		)

func heal(amount: int) -> void:
	if stats:
		var health_before := stats.health
		stats.heal(amount)
		var actual_heal := stats.health - health_before
		if actual_heal > 0:
			show_combat_text("+ %s HP" % amount, Color.GREEN)
	print("%s healed for %d!" % [stats.species_id, amount])


func set_health_bar_ui(ui: Node) -> void:
	if is_inside_tree() and is_instance_valid(status_handler):
		health_bar_ui = ui
		if "status_container" in ui:
			status_handler.set_status_ui_container(ui.get("status_container"))
	else:
		_queued_health_bar_ui = ui


func _on_statuses_applied(type: Status.Type) -> void:
	if type == Status.Type.START_OF_TURN:
		Events.player_creature_start_status_applied.emit(self)
		if unit_status_indicator and unit_status_indicator.has_method("update_status_display"):
			unit_status_indicator.update_status_display(self)
	elif type == Status.Type.END_OF_TURN:
		Events.player_creature_end_status_applied.emit(self)
		if unit_status_indicator and unit_status_indicator.has_method("update_status_display"):
			unit_status_indicator.update_status_display(self)


func _on_enemy_seeded_turn_start(seeded: Status) -> void:
	heal(seeded.heal_strength)


func on_enemy_defeated(enemy: Enemy) -> void:
	if stats.health <= 0:
		return
	print("Enemy defeated: %s" % [enemy.stats.species_id])
	await get_tree().process_frame
	if get_parent().has_node("EnemyHandler"):
		var enemy_handler = get_parent().get_node("EnemyHandler")
		if enemy_handler.get_child_count() == 0:
			await get_tree().process_frame
			await get_tree().create_timer(0.2).timeout


func show_combat_text(text: String, color: Color = Color.WHITE, animation: String = "rise_and_fade") -> void:
	var scene = load("uid://dixq55fwxr3b6")
	if not scene:
		return
	var label = scene.instantiate()
	add_child(label)
	if label.has_method("show_text"):
		label.show_text(text, color, animation)
