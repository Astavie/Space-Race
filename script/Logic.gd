var map;
var info;
var error;

var d = 0;
var s = 10;
var time = 0;

var players = { -1: { "wealth": 0, "colonists": 0, "plutonium": 0, "titanium": 0 }, 0: { "wealth": 10, "colonists": 5, "plutonium": 2, "titanium": 2 } };
var colors = { -1: Color(0.3, 0.0, 0.5), 0: Color(1.0, 0.1, 0.1) };

var bases = [];
var tokens = [];
var route;

var menu;
var options = [];
var current = [0, 0, 0];
var type;
var place;

var moving = false;
var selected;

var shield = load("res://tile/Shield.png");
var font;

var planet;
var aliens;
var homeworld;

var ai;
var viccy3 = 0;

func init(map):
	self.map = map;
	self.info = map.get_node("Foreground/Info");
	self.error = map.get_node("Foreground/Error");
	self.menu = map.get_node("Foreground/Menu");
	
	var label = Label.new();
	font = label.get_font("");
	label.free();
	
	var base_class = load("res://script/building/Base.gd");
	bases.append(base_class.new().init(1, { "wealth": 4, "plutonium": 4 }, { "wealth": 1, "colonists": 1 }, 2, "Colony", "Establish a new colony", load("res://tile/building/Colony.png")));
	bases.append(base_class.new().init(null, {}, { "wealth": 2, "colonists": 2, "plutonium": 1, "titanium": 1 }, 3, "Homeworld", "", load("res://tile/building/Homeworld.png")));
	bases.append(base_class.new().init(null, {}, {}, 6, "Teleporter", "", load("res://tile/building/Teleporter.png")));
	bases.append(base_class.new().init(2, { "wealth": 2, "titanium": 4 }, { "wealth": 1, "plutonium": 1, "titanium": 1 }, 1, "Mining Base", "Send your colonists to mine asteroids", load("res://tile/building/Mining Base.png")));
	bases.append(base_class.new().init(2, { "wealth": 2, "plutonium": 4 }, {}, 1, "Refueling Station", "Build a station to refuel transportation ships", load("res://tile/building/Fuel.png")));
	bases.append(base_class.new().init(2, { "wealth": 4, "titanium": 8 }, {}, 2, "Military Base", "Build a base that can produce fleet", load("res://tile/building/Star.png")));
	
	var token_class = load("res://script/building/Token.gd");
	tokens.append(token_class.new().init({ "wealth": 2, "colonists": 4 }, {}, 1, 0, true, "Passenger Ship", "A passenger ship to transport colonists to a new base", load("res://tile/building/Passenger.png")));
	tokens.append(token_class.new().init({ "wealth": 4, "plutonium": 4, "titanium": 4 }, {}, 2, 0, false, "Shield Generator", "Generate a shield around a colony for extra defense", load("res://tile/building/Shield.png")));
	tokens.append(token_class.new().init({ "wealth": 2, "plutonium": 2, "titanium": 2 }, {}, 1, 2, true, "Fleet", "A fleet that can attack other tokens and claim bases", load("res://tile/building/Fleet.png")));
	
	var route_class = load("res://script/building/Route.gd");
	route = route_class.new().init();
	
	place(0, 0, 4);
	
	var ran = [];
	var belt = randi() % 3 + 2;
	for vector in ring(Vector2(), belt):
		if randf() < 0.5:
			ran.append(vector);
			if randf() < 0.05:
				place(vector.x, vector.y, 5);
			else:
				place(vector.x, vector.y, 2);
	for vector in ring(Vector2(), belt + 1):
		if randf() < 0.5:
			ran.append(vector);
			if randf() < 0.05:
				place(vector.x, vector.y, 5);
			else:
				place(vector.x, vector.y, 2);
	aliens = ran[randi() % ran.size()];
	
	var orbit;
	if belt > 3 and randf() < 0.5:
		orbit = belt - ((randi() & 1) + 2);
	else:
		orbit = belt + ((randi() & 1) + 3);
	
	var pos = ring(Vector2(), orbit);
	planet = pos[randi() % pos.size()];
	
	map.get_node("Camera2D").set_offset(map.grid.map_to_world(map.getMap(planet.x, planet.y)) - Vector2(0, 200));
	
	place(planet.x, planet.y, 1);
	var x = planet.x + (((randi() & 1) - 0.5) * 2);
	var y = planet.y + (((randi() & 1) - 0.5) * 2);
	place(x, y, 3);
	# aliens = Vector2(x, y);
	
	homeworld = map.hex[int(planet.x)][int(planet.y)];
	homeworld.build(bases[1], 0);
	for edge in homeworld.edges:
		edge.build(route, 0);
	return self;

func place(q, r, type):
	q = int(q);
	r = int(r);
	map.hex[q][r].type = type;
	if map.icons[type] != null:
		map.objects.set_cellv(map.getMap(q, r), map.icons[type][randi() % map.icons[type].size()], randf() < 0.5, randf() < 0.5);

func ring(center, radius):
	var results = [];
	var cube = center + (map.dir[4] * radius);
	
	for i in range(6):
		for j in range(radius):
			results.append(cube);
			cube += map.dir[i];
	return results;

func process(delta):
	if not menu.is_visible() and not map.get_node("Foreground/Message").is_visible():
		d += delta;
		while d >= 1:
			d -= 1;
			s += 1;
		while s >= 10:
			time += 1;
			s -= 10;
			for q in map.hex.keys():
				for r in map.hex[q].keys():
					var base = map.hex[q][r].base;
					var player = map.hex[q][r].player;
					if base != null and players.has(player):
						for resource in base.resources.keys():
							if players[player].has(resource):
								players[player][resource] += base.resources[resource];
			if ai != null:
				ai.tick();
		info.text = "";
		for resource in players[0].keys():
			info.text += resource + ": " + str(players[0][resource]) + "\n";
		for q in map.hex.keys():
			for r in map.hex[q].keys():
				var base = map.hex[q][r];
				if base.base != null:
					var t = { -1: 0, 0: 0 };
					for vertex in base.vertices:
						if vertex.token != null:
							t[vertex.player] += vertex.token.attack;
					if base.player == 0 and t[-1] > t[0] and t[-1] >= base.base.strength:
						base.player = -1;
						if base.base.name == "Homeworld":
							game_over();
					if base.player == -1 and t[0] > t[-1] and t[0] >= base.base.strength:
						base.player = 0;
						if base.base.name == "Teleporter":
							victory();
		if ai != null:
			ai.process(delta);

func game_over():
	map.grid.set_visible(false);
	info.set_visible(false);
	error.set_visible(false);
	map.get_node("Foreground/Message/Sprite").set_texture(load("res://tile/Game over.png"));
	map.get_node("Foreground/Message").set_visible(true);
	viccy3 = -1;

func victory():
	map.grid.set_visible(false);
	info.set_visible(false);
	error.set_visible(false);
	map.get_node("Foreground/Message/Sprite").set_texture(load("res://tile/End.png"));
	map.get_node("Foreground/Message").set_visible(true);
	map.get_node("Music").set_stream(load("res://audio/Calm.ogg"));
	map.get_node("Music").play();
	viccy3 = -1;

func draw():
	for q in map.hex.keys():
		for r in map.hex[q].keys():
			if map.hex[q][r].base != null:
				var pos = map.grid.map_to_world(map.getMap(q, r));
				if map.hex[q][r].base.name == "Teleporter":
					map.draw_texture_rect(map.hex[q][r].base.texture, Rect2(pos - Vector2(16, 16), Vector2(32, 32)), false, colors[map.hex[q][r].player]);
				else:
					map.draw_texture_rect(map.hex[q][r].base.texture, Rect2(pos - Vector2(28, 16), Vector2(32, 32)), false, colors[map.hex[q][r].player]);
					map.draw_texture_rect(shield, Rect2(pos - Vector2(0, 10), Vector2(24, 24)), false);
					var shields = str(map.hex[q][r].base.getStrength(map.hex[q][r]));
					map.draw_string(font, pos + Vector2(12, 13) - (font.get_string_size(shields) / 2), shields, Color(0, 0, 0));
	
	var stop = true;
	for edge in map.edges:
		if edge.route != null:
			var a = edge.i * PI / 3;
			var p = Vector2(cos(a), sin(a)) * 46;
			var pos = map.grid.map_to_world(map.getMap(edge.hexes[0].q, edge.hexes[0].r)) + p;
			map.draw_set_transform(pos, a, Vector2(1, 1));
			map.draw_rect(Rect2(Vector2(-2, -9), Vector2(4, 4.5 * edge.energy[edge.route])), Color(0.1, 0.7, 1));
			map.draw_texture_rect(route.texture, Rect2(Vector2(-16, -16), Vector2(32, 32)), false, colors[edge.route]);
			map.draw_set_transform(Vector2(), 0, Vector2(1, 1));
			
			if moving and edge.route != null:
				for i in range(2):
					if edge.vertices[i] == selected:
						stop = false;
						var vertex = edge.vertices[(i + 1) % 2];
						if vertex.player != 0:
							if vertex.token != null and vertex.token.strength > selected.token.attack:
								continue;
							a = (vertex.i * PI / 3) + (PI / 6);
							p = Vector2(cos(a), sin(a)) * 53;
							map.draw_circle(map.grid.map_to_world(map.getMap(vertex.hexes[0].q, vertex.hexes[0].r)) + p, 8, Color(0.1, 1, 0.1, 0.5));
	if moving and (stop or selected.player != 0):
		moving = false;
		selected = null;
	for vertex in map.vertices:
		if vertex.token != null:
			var a = (vertex.i * PI / 3) + (PI / 6);
			var p = Vector2(cos(a), sin(a)) * 53;
			var pos = map.grid.map_to_world(map.getMap(vertex.hexes[0].q, vertex.hexes[0].r)) + p;
			map.draw_texture_rect(vertex.token.texture, Rect2(pos - Vector2(12, 12), Vector2(24, 24)), false, colors[vertex.player]);

func move(v0, edge, v1):
	if v1.token != null:
		if v1.token.strength > v0.token.attack:
			return false;
		map.get_node("Shoot").play();
	else:
		map.get_node("Move").play();
	edge.route = v0.player;
	if v1.token == null or v0.token.strength > v1.token.attack:
		v1.token = v0.token;
		v1.player = v0.player;
	else:
		v1.token = null;
		v1.player = null;
	v0.token = null;
	v0.player = null;
	return true;

func input(event):
	if not map.get_node("Foreground/Message").visible:
		if not menu.is_visible():
			if moving and event.is_action_pressed("ui_cancel"):
				moving = false;
				selected = null;
			elif event.is_action_pressed("ui_select"):
				if map.edge < 0:
					if map.vertex < 0:
						if moving:
							moving = false;
						var hex = map.getHex(map.getAxial(map.selected.x, map.selected.y));
						if hex != null and hex.canPlace(0):
							var t = hex.type;
							if hex.type & 1 == 1:
								t = 1;
							options = [];
							type = 0;
							place = hex;
							for b in bases:
								if b.type == t:
									options.append(b);
							if options.size() > 0:
								setupMenu();
					else:
						var vertex = map.getVertex(map.getAxial(map.selected.x, map.selected.y), map.vertex);
						if vertex != null:
							if moving and vertex.player != 0:
								for e in vertex.edges:
									if e.route != null:
										for v in e.vertices:
											if v == selected:
												if move(selected, e, vertex):
													selected = vertex;
												if selected.token == null:
													selected = null;
													moving = false;
												return;
							elif vertex.token != null and vertex.token.move and vertex.player == 0:
								moving = true;
								selected = vertex;
							else:
								var q = vertex.canPlace(0)
								if q > 0:
									if q == 2:
										options = [tokens[2]];
									else:
										options = tokens;
									type = 1;
									place = vertex;
									if options.size() > 0:
										setupMenu();
						elif moving:
							moving = false;
				elif moving:
					moving = false;
				else:
					var edge = map.getEdge(map.getAxial(map.selected.x, map.selected.y), map.edge);
					if edge != null and edge.canPlace(0):
						options = [route];
						type = 2;
						place = edge;
						setupMenu();
		elif event.is_action_pressed("ui_cancel"):
			menu.set_visible(false);
		elif event.is_action_pressed("ui_left"):
			current[type] = (current[type] - 1) % options.size();
			setupMenu();
		elif event.is_action_pressed("ui_right"):
			current[type] = (current[type] + 1) % options.size();
			setupMenu();
		elif event.is_action_pressed("ui_accept"):
			if aliens != null and type == 0 and place.q == aliens.x and place.r == aliens.y:
				ai = load("res://script/AI.gd").new().init(map, self, place);
				aliens = null;
				menu.set_visible(false);
			elif spend(options[current[type]], 0):
				place.build(options[current[type]], 0);
				map.get_node("Place").play();
				if aliens != null:
					for h in place.hexes:
						if h != null and h.q == aliens.x and h.r == aliens.y:
							ai = load("res://script/AI.gd").new().init(map, self, h);
							aliens = null;
							break;
				menu.set_visible(false);
			else:
				map.get_node("Nope").play();
	elif event.is_action_pressed("ui_accept"):
		if viccy3 < 0:
			map.get_tree().change_scene("res://view/Viewport.tscn");
		elif viccy3 >= 5:
			map.get_node("Foreground/Message").set_visible(false);
			map.grid.set_visible(true);
			info.set_visible(true);
			error.set_visible(true);
		else:
			viccy3 += 1;
			map.get_node("Foreground/Message/Sprite").set_texture(load("res://tile/tutorial/00" + str(viccy3) + ".png"));

func setupMenu():
	map.get_node("Build").play();
	if current[type] >= options.size():
		current[type] = 0;
	menu.get_node("Sprite").set_texture(options[current[type]].texture);
	menu.get_node("Prev").set_texture(options[(current[type] - 1) % options.size()].texture);
	menu.get_node("Next").set_texture(options[(current[type] + 1) % options.size()].texture);
	menu.get_node("Description").text = options[current[type]].description;
	var cost = "";
	for resource in options[current[type]].requirements.keys():
		cost += str(options[current[type]].requirements[resource]) + " " + resource + "\n";
	if type == 0:
		cost += "1 passenger ship";
	menu.get_node("Cost").text = cost;
	if options[current[type]].resources.size() > 0:
		menu.get_node("Gains").text = "Gains: ";
		var gains = "";
		for resource in options[current[type]].resources.keys():
			gains += str(options[current[type]].resources[resource]) + " " + resource + "\n";
		menu.get_node("Gain").text = gains;
	else:
		if type == 1:
			menu.get_node("Gains").text = "Combat: ";
			menu.get_node("Gain").text = str(options[current[type]].strength) + " defense";
			if options[current[type]].attack > 0:
				menu.get_node("Gain").text += "\n" + str(options[current[type]].attack) + " attack";
		else:
			menu.get_node("Gains").text = "";
			menu.get_node("Gain").text = "";
	menu.set_visible(true);

func spend(build, player):
	for resource in build.requirements.keys():
		if not players[player].has(resource) or not players[player][resource] >= build.requirements[resource]:
			return false;
	for resource in build.requirements.keys():
		players[player][resource] -= build.requirements[resource];
	return true;
