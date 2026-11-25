class_name Pellet
extends Node2D

var direction: Vector2 = Vector2.RIGHT
var speed: float = 650.0
var max_range: float = 220.0
var damage: int = 1
var shooter: Node = null

const RADIUS: float = 3.0

var travelled: float = 0.0

@onready var shape_cast: ShapeCast2D = $ShapeCast


func _ready() -> void:
	z_index = 1
	var circle := CircleShape2D.new()
	circle.radius = RADIUS
	shape_cast.shape = circle
	shape_cast.enabled = false
	shape_cast.collision_mask = 3
	if shooter is CollisionObject2D:
		shape_cast.add_exception(shooter)


func _physics_process(delta: float) -> void:
	var step := speed * delta
	var motion := direction * step

	shape_cast.target_position = motion
	shape_cast.force_shapecast_update()

	if shape_cast.is_colliding():
		hit()
		return

	global_position += motion
	travelled += step
	if travelled >= max_range:
		queue_free()


func hit() -> void:
	for i in shape_cast.get_collision_count():
		var body := shape_cast.get_collider(i)
		if body and body != shooter and body.has_method("take_damage"):
			body.take_damage(damage)
			break
	queue_free()


func _draw() -> void:
	draw_line(Vector2.ZERO, -direction * 8.0, Color(1.0, 0.85, 0.3), 2.0)
	draw_circle(Vector2.ZERO, 1.5, Color.WHITE)
