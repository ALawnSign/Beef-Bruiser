extends CharacterBody2D
@export var speed: float = 200.0
@export var acceleration: float = 1500.0
@export var friction: float = 1800.0

@export_group("Walk Bob")
@export var bob_height: float = 4.0
@export var bob_speed: float = 12.0
@export var tilt_degrees: float = 5.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var sprite_base_position: Vector2 = sprite.position

var bob_time: float = 0.0


func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING


func _physics_process(delta: float) -> void:
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")

	if direction != Vector2.ZERO:
		velocity = velocity.move_toward(direction * speed, acceleration * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)

	move_and_slide()
	
	if direction.x != 0:
		sprite.flip_h = direction.x < 0
		
	animate_walk(delta)


func animate_walk(delta: float) -> void:
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
