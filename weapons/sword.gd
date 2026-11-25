extends Weapon

@export var reach: float = 32.0
@export var swing_arc_degrees: float = 120.0
@export var swing_time: float = 0.12
@export var visual_offset: Vector2 = Vector2(0, -26)

@onready var hitbox: Area2D = $Hitbox
@onready var hitbox_shape: CollisionShape2D = $Hitbox/CollisionShape2D

var swing_timer: float = 0.0
var already_hit: Array[Node] = []


func _ready() -> void:
	var circle := CircleShape2D.new()
	circle.radius = reach
	hitbox_shape.shape = circle


func attack(aim: Vector2) -> void:
	rotation = aim.angle()
	swing_timer = swing_time
	already_hit.clear()
	queue_redraw()


func _weapon_physics(delta: float) -> void:
	if swing_timer <= 0.0:
		return
	swing_timer -= delta

	var half_arc := deg_to_rad(swing_arc_degrees) / 2.0
	for body in hitbox.get_overlapping_bodies():
		if not is_target(body) or body in already_hit:
			continue
		# Only hit things inside the arc (we're rotated, so "forward" is angle 0)
		if absf(to_local(body.global_position).angle()) <= half_arc:
			already_hit.append(body)
			deal_damage(body, damage)

	queue_redraw()


func _draw() -> void:
	if swing_timer <= 0.0:
		return
	var fade := swing_timer / swing_time
	var half_arc := deg_to_rad(swing_arc_degrees) / 2.0
	var center := visual_offset.rotated(-rotation)
	draw_arc(center, reach, -half_arc, half_arc, 16, Color(1, 1, 1, fade), 4.0)
