#creature_battle_unit.gd
# The in-battle representation of a creature. One node per active creature on screen.
class_name CreatureBattleUnit
extends BattleActor

const STAT_PALETTE_SHADER := preload("uid://boy12gwxxdf87")

@export var spawn_position: String
@export var sprite_frames: SpriteFrames

@onready var creature_textures: CreatureTextures = $CreatureTextures
@onready var stats_ui: HBoxContainer = $StatsUI
@onready var action_timer: Panel = %ActionTimer
@onready var action_name: Label = %ActionName
@onready var projectile_spawn: Marker2D = %ProjectileSpawn
@onready var hitbox: Area2D = %Hitbox
@onready var creature_skin_handler: CreatureSkinHandler = %CreatureSkinHandler
@onready var status_graphic: Sprite2D = %StatusGraphic

var health_bar_ui: Node = null
var _queued_health_bar_ui: Node = null

var last_damage_taken: int = 0

var _action_fill: ColorRect = null
var _enemy: Enemy
var _already_damaged_bodies: Array[Node] = []

const FOLLOW_DISTANCE := 48.0
const ACTION_INTERVAL: float = 0.4

var _following_player: bool = false

var is_snared: bool = false
var knockbackable: bool = true

func _ready() -> void:
	super()
	add_to_group("active_creatures")

	if _queued_health_bar_ui != null:
		set_health_bar_ui(_queued_health_bar_ui)

	if creature_skin_handler:
		var mat := ShaderMaterial.new()
		mat.shader = STAT_PALETTE_SHADER
		creature_skin_handler.adopt_palette_material(mat)
		if instance:
			creature_skin_handler.identity = instance.identity
			creature_skin_handler.refresh_palette()

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
	if instance and instance.health <= 0:
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
	if not _following_player or is_snared:
		return
	_tick_current_action(delta)
	_decay_knockback(delta)
	velocity = base_velocity + knockback_velocity
	move_and_slide()





func _tick_current_action(delta: float) -> void:
	var current := action_queue.peek()
	if not current.is_empty():
		match current["id"]:
			&"idle":       _tick_idle(current["data"], delta)
			&"seek":       _tick_seek_player(current["data"], delta)
			&"tackle":     _tick_contact_damage_action(current["data"], delta)
			_:             super(delta)


func _on_action_start(id: StringName, data: Dictionary) -> void:
	if action_name:
		action_name.text = String(id).capitalize()
	match id:
		&"seek":       _play_animation(&"idle")
		&"strike":     _run_one_damage_frame_action(data)
		&"tackle":     
			_already_damaged_bodies.clear()
			super(id, data)
		&"buff":
			_play_animation(&"buff") 
			for buff in data["buffs"]:
				modifier_handler.add_timed_value(buff.mod, buff.mod_type, buff.source, buff.amount, buff.duration)
		_:             super(id, data)


func _run_one_damage_frame_action(data: Dictionary) -> void:
	var anim: String = data.get("animation_string", "")
	var effects: Array[Effect] = data.get("effects", [] as Array[Effect])
	if not creature_animation_handler or anim == "":
		return
	creature_animation_handler.play(anim)
	await creature_animation_handler.damage_frame
	var aoe_radius:float = data.get("aoe_radius", 0.0)
	if aoe_radius > 0:
		var targets: Array[Node] = AttackAction.find_opponents_in_radius(self, aoe_radius)
		EffectExecutor.run(effects, targets, self)
		return
	var hits := hitbox.get_overlapping_bodies()
	for body in hits:
		if body != self:
			if is_instance_valid(body) and not effects.is_empty():
				EffectExecutor.run(effects, [body], self)


func _tick_contact_damage_action(data: Dictionary, delta) -> void:
	base_velocity = data.get("direction", Vector2.ZERO) * data.get("speed", 120.0)
	data["duration"] -= delta
	if data["duration"] <= 0.0:
		base_velocity = Vector2.ZERO
		_already_damaged_bodies.clear()
		action_queue.done()
		return
	var effects: Array[Effect] = data.get("effects", [] as Array[Effect])
	var hits := _get_hit_bodies()
	for body in hits:
		if body not in _already_damaged_bodies:
			if is_instance_valid(body) and not effects.is_empty():
				EffectExecutor.run(effects, [body], self)
				_already_damaged_bodies.append(body)

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
	base_velocity = to_player.normalized() * _current_movespeed
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

func _get_hit_bodies() -> Array[Node]:
	var all_hits := hitbox.get_overlapping_bodies()
	var hits: Array[Node]
	for body in all_hits:
		if body != self:
			hits.append(body)
	return hits

func _get_action_interval() -> float:
	if not instance or not instance.definition:
		return ACTION_INTERVAL
	return instance.definition.get_action_interval(instance.identity)


func _play_animation(anim_name: StringName) -> void:
	play_animation(anim_name)

func play_animation(anim_name: StringName) -> void:
	if creature_textures and creature_textures.sprite_frames:
		if creature_textures.sprite_frames.has_animation(anim_name):
			creature_textures.play(anim_name)


func _face_direction(vel: Vector2) -> void:
	creature_textures.scale.x = -1.0 if vel.x < 0 else 1.0


func _update_action_timer_ui(remaining: float) -> void:
	if _action_fill:
		_action_fill.size.x = action_timer.size.x * (1.0 - remaining / _get_action_interval())


# ── Public API ────────────────────────────────────────────────────────────────

func set_instance(creature: CreatureInstance) -> void:
	instance = creature
	if not instance:
		return
	instance.health = instance.definition.max_health
	if not instance.stats_changed.is_connected(update_stats):
		instance.stats_changed.connect(update_stats)
	super(creature)
	update_creature()


func update_creature() -> void:
	if not instance or not instance.definition:
		return
	if not is_inside_tree():
		await ready
	var frames_to_use: SpriteFrames = instance.definition.frames if instance.definition.frames else sprite_frames
	if frames_to_use:
		creature_textures.sprite_frames = frames_to_use
		creature_textures.play("idle")
	if creature_skin_handler:
		creature_skin_handler.identity = instance.identity
		creature_skin_handler.refresh_palette()
	update_stats()


func update_stats() -> void:
	if stats_ui and stats_ui.has_method("update_stats"):
		stats_ui.update_stats(instance)


func gain_block(block: int, _mod_type: Modifier.Type) -> void:
	if instance.health <= 0:
		return
	var tween := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	var start := self.global_position
	var up_position := start + Vector2(0, -10)
	tween.tween_property(self, "position", up_position, 0.1)
	tween.tween_property(self, "position", start, 0.1)
	tween.tween_callback(instance.gain_block.bind(block))
	tween.tween_interval(0.17)


func take_damage(damage: int, mod_type: Modifier.Type, attacker: Node) -> void:
	if instance.health <= 0: return
	last_damage_taken = 0

	var modified_damage := modifier_handler.get_modified_value(damage, mod_type)

	if modified_damage > 0:
		show_combat_text("%s" % modified_damage)
		last_damage_taken = modified_damage
		if attacker == null:
			attacker = _get_target()
		if is_instance_valid(attacker):
			_apply_knockback(attacker.global_position)
		if is_countering:
			if "take_damage" in attacker and attacker is Enemy:
				var att:Enemy = attacker
				att.take_damage(modified_damage,Modifier.Type.DMG_TAKEN, self)
				_counter_completed = true
				is_countering = false
		
		var tween := create_tween()
		Shaker.shake(self, 25, 0.15)
		tween.tween_callback(instance.take_damage.bind(modified_damage))
		tween.tween_interval(0.17)
		tween.finished.connect(func():
			if instance.health <= 0:
				Events.party_creature_fainted.emit(self)
				hide()
		)

func heal(amount: int) -> void:
	if instance:
		var health_before := instance.health
		instance.heal(amount)
		var actual_heal := instance.health - health_before
		if actual_heal > 0:
			show_combat_text("+ %s HP" % amount, Color.GREEN)
	print("%s healed for %d!" % [instance.definition.species_id, amount])


func set_health_bar_ui(ui: Node) -> void:
	if is_inside_tree():
		health_bar_ui = ui
	else:
		_queued_health_bar_ui = ui


func on_enemy_defeated(enemy: Enemy) -> void:
	if instance.health <= 0:
		return
	print("Enemy defeated: %s" % [enemy.instance.definition.species_id])
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


func snare() -> void:
	if is_snared:
		return
	status_graphic.visible = true
	is_snared = true
	action_queue.clear()
	base_velocity = Vector2.ZERO
	print("[CREATURE] snare() -> emit creature_ensnared")
	Events.creature_ensnared.emit(self)
	
	
func unsnare() -> void:
	status_graphic.visible = false
	is_snared = false
	action_queue.enqueue(&"idle", {"timer": _get_action_interval()})
	print("[CREATURE] unsnare() -> emit creature_freed")
	Events.creature_freed.emit(self)

func _on_queue_emptied() -> void:
	if action_name:
		action_name.text = ""
	if is_snared:
		return
	super()
