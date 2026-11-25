extends Weapon

@export_group("Spin")
@export var orbit_radius: float = 55.0
@export var orbit_offset: Vector2 = Vector2(0, -26)
@export var spin_time: float = 0.3
@export var spin_turns: float = 1.0

@export_group("Look")
@export var ball_radius: float = 6.0
@export var rest_offset: Vector2 = Vector2(12, 14)

const ENEMY_MASK := 2

var spinning: bool = false
var spin_timer: float = 0.0
var start_angle: float = 0.0
var swept: float = 0.0
var already_hit: Array[Node] = []

var spin_area: Area2D
var spin_shape: CircleShape2D


func _ready() -> void:
	z_index = 1
	spin_area = Area2D.new()
	spin_area.collision_layer = 0
	spin_area.collision_mask = ENEMY_MASK
	spin_area.monitorable = false
	spin_shape = CircleShape2D.new()
	var shape := CollisionShape2D.new()
	shape.shape = spin_shape
	spin_area.add_child(shape)
	add_child(spin_area)
	_update_area()


func _update_area() -> void:
	spin_shape.radius = orbit_radius + ball_radius
	spin_area.position = orbit_offset


func _weapon_physics(delta: float) -> void:
	if Input.is_action_just_pressed("flail_spin") and player.hurt_timer == 0.0:
		try_attack(player.facing)

	if spinning:
		_spin_step(delta)

	queue_redraw()


func attack(aim: Vector2) -> void:
	spinning = true
	spin_timer = 0.0
	swept = 0.0
	start_angle = aim.angle()
	already_hit.clear()
	print("Flail spin!")


func _spin_step(delta: float) -> void:
	spin_timer += delta
	var t := minf(spin_timer / spin_time, 1.0)
	swept = t * TAU * spin_turns

	var center := global_position + orbit_offset
	for body in spin_area.get_overlapping_bodies():
		if not is_target(body) or body in already_hit:
			continue
		var cow_angle := (body.global_position - center).angle()
		if swept >= TAU or wrapf(cow_angle - start_angle, 0.0, TAU) <= swept:
			already_hit.append(body)
			deal_damage(body, damage)

	if t >= 1.0:
		spinning = false


func _draw() -> void:
	if spinning:
		var a := start_angle + swept
		var ball_pos := orbit_offset + Vector2.from_angle(a) * orbit_radius
		var trail := minf(swept, TAU * 0.6)
		draw_arc(orbit_offset, orbit_radius, a - trail, a, 24, Color(1, 1, 1, 0.35), 6.0)
		draw_line(orbit_offset, ball_pos, Color(0.6, 0.6, 0.6), 2.0)
		_draw_ball(ball_pos, 1.0)
	else:
		var alpha := 1.0 if cooldown_timer == 0.0 else 0.3
		_draw_ball(orbit_offset + rest_offset, alpha)


func _draw_ball(pos: Vector2, alpha: float) -> void:
	draw_circle(pos, ball_radius, Color(0.35, 0.35, 0.4, alpha))
	for s in 6:
		var dir := Vector2.from_angle(TAU * s / 6.0 + spin_timer * 20.0)
		draw_line(pos + dir * ball_radius, pos + dir * (ball_radius + 3.0),
				Color(0.8, 0.8, 0.85, alpha), 2.0)
