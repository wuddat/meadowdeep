# global/qte_controller.gd (autoload)
extends Node

signal qte_started(data: QTEData)
signal qte_resolved(outcome: QTEOutcome, quality: String)

const QTE_WIDGET = preload("uid://c4seq51cir2b4")

var _canvas: CanvasLayer
var _busy: bool = false

func _ready() -> void:
	_canvas = CanvasLayer.new()
	_canvas.layer = 100
	add_child(_canvas)




func run(data: QTEData) -> QTEOutcome:
	if not data or _busy:
		var outcome:QTEOutcome = QTEOutcome.new()
		outcome.damage_multiplier = 1.0
		return outcome
	_busy = true
	var widget = _spawn_widget(data)
	qte_started.emit(data)
	var quality: String = await widget.QTE_resolved
	widget.queue_free()
	_busy = false
	var outcome: QTEOutcome = _pick_outcome(data, quality)
	qte_resolved.emit(outcome, quality)
	return outcome

func _spawn_widget(data) -> QTEWidget:
	var qte_widget = QTE_WIDGET.instantiate()
	_canvas.add_child(qte_widget)
	qte_widget.setup(data)
	return qte_widget

func _pick_outcome(data, quality) -> QTEOutcome:
	match quality:
		"perfect": return data.on_perfect
		"good":    return data.on_good
		_:         return data.on_miss
	
