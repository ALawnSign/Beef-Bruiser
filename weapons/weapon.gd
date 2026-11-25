class_name Weapon
extends Node2D

signal attacked
signal killed(target: Node)

@export var weapon_name: String = "Weapon"
@export var damage: int = 1
@export var cooldown: float = 0.4
@export var unlocked: bool = true

var player: Player
var cooldown_timer: float = 0.0

@onready var ammo: Ammo = get_node_or_null("Ammo") as Ammo


func _physics_process(delta: float) -> void:
	cooldown_timer = maxf(cooldown_timer - delta, 0.0)
	_weapon_physics(delta)


func can_attack() -> bool:
	if cooldown_timer > 0.0:
		return false
	if ammo and not ammo.has_ammo():
		return false
	return true


func try_attack(aim: Vector2) -> void:
	if not can_attack():
		return
	if ammo:
		ammo.use()
	cooldown_timer = cooldown
	attack(aim)
	attacked.emit()


func reload() -> void:
	if ammo:
		ammo.request_reload()


func deal_damage(target: Node, amount: int) -> void:
	target.take_damage(amount)
	if target.is_queued_for_deletion():
		killed.emit(target)


func attack(_aim: Vector2) -> void:
	pass


func _weapon_physics(_delta: float) -> void:
	pass


func on_equipped() -> void:
	show()


func on_unequipped() -> void:
	if ammo:
		ammo.stop_reload()
	hide()


func is_target(body: Node) -> bool:
	return body != player and body.has_method("take_damage")
