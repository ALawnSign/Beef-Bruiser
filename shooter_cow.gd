extends "res://enemy.gd"

const PROJECTILE_SCRIPT = preload("res://cow_projectile.gd")

@export_group("Ranged Attack")
@export var attack_range: float = 260.0
@export var retreat_range: float = 100.0
@export var fire_interval: float = 1.8
@export var initial_fire_delay: float = 1.0
@export var projectile_speed: float = 180.0
@export var projectile_damage: int = 1

var fire_timer: float = 0.0


func _ready() -> void:
	super._ready()
	fire_timer = initial_fire_delay


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if not is_instance_valid(player) or (player is Player and player.is_dead):
		return

	fire_timer = maxf(fire_timer - delta, 0.0)
	if fire_timer > 0.0 or global_position.distance_to(player.global_position) > attack_range:
		return
	if not has_line_of_sight():
		return

	var projectile = PROJECTILE_SCRIPT.new()
	projectile.direction = global_position.direction_to(player.global_position)
	projectile.speed = projectile_speed
	projectile.damage = projectile_damage
	projectile.max_range = attack_range + 80.0
	projectile.shooter = self
	# Add to the map, not the scaled cow: projectiles retain world-space size/speed.
	get_parent().add_child(projectile)
	projectile.global_position = global_position
	fire_timer = maxf(fire_interval, 0.1)


func get_movement_direction() -> Vector2:
	var toward_player := global_position.direction_to(player.global_position)
	var distance := global_position.distance_to(player.global_position)
	if distance < retreat_range:
		return -toward_player
	if distance > attack_range * 0.8 or not has_line_of_sight():
		return toward_player
	return Vector2.ZERO


func has_line_of_sight() -> bool:
	var query := PhysicsRayQueryParameters2D.create(global_position, player.global_position, 1)
	query.exclude = [get_rid()]
	var result := get_world_2d().direct_space_state.intersect_ray(query)
	return result.is_empty() or result.collider == player
