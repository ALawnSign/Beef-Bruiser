extends CharacterBody2D

signal attacked
signal killed(target: Node)

@export var weapon_name: String = "Weapon"
@export var damage: int = 1
@export var cooldown: float = 0.4
@export var unlocked: bool = true
@export var passive: bool = false

var player: Player
var cooldown_timer: float = 0.0

var _hit_cooldowns: Dictionary = {}

@onready var ammo: Ammo = get_node_or_null("Ammo") as Ammo

func _physics_process(delta: float) -> void:
	if passive and (not unlocked or player == null or player.is_dead):
		return
	cooldown_timer = maxf(cooldown_timer - delta, 0.0)
	_tick_hit_cooldowns(delta)
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
	if not is_instance_valid(target) or target.is_queued_for_deletion():
		return
	target.take_damage(amount)
	if target.is_queued_for_deletion():
		killed.emit(target)


func can_hit(target: Node) -> bool:
	return not _hit_cooldowns.has(target)


func try_hit(target: Node, amount: int, hit_cooldown: float) -> bool:
	if not can_hit(target):
		return false
	_hit_cooldowns[target] = hit_cooldown
	deal_damage(target, amount)
	return true


func _tick_hit_cooldowns(delta: float) -> void:
	for target in _hit_cooldowns.keys():
		if not is_instance_valid(target):
			_hit_cooldowns.erase(target)
			continue
		_hit_cooldowns[target] -= delta
		if _hit_cooldowns[target] <= 0.0:
			_hit_cooldowns.erase(target)


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
