extends Node2D

# --- Scale ---
# Multiplies the size of the whole map (text, walls and spawn point together).
# Change this in the Inspector to make the map bigger/smaller.
@export var tile_scale: float = 3.0

# Original cell size the map was built around (one text character)
const CELL_W = 9
const CELL_H = 26

func _ready() -> void:
	create_maze()
	show_map()
	walls()
	spawn_player()
	door_timer()

var arena = [
	[1,1,1,1,1],
	[1,0,0,0,1],
	[1,0,0,0,2],
	[1,0,0,0,2],
	[1,1,1,1,1]
]
var arena_rows = 5
var arena_cols = 5
var door_open = false

#var maze = [
#	[1,1,1,1,1],
#	[1,0,0,0,1],
#	[1,0,1,0,1],
#	[1,0,0,0,1],
#	[1,1,1,1,1]
#]
var maze_rows = 5
var maze_cols = 15
var map_x = 400
var map_y = 250
var maze = []


# Spawn point inside the arena (scales with the map)
func get_spawn_position() -> Vector2:
	return Vector2(map_x + 15 * tile_scale, map_y + 39 * tile_scale)

# Moves the Player to the spawn point.
# Works whether Player is a child of Map or next to Map in the same scene.
func spawn_player():
	var player = get_node_or_null("Player")
	if player == null and get_parent() != null:
		player = get_parent().get_node_or_null("Player")
	if player != null:
		player.global_position = to_global(get_spawn_position())


func create_maze():
	for row in range(maze_rows):
		var new_row = []
		for col in range(maze_cols):
			if row == 0 or row == maze_rows - 1:
				new_row.append(1)
			elif col == 0:
				new_row.append(0)
			elif col == maze_cols - 1:
				new_row.append(1)
			else:
				new_row.append(0)
		maze.append(new_row)

func make_wall(x_offset: float, row: int):
	var wall = StaticBody2D.new()
	var collision = CollisionShape2D.new()
	var box = RectangleShape2D.new()
	box.size = Vector2(CELL_W, CELL_H) * tile_scale
	collision.shape = box
	wall.position = Vector2(map_x + x_offset * tile_scale, map_y + row * CELL_H * tile_scale)
	wall.add_child(collision)
	add_child(wall)


func walls():
	for row in range(arena_rows):
		for col in range(arena_cols):
			if arena[row][col] == 1 or arena[row][col] == 2 and not door_open:
				make_wall(4.5 + col * CELL_W, row)
	for row in range(maze_rows):
		for col in range(maze_cols):
			if maze[row][col] == 1:
				make_wall(49.5 + col * CELL_W, row)


func door_timer():
	await get_tree().create_timer(20).timeout
	door_open = true
	for child in get_children():
		if child is StaticBody2D:
			child.queue_free()
	walls()
	print("Door opens")
	$MapLabel.free()
	show_map()


func show_map():
	var label = Label.new()
	label.name = "MapLabel"
	label.position = Vector2(map_x, map_y)
	label.scale = Vector2(tile_scale, tile_scale)  # text grows with the walls
	var text = ""

	for row in range(5):
		for col in arena[row]:
			if col == 2 and door_open:
				text = text + "  "
			elif col == 0:
				text = text + "   "
			else:
				text = text + str(col)
		for col in maze[row]:
			if col == 0:
				text = text + "  "
			else:
				text = text + str(col)
		text = text + "\n"

	label.text = text
	add_child(label)
