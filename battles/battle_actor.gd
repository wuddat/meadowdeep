#battle_actor.gd
# Shared autonomous-fighter spine for all battle participants.
# Brain drives all behavior — movement, attack — via the action queue.
class_name BattleActor
extends CharacterBody2D

@export var base_movespeed: float = MIN_MOVESPEED
@export var battle_action_list: Array[BattleAction]
@export var creature_animation_handler: CreatureAnimationHandler
@export var instance: CreatureInstance : set = set_instance
@export var modifier_handler: ModifierHandler
@export var collider: CollisionShape2D
@export var hit_box: HitBox

const MIN_MOVESPEED: float = 45.0
const BRAIN_DELAY: float = 0.1
const HIT_INDICATOR_SCENE := preload("uid://chqjwfc5xsls0")
const KNOCKBACK_IMMUNE: Array[StringName] = [&"tackle", &"dash"]  # committed bursts ignore knockback
var _current_movespeed: float

var _in_combat: bool = false
var action_queue := ActionQueue.new()
var _current_action: BattleAction

var knockbackable: bool = true
var is_dodging: bool = false
var is_countering: bool = false
var _counter_completed:bool = false


var knockback_strength: float = 1000.0
var knockback_exp: float = 8.0

var base_velocity: Vector2 = Vector2.ZERO
var knockback_velocity: Vector2 = Vector2.ZERO

@onready var brain: Brain = get_node_or_null("Brain") as Brain


func _ready() -> void:
	_establish_connections()


func start_combat() -> void:
	_in_combat = true
	action_queue.enqueue(&"idle", {"timer": _get_action_interval()})


func stop_combat() -> void:
	_in_combat = false
	action_queue.clear()

func set_instance(value: CreatureInstance) -> void:
	_hydrate_actions()
	if value.definition and value.definition.base_speed > 0.0:
		base_movespeed = value.definition.base_speed
	else:
		var min_spd: float = MIN_MOVESPEED + value.identity.AGI.get_combat_mod()
		if base_movespeed < min_spd:
			base_movespeed = min_spd
	_current_movespeed = base_movespeed


func _physics_process(delta: float) -> void:
	if not _in_combat:
		return
	_check_battle_triggers()
	_tick_current_action(delta)
	_decay_knockback(delta)
	velocity = base_velocity + knockback_velocity
	move_and_slide()


func _on_queue_emptied() -> void:
	if not _in_combat:
		return
	if brain == null or battle_action_list.is_empty():
		if self is CreatureBattleUnit:
			push_warning("[IDLE]: brain NULL or action_list EMPTY")
		action_queue.enqueue(&"idle", {"timer": BRAIN_DELAY})
		return
	var chosen := brain.select_action()
	if chosen == null:
		#if self is CreatureBattleUnit:
			#push_warning("[IDLE]: _queue_emptied chosen == null")
		action_queue.enqueue(&"idle", {"timer": BRAIN_DELAY})
		return
	var steps := chosen.build_steps(self)
	if steps.is_empty():
		if self is CreatureBattleUnit:
			push_warning("[IDLE]: steps.is_empty")
		action_queue.enqueue(&"idle", {"timer": _get_action_interval()})
		return
	for step in steps:
		action_queue.enqueue(step["id"], step["data"])
	if action_queue.peek().is_empty():
		if self is CreatureBattleUnit:
			push_warning("[IDLE]: action_queue.peek().is_empty():")
		action_queue.enqueue(&"idle", {"timer": _get_action_interval()})


func _on_action_start(id: StringName, data: Dictionary) -> void:
	match id:
		&"idle":       _play_animation(&"idle")
		&"move":       _play_animation(&"run")
		&"dash":       _play_animation(&"dash")
		&"strike":     _play_animation(&"strike")
		&"projectile": _play_animation(&"strike")
		&"tackle":
			_play_animation(&"tackle")
			# The damaging charge: arm the body hitbox for the travel window, sized to
			# our body. Actors without a hit_box component (e.g. the player, which uses
			# its own _tick_contact_damage_action) skip this.
			if hit_box and not data.get("effects", [] as Array[Effect]).is_empty():
				var extents := Vector2.ZERO
				if collider and collider.shape is RectangleShape2D:
					extents = (collider.shape as RectangleShape2D).size
				hit_box.setup(data["effects"], self, extents)
				hit_box.activate()
		&"indicate":   _spawn_hit_indicator(data)
		&"bite":
			_play_animation(&"bite")
			_spawn_bite_fang(data)
		&"buff":       
			_play_animation(&"buff") 
			for buff in data["buffs"]:
				modifier_handler.add_timed_value(buff.mod, buff.mod_type, buff.source, buff.amount, buff.duration)
		&"counter":
			_play_animation(&"counter")
			is_countering = true
			_counter_completed = false
			var mod:Modifier = modifier_handler.get_modifier(Modifier.Type.DMG_TAKEN)
			var dur:float = data["duration"]
			mod.add_new_value(ModifierValue.Type.PERCENTAGE, &"counter", -50, dur)
		_:
			print("[BATTLEACTOR]: end of _on_action_start")

#Unused for now
func _check_battle_triggers() -> void:
	pass


func _tick_current_action(delta: float) -> void:
	var current := action_queue.peek()
	if current.is_empty():
		return
	match current["id"]:
		&"idle":       _tick_idle(current["data"], delta)
		&"move":       _tick_move(current["data"], delta)
		&"dash":       _tick_dash(current["data"], delta)
		&"strike":     _tick_strike(current["data"], delta)
		&"projectile": _tick_projectile(current["data"], delta)
		&"counter":    _tick_counter(current["data"], delta)
		&"buff":        _tick_buff(current["data"], delta)
		&"tackle":     _tick_tackle(current["data"], delta)
		&"indicate":   _tick_indicate(current["data"], delta)
		&"bite":       _tick_bite(current["data"], delta)


func _tick_idle(data: Dictionary, delta: float) -> void:
	_update_action_timer_ui(data["timer"] - delta)
	_tick_timed(data, delta)


func _tick_brace(data:Dictionary, delta: float) -> void:
	data["duration"] -= delta
	if data.has("min_duration"):
		data["min_duration"] -= delta
		if data["min_duration"] >= 0.0:
			return
	action_queue.done()


func _tick_strike(data: Dictionary, delta: float) -> void:
	var targets: Array[Node] = data.get("target", [] as Array[Node])
	var effects: Array[Effect] = data.get("effects", [] as Array[Effect])
	if not effects.is_empty():
		var valid_targets: Array[Node] = targets.filter(func(node): return is_instance_valid(node))
		if not valid_targets.is_empty():
			EffectExecutor.run(effects, valid_targets, self)
			data["effects"] = [] as Array[Effect]
	if data.has("min_duration"):
		data["min_duration"] -= delta
		if data["min_duration"] >= 0.0:
			return
	action_queue.done()


func _tick_move(data: Dictionary, delta: float) -> void:
	var raw = data.get("target")
	if not is_instance_valid(raw):
		base_velocity = Vector2.ZERO
		action_queue.done()
		return
	var target: Node2D = raw

	if data.has("duration"):
		data["duration"] -= delta
		if data["duration"] <= 0.0:
			base_velocity = Vector2.ZERO
			action_queue.done()
			return

	var stop_distance: float = data.get("stop_distance", 32.0)
	var mode: MoveToAction.Mode = data.get("mode", MoveToAction.Mode.TOWARD)
	
	var to_target: Vector2 = target.global_position - global_position
	var dist := to_target.length()
	
	match mode:
		MoveToAction.Mode.TOWARD:
			if dist <= stop_distance:
				base_velocity = Vector2.ZERO
				action_queue.done()
				return
			base_velocity = to_target.normalized() * _current_movespeed

		MoveToAction.Mode.AWAY:
			if dist >= stop_distance: # Assuming stopping at a max distance away, modify if you want continuous flee
				base_velocity = Vector2.ZERO
				action_queue.done()
				return
			base_velocity = -to_target.normalized() * _current_movespeed

		MoveToAction.Mode.ORBITL:
			var tangent := to_target.normalized().rotated(-PI / 2)
			base_velocity = tangent * _current_movespeed

		MoveToAction.Mode.ORBITR:
			var tangent := to_target.normalized().rotated(PI / 2)
			base_velocity = tangent * _current_movespeed

		MoveToAction.Mode.PING_PONG:
			var toward := to_target.normalized()
			var max_range: float = data.get("max_range", 160.0)
			# Persistent travel direction — only changes on events, never re-aimed per
			# frame (that's what got it stuck homing into walls). Bounce off walls; softly
			# curve back toward the target when it drifts past max_range (the leash).
			var dir: Vector2 = data.get("dir", Vector2.ZERO)
			if dir == Vector2.ZERO:
				dir = toward
			# We only physically collide with walls (collision_mask = layer 4), so any
			# slide collision IS a wall — bounce off its normal. TileMap walls aren't
			# CollisionObject2D, so we can't/needn't filter by collider type or layer.
			if get_slide_collision_count() > 0:
				dir = dir.bounce(get_slide_collision(0).get_normal())
			elif dist >= max_range:
				dir = dir.lerp(toward, 0.08)  # past the leash — curve home, don't snap
			dir = dir.normalized()
			data["dir"] = dir
			base_velocity = dir * _current_movespeed

	_face_direction(base_velocity)


func _tick_projectile(data: Dictionary, _delta: float) -> void:
	var scene: PackedScene = data.get("scene")
	var target = data.get("target")
	if scene == null or not is_instance_valid(target):
		action_queue.done()
		return
	var p := scene.instantiate() as ProjectileObject
	if p == null:
		action_queue.done()
		return
	p.art = data.get("art")
	p.effects = data.get("effects", [] as Array[Effect])
	p.duration = data.get("duration", 0.0)
	p.max_distance = data.get("max_distance", 0.0)
	p.speed = data.get("speed", 0.0)
	_vfx_parent().add_child(p)
	p.setup(self, target)
	action_queue.done()


func _tick_dash(data: Dictionary, delta: float) -> void:
	base_velocity = data.get("direction", Vector2.ZERO) * data.get("speed", 120.0)
	data["duration"] -= delta
	if data["duration"] <= 0.0:
		base_velocity = Vector2.ZERO
		is_dodging = false
		action_queue.done()


# Damaging charge for actors with a hit_box component (enemies). Velocity over a
# duration; the armed hit_box self-delivers on contact. CreatureBattleUnit overrides
# &"tackle" with its own _tick_contact_damage_action, so this is the enemy path.
func _tick_tackle(data: Dictionary, delta: float) -> void:
	base_velocity = data.get("direction", Vector2.ZERO) * data.get("speed", 160.0)
	data["duration"] -= delta
	if data["duration"] <= 0.0:
		base_velocity = Vector2.ZERO
		if hit_box:
			hit_box.deactivate()
		action_queue.done()

func _tick_buff(data: Dictionary, delta: float) -> void:
	if data.has("min_duration"):
		data["min_duration"] -= delta
		if data["min_duration"] >= 0.0:
			return
	action_queue.done()

func _tick_counter(data: Dictionary, delta: float) -> void:
	data["duration"] -= delta
	if data["duration"] <= 0 or _counter_completed:
		is_countering = false
		_counter_completed = false
		action_queue.done()


# indicate and bite both just hold for a beat — the work happens on action-start
# (spawn the lane indicator / spawn the fang). The spawned node does the rest.
func _tick_indicate(data: Dictionary, delta: float) -> void:
	_tick_timed(data, delta)


func _tick_bite(data: Dictionary, delta: float) -> void:
	_tick_timed(data, delta)


func _tick_timed(data: Dictionary, delta: float) -> void:
	data["timer"] -= delta
	if data["timer"] > 0.0:
		return
	action_queue.done()


# Where transient VFX (indicators, fangs, projectiles) should live. Enemies are nested
# under EnemyHandler, whose children must stay strictly Enemy (it iterates them typed and
# uses child_count as the combat-cleared check) — so bubble up to the room for those.
func _vfx_parent() -> Node:
	var p := get_parent()
	return p.get_parent() if p is EnemyHandler else p


# Paint the lane a dive is about to sweep. Lives in world space (added to the arena,
# not to self) so it stays put while we charge through it. add_child before setup —
# the indicator's fade tween needs the node in-tree.
func _spawn_hit_indicator(data: Dictionary) -> void:
	var indicator := HIT_INDICATOR_SCENE.instantiate() as HitIndicator
	_vfx_parent().add_child(indicator)
	indicator.setup(
		global_position,
		data.get("direction", Vector2.RIGHT),
		data.get("length", 64.0),
		data.get("width", 24.0),
		data.get("indicator_duration", data.get("timer", 0.5)),
	)


# Spawn the committing, animation-driven fang over the target. The fang's own
# AnimationPlayer toggles its HitBox on/off — we just place it and inject what to deal.
func _spawn_bite_fang(data: Dictionary) -> void:
	var scene: PackedScene = data.get("animated_hitbox")
	if scene == null:
		return
	var fang := scene.instantiate()
	_vfx_parent().add_child(fang)
	var target = data.get("target")
	fang.global_position = target.global_position if is_instance_valid(target) else global_position
	if fang.has_method("setup"):
		fang.setup(data.get("effects", [] as Array[Effect]), self)


# ── Virtual hooks ─────────────────────────────────────────────────────────────

func _get_action_interval() -> float:
	return 0.25

func get_movespeed() -> float:
	var new_movespeed := modifier_handler.get_modified_value(int(base_movespeed), Modifier.Type.MOVESPEED)
	return new_movespeed

func apply_knockback(source_pos: Vector2, strength: float = -1.0) -> void:
	if "knockbackable" in self and not knockbackable:
		return
	if action_queue.current_action in KNOCKBACK_IMMUNE:
		return  # committed charge — don't let knockback shove or cancel the dive
	var force := strength if strength >= 0.0 else knockback_strength
	var direction := (global_position - source_pos).normalized()
	knockback_velocity = direction * force
	if action_queue.current_action != &"strike":
		if creature_animation_handler:
			if not creature_animation_handler.is_playing():
				creature_animation_handler.RESET()
				creature_animation_handler.play("on_hurt")
		if action_queue.current_action != &"idle":
			action_queue.clear()
			action_queue.enqueue(&"idle", {"timer": 0.1})

func _hydrate_actions() -> void:
	if not instance or not instance.identity:
		return
	var ids: Array[String] = instance.identity.assigned_actions
	if ids.is_empty():
		ids = instance.identity.known_actions
	if ids.is_empty() and instance.definition:
		ids = instance.definition.starting_actions
	battle_action_list = ActionData.get_actions(ids)

func _decay_knockback(delta: float) -> void:
	if knockback_velocity.length() <= 0.01:
		knockback_velocity = Vector2.ZERO
		return
	knockback_velocity *= exp(-knockback_exp * delta)

func _play_animation(_anim_name: StringName) -> void:
	pass

func _face_direction(_vel: Vector2) -> void:
	pass

func _face_target(data: Dictionary) -> void:
	var target = data.get("target")
	if is_instance_valid(target):
		_face_direction(target.global_position - global_position)

func _update_action_timer_ui(_remaining: float) -> void:
	pass

func _on_mods_changed() -> void:
	_current_movespeed = get_movespeed()

func _establish_connections() -> void:
	action_queue.action_started.connect(_on_action_start)
	action_queue.queue_emptied.connect(_on_queue_emptied)
	modifier_handler.mods_changed.connect(_on_mods_changed)
