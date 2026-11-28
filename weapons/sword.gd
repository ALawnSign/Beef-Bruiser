extends Weapon

@export var reach: float = 32.0
@export var swing_arc_degrees: float = 120.0
@export var swing_time: float = 0.12
@export var visual_offset: Vector2 = Vector2(0, -26)

@export_group("Visual")
@export var rest_hand: Vector2 = Vector2(9, -20)
@export var rest_angle_degrees: float = -60.0
@export var swing_hand_distance: float = 8.0
@onready var sword_pivot: Node2D = $SwordPivot

@onready var hitbox: Area2D = $Hitbox
@onready var hitbox_shape: CollisionShape2D = $Hitbox/CollisionShape2D

var swing_timer: float = 0.0
var already_hit: Array[Node] = []
var swing_dir: float = 1.0


func _ready() -> void:
	var circle := CircleShape2D.new()
	circle.radius = reach
	hitbox_shape.shape = circle


func attack(aim: Vector2) -> void:
	rotation = aim.angle()
	swing_timer = swing_time
	swing_dir = -swing_dir
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


func _process(_delta: float) -> void:
	if player == null or not visible:
		return
	var hand: Vector2
	var angle: float
	var flip: bool
	if swing_timer > 0.0:
		var t := 1.0 - swing_timer / swing_time
		var half_arc := deg_to_rad(swing_arc_degrees) / 2.0
		angle = rotation + lerpf(-half_arc, half_arc, t) * swing_dir
		hand = visual_offset + Vector2.from_angle(angle) * swing_hand_distance
		flip = cos(rotation) < 0.0
	else:
		flip = player.sprite.flip_h
		var rest_angle := deg_to_rad(rest_angle_degrees)
		if flip:
			hand = Vector2(-rest_hand.x, rest_hand.y)
			angle = PI - rest_angle
		else:
			hand = rest_hand
			angle = rest_angle
		hand += player.sprite.position - player.sprite_base_position
	sword_pivot.position = hand.rotated(-rotation)
	sword_pivot.rotation = angle - rotation
	sword_pivot.scale = Vector2(1, -1 if flip else 1)
