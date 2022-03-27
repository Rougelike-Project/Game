extends Node2D

const TileSize = 64

const LevelSizes = [
	Vector2(60, 60), 
	Vector2(70, 70),
	Vector2(80, 80),
	Vector2(90, 90),
	Vector2(100, 100),
]

const LevelRoomCounts = [9, 11, 13, 16, 18]
const MinRoomDimension = 12
const MaxRoomDimension = 18

enum Tile {Floor, ElevatedFloor, Clif, Wall}

#Current Level ------------------------

var LevelNum = 0
var map = []
var rooms = []
var LevelSize 

#Node References -----------------------------

onready var tile_map = $TileMap
onready var player = $Player

#Game State -----------------------------

var PlayerTile
var score = 0



func _ready():
	OS.set_window_size(Vector2(1960, 1080))
	randomize()
	buildLevel()
	
func buildLevel():
	#Start blank map
	
	rooms.clear()
	map.clear()
	tile_map.clear()
	
	LevelSize = LevelSizes[LevelNum]
	for x in range(LevelSize.x):
		map.append([])
		for y in range(LevelSize.y):
			map[x].append(Tile.Floor)
			tile_map.set_cell(x, y, Tile.Floor) 
			
	var free_regions = [Rect2(Vector2(2,2), LevelSize - Vector2(4,4))]
	var num_rooms = LevelRoomCounts[LevelNum]
	#Create Rooms
	for i in range(num_rooms):
		add_room(free_regions)
		if free_regions.empty():
			break

	connect_rooms()
	
	#Place player please dont crash 
		# Place player
	

	
func connect_rooms():
	# Build an AStar graph of the area where we can add corridors
	
	var stone_graph = AStar.new()
	var point_id = 0
	for x in range(LevelSize.x):
		for y in range(LevelSize.y):
			if map[x][y] == Tile.Floor:
				stone_graph.add_point(point_id, Vector3(x, y, 0))
				
				# Connect to left if also stone
				if x > 0 && map[x - 1][y] == Tile.Floor:
					var left_point = stone_graph.get_closest_point(Vector3(x - 1, y, 0))
					stone_graph.connect_points(point_id, left_point)
					
				# Connect to above if also stone
				if y > 0 && map[x][y - 1] == Tile.Floor:
					var above_point = stone_graph.get_closest_point(Vector3(x, y - 1, 0))
					stone_graph.connect_points(point_id, above_point)
					
				point_id += 1

	# Build an AStar graph of room connections
	
	var room_graph = AStar.new()
	point_id = 0
	for room in rooms:
		var room_center = room.position + room.size / 2
		room_graph.add_point(point_id, Vector3(room_center.x, room_center.y , 0))
		point_id += 1
	
	# Add random connections until everything is connected
	
	while !is_everything_connected(room_graph):
		add_random_connection(stone_graph, room_graph)

		
func is_everything_connected(graph):
	var points = graph.get_points()
	var start = points.pop_back()
	for point in points:
		var path = graph.get_point_path(start, point)
		if !path:
			return false
			
	return true

func add_random_connection(floor_graph, room_graph):
	# Pick rooms to connect

	var start_room_id = get_least_connected_point(room_graph)
	var end_room_id = get_nearest_unconnected_point(room_graph, start_room_id)
	
	# Pick door locations
	
	var start_position = pick_random_door_location(rooms[start_room_id])
	var end_position = pick_random_door_location(rooms[end_room_id])
	
	# Find a path to connect the doors to each other
	
	var closest_start_point = floor_graph.get_closest_point(start_position)
	var closest_end_point = floor_graph.get_closest_point(end_position)
	
	var path = floor_graph.get_point_path(closest_start_point, closest_end_point)

	
	# Add path to the map
	
	path = Array(path)
	
	set_tile(start_position.x, start_position.y, Tile.ElevatedFloor)
	set_tile(end_position.x, end_position.y, Tile.ElevatedFloor)
	
	for position in path:
		set_tile(position.x, position.y, Tile.Floor)
	
	room_graph.connect_points(start_room_id, end_room_id)	

func get_least_connected_point(graph):
	var point_ids = graph.get_points()
	
	var least
	var tied_for_least = []
	
	for point in point_ids:
		var count = graph.get_point_connections(point).size()
		if !least || count < least:
			least = count
			tied_for_least = [point]
		elif count == least:
			tied_for_least.append(point)
			
	return tied_for_least[randi() % tied_for_least.size()]
	
func get_nearest_unconnected_point(graph, target_point):
	var target_position = graph.get_point_position(target_point)
	var point_ids = graph.get_points()
	
	var nearest
	var tied_for_nearest = []
	
	for point in point_ids:
		if point == target_point:
			continue
		
		var path = graph.get_point_path(point, target_point)
		if path:
			continue
			
		var dist = (graph.get_point_position(point) - target_position).length()
		if !nearest || dist < nearest:
			nearest = dist
			tied_for_nearest = [point]
		elif dist == nearest:
			tied_for_nearest.append(point)
			
	return tied_for_nearest[randi() % tied_for_nearest.size()]
	
func pick_random_door_location(room):
	var options = []
	
	# Top and bottom walls
	
	for x in range(room.position.x + 1, room.end.x - 2):
		options.append(Vector3(x, room.position.y, 0))
		options.append(Vector3(x, room.end.y - 1, 0))
			
	# Left and right walls
	
	for y in range(room.position.y + 1, room.end.y - 2):
		options.append(Vector3(room.position.x, y, 0))
		options.append(Vector3(room.end.x - 1, y, 0))
			
	return options[randi() % options.size()]

func add_room(free_regions):
	var region = free_regions[randi() % free_regions.size()]
	
	var size_x = MinRoomDimension
	if region.size.x > MinRoomDimension:
		size_x += randi() % int(region.size.x - MinRoomDimension)
	
	var size_y = MinRoomDimension
	if region.size.y > MinRoomDimension:
		size_y += randi() % int(region.size.y - MinRoomDimension)

	size_x = min(size_x,MaxRoomDimension)
	size_y = min(size_y, MaxRoomDimension)
	
	var start_x = region.position.x
	if region.size.x > size_x:
		start_x += randi() % int(region.size.x - size_x)
	
	var start_y = region.position.y
	if region.size.y > size_y:
		start_y += randi() % int(region.size.y - size_y)

	var room = Rect2(start_x, start_y, size_x, size_y)
	rooms.append(room)
	
	for x in range(start_x, start_x + size_x):
		#Upper Wall of each room
		set_tile(x, start_y, Tile.Clif)
		#Lower Wall of each room
		set_tile(x, start_y + size_y - 1, Tile.Wall)
		
		#both left and right walls
	for y in range(start_y + 1, start_y + size_y - 1):
		set_tile(start_x,y,Tile.Wall)
		set_tile(start_x + size_x - 1, y, Tile.Wall)
		
		#filler of whole map
		for x in range(start_x + 1, start_x + size_x - 1):
			set_tile(x,y,Tile.Floor)
			
	cut_regions(free_regions, room)
	
func cut_regions(free_regions, region_to_remove):
	var removal_queue = []
	var addition_quene = []
	
	for region in free_regions:
		if region.intersects(region_to_remove):
			removal_queue.append(region)
			
			var leftover_left = region_to_remove.position.x - region.position.x - 1
			var leftover_right = region.end.x - region_to_remove.end.x - 1
			var leftover_above = region_to_remove.position.y - region.position.y - 1
			var leftover_below = region.end.y - region_to_remove.end.y - 1
			
			if leftover_left >= MinRoomDimension:
				addition_quene.append(Rect2(region.position, Vector2(leftover_left, region.size.y)))
			if leftover_right >= MinRoomDimension:
				addition_quene.append(Rect2(Vector2(region_to_remove.end.x + 1, region.position.y), Vector2(leftover_right, region.size.y)))
			if leftover_above >= MinRoomDimension:
				addition_quene.append(Rect2(region.position, Vector2(region.size.x, leftover_above)))
			if leftover_below >= MinRoomDimension:
				addition_quene.append(Rect2(Vector2(region.position.x, region_to_remove.end.y + 1), Vector2(region.size.x, leftover_below)))
				

	for region in removal_queue:
		free_regions.erase(region)
		
	for region in addition_quene:
		free_regions.append(region)

func set_tile(x,y,type):
	map[x][y] = type
	tile_map.set_cell(x, y, type)
	

