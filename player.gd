extends CharacterBody2D
@export var speed: float = 200.0
@export var hitpoints: int = 5
@export var damage_cooldown: float = 1.0

var protection_remaining: float = 0.0

func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING


func _physics_process(delta: float) -> void:
	protection_remaining = maxf(protection_remaining - delta, 0.0)

	var direction := Input.get_vector(
		"move_left", "move_right", "move_up", "move_down"
	)
	velocity = direction * speed
	move_and_slide()


func take_damage(amount: int = 1) -> void:
	if hitpoints <= 0 or protection_remaining > 0.0:
		return

	hitpoints = maxi(hitpoints - amount, 0)
	protection_remaining = damage_cooldown

	print("Player hit! Hitpoints remaining: ", hitpoints)

	if hitpoints == 0:
		print("Player defeated!")
		queue_free()
