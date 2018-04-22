var map;
var logic;
var spawn;

var total = 0;
var time = 0;

var fleet = [];

func init(map, logic, spawn):
	self.map = map;
	self.logic = logic;
	self.spawn = spawn;
	spawn.build(logic.bases[2], -1);
	for edge in spawn.edges:
		if edge.route == null:
			edge.route = -1;
	map.get_node("Music").set_stream(load("res://audio/Not so calm.ogg"));
	map.get_node("Music").play();
	return self;

func tick():
	var t = 3;
	var played = false;
	for vertex in spawn.vertices:
		if total >= (logic.time / 2) or t == 0:
			break;
		if vertex.token == null:
			if not played:
				map.get_node("Teleport").play();
				played = true;
			vertex.build(logic.tokens[2], -1);
			fleet.append(vertex);
		t -= 1;
		total += 1;

func process(delta):
	time += delta;
	while time > 0.25:
		time -= 0.25;
		if fleet.size() > 0:
			var vertex = fleet[randi() % fleet.size()];
			if vertex.player != -1:
				fleet.erase(vertex);
			else:
				var goal = logic.homeworld.vertices[randi() % 6];
				if goal.player != -1:
					var path = astar(vertex, goal);
					if path.size() > 0 and path[0].player != -1 and logic.move(vertex, getEdge(vertex, path[0]), path[0]):
						fleet.erase(vertex);
						fleet.append(path[0]);

func getEdge(v0, v1):
	for edge in v0.edges:
		for vertex in edge.vertices:
			if vertex == v1:
				return edge;
	return null;

func astar(goal, start):
	var closed = [];
	var open = [start];
	var from = {};
	var gscore = { start: 0 };
	var fscore = { start: map.distance(Vector2(start.hexes[0].q, start.hexes[0].r), Vector2(goal.hexes[0].q, goal.hexes[0].r)) };
	while open.size() > 0:
		var current = open[0];
		var f = fscore[current];
		for vertex in open:
			if fscore[vertex] < f:
				current = vertex;
				f = fscore[current];
		
		if current == goal:
			var path = [];
			while from.has(current):
				current = from[current];
				path.append(current);
			return path;
		
		open.erase(current);
		closed.append(current);
		for edge in current.edges:
			if edge.route == null:
				continue;
			var neighbour = edge.vertices[(edge.vertices.find(current) + 1) & 1];
			if closed.has(neighbour):
				continue;
			if not open.has(neighbour):
				open.append(neighbour);
			
			var tmp = gscore[current] + 1;
			if gscore.has(neighbour) and tmp >= gscore[neighbour]:
				continue;
			from[neighbour] = current;
			gscore[neighbour] = tmp;
			fscore[neighbour] = map.distance(Vector2(neighbour.hexes[0].q, neighbour.hexes[0].r), Vector2(goal.hexes[0].q, goal.hexes[0].r));
	return [];
