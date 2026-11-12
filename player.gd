extends CharacterBody2D

signal health_changed(current: int, maximum: int)
signal died

@export var speed: float = 200.0
@export var acceleration: float = 1500.0
@export var friction: float = 1800.0

@export_group("Walk Bob")
@export var bob_height: float = 4.0
@export var bob_speed: float = 12.0
@export var tilt_degrees: float = 5.0

@export_group("Dash")
@export var can_dash: bool = true
@export var dash_speed: float = 650.0
@export var dash_time: float = 0.15
@export var dash_cooldown: float = 0.6

@export_group("Health")
@export var max_health: int = 5
@export var invincible_time: float = 1.0
@export var knockback_strength: float = 350.0
@export var hurt_stun_time: float = 0.15 

@onready var sprite: Sprite2D = $Sprite2D
@onready var sprite_base_position: Vector2 = sprite.position
@onready var sprite_base_scale: Vector2 = sprite.scale

var bob_time: float = 0.0
var facing: Vector2 = Vector2.RIGHT

var is_dashing: bool = false
var dash_timer: float = 0.0
var dash_cooldown_timer: float = 0.0
var dash_direction: Vector2 = Vector2.RIGHT
var health: int = 0
var invincible_timer: float = 0.0
var hurt_timer: float = 0.0
var is_dead: bool = false


func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	add_to_group("player")
	health = max_health


func _physics_process(delta: float) -> void:
	if is_dead:
		return
	
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")

	if direction != Vector2.ZERO:
		facing = direction.normalized()
	
	dash_cooldown_timer = maxf(dash_cooldown_timer - delta, 0.0)
	invincible_timer = maxf(invincible_timer - delta, 0.0)
	hurt_timer = maxf(hurt_timer - delta, 0.0)
	
	if can_dash and hurt_timer == 0.0 and Input.is_action_just_pressed("dash") and not is_dashing and dash_cooldown_timer == 0.0:
		start_dash()
	
	if is_dashing:
		dash_timer -= delta
		velocity = dash_direction * dash_speed
		if dash_timer <= 0.0:
			is_dashing = false
			velocity = dash_direction * speed
	elif hurt_timer > 0.0:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
	elif direction != Vector2.ZERO:
		velocity = velocity.move_toward(direction * speed, acceleration * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
	
	move_and_slide()
	
	if direction.x != 0 and hurt_timer == 0.0:
		sprite.flip_h = direction.x < 0

	animate_walk(delta)
	animate_hurt()


# ---------- Dash ----------
func start_dash() -> void:
	is_dashing = true
	dash_timer = dash_time
	dash_cooldown_timer = dash_cooldown
	dash_direction = facing


func unlock_dash() -> void:
	can_dash = true


# ---------- Health ----------
func take_damage(amount: int, source_position: Vector2 = Vector2.INF) -> void:
	if is_dead or invincible_timer > 0.0:
		return

	health = maxi(health - amount, 0)
	health_changed.emit(health, max_health)
	print("Player health: ", health)

	if health == 0:
		die()
		return

	invincible_timer = invincible_time

	if source_position != Vector2.INF:
		is_dashing = false
		hurt_timer = hurt_stun_time
		velocity = source_position.direction_to(global_position) * knockback_strength


func heal(amount: int) -> void:
	if is_dead:
		return
	health = mini(health + amount, max_health)
	health_changed.emit(health, max_health)
	print("Player health: ", health)


func die() -> void:
	is_dead = true
	is_dashing = false
	velocity = Vector2.ZERO

	# Fall over and go grey
	sprite.position = sprite_base_position
	sprite.scale = sprite_base_scale
	sprite.rotation = deg_to_rad(90)
	sprite.modulate = Color(0.5, 0.5, 0.5)

	print("Player died")
	died.emit()


# ---------- Visuals ----------
func animate_walk(delta: float) -> void:
	if is_dashing:
		# Stretch out during the dash, no hopping
		sprite.position = sprite_base_position
		sprite.rotation = 0.0
		sprite.scale = sprite_base_scale * Vector2(1.3, 0.8)
		return

	# Ease back to normal size after a dash
	sprite.scale = sprite.scale.lerp(sprite_base_scale, 15.0 * delta)

	var moving := velocity.length() > 10.0

	if moving:
		# Steps get faster the faster we're going
		bob_time += delta * bob_speed * (velocity.length() / speed)
		var hop := absf(sin(bob_time))
		sprite.position.y = sprite_base_position.y - hop * bob_height
		sprite.rotation = deg_to_rad(sin(bob_time) * tilt_degrees)
	else:
		# Smoothly settle back to standing still
		bob_time = 0.0
		sprite.position = sprite.position.lerp(sprite_base_position, 15.0 * delta)
		sprite.rotation = lerp_angle(sprite.rotation, 0.0, 15.0 * delta)


func animate_hurt() -> void:
	if invincible_timer > 0.0:
		var blink_on := int(invincible_timer * 20.0) % 2 == 0
		sprite.modulate = Color(1.0, 0.5, 0.5, 1.0 if blink_on else 0.3)
	else:
		sprite.modulate = Color.WHITE


func _unhandled_input(event: InputEvent) -> void:
	if not OS.is_debug_build():
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_K:
			take_damage(1, global_position + Vector2(40, 0))  # pretend hit from the right
		elif event.keycode == KEY_H:
			heal(1)
		elif event.keycode == KEY_R:
			get_tree().reload_current_scene()
