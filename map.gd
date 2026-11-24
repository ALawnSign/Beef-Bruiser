extends Node2D

# --- Scale ---
# Multiplies the size of the whole map (text, walls and spawn point together).
# Change this in the Inspector to make the map bigger/smaller.
@export var tile_scale: float = 0.75
@export var enemy_spawn_cell: Vector2i = Vector2i(30, 27)

# Spawn point inside the arena, given as a grid cell (column, row)
@export var spawn_cell: Vector2i = Vector2i(10, 27)

const CELL_W = 9
const CELL_H = 26

var arena = []

var arena_rows = 55
var arena_cols = 67
var door_open = false

var maze = []

var maze_rows = 55
var maze_cols = 217
var exit_list = []
var exit_numbers = [1 ,2, 3]
var clue_number = 0

#color for each number: 1 = red, 2 = blue, 3 = green
var number_colors = [Color.RED, Color.BLUE, Color.GREEN]

#Game over message
var game_over =  false

#Amp size of one tile
var tile_width = CELL_W * tile_scale
var tile_height = CELL_H * tile_scale

var map_x = 400
var map_y = 250


# ============================================================
# MAP 
# ============================================================
func _ready() -> void:
	create_arena()
	create_maze()
	center_map()
	show_map()
	walls()
	spawn_player()
	position_enemy()
	door_timer()
	make_exit()


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


#Builds the maze
func create_maze():
	#fill the whole maze with walls
	for row in range(maze_rows):
		var new_row = []
		for col in range(maze_cols):
			new_row.append(1)
		maze.append(new_row)

	#entrance that lines up with the arena door
	open_door(0, 25, 10, 5)

	#make the rooms (8 across, 6 down)
	for room_row in range(6):
		for room_col in range(8):
			open_door(1 + room_col * 27, 1 + room_row * 9, 26, 8)

	#make random paths between rooms
	make_paths()

	#the 3 exits [col, row, width, height]
	var exits = [
		[216, 2, 1, 5],
		[216, 47, 1, 5],
		[113, 54, 15, 1]
	]
	#pick one exit to be the real one
	var real_exit = randi() % exits.size()

	#mark each exit, 3 = real, 4 = fake
	for i in range(exits.size()):
		var value = 4
		if i == real_exit:
			value = 3

		var e = exits[i]
		for row in range(e[1], e[1] + e[3]):
			for col in range(e[0], e[0] + e[2]):
				maze[row][col] = value

	#mix up 1, 2, 3 so each exit gets a random number
	exit_numbers.shuffle()
	#save the real exit's number for the door
	clue_number = exit_numbers[real_exit]
	#save the exits so show_map can draw them
	exit_list = exits

	#random chests and traps
	place_random(5, 6)
	place_random(6, 20)


#Turns sides of the room into open paths/open doors
func open_door(col: int, row: int, width: int, height: int):
	#Go down from starting row to end row plus thus the size of the door/path
	for current_row in range(row, row + height):
		
		#Go across from starting col to end col plus thus the size of the door/path
		for current_col in range(col, col + width):
			
			#replace wtih 0 which is a path
			maze[current_row][current_col] = 0


#Goes through every room and makes a path to the right or down
func make_paths():
	#Go through all rooms in the map 
	for room_row in range(6):
		for room_col in range(8):
			#Find where this room starts on the map 
			var col = 1 + room_col * 27
			var row = 1 + room_row * 9
			
			#bottom-right room: nowhere to go, do nothing
			if room_col == 7 and room_row == 5:
				pass
				
			#far-right column: can only open a door down
			elif room_col == 7:
				open_door(col + randi() % 12, row + 8, 15, 1)
				
			#bottom row: can only open a door right
			elif room_row == 5:
				open_door(col + 26, row + randi() % 4, 1, 5)
				
			#coin flip 0: open a door right
			elif randi() % 2 == 0:
				open_door(col + 26, row + randi() % 4, 1, 5)
				
			#coin flip 1: open a door down
			else:
				open_door(col + randi() % 12, row + 8, 15, 1)


#Centers the whole map on the screen
func center_map():
	#Get how big the game window is
	var screen_size = get_viewport_rect().size

	#How wide the whole map is (arena + maze side by side)
	var map_width = (arena_cols + maze_cols) * CELL_W * tile_scale
	
	#How tall the whole map is (uses whichever is taller)
	var map_height = max(arena_rows, maze_rows) * CELL_H * tile_scale

	#Leftover space split in half on each side, so the map sits in the middle
	map_x = (screen_size.x - map_width) / 2
	map_y = (screen_size.y - map_height) / 2


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
	await get_tree().create_timer(2).timeout

	door_open = true

	for child in get_children():
		if child is StaticBody2D:
			child.queue_free()

	walls()

	print("Door opens")

	$MapLabel.free()
	show_map()


#Draws the map on screen
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

	#when the door opens, put a small clue color next to the door
	if door_open:
		make_color_tile(map_label, arena_cols - 2, 24, number_colors[clue_number - 1])

	for row in range(maze_rows):
		for col in range(maze_cols):

			if maze[row][col] == 1:
				make_number(
					map_label,
					arena_cols + col,
					row,
					"1"
				)
			elif maze[row][col] == 5:
				make_color_tile(map_label, arena_cols + col, row, Color.GOLD)
			elif maze[row][col] == 6:
				make_color_tile(map_label, arena_cols + col, row, Color.PURPLE)

	#put a small color next to each exit
	for i in range(exit_list.size()):
		var e = exit_list[i]
		make_color_tile(map_label, arena_cols + e[0] - 1, e[1] - 1, number_colors[exit_numbers[i] - 1])


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

#Colors one tile on the map
func make_color_tile(parent, col, row, color):
	var tile = ColorRect.new()
	tile.color = color
	tile.size = Vector2(CELL_W, CELL_H) * tile_scale
	tile.position = Vector2(map_x + col * CELL_W * tile_scale, map_y + row * CELL_H * tile_scale)
	parent.add_child(tile)

#Puts chests or traps in random spots inside the rooms
func place_random(value, amount):
	for i in range(amount):
		#pick a random room
		var room_col = randi() % 8
		var room_row = randi() % 6
		#pick a random spot inside that room
		var col = 1 + room_col * 27 + randi() % 26
		var row = 1 + room_row * 9 + randi() % 8
		maze[row][col] = value


#Shows big text in the middle of the screen and freezes the game
func show_message(text):
	#keeps the text on the screen
	var layer = CanvasLayer.new()
	add_child(layer)

	#the text
	var label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 64)

	#stretch the label across the screen and center the text in it
	var screen_size = get_viewport_rect().size
	label.position = Vector2(0, screen_size.y / 2 - 40)
	label.size.x = screen_size.x
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layer.add_child(label)

	#freeze the game
	get_tree().paused = true


func real_exit(body):
	if body.name == "Player" and game_over == false:
		game_over = true
		show_message("Congratulations You Have Survived")


func fake_exit(body):
	if body.name == "Player" and game_over == false:
		game_over = true
		show_message("You have been Cowed!!")


func trap_hit(body):
	if body.name =="Player" and game_over == false:
		game_over = true
		show_message("You have stepped in cow min")

func make_exit(): 
	for row in range(maze_rows):
		for col in range(maze_cols):
			
			if maze[row][col] == 3 or maze[row][col] == 4 or maze[row][col] == 6:
				
				var plate = Area2D.new()
				var shape = CollisionShape2D.new()
				var box = RectangleShape2D.new()
				
				box.size = Vector2(tile_width, tile_height)
				shape.shape = box
				plate.add_child(shape)
				
				var x = map_x + (arena_cols + col) * tile_width
				
				var y = map_y + row * tile_height
				
				x = x + tile_width / 2
				y = y + tile_height / 2 
				
				plate.position = Vector2(x, y)
				
				if maze[row][col] == 3: 
					plate.body_entered.connect(real_exit)
				if maze[row][col] == 4:
					plate.body_entered.connect(fake_exit)
				if maze[row][col] == 6:
					plate.body_entered.connect(trap_hit)
				
				add_child(plate)


# ============================================================
# CHARACTER
# ============================================================

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
	
	


# ============================================================
# ENEMY
# ============================================================

func position_enemy() -> void:
	var enemy := get_node_or_null("Enemy") as Node2D

	if enemy == null:
		return

	var spawn_position := Vector2(
		map_x + (enemy_spawn_cell.x + 0.5) * CELL_W * tile_scale,
		map_y + (enemy_spawn_cell.y + 0.5) * CELL_H * tile_scale
	)

	enemy.global_position = to_global(spawn_position)
