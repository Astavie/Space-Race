extends Node2D

var objects;
var grid;
var label;
var info;

var hex = {};
var edges = [];
var vertices = [];
var size = 10;

var dir = [Vector2(1, 0), Vector2(0, 1), Vector2(-1, 1), Vector2(-1, 0), Vector2(0, -1), Vector2(1, -1)];
var names = ["Space", "Terrestrial Planet", "Asteroids", "Moon", "Star", "Dwarf Planet", "Rings", "Gas Giant"];
var icons = [null   , [0, 1, 2]           ,[4, 5, 6, 7], [3]   , [8]   , [3]           , null   , null       ];

var selected;
var edge;
var vertex;

var logic;

func _ready():
	label = get_node("Foreground/Debug");
	info = get_node("Foreground/Error");
	
	objects = get_node("Objects");
	grid = objects.get_node("Hexes");
	var hex_class = load("res://script/hex/Hex.gd");
	
	for q in range(-size + 1, size):
		hex[q] = {};
		for r in range(-size + 1, size):
			if distance(Vector2(q, r), Vector2()) >= size:
				continue;
			var pos = getMap(q, r);
			hex[q][r] = hex_class.new().init(q, r, 0);
			grid.set_cellv(pos, 0);
	for q in hex.keys():
		for r in hex[q].keys():
			hex[q][r].finalizeEdges(self);
	for q in hex.keys():
		for r in hex[q].keys():
			hex[q][r].finalizeVertices(self);
	
	logic = load("res://script/Logic.gd").new().init(self);

func _process(delta):
	var mouse = get_global_mouse_position();
	
	var p0 = grid.world_to_map(mouse + Vector2(64, 64));
	var p1 = p0 - Vector2(1, 0);
	var p2 = p0 - Vector2(0, 1);
	var p3;
	if int(p0.y) & 1 == 0:
		p3 = p0 - Vector2(1, 1);
	else:
		p3 = p0 - Vector2(-1, 1);
	
	var d0 = mouse.distance_squared_to(grid.map_to_world(p0));
	var d1 = mouse.distance_squared_to(grid.map_to_world(p1));
	var d2 = mouse.distance_squared_to(grid.map_to_world(p2));
	var d3 = mouse.distance_squared_to(grid.map_to_world(p3));
	
	var dis;
	if d0 <= d1 and d0 <= d2 and d0 <= d3:
		selected = p0;
		dis = d0;
	elif d0 >= d1 and d1 <= d2 and d1 <= d3:
		selected = p1;
		dis = d1;
	elif d0 >= d2 and d1 >= d2 and d2 <= d3:
		selected = p2;
		dis = d2;
	else:
		selected = p3;
		dis = d3;
	label.text = "";
	if dis < 1024:
		edge = -1;
		vertex = -1;
	else:
		var angle = mouse.angle_to_point(grid.map_to_world(selected));
		var mod = fposmod(angle, PI / 3);
		var qp = PI / 9;
		if mod > qp and mod < 2 * qp:
			edge = -1;
			vertex = int(fposmod(angle, 2 * PI) / PI * 3);
		else:
			edge = int(fposmod(angle + (PI / 6), 2 * PI) / PI * 3);
			vertex = -1;
	logic.process(delta);
	
	if edge < 0:
		if vertex < 0:
			var h = getHex(getAxial(selected.x, selected.y));
			if h != null:
				info.text = names[h.type];
				if h.base != null:
					info.text += "\n" + h.base.name;
			else:
				info.text = "Space";
		else:
			var v = getVertex(getAxial(selected.x, selected.y), vertex);
			if v != null:
				info.text = names[v.getType()];
				if v.token != null:
					info.text += "\n" + v.token.name;
			else:
				info.text = "Space";
	else:
		var e = getEdge(getAxial(selected.x, selected.y), edge);
		if e != null:
			info.text = names[e.getType()];
			if e.route != null:
				info.text += "\nTransport Ship";
	update();

func _draw():
	logic.draw();
	
	if selected != null and not get_node("Foreground/Message").visible:
		if edge < 0:
			if vertex < 0:
				if getHex(getAxial(selected.x, selected.y)) != null:
					draw_circle(grid.map_to_world(selected), 8, Color(0, 0, 1, 0.5));
			elif getVertex(getAxial(selected.x, selected.y), vertex) != null:
				var a = (vertex * PI / 3) + (PI / 6)
				var p = Vector2(cos(a), sin(a)) * 53;
				draw_circle(grid.map_to_world(selected) + p, 8, Color(0, 0, 1, 0.5));
		elif getEdge(getAxial(selected.x, selected.y), edge) != null:
			var a = edge * PI / 3;
			var p = Vector2(cos(a), sin(a)) * 46;
			draw_circle(grid.map_to_world(selected) + p, 8, Color(0, 0, 1, 0.5));

func _input(event):
	if event.is_action_pressed("ui_toggle"):
		grid.set_visible(not grid.is_visible());
	logic.input(event);

func distance(a, b):
	return (abs(a.x - b.x) + abs (a.x + a.y - b.x - b.y) + abs(a.y - b.y)) / 2;

func getMap(q, r):
	return Vector2(q + (r - (int(r) & 1)) / 2, r);

func getAxial(x, y):
	return Vector2(x - (y - (int(y) & 1)) / 2, y);

func getHex(vector):
	var q = int(vector.x);
	var r = int(vector.y);
	if hex.has(q) and hex[q].has(r):
		return hex[q][r];
	return null;

func getEdge(vector, i):
	var q = int(vector.x);
	var r = int(vector.y);
	if hex.has(q) and hex[q].has(r) and hex[q][r].edges[i] != null:
		return hex[q][r].edges[i];
	else:
		q += int(dir[i].x);
		r += int(dir[i].y);
		if hex.has(q) and hex[q].has(r):
			return hex[q][r].edges[(i + 3) % 6];
	return null;

func getVertex(vector, i):
	var q = int(vector.x);
	var r = int(vector.y);
	if hex.has(q) and hex[q].has(r) and hex[q][r].vertices[i] != null:
		return hex[q][r].vertices[i];
	else:
		var q0 = int(q + dir[i].x);
		var r0 = int(r + dir[i].y);
		if hex.has(q0) and hex[q0].has(r0) and hex[q0][r0].vertices[(i + 2) % 6] != null:
			return hex[q0][r0].vertices[(i + 2) % 6];
		else:
			var q1 = int(q + dir[(i + 1) % 6].x);
			var r1 = int(r + dir[(i + 1) % 6].y);
			if hex.has(q1) and hex[q1].has(r1):
				return hex[q1][r1].vertices[(i + 4) % 6];
	return null;
