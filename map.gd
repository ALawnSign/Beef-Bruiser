extends Node2D

# --- Scale ---
# Multiplies the size of the whole map (text, walls and spawn point together).
# Change this in the Inspector to make the map bigger/smaller.
@export var tile_scale: float = 0.75

# Original cell size the map was built around (one text character)
const CELL_W = 9
const CELL_H = 26

func _ready() -> void:
	create_arena()
	create_maze()
	center_map()
	show_map()
	walls()
	spawn_player()
	door_timer()


var arena = []

var arena_rows = 55
var arena_cols = 67
var door_open = false


var maze = []

var maze_rows = 55
var maze_cols = 217

var map_x = 400
var map_y = 250


# Builds the arena: walls around the edge, open inside, door on the right
func create_arena():
	for row in range(arena_rows):
		var new_row = []
		for col in range(arena_cols):
			if row == 0 or row == arena_rows - 1:
				new_row.append(1)
			elif col == 0:
				new_row.append(1)
			elif col == arena_cols - 1:
				if row >= 25 and row <= 29:
					new_row.append(2)
				else:
					new_row.append(1)
			else:
				new_row.append(0)
		arena.append(new_row)


# Builds the maze: start with all walls, then carve out rooms and halls
func create_maze():
	for row in range(maze_rows):
		var new_row = []
		for col in range(maze_cols):
			new_row.append(1)
		maze.append(new_row)

	# add_room(column, row, width, height)
	# Entrance (rows 25-29 line up with the arena door, in the middle)
	add_room(0, 25, 10, 5)

	# Rooms: 8 across and 6 down, each 26 wide and 8 tall
	# The +27 and +9 leave a wall only 1 tile thick between rooms
	for room_row in range(6):
		for room_col in range(8):
			add_room(1 + room_col * 27, 1 + room_row * 9, 26, 8)

	# Openings between rooms
	# Left/right openings are 5 rows tall, up/down openings are 15 columns wide
	# A full-size opening removes the whole wall, joining 2 rooms into 1 big room
	add_room(54, 1, 1, 5)
	add_room(162, 1, 1, 5)
	add_room(189, 1, 1, 5)
	add_room(27, 2, 1, 5)
	add_room(108, 2, 1, 5)
	add_room(81, 3, 1, 5)
	add_room(135, 3, 1, 5)
	add_room(37, 9, 15, 1)
	add_room(64, 9, 15, 1)
	add_room(116, 9, 15, 1)
	add_room(197, 9, 15, 1)
	add_room(108, 11, 1, 5)
	add_room(81, 12, 1, 5)
	add_room(162, 12, 1, 5)
	add_room(12, 18, 15, 1)
	add_room(57, 18, 15, 1)
	add_room(119, 18, 15, 1)
	add_room(142, 18, 15, 1)
	add_room(198, 18, 15, 1)
	add_room(54, 19, 1, 5)
	add_room(108, 19, 1, 8)
	add_room(135, 19, 1, 5)
	add_room(162, 19, 1, 5)
	add_room(189, 19, 1, 8)
	add_room(10, 27, 15, 1)
	add_room(37, 27, 15, 1)
	add_room(83, 27, 15, 1)
	add_room(110, 27, 15, 1)
	add_room(140, 27, 15, 1)
	add_room(168, 27, 15, 1)
	add_room(108, 28, 1, 8)
	add_room(27, 29, 1, 5)
	add_room(81, 29, 1, 5)
	add_room(189, 30, 1, 5)
	add_room(58, 36, 15, 1)
	add_room(111, 36, 15, 1)
	add_room(190, 36, 26, 1)
	add_room(54, 39, 1, 5)
	add_room(135, 39, 1, 5)
	add_room(162, 39, 1, 5)
	add_room(27, 40, 1, 5)
	add_room(12, 45, 15, 1)
	add_room(88, 45, 15, 1)
	add_room(143, 45, 15, 1)
	add_room(198, 45, 15, 1)
	add_room(54, 46, 1, 8)
	add_room(81, 46, 1, 5)
	add_room(108, 46, 1, 5)
	add_room(162, 46, 1, 5)
	add_room(27, 47, 1, 5)
	add_room(189, 47, 1, 5)

	# Exits: 3 gaps in the outer wall of the maze
	# 3 = real exit, 4 = fake exit
	# Each game, one exit is picked at random to be the real one
	var exits = [
		[216, 2, 1, 5],
		[216, 47, 1, 5],
		[113, 54, 15, 1]
	]
	var real_exit = randi() % exits.size()

	for i in range(exits.size()):
		var value = 4
		if i == real_exit:
			value = 3

		var e = exits[i]
		for row in range(e[1], e[1] + e[3]):
			for col in range(e[0], e[0] + e[2]):
				maze[row][col] = value

# Opens a box of 0s in the maze
func add_room(start_col: int, start_row: int, width: int, height: int):
	for row in range(start_row, start_row + height):
		for col in range(start_col, start_col + width):
			maze[row][col] = 0


func center_map():
	var screen_size = get_viewport_rect().size

	var map_width = (arena_cols + maze_cols) * CELL_W * tile_scale
	var map_height = max(arena_rows, maze_rows) * CELL_H * tile_scale

	map_x = (screen_size.x - map_width) / 2
	map_y = (screen_size.y - map_height) / 2


# Spawn point inside the arena, given as a grid cell (column, row)
@export var spawn_cell: Vector2i = Vector2i(10, 27)
func get_spawn_position() -> Vector2:
	return Vector2(
		map_x + (spawn_cell.x + 0.5) * CELL_W * tile_scale,
		map_y + (spawn_cell.y + 0.5) * CELL_H * tile_scale
	)


# Moves the Player to the spawn point.
# Works whether Player is a child of Map or next to Map in the same scene.
func spawn_player():
	var player = get_node_or_null("Player")

	if player == null and get_parent() != null:
		player = get_parent().get_node_or_null("Player")

	if player != null:
		player.global_position = to_global(get_spawn_position())


func make_wall(x_offset: float, row: int):
	var wall = StaticBody2D.new()
	var collision = CollisionShape2D.new()
	var box = RectangleShape2D.new()

	box.size = Vector2(CELL_W, CELL_H) * tile_scale
	collision.shape = box

	wall.position = Vector2(
		map_x + x_offset * tile_scale,
		map_y + (row * CELL_H + CELL_H / 2.0) * tile_scale
	)

	wall.add_child(collision)
	add_child(wall)


func walls():
	for row in range(arena_rows):
		for col in range(arena_cols):
			if arena[row][col] == 1 or arena[row][col] == 2 and not door_open:
				make_wall(
					4.5 + col * CELL_W,
					row
				)

	for row in range(maze_rows):
		for col in range(maze_cols):
			if maze[row][col] == 1:
				make_wall(
					4.5 + arena_cols * CELL_W + col * CELL_W,
					row
				)


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
	var map_label = Node2D.new()
	map_label.name = "MapLabel"
	add_child(map_label)

	for row in range(arena_rows):
		for col in range(arena_cols):

			if arena[row][col] == 1:
				make_number(
					map_label,
					col,
					row,
					"1"
				)

			elif arena[row][col] == 2 and not door_open:
				make_number(
					map_label,
					col,
					row,
					"2"
				)

	for row in range(maze_rows):
		for col in range(maze_cols):

			if maze[row][col] == 1:
				make_number(
					map_label,
					arena_cols + col,
					row,
					"1"
				)


func make_number(parent, col: int, row: int, number: String):
	var label = Label.new()

	label.text = number

	label.position = Vector2(
		map_x + col * CELL_W * tile_scale,
		map_y + row * CELL_H * tile_scale
	)

	label.scale = Vector2(
		tile_scale,
		tile_scale
	)

	label.add_theme_font_size_override(
		"font_size",
		12
	)

	parent.add_child(label)
