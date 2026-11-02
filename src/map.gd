extends Node2D

func _ready() -> void:
	create_maze()
	show_map()
	walls()
	door_timer()
	# player spawn, turn on when Player is added
	#$Player.position = Vector2(map_x + 15, map_y + 39)

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
	
func walls():
	for row in range(arena_rows):
		for col in range(arena_cols):
			if arena[row][col] == 1 or arena[row][col] == 2 and not door_open:
				var wall = StaticBody2D.new()
				var collision = CollisionShape2D.new()
				var box = RectangleShape2D.new()
				
				box.size = Vector2(9, 26)
				collision.shape = box
				
				wall.position = Vector2(map_x + 4.5 + col * 9, map_y + row * 26)
				
				wall.add_child(collision)
				add_child(wall)

	for row in range(maze_rows):
		for col in range(maze_cols):
			if maze[row][col] == 1:
				var wall = StaticBody2D.new()
				var collision = CollisionShape2D.new()
				var box = RectangleShape2D.new()
				
				box.size = Vector2(9, 26)
				collision.shape = box
				
				wall.position = Vector2(map_x + 49.5 + col * 9, map_y + row * 26)
				
				wall.add_child(collision)
				add_child(wall)

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
