extends CharacterBody2D

@export var speed: float = 80.0
#@export var health: int = 3
@export var hitpoints: int = 2
@export var contact_damage: int = 1

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

	for area in $ContactArea.get_overlapping_areas():
		if area.is_in_group("player_hurtbox"):
			player.call("take_damage", contact_damage, global_position)
			break

func take_damage(amount: int = 1) -> void:
	if hitpoints <= 0:
		return

	hitpoints = maxi(hitpoints - amount, 0)
	print(name, " has ", hitpoints, " hitpoints left")

	if hitpoints == 0:
		die()
	
func die() -> void:
	queue_free()
