var q;
var r;

var hexes = [null, null, null, null, null, null];
var edges = [null, null, null, null, null, null];
var vertices = [null, null, null, null, null, null];
var type; # 0 = Space, 1 = Terrestrial Planet, 2 = Asteroids, 3 = Moon, 4 = Star, 5 = Dwarf Planet, 6 = Rings, 7 =? Gas Giant

var base;
var player;

func init(q, r, type = 0):
	self.q = q;
	self.r = r;
	self.type = type;
	return self;

func finalizeEdges(map):
	var edge_class = load("res://script/hex/Edge.gd");
	for i in range (6):
		var edge = map.getEdge(Vector2(q, r), i);
		if edge == null:
			edge = edge_class.new().init(self, i);
			map.edges.append(edge);
		else:
			edge.hexes.append(self);
			hexes[i] = edge.hexes[0];
		if i > 0:
			edge.edges.append(edges[i - 1]);
			edges[i - 1].edges.append(edge);
			if i == 5:
				edge.edges.append(edges[0]);
				edges[0].edges.append(edge);
		edges[i] = edge;

func finalizeVertices(map):
	var vertex_class = load("res://script/hex/Vertex.gd");
	for i in range (6):
		var vertex = map.getVertex(Vector2(q, r), i);
		if vertex == null:
			vertex = vertex_class.new().init(self, i);
			map.vertices.append(vertex);
		else:
			vertex.hexes.append(self);
		if i > 0:
			vertex.vertices.append(vertices[i - 1]);
			vertices[i - 1].vertices.append(vertex);
			if i == 5:
				vertex.vertices.append(vertices[0]);
				vertices[0].vertices.append(vertex);
		
		if not vertex.edges.has(edges[i]):
			vertex.edges.append(edges[i]);
			edges[i].vertices.append(vertex);
		if not vertex.edges.has(edges[(i + 1) % 6]):
			vertex.edges.append(edges[(i + 1) % 6]);
			edges[(i + 1) % 6].vertices.append(vertex);
		
		vertices[i] = vertex;

func canPlace(player):
	if base != null:
		return false;
	for vertex in vertices:
		if vertex.token != null and vertex.player == player and vertex.token.name == "Passenger Ship":
			return true;
	return false;

func build(build, player):
	for vertex in vertices:
		if vertex.token != null and vertex.player == player and vertex.token.name == "Passenger Ship":
			vertex.token = null;
			vertex.player = null;
			break;
	self.base = build;
	self.player = player;
	if type & 1 == 1 or build.name == "Refueling Station" or build.name == "Dyson Sphere" or build.name == "Teleporter":
		calculateEnergy(player, 4);

func calculateEnergy(player, energy):
	var e = [];
	var m = [];
	for edge in edges:
		if edge.energy[player] < energy:
			e.append(edge);
	while energy > 0 and e.size() > 0:
		for edge in e:
			edge.energy[player] = energy;
			for n in edge.edges:
				if n.energy[player] < energy and not e.has(n) and not m.has(n):
					m.append(n);
		energy -= 1;
		e = m;
		m = [];
