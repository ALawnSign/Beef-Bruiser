class_name Ammo
extends Node

signal ammo_changed(current: int, maximum: int)
signal reload_started
signal reload_finished

@export var max_ammo: int = 4
@export var debug_print: bool = true

@export_group("Reload")
@export var manual_reload: bool = true
@export var auto_reload: bool = false
@export var reload_delay: float = 0.6
@export var reload_time: float = 0.4

@export_group("Kill Refill")
@export var refill_on_kill: bool = true
@export var shells_per_kill: int = 1

var ammo: int = 0
var is_reloading: bool = false
var _since_shot: float = 0.0
var _reload_progress: float = 0.0


func _ready() -> void:
	ammo = max_ammo
	_emit()


func has_ammo(amount: int = 1) -> bool:
	return ammo >= amount


func is_full() -> bool:
	return ammo >= max_ammo


func use(amount: int = 1) -> bool:
	if ammo < amount:
		return false
	ammo -= amount
	_since_shot = 0.0
	stop_reload()
	_emit()
	return true


func add_ammo(amount: int = 1) -> void:
	var old := ammo
	ammo = clampi(ammo + amount, 0, max_ammo)
	if ammo != old:
		_emit()


func request_reload() -> void:
	if manual_reload:
		start_reload()


func start_reload() -> void:
	if is_reloading or is_full():
		return
	is_reloading = true
	_reload_progress = 0.0
	reload_started.emit()
	if debug_print:
		print("%s reloading..." % get_parent().name)


func stop_reload() -> void:
	if not is_reloading:
		return
	is_reloading = false
	_reload_progress = 0.0
	reload_finished.emit()


func on_kill() -> void:
	if refill_on_kill:
		add_ammo(shells_per_kill)


func _process(delta: float) -> void:
	_since_shot += delta

	if not is_reloading:
		if auto_reload and not is_full() and _since_shot >= reload_delay:
			start_reload()
		return

	if is_full():
		stop_reload()
		return

	_reload_progress += delta
	if _reload_progress >= reload_time:
		_reload_progress -= reload_time
		add_ammo(1)
		if is_full():
			stop_reload()


func _emit() -> void:
	ammo_changed.emit(ammo, max_ammo)
	if debug_print:
		print("%s shells: %d/%d" % [get_parent().name, ammo, max_ammo])
