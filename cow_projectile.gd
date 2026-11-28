extends Node2D

var direction: Vector2 = Vector2.RIGHT
var speed: float = 180.0
var damage: int = 1
var max_range: float = 340.0
var shooter: CollisionObject2D
var travelled: float = 0.0
var sweep: ShapeCast2D


func _ready() -> void:
	z_index = 1
	sweep = ShapeCast2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 4.0
	sweep.shape = circle
	# World and player bodies share layer 1. Ignore enemy bodies on layer 2.
	sweep.collision_mask = 1
	sweep.enabled = false
	add_child(sweep)
	if is_instance_valid(shooter):
		sweep.add_exception(shooter)


func _physics_process(delta: float) -> void:
	var step := minf(speed * delta, max_range - travelled)
	sweep.target_position = direction * step
	sweep.force_shapecast_update()
	if sweep.is_colliding():
		# Use the nearest collision so a wall always shields the player behind it.
		var nearest: Object = null
		var nearest_fraction: float = INF
		for i in sweep.get_collision_count():
			var fraction := global_position.distance_squared_to(sweep.get_collision_point(i))
			if fraction < nearest_fraction:
				nearest_fraction = fraction
				nearest = sweep.get_collider(i)
		if nearest is Player:
			nearest.take_damage(damage, global_position)
		queue_free()
		return

	global_position += direction * step
	travelled += step
	if travelled >= max_range:
		queue_free()


func _draw() -> void:
	draw_circle(Vector2.ZERO, 5.0, Color(0.2, 0.65, 1.0))
	draw_circle(Vector2.ZERO, 2.0, Color.WHITE)
