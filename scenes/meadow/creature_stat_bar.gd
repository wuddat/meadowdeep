class_name CreatureStatBar
extends Control

@onready var stat_name: Label = %StatName
@onready var lvl: Label = %Lvl
@onready var pill_box: HBoxContainer = %PillBox
@onready var stat_grade: Label = %StatGrade
@onready var score: Label = %Score

const PILL_EMPTY = preload("uid://cg4v0q208cksl")
const PILL_FULL = preload("uid://d3wnng60mj0x0")
const PING_SFX: AudioStream = preload("res://art/game_art/sfx/ping_SFX.wav")
const LEVEL_UP_SFX: AudioStream = preload("res://art/game_art/sfx/level_up.wav")

const PIP_STAGGER := 0.2
const PIP_FLASH_DURATION := 0.2
const PIP_PREVIEW_PAUSE := .2
const PIP_REST_COLOR := Color(0.84, 0.681, 0.116, 1.0)
const PIP_FLASH_COLOR := Color.WHITE
const LEVEL_UP_PAUSE := 0.5

var _last_lvl: int = -1
var _last_pips: int = -1
var _last_max_pips: int = 0
var _active_tween: Tween = null


func setup(stat: GrowthStat, label: String) -> void:
	stat_name.text = label
	stat_grade.text = GrowthStat.Grade.keys()[stat.grade]
	_ensure_pips(stat.max_pips)

	var total_new: int = -1
	if _last_pips >= 0:
		total_new = (stat.lvl - _last_lvl) * _last_max_pips + stat.pips - _last_pips

	if total_new <= 0:
		if _active_tween and _active_tween.is_valid():
			_active_tween.kill()
		lvl.text = "LV: %d" % stat.lvl
		score.text = str(stat.points)
		_set_pips_visual(stat.pips)
	else:
		_animate_sequence(stat)

	_last_lvl = stat.lvl
	_last_pips = stat.pips
	_last_max_pips = stat.max_pips


func reset() -> void:
	_last_lvl = -1
	_last_pips = -1
	_last_max_pips = 0


func _ensure_pips(count: int) -> void:
	while pill_box.get_child_count() < count:
		var p := TextureRect.new()
		p.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		p.texture = PILL_EMPTY
		pill_box.add_child(p)


func _set_pips_visual(filled: int) -> void:
	for i in pill_box.get_child_count():
		var p := pill_box.get_child(i) as TextureRect
		if not p:
			continue
		if i < filled:
			p.texture = PILL_FULL
			p.modulate = PIP_REST_COLOR
		else:
			p.texture = PILL_EMPTY
			p.modulate = Color.WHITE


func _animate_sequence(stat: GrowthStat) -> void:
	if _active_tween and _active_tween.is_valid():
		_active_tween.kill()

	_active_tween = create_tween()
	var cur_lvl := _last_lvl
	var cur_pips := _last_pips

	while cur_lvl < stat.lvl or cur_pips < stat.pips:
		var ends_with_levelup := cur_lvl < stat.lvl
		var slice_end: int = _last_max_pips if ends_with_levelup else stat.pips
		var slice_start := cur_pips
		var slice_lvl := cur_lvl

		_active_tween.tween_callback(func() -> void:
			lvl.text = "LV: %d" % slice_lvl
			_set_slice_preview(slice_start, slice_end)
		)
		_active_tween.tween_interval(PIP_PREVIEW_PAUSE)

		for i in range(slice_start, slice_end):
			var idx := i
			_active_tween.tween_callback(func() -> void: SFXPlayer.play(PING_SFX))
			_active_tween.tween_property(pill_box.get_child(idx), "modulate", PIP_REST_COLOR, PIP_FLASH_DURATION)
			_active_tween.tween_interval(PIP_STAGGER)

		if ends_with_levelup:
			_active_tween.tween_callback(func() -> void: SFXPlayer.play(LEVEL_UP_SFX))
			_active_tween.tween_property(stat_name, "modulate", PIP_REST_COLOR, PIP_FLASH_DURATION)
			_active_tween.parallel().tween_property(lvl, "modulate", PIP_REST_COLOR, PIP_FLASH_DURATION)
			_active_tween.tween_property(stat_name, "modulate", Color.WHITE, PIP_FLASH_DURATION)
			_active_tween.parallel().tween_property(lvl, "modulate", Color.WHITE, PIP_FLASH_DURATION)
			_active_tween.tween_interval(LEVEL_UP_PAUSE)
			cur_lvl += 1
			cur_pips = 0
		else:
			break

	_active_tween.tween_callback(func() -> void:
		score.text = str(stat.points)
	)


func _set_slice_preview(gained: int, will_gain_to: int) -> void:
	for i in pill_box.get_child_count():
		var p := pill_box.get_child(i) as TextureRect
		if not p:
			continue
		if i < gained:
			p.texture = PILL_FULL
			p.modulate = PIP_REST_COLOR
		elif i < will_gain_to:
			p.texture = PILL_FULL
			p.modulate = PIP_FLASH_COLOR
		else:
			p.texture = PILL_EMPTY
			p.modulate = Color.WHITE
