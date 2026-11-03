extends CharacterBody2D

@export var speed: float = 80.0
@export var health: int = 3

var player: Node2D


func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	player = get_tree().get_first_node_in_group("player") as Node2D


func _physics_process(_delta: float) -> void:
	if not is_instance_valid(player):
		velocity = Vector2.ZERO
		return

	var direction := global_position.direction_to(player.global_position)
	velocity = direction * speed
	move_and_slide()


func take_damage(amount: int) -> void:
	health -= amount

	if health <= 0:
		queue_free()
