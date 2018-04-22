var hexes = [];
var edges = [];
var vertices = [];
var i;

var route;
var energy = {0: 0, -1: 0};

func init(hex1, i):
	self.hexes.append(hex1);
	self.i = i;
	return self;

func canPlace(player):
	if route != null || energy[player] == 0:
		return false;
	for edge in edges:
		if edge.route == player:
			return true;
	for hex in hexes:
		if hex.player == player and hex.base.name == "Homeworld":
			return true;
	return false;

func build(build, player):
	self.route = player;

func getType():
	if hexes.size() == 2 and hexes[0].type == hexes[1].type:
		return hexes[0].type;
	return 0;
