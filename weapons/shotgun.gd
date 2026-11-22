extends Weapon

const PELLET_SCENE: PackedScene = preload("res://weapons/pellet.tscn")

@export_group("Spread")
@export var pellet_count: int = 5
@export var spread_degrees: float = 30.0
@export var spread_jitter_degrees: float = 4.0

@export_group("Pellets")
@export var pellet_speed: float = 650.0
@export var pellet_range: float = 220.0

@export var muzzle_offset: Vector2 = Vector2(0, -26)

func attack(aim: Vector2) -> void:
	var start := get_muzzle_position()
	var half_spread := deg_to_rad(spread_degrees) / 2.0
	var jitter := deg_to_rad(spread_jitter_degrees)

	for i in pellet_count:
		var t := 0.5 if pellet_count == 1 else float(i) / (pellet_count - 1)
		var angle := aim.angle() + lerpf(-half_spread, half_spread, t) + randf_range(-jitter, jitter)
		spawn_pellet(start, Vector2.from_angle(angle))


func spawn_pellet(start: Vector2, dir: Vector2) -> void:
	var pellet: Pellet = PELLET_SCENE.instantiate()
	pellet.direction = dir
	pellet.speed = pellet_speed
	pellet.max_range = pellet_range
	pellet.damage = damage
	pellet.shooter = player
	get_tree().current_scene.add_child(pellet)
	pellet.global_position = start


func get_muzzle_position() -> Vector2:
	var feet := player.global_position
	var muzzle := feet + muzzle_offset
	var query := PhysicsRayQueryParameters2D.create(feet, muzzle)
	query.collision_mask = 1
	query.exclude = [player.get_rid()]
	var result := get_world_2d().direct_space_state.intersect_ray(query)
	if result:
		return result.position
	return muzzle
