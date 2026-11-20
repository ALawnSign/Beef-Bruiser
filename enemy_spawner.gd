extends Node2D

@export var spawn_interval: float = 0.25
@export var enemy_scale: float = 0.3

const ENEMY_SCENE: PackedScene = preload("res://enemy.tscn")

var spawn_timer: Timer
var spawned_count: int = 0

# Cells inside the starting arena.
var spawn_cells: Array[Vector2i] = [
	Vector2i(30, 27),
	Vector2i(45, 15),
	Vector2i(45, 40),
]


func _ready() -> void:
	spawn_timer = Timer.new()
	spawn_timer.wait_time = maxf(spawn_interval, 0.1)
	spawn_timer.timeout.connect(spawn_enemy)
	add_child(spawn_timer)
	spawn_timer.start()

func _process(_delta: float) -> void:
	if get_parent().door_open:
		spawn_timer.stop()

func spawn_enemy() -> void:
	var map = get_parent()
	var player := get_tree().get_first_node_in_group("player")
	
	if map.door_open or not is_instance_valid(player):
		spawn_timer.stop()
		return
	
	var cell: Vector2i = spawn_cells.pick_random()

	var spawn_position := Vector2(
		map.map_x + (cell.x + 0.5) * map.CELL_W * map.tile_scale,
		map.map_y + (cell.y + 0.5) * map.CELL_H * map.tile_scale
	)

	var enemy := ENEMY_SCENE.instantiate() as CharacterBody2D
	enemy.position = spawn_position
	enemy.scale = Vector2.ONE * enemy_scale
	map.add_child(enemy)

	spawned_count += 1
	print("Spawned cow ", spawned_count)
