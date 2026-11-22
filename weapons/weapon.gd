class_name Weapon
extends Node2D

signal attacked

@export var weapon_name: String = "Weapon"
@export var damage: int = 1
@export var cooldown: float = 0.4
@export var unlocked: bool = true

var player: Player
var cooldown_timer: float = 0.0

func _physics_process(delta: float) -> void:
	cooldown_timer = maxf(cooldown_timer - delta, 0.0)
	_weapon_physics(delta)


func can_attack() -> bool:
	return cooldown_timer == 0.0


func try_attack(aim: Vector2) -> void:
	if not can_attack():
		return
	cooldown_timer = cooldown
	attack(aim)
	attacked.emit()


func attack(_aim: Vector2) -> void:
	pass


func _weapon_physics(_delta: float) -> void:
	pass


func on_equipped() -> void:
	show()


func on_unequipped() -> void:
	hide()


func is_target(body: Node) -> bool:
	return body != player and body.has_method("take_damage")
