class_name HitBox
extends Node2D

# Faction groups: a HitBox never delivers to a body that shares the owner's faction.
# Everything sits on collision layer 1 — friend/foe is decided by group, not layer.
const FACTION_GROUPS: Array[StringName] = [&"enemies", &"pets", &"player"]

@onready var area_2d: Area2D = $Area2D
@onready var collider: CollisionShape2D = $Area2D/CollisionShape2D

var effects: Array[Effect]
var _hit_source: Node = null
var _active := false
var _already_hit: Array[Node] = []

func _physics_process(_delta: float) -> void:
	# Continuous delivery for a held window (dive/tackle sweep).
	if _active:
		deliver()


# One pass: for every overlapping HurtBox, hit its owning actor once (the _already_hit
# guard makes repeat calls safe). Detection is area-vs-area — the HurtBox is the
# damageable region, decoupled from the physics body. The owner is the HurtBox's parent.
# Call directly for a frame-synced one-shot (bite/strike damage frame), or let
# _physics_process call it every frame while active.
func deliver() -> void:
	for hurt_box in area_2d.get_overlapping_areas():
		var actor := hurt_box.get_parent()
		if actor == _hit_source or actor in _already_hit:
			continue
		if not actor.has_method("take_damage"):
			continue
		if _shares_faction(actor):
			continue
		_already_hit.append(actor)
		if is_instance_valid(actor) and is_instance_valid(_hit_source):
			EffectExecutor.run(effects, [actor], _hit_source)


# True when body is on the owner's side (shares a faction group) — skip allies.
func _shares_faction(body: Node) -> bool:
	if _hit_source == null:
		return false
	for g in FACTION_GROUPS:
		if _hit_source.is_in_group(g) and body.is_in_group(g):
			return true
	return false

# Begin an attack window: inject what/who, arm detection, and clear stale hits. Callers
# that want continuous delivery follow with activate(); one-shot callers (bite/strike)
# just deliver() on the damage frame. Arming here means monitoring is live before any
# await, giving the physics server frames to register overlaps.
func setup(hit_effects: Array[Effect], hit_source: Node, extents: Vector2 = Vector2.ZERO) -> void:
	if hit_effects:
		effects = hit_effects
	if hit_source and is_instance_valid(hit_source):
		_hit_source = hit_source
	if extents != Vector2.ZERO:
		set_extents(extents)
	area_2d.monitoring = true
	_already_hit.clear()


# Resize the box (e.g. to match the owner's body for a dive sweep). Assigns a fresh
# shape so we never mutate the scene's shared sub-resource across HitBox instances.
func set_extents(size: Vector2) -> void:
	var rect := RectangleShape2D.new()
	rect.size = size
	collider.shape = rect


func activate() -> void:
	area_2d.monitoring = true
	_already_hit.clear()
	_active = true

func deactivate() -> void:
	_active = false
	area_2d.monitoring = false
