class_name HitBox
extends Node2D

# Faction groups: a HitBox never delivers to a body that shares the owner's faction.
# Everything sits on collision layer 1 — friend/foe is decided by group, not layer.
const FACTION_GROUPS: Array[StringName] = [&"enemies", &"active_creatures"]

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


# One pass: hit every overlapping body once (the _already_hit guard makes repeat calls
# safe). Call directly for a frame-synced one-shot (bite damage frame), or let
# _physics_process call it every frame while active.
func deliver() -> void:
	for body in area_2d.get_overlapping_bodies():
		if body == _hit_source or body in _already_hit:
			continue
		if not body.has_method("take_damage"):
			continue
		if _shares_faction(body):
			continue
		_already_hit.append(body)
		EffectExecutor.run(effects, [body], _hit_source)


# True when body is on the owner's side (shares a faction group) — skip allies.
func _shares_faction(body: Node) -> bool:
	if _hit_source == null:
		return false
	for g in FACTION_GROUPS:
		if _hit_source.is_in_group(g) and body.is_in_group(g):
			return true
	return false

func setup(hit_effects: Array[Effect], hit_source: Node, extents: Vector2 = Vector2.ZERO) -> void:
	if hit_effects:
		effects = hit_effects
	if hit_source and is_instance_valid(hit_source):
		_hit_source = hit_source
	if extents != Vector2.ZERO:
		set_extents(extents)


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
