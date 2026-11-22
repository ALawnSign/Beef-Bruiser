extends Node2D

signal weapon_changed(weapon: Weapon)

enum AimMode { MOUSE, FACING }
@export var aim_mode: AimMode = AimMode.MOUSE
@export var aim_offset: Vector2 = Vector2(0, -26)

@onready var player: Player = get_parent() as Player

var weapons: Array[Weapon] = []
var current: Weapon = null


func _ready() -> void:
	for child in get_children():
		if child is Weapon:
			child.player = player
			child.hide()
			weapons.append(child)
	switch_by(1)


func _physics_process(_delta: float) -> void:
	if player.is_dead:
		return
	if Input.is_action_just_pressed("next_weapon"):
		switch_by(1)
	elif Input.is_action_just_pressed("prev_weapon"):
		switch_by(-1)

	for i in mini(weapons.size(), 4):
		if Input.is_action_just_pressed("weapon_%d" % (i + 1)):
			equip(i)

	if current and Input.is_action_pressed("attack") \
			and player.hurt_timer == 0.0 and not player.is_dashing:
		current.try_attack(get_aim_direction())


func get_aim_direction() -> Vector2:
	if aim_mode == AimMode.MOUSE:
		var to_mouse := get_global_mouse_position() - (global_position + aim_offset)
		if to_mouse.length() > 1.0:
			return to_mouse.normalized()
	return player.facing


func equip(index: int) -> void:
	if index < 0 or index >= weapons.size():
		return
	var weapon := weapons[index]
	if not weapon.unlocked or weapon == current:
		return
	if current:
		current.on_unequipped()
	current = weapon
	current.on_equipped()
	weapon_changed.emit(current)
	print("Equipped: ", current.weapon_name)


func switch_by(step: int) -> void:
	if weapons.is_empty():
		return
	var start := weapons.find(current)
	for n in range(1, weapons.size() + 1):
		var i := posmod(start + step * n, weapons.size())
		if weapons[i].unlocked:
			equip(i)
			return


func unlock_weapon(weapon_name: String, equip_now: bool = true) -> void:
	for i in weapons.size():
		if weapons[i].weapon_name == weapon_name:
			weapons[i].unlocked = true
			if equip_now or current == null:
				equip(i)
			return
