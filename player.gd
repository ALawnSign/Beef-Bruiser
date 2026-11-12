extends CharacterBody2D
@export var speed: float = 200.0
@export var acceleration: float = 1500.0
@export var friction: float = 1800.0

@onready var sprite: Sprite2D = $Sprite2D


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
